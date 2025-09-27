import 'dart:convert';

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

class GovernmentEmailRepository {
  GovernmentEmailRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String _claimCollection = 'government_email_index';
  static const String _aliasCollection = 'government_email_aliases';

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
