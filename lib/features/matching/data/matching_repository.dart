import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firebase/paginated_query.dart';
import '../../profile/domain/user_profile.dart';
import '../domain/entities/curated_match.dart';
import '../domain/entities/match_compatibility.dart';
import '../domain/entities/match_flow.dart';
import '../domain/entities/match_preferences.dart';
import '../domain/entities/match_profile.dart';
import '../domain/entities/match_questionnaire.dart';
import '../domain/services/match_compatibility_engine.dart';

typedef JsonMap = Map<String, Object?>;

class MatchRequestResult {
  const MatchRequestResult({required this.isSuccessful, required this.message});

  final bool isSuccessful;
  final String message;
}

class MatchingRepository {
  MatchingRepository({
    FirebaseFirestore? firestore,
    MatchCompatibilityEngine? compatibilityEngine,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _compatibilityEngine =
           compatibilityEngine ?? const MatchCompatibilityEngine();

  final FirebaseFirestore _firestore;
  final MatchCompatibilityEngine _compatibilityEngine;
  static const int _dailyExposureLimit = 5;
  static const int _premiumExposureBonus = 2;

  CollectionReference<JsonMap> get _usersRef => _firestore.collection('users');

  CollectionReference<JsonMap> _userMatchingMeta(String uid) =>
      _userDoc(uid).collection('matching_meta');

  DocumentReference<JsonMap> _userDoc(String uid) => _usersRef.doc(uid);

  CollectionReference<JsonMap> _likesCollection(String uid) =>
      _userDoc(uid).collection('matching_likes');

  CollectionReference<JsonMap> _receivedLikesCollection(String uid) =>
      _userDoc(uid).collection('matching_inbox');

  Future<List<CuratedMatch>> fetchCandidates({
    required UserProfile currentUser,
    int limit = 5,
    bool includePremiumHighlights = true,
  }) async {
    final int requested = limit.clamp(3, 5);
    try {
      final int allowed = await _ensureExposureCapacity(
        currentUser: currentUser,
        requested: requested,
      );
      if (allowed <= 0) {
        return _generateDummyCandidates(
          currentUser: currentUser,
          count: requested,
        );
      }

      final int fetchBatchSize = max(allowed * 4, requested * 3);
      final QuerySnapshot<JsonMap> snapshot = await _usersRef
          .where('isDeleted', isEqualTo: false)
          .orderBy('points', descending: true)
          .limit(fetchBatchSize)
          .get();

      final List<CuratedMatch> curated = <CuratedMatch>[];
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
        if (profile.serial == currentUser.serial &&
            currentUser.serial.isNotEmpty) {
          continue;
        }

        final CompatibilityAssessment assessment = _compatibilityEngine.assess(
          currentUser: currentUser,
          candidate: profile,
        );

        if (!assessment.passesHardFilters) {
          continue;
        }

        final MatchProfileStage stage =
            profile.premiumTier == PremiumTier.premium
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

        curated.add(
          CuratedMatch(
            profile: matchProfile,
            compatibility: assessment.summary,
            stage: MatchFlowStage.interestExpression,
            availablePrompts: defaultMatchSurvey.firstMessagePrompts,
            preferences: profile.matchPreferences,
          ),
        );

        if (curated.length >= allowed) {
          break;
        }
      }

      if (curated.isEmpty) {
        return _generateDummyCandidates(
          currentUser: currentUser,
          count: requested,
        );
      }

      curated.sort((CuratedMatch a, CuratedMatch b) {
        final int scoreCompare = b.compatibility.totalScore.compareTo(
          a.compatibility.totalScore,
        );
        if (scoreCompare != 0) {
          return scoreCompare;
        }
        if (includePremiumHighlights &&
            a.profile.isPremium != b.profile.isPremium) {
          return a.profile.isPremium ? -1 : 1;
        }
        return (b.profile.points ?? 0).compareTo(a.profile.points ?? 0);
      });

      final List<CuratedMatch> limited = curated
          .take(allowed)
          .toList(growable: false);
      await _incrementExposureCount(currentUser.uid, limited.length);
      return limited;
    } catch (_) {
      return _generateDummyCandidates(
        currentUser: currentUser,
        count: requested,
      );
    }
  }

  Future<PaginatedQueryResult<MatchProfile>> fetchLikesReceived({
    required UserProfile currentUser,
    int limit = 20,
    QueryDocumentSnapshotJson? startAfter,
  }) async {
    QueryJson query = _receivedLikesCollection(
      currentUser.uid,
    ).orderBy('createdAt', descending: true).limit(limit);
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
    final QueryDocumentSnapshotJson? last = snapshot.docs.isEmpty
        ? null
        : snapshot.docs.last;
    return PaginatedQueryResult<MatchProfile>(
      items: profiles,
      hasMore: hasMore,
      lastDocument: last,
    );
  }

  Future<MatchRequestResult> requestMatch({
    required UserProfile currentUser,
    required String targetUid,
    String? message,
    String? firstQuestionPrompt,
    String? firstQuestionAnswer,
  }) async {
    if (currentUser.uid == targetUid) {
      return const MatchRequestResult(
        isSuccessful: false,
        message: '자기 자신에게는 매칭을 신청할 수 없습니다.',
      );
    }

    final DocumentReference<JsonMap> likeDoc = _likesCollection(
      currentUser.uid,
    ).doc(targetUid);
    final DocumentReference<JsonMap> inboxDoc = _receivedLikesCollection(
      targetUid,
    ).doc(currentUser.uid);
    final DocumentReference<JsonMap> reciprocalDoc = _likesCollection(
      targetUid,
    ).doc(currentUser.uid);

    return _firestore.runTransaction<MatchRequestResult>((
      Transaction transaction,
    ) async {
      final DocumentSnapshot<JsonMap> reciprocalSnapshot = await transaction
          .get(reciprocalDoc);
      final bool isMutual = reciprocalSnapshot.exists;

      final Map<String, Object?> payload = <String, Object?>{
        'createdAt': Timestamp.now(),
        if (message != null) 'message': message,
        if (firstQuestionPrompt != null && firstQuestionAnswer != null)
          'firstQuestion': <String, Object?>{
            'prompt': firstQuestionPrompt,
            'answer': firstQuestionAnswer,
          },
      };

      transaction.set(likeDoc, payload);

      transaction.set(inboxDoc, payload);

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
        return const MatchRequestResult(
          isSuccessful: true,
          message: '서로 좋아요를 보냈어요! 매칭 채팅방을 열어드릴게요.',
        );
      }

      return const MatchRequestResult(
        isSuccessful: true,
        message: '매칭 요청을 보냈습니다. 상대방이 수락하면 알려드릴게요.',
      );
    });
  }

