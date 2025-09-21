import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../core/firebase/paginated_query.dart';
import '../../../core/utils/prefix_tokenizer.dart';
import '../domain/user_profile.dart';

typedef JsonMap = Map<String, Object?>;

class UserProfileRepository {
  UserProfileRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final PrefixTokenizer _tokenizer = const PrefixTokenizer();

  CollectionReference<JsonMap> get _usersRef => _firestore.collection('users');

  DocumentReference<JsonMap> _userDoc(String uid) => _usersRef.doc(uid);

  DocumentReference<JsonMap> _handleDoc(String handle) =>
      _firestore.collection('handles').doc(handle);

  CollectionReference<JsonMap> _badgesCollection(String uid) =>
      _userDoc(uid).collection('badges');

  Future<UserProfile?> fetchProfile(String uid) async {
    final DocumentSnapshot<JsonMap> snapshot = await _userDoc(uid).get();
    if (!snapshot.exists) {
      return null;
    }
    return UserProfile.fromSnapshot(snapshot);
  }

  Stream<UserProfile?> watchProfile(String uid) {
    return _userDoc(uid).snapshots().map((DocumentSnapshot<JsonMap> snapshot) {
      if (!snapshot.exists) {
        return null;
      }
      return UserProfile.fromSnapshot(snapshot);
    });
  }

  Future<UserProfile> ensureUserProfile({
    required String uid,
    required String nickname,
    required String serial,
    required String department,
    required String region,
    String jobTitle = '직무 미입력',
    int yearsOfService = 0,
    String? photoUrl,
    UserRole role = UserRole.member,
  }) async {
    return _firestore.runTransaction<UserProfile>((Transaction transaction) async {
      final DocumentReference<JsonMap> userRef = _userDoc(uid);
      final DocumentSnapshot<JsonMap> existing = await transaction.get(userRef);
      if (existing.exists) {
        return UserProfile.fromSnapshot(existing);
      }

      final String normalizedHandle = _normalizeHandle(nickname, fallback: uid);
      await _reserveHandle(transaction, normalizedHandle, uid);

      final DateTime now = DateTime.now();
      final UserProfile profile = UserProfile(
        uid: uid,
        nickname: nickname,
        handle: normalizedHandle,
        serial: serial,
        department: department,
        region: region,
        role: role,
        jobTitle: jobTitle,
        yearsOfService: yearsOfService,
        createdAt: now,
        updatedAt: now,
        supporterLevel: 0,
        premiumTier: PremiumTier.none,
        points: 0,
        level: 1,
        badges: const <String>[],
        careerTrack: _careerTrackFromSerial(serial),
        excludedSerials: const <String>{},
        excludedDepartments: const <String>{},
        excludedRegions: const <String>{},
        nicknameChangeCount: 0,
        nicknameLastChangedAt: null,
        nicknameResetAt: DateTime(now.year, now.month),
        extraNicknameTickets: 0,
        interests: const <String>[],
        bio: null,
        photoUrl: photoUrl,
        isAnonymousDefault: true,
        hasUnreadModerationNotice: false,
        moderationStrike: 0,
        isDeleted: false,
        lastLoginAt: now,
      );

      transaction.set(userRef, profile.toMap());
      return profile;
    });
  }

