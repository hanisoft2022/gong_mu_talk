import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

enum GovernmentEmailClaimStatus { notClaimed, pending, verified }

class GovernmentEmailClaim {
  const GovernmentEmailClaim({
    required this.userId,
    required this.status,
    this.originalEmail,
    this.originalProviderIds = const <String>[],
  });

  final String userId;
  final GovernmentEmailClaimStatus status;
  final String? originalEmail;
  final List<String> originalProviderIds;
}

class GovernmentEmailAlias {
  const GovernmentEmailAlias({
    required this.governmentEmail,
    required this.userId,
  });

  final String governmentEmail;
  final String userId;
}

class GovernmentEmailVerificationToken {
  const GovernmentEmailVerificationToken({
    required this.token,
    required this.email,
    required this.userId,
    required this.expiresAt,
    required this.createdAt,
    this.verifiedAt,
  });

  final String token;
  final String email;
  final String userId;
  final DateTime expiresAt;
  final DateTime createdAt;
  final DateTime? verifiedAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isVerified => verifiedAt != null;
}

class GovernmentEmailRepository {
  GovernmentEmailRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String _claimCollection = 'government_email_index';
  static const String _aliasCollection = 'government_email_aliases';
  static const String _verificationTokenCollection = 'government_email_verification_tokens';

  Future<GovernmentEmailClaim?> fetchClaim(String email) async {
    final DocumentSnapshot<Map<String, dynamic>> snapshot = await _claimRef(
      email,
    ).get();
    if (!snapshot.exists) {
      return null;
    }

    final Map<String, dynamic> data = snapshot.data()!;
    final String userId = (data['userId'] as String?) ?? '';
    final String statusValue = (data['status'] as String?) ?? 'pending';
    final List<String> providerIds =
        ((data['originalProviderIds'] as List<dynamic>?) ?? const <dynamic>[])
            .map((dynamic value) => value.toString())
            .toList(growable: false);

    final GovernmentEmailClaimStatus status = switch (statusValue) {
      'verified' => GovernmentEmailClaimStatus.verified,
      _ => GovernmentEmailClaimStatus.pending,
    };

    return GovernmentEmailClaim(
      userId: userId,
      status: status,
      originalEmail: data['originalEmail'] as String?,
      originalProviderIds: providerIds,
    );
  }

  Future<void> markPending({
    required String userId,
    required String governmentEmail,
    String? originalEmail,
    List<String> providerIds = const <String>[],
    String? displayName,
    String? photoUrl,
  }) async {
    final DocumentReference<Map<String, dynamic>> ref = _claimRef(
      governmentEmail,
    );
    final DocumentSnapshot<Map<String, dynamic>> snapshot = await ref.get();

    final Map<String, dynamic> payload = <String, dynamic>{
      'email': _normalize(governmentEmail),
      'userId': userId,
      'status': 'pending',
      'originalEmail': originalEmail,
      'originalProviderIds': providerIds,
      'updatedAt': FieldValue.serverTimestamp(),
      'userDisplayName': displayName,
      'userPhotoUrl': photoUrl,
    };

    if (!snapshot.exists) {
      payload['createdAt'] = FieldValue.serverTimestamp();
    }

    await ref.set(payload, SetOptions(merge: true));
  }

  Future<void> markVerified({
    required String userId,
    required String governmentEmail,
    String? originalEmail,
    List<String> providerIds = const <String>[],
    String? displayName,
    String? photoUrl,
    String? verifiedEmail,
  }) async {
    final DocumentReference<Map<String, dynamic>> ref = _claimRef(
      governmentEmail,
    );
    final DocumentSnapshot<Map<String, dynamic>> snapshot = await ref.get();
    final Map<String, dynamic> payload = <String, dynamic>{
      'email': _normalize(governmentEmail),
      'userId': userId,
      'status': 'verified',
      'verifiedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'userDisplayName': displayName,
      'userPhotoUrl': photoUrl,
      'verifiedUserEmail': verifiedEmail,
      'verifiedProviderIds': providerIds,
    };

    if (originalEmail != null && originalEmail.isNotEmpty) {
      payload['originalEmail'] = originalEmail;
    }
    if (providerIds.isNotEmpty) {
      payload['originalProviderIds'] = providerIds;
    }
    if (!snapshot.exists) {
      payload['createdAt'] = FieldValue.serverTimestamp();
    }

    await ref.set(payload, SetOptions(merge: true));
  }