  Future<void> recordChatMessage({
    required String matchId,
    required String senderUid,
  }) async {
    final DocumentReference<JsonMap> matchDoc = _firestore
        .collection('matches')
        .doc(matchId);
    await matchDoc.set(<String, Object?>{
      'lastMessageAt': Timestamp.now(),
      'lastMessageSender': senderUid,
    }, SetOptions(merge: true));
  }

  Future<void> progressRevealStage({
    required String matchId,
    required MatchProfileStage nextStage,
  }) async {
    final DocumentReference<JsonMap> matchDoc = _firestore
        .collection('matches')
        .doc(matchId);
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
    await doc.set(<String, Object?>{
      'count': FieldValue.increment(delta),
      'updatedAt': Timestamp.now(),
    }, SetOptions(merge: true));
  }

  DocumentReference<JsonMap> _exposureDoc(String uid) {
    final DateTime now = DateTime.now();
    final String ymd =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    return _userMatchingMeta(uid).doc('daily_$ymd');
  }

  String _maskNickname(String nickname) {
    if (nickname.length <= 2) {
      return '${nickname[0]}*';
    }
    return nickname[0] +
        ('*' * (nickname.length - 2)) +
        nickname[nickname.length - 1];
  }

  String _matchId(String a, String b) {
    final List<String> ids = <String>[a, b]..sort();
    return ids.join('_');
  }