  Future<UserProfile> updateNickname({
    required String uid,
    required String newNickname,
  }) async {
    final String trimmedNickname = newNickname.trim();
    if (trimmedNickname.isEmpty) {
      throw ArgumentError('닉네임은 비워둘 수 없습니다.');
    }

    return _firestore.runTransaction<UserProfile>((Transaction transaction) async {
      final DocumentReference<JsonMap> userRef = _userDoc(uid);
      final DocumentSnapshot<JsonMap> userSnapshot = await transaction.get(userRef);
      if (!userSnapshot.exists) {
        throw StateError('사용자 프로필을 찾을 수 없습니다.');
      }

      final UserProfile profile = UserProfile.fromSnapshot(userSnapshot);
      final DateTime now = DateTime.now();
      if (!profile.canChangeNickname) {
        throw StateError('닉네임 변경 가능 횟수가 부족합니다.');
      }

      final String newHandle = _normalizeHandle(trimmedNickname, fallback: uid);
      if (newHandle != profile.handle) {
        final DocumentReference<JsonMap> newHandleDoc = _handleDoc(newHandle);
        final DocumentSnapshot<JsonMap> handleSnapshot = await transaction.get(newHandleDoc);
        if (handleSnapshot.exists) {
          throw StateError('이미 사용 중인 닉네임입니다.');
        }

        transaction.set(newHandleDoc, <String, Object?>{'uid': uid});
        transaction.delete(_handleDoc(profile.handle));
      }

      int changeCount = profile.nicknameChangeCount;
      int extraTickets = profile.extraNicknameTickets;
      if (changeCount >= 2) {
        if (extraTickets <= 0) {
          throw StateError('닉네임 변경권이 부족합니다.');
        }
        extraTickets -= 1;
      } else {
        changeCount += 1;
      }

      final DateTime resetAnchor = DateTime(now.year, now.month);

      final Map<String, Object?> updates = <String, Object?>{
        'nickname': trimmedNickname,
        'handle': newHandle,
        'updatedAt': Timestamp.fromDate(now),
        'nicknameLastChangedAt': Timestamp.fromDate(now),
        'nicknameResetAt': Timestamp.fromDate(resetAnchor),
        'nicknameChangeCount': changeCount,
        'extraNicknameTickets': extraTickets,
        'keywords': _tokenizer.buildPrefixes(title: trimmedNickname),
      };

      transaction.update(userRef, updates);
      return profile.copyWith(
        nickname: trimmedNickname,
        handle: newHandle,
        updatedAt: now,
        nicknameLastChangedAt: now,
        nicknameResetAt: resetAnchor,
        nicknameChangeCount: changeCount,
        extraNicknameTickets: extraTickets,
      );
    });
  }

  Future<UserProfile> updateProfileFields({
    required String uid,
    String? serial,
    String? department,
    String? region,
    CareerTrack? careerTrack,
    List<String>? interests,
    String? bio,
    bool? isAnonymousDefault,
    String? jobTitle,
    int? yearsOfService,
    String? photoUrl,
  }) async {
    final DocumentReference<JsonMap> doc = _userDoc(uid);
    final Map<String, Object?> updates = <String, Object?>{};
    if (serial != null) {
      updates['serial'] = serial;
    }
    if (department != null) {
      updates['department'] = department;
    }
    if (region != null) {
      updates['region'] = region;
    }
    if (careerTrack != null) {
      updates['careerTrack'] = careerTrack.name;
    }
    if (interests != null) {
      updates['interests'] = interests;
    }
    if (bio != null) {
      updates['bio'] = bio;
    }
    if (isAnonymousDefault != null) {
      updates['isAnonymousDefault'] = isAnonymousDefault;
    }
    if (jobTitle != null) {
      updates['jobTitle'] = jobTitle;
    }
    if (yearsOfService != null) {
      updates['yearsOfService'] = yearsOfService;
    }
    if (photoUrl != null) {
      updates['photoUrl'] = photoUrl;
    }
    updates['updatedAt'] = Timestamp.now();

    await doc.update(updates);
    final DocumentSnapshot<JsonMap> updatedSnapshot = await doc.get();
    return UserProfile.fromSnapshot(updatedSnapshot);
  }

  Future<void> updateExclusionSettings({
    required String uid,
    Set<String>? excludedSerials,
    Set<String>? excludedDepartments,
    Set<String>? excludedRegions,
  }) async {
    final Map<String, Object?> updates = <String, Object?>{
      'updatedAt': Timestamp.now(),
    };

    if (excludedSerials != null) {
      updates['excludedSerials'] = excludedSerials.toList(growable: false);
    }
    if (excludedDepartments != null) {
      updates['excludedDepartments'] = excludedDepartments.toList(growable: false);
    }
    if (excludedRegions != null) {
      updates['excludedRegions'] = excludedRegions.toList(growable: false);
    }

    await _userDoc(uid).update(updates);
  }

