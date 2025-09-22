import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firebase/paginated_query.dart';
import '../../profile/domain/user_profile.dart';
import '../domain/entities/match_profile.dart';

typedef JsonMap = Map<String, Object?>;

class MatchRequestResult {
  const MatchRequestResult({required this.isSuccessful, required this.message});

  final bool isSuccessful;
  final String message;
}

class MatchingRepository {
  MatchingRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const int _dailyExposureLimit = 8;
  static const int _premiumExposureBonus = 10;

  CollectionReference<JsonMap> get _usersRef => _firestore.collection('users');

  CollectionReference<JsonMap> _userMatchingMeta(String uid) =>
      _userDoc(uid).collection('matching_meta');

  DocumentReference<JsonMap> _userDoc(String uid) => _usersRef.doc(uid);

  CollectionReference<JsonMap> _likesCollection(String uid) =>
      _userDoc(uid).collection('matching_likes');

  CollectionReference<JsonMap> _receivedLikesCollection(String uid) =>
      _userDoc(uid).collection('matching_inbox');

  Future<List<MatchProfile>> fetchCandidates({
    required UserProfile currentUser,
    int limit = 6,
    bool includePremiumHighlights = true,
  }) async {
    final int allowed = await _ensureExposureCapacity(
      currentUser: currentUser,
      requested: limit,
    );
    if (allowed <= 0) {
      return const <MatchProfile>[];
    }

    final QuerySnapshot<JsonMap> snapshot = await _usersRef
        .where('isDeleted', isEqualTo: false)
        .orderBy('points', descending: true)
        .limit(allowed * 3)
        .get();

    final List<MatchProfile> candidates = <MatchProfile>[];
    final Set<String> excludedSerials = currentUser.excludedSerials;
    final Set<String> excludedDepartments = currentUser.excludedDepartments;
    final Set<String> excludedRegions = currentUser.excludedRegions;

    for (final QueryDocumentSnapshot<JsonMap> doc in snapshot.docs) {
      if (doc.id == currentUser.uid) {
        continue;
      }

      final UserProfile profile = UserProfile.fromSnapshot(doc);
      if (profile.isBlocked || profile.isDeleted) {
        continue;
      }
      if (excludedSerials.contains(profile.serial)) {
        continue;
      }
      if (excludedDepartments.contains(profile.department)) {
        continue;
      }
      if (excludedRegions.contains(profile.region)) {
        continue;
      }
      if (profile.serial == currentUser.serial && currentUser.serial.isNotEmpty) {
        continue;
      }

      final MatchProfileStage stage = profile.premiumTier == PremiumTier.premium
          ? MatchProfileStage.nicknameRevealed
          : MatchProfileStage.anonymized;

      final MatchProfile matchProfile = MatchProfile(
        id: profile.uid,
        nickname: profile.nickname,
        maskedNickname: _maskNickname(profile.nickname),
        serial: profile.serial,
        department: profile.department,
        region: profile.region,
        jobTitle: profile.jobTitle,
        yearsOfService: profile.yearsOfService,
        introduction: profile.bio ?? '아직 소개가 없습니다.',
        interests: profile.interests,
        careerTrack: profile.careerTrack,
        badges: profile.badges,
        stage: stage,
        isPremium: profile.isPremium,
        premiumTier: profile.premiumTier,
        photoUrl: profile.photoUrl,
        points: profile.points,
        level: profile.level,
      );

      candidates.add(matchProfile);
      if (candidates.length >= allowed) {
        break;
      }
    }

    if (includePremiumHighlights) {
      candidates.sort((MatchProfile a, MatchProfile b) {
        if (a.isPremium == b.isPremium) {
          return (b.points ?? 0).compareTo(a.points ?? 0);
        }
        return a.isPremium ? -1 : 1;
      });
    } else {
      candidates.shuffle(Random());
    }

    await _incrementExposureCount(currentUser.uid, candidates.length);
    return candidates;
  }

  Future<PaginatedQueryResult<MatchProfile>> fetchLikesReceived({
    required UserProfile currentUser,
    int limit = 20,
    QueryDocumentSnapshotJson? startAfter,
  }) async {
    QueryJson query = _receivedLikesCollection(currentUser.uid)
        .orderBy('createdAt', descending: true)
        .limit(limit);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final QuerySnapshot<JsonMap> snapshot = await query.get();
    final List<MatchProfile> profiles = <MatchProfile>[];
    for (final QueryDocumentSnapshot<JsonMap> doc in snapshot.docs) {
      final String likerUid = doc.id;
      final UserProfile? profile = await _fetchProfile(likerUid);
      if (profile == null) {
        continue;
      }
      profiles.add(
        MatchProfile(
          id: profile.uid,
          nickname: profile.nickname,
          maskedNickname: _maskNickname(profile.nickname),
          serial: profile.serial,
          department: profile.department,
          region: profile.region,
          jobTitle: profile.jobTitle,
          yearsOfService: profile.yearsOfService,
          introduction: profile.bio ?? '소개 작성 전입니다.',
          interests: profile.interests,
          careerTrack: profile.careerTrack,
          badges: profile.badges,
          stage: MatchProfileStage.nicknameRevealed,
          isPremium: profile.isPremium,
          premiumTier: profile.premiumTier,
          photoUrl: profile.photoUrl,
          points: profile.points,
          level: profile.level,
        ),
      );
    }

    final bool hasMore = snapshot.docs.length == limit;
    final QueryDocumentSnapshotJson? last = snapshot.docs.isEmpty ? null : snapshot.docs.last;
    return PaginatedQueryResult<MatchProfile>(items: profiles, hasMore: hasMore, lastDocument: last);
  }