  List<CuratedMatch> _generateDummyCandidates({
    required UserProfile currentUser,
    int count = 5,
  }) {
    final Random random = Random();
    final List<String> nicknames = <String>[
      '민수',
      '지영',
      '현우',
      '서연',
      '도윤',
      '하은',
      '지호',
      '예린',
    ];
    final List<String> jobs = <String>['행정사무관', '주무관', '전산주사', '교육행정', '세무주사'];
    final List<String> regions = <String>['서울', '부산', '대전', '대구', '광주'];
    final List<String> weekendStyles = <String>[
      '집콕',
      '카페',
      '등산',
      '러닝',
      '영화',
      '독서',
      '여행',
    ];

    final MatchPreferences seekerPrefs = currentUser.matchPreferences;

    final List<CuratedMatch> items = <CuratedMatch>[];
    for (int i = 0; i < count; i += 1) {
      final String base = nicknames[random.nextInt(nicknames.length)];
      final String id =
          'dummy_match_${DateTime.now().millisecondsSinceEpoch}_${i}_${random.nextInt(9999)}';
      final String nickname = base;
      final String region = regions[random.nextInt(regions.length)];
      final int points = random.nextInt(800) + 200;
      final int level = 1 + random.nextInt(9);
      final List<String> interests = <String>['독서', '운동', '여행', '요리']
        ..shuffle(random);

      final MatchProfile profile = MatchProfile(
        id: id,
        nickname: nickname,
        maskedNickname: _maskNickname(nickname),
        serial: currentUser.careerTrack.name,
        department: currentUser.department,
        region: region,
        jobTitle: jobs[random.nextInt(jobs.length)],
        yearsOfService: random.nextInt(15),
        introduction: '안녕하세요! 함께 정보 나눠요.',
        interests: interests.take(3).toList(growable: false),
        careerTrack: currentUser.careerTrack,
        badges: const <String>['친절', '성실'],
        stage: MatchProfileStage.anonymized,
        isPremium: random.nextBool(),
        premiumTier: random.nextBool() ? PremiumTier.premium : PremiumTier.none,
        photoUrl: null,
        points: points,
        level: level,
      );

      final List<CompatibilityBreakdown> breakdowns = <CompatibilityBreakdown>[
        CompatibilityBreakdown(
          dimension: CompatibilityDimension.coreValues,
          score: random.nextDouble() * 0.4 + 0.6,
          weight: seekerPrefs.valuesWeight,
        ),
        CompatibilityBreakdown(
          dimension: CompatibilityDimension.lifestyle,
          score: random.nextDouble() * 0.4 + 0.5,
          weight: seekerPrefs.lifestyleWeight,
        ),
        CompatibilityBreakdown(
          dimension: CompatibilityDimension.distance,
          score: random.nextDouble() * 0.3 + 0.5,
          weight: seekerPrefs.distanceWeight,
        ),
        CompatibilityBreakdown(
          dimension: CompatibilityDimension.familyPlan,
          score: random.nextDouble() * 0.4 + 0.5,
          weight: seekerPrefs.familyPlanWeight,
        ),
        CompatibilityBreakdown(
          dimension: CompatibilityDimension.trustSignals,
          score: random.nextDouble() * 0.3 + 0.5,
          weight: seekerPrefs.trustSignalWeight,
        ),
        CompatibilityBreakdown(
          dimension: CompatibilityDimension.preferenceTags,
          score: random.nextDouble() * 0.4 + 0.5,
          weight: seekerPrefs.tagWeight,
        ),
      ];

      final double totalScore =
          breakdowns
              .map(
                (CompatibilityBreakdown breakdown) => breakdown.weightedScore,
              )
              .fold<double>(0, (double acc, double value) => acc + value) *
          100;

      final List<String> weekendSample = List<String>.from(weekendStyles)
        ..shuffle(random);
      final String weekendText = weekendSample.take(2).join('·');
      final List<String> highlightPool = <String>{
        '주말엔 함께 $weekendText 즐겨요',
        '가족 계획 방향성이 비슷해요',
        '취향 태그가 겹쳐요',
        '생활 리듬 호환성이 높아요',
      }.toList()..shuffle(random);

      items.add(
        CuratedMatch(
          profile: profile,
          compatibility: CompatibilitySummary(
            totalScore: totalScore.clamp(55, 92).toDouble(),
            breakdowns: breakdowns,
            highlightReasons: highlightPool.take(3).toList(growable: false),
          ),
          stage: MatchFlowStage.interestExpression,
          availablePrompts: defaultMatchSurvey.firstMessagePrompts,
          preferences: const MatchPreferences(),
        ),
      );
    }

    items.sort(
      (CuratedMatch a, CuratedMatch b) =>
          b.compatibility.totalScore.compareTo(a.compatibility.totalScore),
    );
    return items;
  }
}