  Future<void> incrementPoints({
    required String uid,
    required int delta,
    int? levelDelta,
  }) async {
    await _userDoc(uid).update(<String, Object?>{
      'points': FieldValue.increment(delta),
      if (levelDelta != null) 'level': FieldValue.increment(levelDelta),
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> assignBadge({
    required String uid,
    required String badgeId,
    required String label,
    String? description,
  }) async {
    final DocumentReference<JsonMap> badgeDoc = _badgesCollection(uid).doc(badgeId);
    await badgeDoc.set(<String, Object?>{
      'label': label,
      'description': description,
      'awardedAt': Timestamp.now(),
    });
  }

  Future<void> addNicknameTickets({
    required String uid,
    int count = 1,
  }) async {
    await _userDoc(uid).update(<String, Object?>{
      'extraNicknameTickets': FieldValue.increment(count),
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> markModerationNoticeRead(String uid) async {
    await _userDoc(uid).update(<String, Object?>{
      'hasUnreadModerationNotice': false,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> recordLogin(String uid) async {
    await _userDoc(uid).update(<String, Object?>{
      'lastLoginAt': Timestamp.now(),
    });
  }

  Future<PaginatedQueryResult<UserProfile>> fetchProfiles({
    int limit = 20,
    QueryDocumentSnapshotJson? startAfter,
    String? serial,
    String? department,
    String? region,
    bool excludeDeleted = true,
  }) async {
    QueryJson query = _usersRef.orderBy('createdAt', descending: true).limit(limit);
    if (serial != null) {
      query = query.where('serial', isEqualTo: serial);
    }
    if (department != null) {
      query = query.where('department', isEqualTo: department);
    }
    if (region != null) {
      query = query.where('region', isEqualTo: region);
    }
    if (excludeDeleted) {
      query = query.where('isDeleted', isEqualTo: false);
    }
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final QuerySnapshot<JsonMap> snapshot = await query.get();
    final List<UserProfile> profiles = snapshot.docs
        .map(UserProfile.fromSnapshot)
        .toList(growable: false);

    final bool hasMore = snapshot.docs.length == limit;
    final QueryDocumentSnapshotJson? last = snapshot.docs.isEmpty ? null : snapshot.docs.last;
    return PaginatedQueryResult<UserProfile>(items: profiles, lastDocument: last, hasMore: hasMore);
  }

  Future<String> uploadProfileImage({
    required String uid,
    required String path,
    required List<int> bytes,
    String contentType = 'image/jpeg',
  }) async {
    final Reference ref = _storage.ref('profile_images/$uid/$path');
    await ref.putData(bytes, SettableMetadata(contentType: contentType));
    return ref.getDownloadURL();
  }

  String _normalizeHandle(String nickname, {required String fallback}) {
    final String trimmed = nickname.trim().toLowerCase();
    if (trimmed.isEmpty) {
      return fallback;
    }

    final String normalized = trimmed
        .replaceAll(RegExp(r'[^a-z0-9가-힣_]'), '-')
        .replaceAll(RegExp(r'-{2,}'), '-')
        .replaceAll(RegExp(r'^-+'), '')
        .replaceAll(RegExp(r'-+$'), '');

    if (normalized.isEmpty) {
      return '$fallback-${_randomSuffix()}';
    }
    return normalized;
  }

  Future<void> _reserveHandle(Transaction transaction, String handle, String uid) async {
    final DocumentReference<JsonMap> handleRef = _handleDoc(handle);
    final DocumentSnapshot<JsonMap> snapshot = await transaction.get(handleRef);
    if (snapshot.exists) {
      throw StateError('닉네임이 이미 사용 중입니다.');
    }
    transaction.set(handleRef, <String, Object?>{'uid': uid});
  }

  String _randomSuffix() {
    final Random random = Random();
    final int suffix = random.nextInt(9999);
    return suffix.toString().padLeft(4, '0');
  }

  CareerTrack _careerTrackFromSerial(String serial) {
    for (final CareerTrack track in CareerTrack.values) {
      if (track == CareerTrack.none) {
        continue;
      }
      if (serial.toLowerCase().contains(track.name.toLowerCase())) {
        return track;
      }
    }
    return CareerTrack.none;
  }
}