  Future<void> upsertAlias({
    required String legacyEmail,
    required String governmentEmail,
    required String userId,
    String? displayName,
    String? photoUrl,
  }) async {
    final DocumentReference<Map<String, dynamic>> ref = _aliasRef(legacyEmail);
    final DocumentSnapshot<Map<String, dynamic>> snapshot = await ref.get();

    final Map<String, dynamic> payload = <String, dynamic>{
      'legacyEmail': _normalize(legacyEmail),
      'governmentEmail': _normalize(governmentEmail),
      'userId': userId,
      'updatedAt': FieldValue.serverTimestamp(),
      'userDisplayName': displayName,
      'userPhotoUrl': photoUrl,
    };

    if (!snapshot.exists) {
      payload['createdAt'] = FieldValue.serverTimestamp();
    }

    await ref.set(payload, SetOptions(merge: true));
  }

  Future<GovernmentEmailAlias?> findAliasForLegacyEmail(
    String legacyEmail,
  ) async {
    final DocumentSnapshot<Map<String, dynamic>> snapshot = await _aliasRef(
      legacyEmail,
    ).get();
    if (!snapshot.exists) {
      return null;
    }

    final Map<String, dynamic> data = snapshot.data()!;
    final String? governmentEmail = data['governmentEmail'] as String?;
    final String? userId = data['userId'] as String?;
    if (governmentEmail == null ||
        governmentEmail.isEmpty ||
        userId == null ||
        userId.isEmpty) {
      return null;
    }

    return GovernmentEmailAlias(
      governmentEmail: governmentEmail,
      userId: userId,
    );
  }

  Future<void> ensureVerifiedClaim({
    required String userId,
    required String governmentEmail,
    String? displayName,
    String? photoUrl,
    String? verifiedEmail,
    List<String> providerIds = const <String>[],
  }) async {
    final GovernmentEmailClaim? existingClaim = await fetchClaim(
      governmentEmail,
    );
    if (existingClaim != null && existingClaim.userId != userId) {
      return;
    }

    final List<String> resolvedProviderIds = providerIds.isNotEmpty
        ? providerIds
        : (existingClaim?.originalProviderIds ?? const <String>[]);

    if (existingClaim == null ||
        existingClaim.status != GovernmentEmailClaimStatus.verified) {
      await markVerified(
        userId: userId,
        governmentEmail: governmentEmail,
        originalEmail: existingClaim?.originalEmail,
        providerIds: resolvedProviderIds,
        displayName: displayName,
        photoUrl: photoUrl,
        verifiedEmail: verifiedEmail,
      );
      return;
    }

    if (displayName != null ||
        photoUrl != null ||
        verifiedEmail != null ||
        providerIds.isNotEmpty) {
      await markVerified(
        userId: userId,
        governmentEmail: governmentEmail,
        originalEmail: existingClaim.originalEmail,
        providerIds: resolvedProviderIds,
        displayName: displayName,
        photoUrl: photoUrl,
        verifiedEmail: verifiedEmail,
      );
    }
  }

  Future<String?> findOriginalEmailForGovernmentEmail({
    required String userId,
    required String governmentEmail,
  }) async {
    final GovernmentEmailClaim? claim = await fetchClaim(governmentEmail);
    if (claim == null) {
      return null;
    }

    if (claim.userId != userId) {
      return null;
    }

    final String? originalEmail = claim.originalEmail;
    if (originalEmail == null || originalEmail.isEmpty) {
      return null;
    }

    return originalEmail;
  }