  Future<MatchRequestResult> requestMatch({
    required UserProfile currentUser,
    required String targetUid,
    String? message,
  }) async {
    if (currentUser.uid == targetUid) {
      return const MatchRequestResult(
        isSuccessful: false,
        message: '자기 자신에게는 매칭을 신청할 수 없습니다.',
      );
    }

    final DocumentReference<JsonMap> likeDoc = _likesCollection(currentUser.uid).doc(targetUid);
    final DocumentReference<JsonMap> inboxDoc = _receivedLikesCollection(targetUid).doc(currentUser.uid);
    final DocumentReference<JsonMap> reciprocalDoc = _likesCollection(targetUid).doc(currentUser.uid);

    return _firestore.runTransaction<MatchRequestResult>((Transaction transaction) async {
      final DocumentSnapshot<JsonMap> reciprocalSnapshot = await transaction.get(reciprocalDoc);
      final bool isMutual = reciprocalSnapshot.exists;

      transaction.set(likeDoc, <String, Object?>{
        'createdAt': Timestamp.now(),
        'message': message,
      });

      transaction.set(inboxDoc, <String, Object?>{
        'createdAt': Timestamp.now(),
        'message': message,
      });

      if (isMutual) {
        final DocumentReference<JsonMap> matchesRef = _firestore
            .collection('matches')
            .doc(_matchId(currentUser.uid, targetUid));
        transaction.set(matchesRef, <String, Object?>{
          'userA': currentUser.uid,
          'userB': targetUid,
          'createdAt': Timestamp.now(),
          'stage': 'nicknameRevealed',
        });
        return MatchRequestResult(
          isSuccessful: true,
          message: '서로 좋아요를 보냈어요! 매칭 채팅방을 열어드릴게요.',
        );
      }

      return MatchRequestResult(
        isSuccessful: true,
        message: '매칭 요청을 보냈습니다. 상대방이 수락하면 알려드릴게요.',
      );
    });
  }

  Future<void> recordChatMessage({
    required String matchId,
    required String senderUid,
  }) async {
    final DocumentReference<JsonMap> matchDoc = _firestore.collection('matches').doc(matchId);
    await matchDoc.set(
      <String, Object?>{
        'lastMessageAt': Timestamp.now(),
        'lastMessageSender': senderUid,
      },
      SetOptions(merge: true),
    );
  }

  Future<void> progressRevealStage({
    required String matchId,
    required MatchProfileStage nextStage,
  }) async {
    final DocumentReference<JsonMap> matchDoc = _firestore.collection('matches').doc(matchId);
    await matchDoc.update(<String, Object?>{'stage': nextStage.name});
  }

  Future<UserProfile?> _fetchProfile(String uid) async {
    final DocumentSnapshot<JsonMap> snapshot = await _userDoc(uid).get();
    if (!snapshot.exists) {
      return null;
    }
    return UserProfile.fromSnapshot(snapshot);
  }

  Future<int> _ensureExposureCapacity({
    required UserProfile currentUser,
    required int requested,
  }) async {
    final DocumentReference<JsonMap> doc = _exposureDoc(currentUser.uid);
    final DocumentSnapshot<JsonMap> snapshot = await doc.get();
    final int currentCount = (snapshot.data()?['count'] as num?)?.toInt() ?? 0;
    final int limit = currentUser.isPremium
        ? _dailyExposureLimit + _premiumExposureBonus
        : _dailyExposureLimit;
    final int remaining = (limit - currentCount).clamp(0, limit);
    if (remaining <= 0) {
      return 0;
    }
    return remaining < requested ? remaining : requested;
  }

  Future<void> _incrementExposureCount(String uid, int delta) async {
    final DocumentReference<JsonMap> doc = _exposureDoc(uid);
    await doc.set(
      <String, Object?>{
        'count': FieldValue.increment(delta),
        'updatedAt': Timestamp.now(),
      },
      SetOptions(merge: true),
    );
  }

  DocumentReference<JsonMap> _exposureDoc(String uid) {
    final DateTime now = DateTime.now();
    final String ymd = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    return _userMatchingMeta(uid).doc('daily_$ymd');
  }

  String _maskNickname(String nickname) {
    if (nickname.length <= 2) {
      return '${nickname[0]}*';
    }
    return nickname[0] + ('*' * (nickname.length - 2)) + nickname[nickname.length - 1];
  }

  String _matchId(String a, String b) {
    final List<String> ids = <String>[a, b]..sort();
    return ids.join('_');
  }
}
