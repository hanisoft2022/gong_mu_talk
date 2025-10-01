import 'package:test/test.dart';
import 'package:gong_mu_talk/features/matching/domain/entities/match_compatibility.dart';
import 'package:gong_mu_talk/features/matching/domain/entities/match_preferences.dart';
import 'package:gong_mu_talk/features/matching/domain/entities/match_preference_enums.dart';
import 'package:gong_mu_talk/features/matching/domain/entities/match_preference_helpers.dart';
import 'package:gong_mu_talk/features/matching/domain/services/match_compatibility_engine.dart';
import 'package:gong_mu_talk/features/profile/domain/user_profile.dart';

void main() {
  group('MatchCompatibilityEngine', () {
    const MatchCompatibilityEngine engine = MatchCompatibilityEngine();

    UserProfile buildUser({
      required String uid,
      required MatchPreferences preferences,
      int level = 5,
      int points = 700,
      List<String> interests = const <String>['여행', '등산'],
    }) {
      return UserProfile(
        uid: uid,
        nickname: '닉네임$uid',
        handle: uid,
        serial: 'serial_$uid',
        department: '기획재정부',
        region: '서울',
        role: UserRole.member,
        jobTitle: '주무관',
        yearsOfService: 6,
        createdAt: DateTime(2024, 1, 1),
        badges: const <String>['성실'],
        points: points,
        level: level,
        interests: interests,
        matchPreferences: preferences,
      );
    }

    test('returns strong compatibility when core preferences align', () {
      const MatchPreferences seekerPrefs = MatchPreferences(
        smoking: SmokingHabit.none,
        religion: ReligionPreference.none,
        marriageTimeline: MarriageTimelinePreference.withinOneYear,
        childrenPlan: ChildrenPlanPreference.want,
        financeStyle: FinanceStylePreference.shared,
        parentsCare: ParentsCarePreference.coLivingOk,
        decisionStyle: DecisionStylePreference.dialogue,
        conflictStyle: ConflictResolutionPreference.immediateTalk,
        shiftPattern: ShiftPattern.day,
        sleepRange: TimeRangePreference(startMinutes: 0, endMinutes: 420),
        weekendStyles: {'여행', '카페'},
        consumptionStyle: ConsumptionStylePreference.experience,
        maxTravelMinutes: 60,
        longDistancePreference: LongDistancePreference.maybe,
        hardFilters: MatchHardFilters(excludeSmoking: true),
      );

      final MatchPreferences candidatePrefs = seekerPrefs.copyWith(
        weekendStyles: const <String>{'여행', '등산'},
      );

      final UserProfile seeker = buildUser(
        uid: 'seeker',
        preferences: seekerPrefs,
      );
      final UserProfile candidate = buildUser(
        uid: 'candidate',
        preferences: candidatePrefs,
        level: 7,
        points: 820,
        interests: const <String>['여행', '러닝'],
      );

      final CompatibilityAssessment assessment = engine.assess(
        currentUser: seeker,
        candidate: candidate,
      );

      expect(assessment.passesHardFilters, isTrue);
      expect(assessment.summary.totalScore, greaterThan(80));
      expect(
        assessment.summary.highlightReasons.any(
          (String reason) => reason.contains('주말엔 함께'),
        ),
        isTrue,
      );
    });

    test('fails hard filters when candidate violates exclusions', () {
      const MatchPreferences seekerPrefs = MatchPreferences(
        smoking: SmokingHabit.none,
        hardFilters: MatchHardFilters(excludeSmoking: true),
      );
      const MatchPreferences candidatePrefs = MatchPreferences(
        smoking: SmokingHabit.yes,
      );

      final UserProfile seeker = buildUser(
        uid: 'seeker',
        preferences: seekerPrefs,
      );
      final UserProfile candidate = buildUser(
        uid: 'candidate',
        preferences: candidatePrefs,
      );

      final CompatibilityAssessment assessment = engine.assess(
        currentUser: seeker,
        candidate: candidate,
      );

      expect(assessment.passesHardFilters, isFalse);
      expect(assessment.summary.totalScore, closeTo(50, 50));
    });

    test('penalises different marriage timeline in family plan breakdown', () {
      const MatchPreferences seekerPrefs = MatchPreferences(
        marriageTimeline: MarriageTimelinePreference.withinOneYear,
        childrenPlan: ChildrenPlanPreference.want,
      );
      const MatchPreferences candidatePrefs = MatchPreferences(
        marriageTimeline: MarriageTimelinePreference.fourPlusYears,
        childrenPlan: ChildrenPlanPreference.want,
      );

      final UserProfile seeker = buildUser(
        uid: 'seeker',
        preferences: seekerPrefs,
      );
      final UserProfile candidate = buildUser(
        uid: 'candidate',
        preferences: candidatePrefs,
      );

      final CompatibilityAssessment assessment = engine.assess(
        currentUser: seeker,
        candidate: candidate,
      );

      final double familyPlanScore = assessment.summary.breakdowns
          .firstWhere(
            (CompatibilityBreakdown breakdown) =>
                breakdown.dimension == CompatibilityDimension.familyPlan,
          )
          .score;

      expect(familyPlanScore, lessThan(1));
      expect(assessment.summary.totalScore, lessThan(70));
    });
  });
}