  /// 새로운 공직자 메일 인증 토큰 생성
  Future<String> createVerificationToken({
    required String userId,
    required String governmentEmail,
  }) async {
    // 기존에 해당 이메일로 인증된 사용자가 있는지 확인
    final GovernmentEmailClaim? existingClaim = await fetchClaim(governmentEmail);
    if (existingClaim != null &&
        existingClaim.status == GovernmentEmailClaimStatus.verified &&
        existingClaim.userId != userId) {
      throw Exception('이미 다른 사용자가 인증한 공직자 메일입니다.');
    }

    // 랜덤 토큰 생성 (64자리 hex)
    final Random random = Random.secure();
    final List<int> bytes = List<int>.generate(32, (_) => random.nextInt(256));
    final String token = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

    final DateTime now = DateTime.now();
    final DateTime expiresAt = now.add(const Duration(hours: 24)); // 24시간 후 만료

    // 토큰 저장
    await _firestore.collection(_verificationTokenCollection).doc(token).set({
      'token': token,
      'email': _normalize(governmentEmail),
      'userId': userId,
      'expiresAt': Timestamp.fromDate(expiresAt),
      'createdAt': Timestamp.fromDate(now),
      'verifiedAt': null,
    });

    // pending 상태로 claim 생성/업데이트
    await markPending(
      userId: userId,
      governmentEmail: governmentEmail,
    );

    return token;
  }

  /// 인증 토큰 검증 및 처리
  Future<bool> verifyToken(String token) async {
    final DocumentSnapshot<Map<String, dynamic>> tokenSnapshot =
        await _firestore.collection(_verificationTokenCollection).doc(token).get();

    if (!tokenSnapshot.exists) {
      return false;
    }

    final Map<String, dynamic> data = tokenSnapshot.data()!;
    final GovernmentEmailVerificationToken verificationToken = _parseVerificationToken(data);

    if (verificationToken.isExpired || verificationToken.isVerified) {
      return false;
    }

    final DateTime now = DateTime.now();

    // 토큰을 verified 상태로 업데이트
    await tokenSnapshot.reference.update({
      'verifiedAt': Timestamp.fromDate(now),
    });

    // claim을 verified 상태로 업데이트
    await markVerified(
      userId: verificationToken.userId,
      governmentEmail: verificationToken.email,
    );

    // 사용자 프로필에 공직자 메일 정보 업데이트
    await _updateUserProfileGovernmentEmail(
      userId: verificationToken.userId,
      governmentEmail: verificationToken.email,
      verifiedAt: now,
    );

    return true;
  }

  /// 사용자 프로필에 공직자 메일 정보 업데이트
  Future<void> _updateUserProfileGovernmentEmail({
    required String userId,
    required String governmentEmail,
    required DateTime verifiedAt,
  }) async {
    await _firestore.collection('users').doc(userId).update({
      'governmentEmail': governmentEmail,
      'governmentEmailVerifiedAt': Timestamp.fromDate(verifiedAt),
      'updatedAt': Timestamp.fromDate(verifiedAt),
    });
  }

  /// 특정 사용자의 미완료 인증 토큰들 조회
  Future<List<GovernmentEmailVerificationToken>> getPendingTokensForUser(String userId) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
        .collection(_verificationTokenCollection)
        .where('userId', isEqualTo: userId)
        .where('verifiedAt', isNull: true)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => _parseVerificationToken(doc.data()))
        .where((token) => !token.isExpired)
        .toList();
  }

  GovernmentEmailVerificationToken _parseVerificationToken(Map<String, dynamic> data) {
    return GovernmentEmailVerificationToken(
      token: data['token'] as String,
      email: data['email'] as String,
      userId: data['userId'] as String,
      expiresAt: (data['expiresAt'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      verifiedAt: data['verifiedAt'] != null
          ? (data['verifiedAt'] as Timestamp).toDate()
          : null,
    );
  }

  DocumentReference<Map<String, dynamic>> _claimRef(String email) {
    final String docId = _encodeEmail(email);
    return _firestore.collection(_claimCollection).doc(docId);
  }

  DocumentReference<Map<String, dynamic>> _aliasRef(String email) {
    final String docId = _encodeEmail(email);
    return _firestore.collection(_aliasCollection).doc(docId);
  }

  String _normalize(String email) => email.trim().toLowerCase();

  String _encodeEmail(String email) =>
      base64Url.encode(utf8.encode(_normalize(email)));
}
