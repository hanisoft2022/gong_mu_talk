import 'dart:math';

import 'package:collection/collection.dart';

import '../../../profile/domain/user_profile.dart';
import '../entities/match_compatibility.dart';
import '../entities/match_flow.dart';
import '../entities/match_preferences.dart';

class MatchCompatibilityEngine {
  const MatchCompatibilityEngine({
    this.flowPolicy = MatchFlowPolicy.defaultPolicy,
  });

  final MatchFlowPolicy flowPolicy;

  CompatibilityAssessment assess({
    required UserProfile currentUser,
    required UserProfile candidate,
  }) {
    final MatchPreferences seekerPrefs = currentUser.matchPreferences;
    final MatchPreferences candidatePrefs = candidate.matchPreferences;

    final bool passesHardFilters = _passesHardFilters(
      seekerPrefs,
      candidatePrefs,
    );

    final double valuesScore = _valuesScore(seekerPrefs, candidatePrefs);
    final double lifestyleScore = _lifestyleScore(seekerPrefs, candidatePrefs);
    final double distanceScore = _distanceScore(
      seekerPrefs,
      candidatePrefs,
      currentUser: currentUser,
      candidate: candidate,
    );
    final double familyPlanScore = _familyPlanScore(
      seekerPrefs,
      candidatePrefs,
    );
    final double trustScore = _trustSignalScore(candidate);
    final double tagsScore = _preferenceTagScore(currentUser, candidate);

    final List<CompatibilityBreakdown> breakdowns = <CompatibilityBreakdown>[
      CompatibilityBreakdown(
        dimension: CompatibilityDimension.coreValues,
        score: valuesScore,
        weight: seekerPrefs.valuesWeight,
      ),
      CompatibilityBreakdown(
        dimension: CompatibilityDimension.lifestyle,
        score: lifestyleScore,
        weight: seekerPrefs.lifestyleWeight,
      ),
      CompatibilityBreakdown(
        dimension: CompatibilityDimension.distance,
        score: distanceScore,
        weight: seekerPrefs.distanceWeight,
      ),
      CompatibilityBreakdown(
        dimension: CompatibilityDimension.familyPlan,
        score: familyPlanScore,
        weight: seekerPrefs.familyPlanWeight,
      ),
      CompatibilityBreakdown(
        dimension: CompatibilityDimension.trustSignals,
        score: trustScore,
        weight: seekerPrefs.trustSignalWeight,
      ),
      CompatibilityBreakdown(
        dimension: CompatibilityDimension.preferenceTags,
        score: tagsScore,
        weight: seekerPrefs.tagWeight,
      ),
    ];

    final double weightedScore = breakdowns
        .map((CompatibilityBreakdown breakdown) => breakdown.weightedScore)
        .fold<double>(0, (double acc, double value) => acc + value);

    final List<String> highlights = _buildHighlights(
      seekerPrefs: seekerPrefs,
      candidatePrefs: candidatePrefs,
      currentUser: currentUser,
      candidate: candidate,
      breakdowns: breakdowns,
    );

    return CompatibilityAssessment(
      passesHardFilters: passesHardFilters,
      summary: CompatibilitySummary(
        totalScore: (weightedScore * 100).clamp(0, 100),
        breakdowns: breakdowns,
        highlightReasons: highlights,
      ),
    );
  }

  bool _passesHardFilters(
    MatchPreferences seekerPrefs,
    MatchPreferences candidatePrefs,
  ) {
    if (!seekerPrefs.hasHardFilters) {
      return true;
    }

    if (seekerPrefs.hardFilters.excludeSmoking) {
      final SmokingHabit? habit = candidatePrefs.smoking;
      if (habit != null && habit != SmokingHabit.none) {
        return false;
      }
    }

    if (seekerPrefs.hardFilters.excludePetOwners &&
        candidatePrefs.pets.isNotEmpty) {
      return false;
    }

    if (seekerPrefs.hardFilters.excludedReligions.isNotEmpty) {
      final ReligionPreference? candidateReligion = candidatePrefs.religion;
      if (candidateReligion != null &&
          seekerPrefs.hardFilters.excludedReligions.contains(
            candidateReligion,
          )) {
        return false;
      }
    }

    return true;
  }

  double _valuesScore(MatchPreferences seeker, MatchPreferences candidate) {
    final List<double> scores = <double>[];

    if (seeker.decisionStyle != null && candidate.decisionStyle != null) {
      scores.add(seeker.decisionStyle == candidate.decisionStyle ? 1 : 0.5);
    }

    if (seeker.conflictStyle != null && candidate.conflictStyle != null) {
      scores.add(seeker.conflictStyle == candidate.conflictStyle ? 1 : 0.5);
    }

    if (scores.isEmpty) {
      return 0.5;
    }
    return scores.average;
  }

  double _lifestyleScore(MatchPreferences seeker, MatchPreferences candidate) {
    final List<double> scores = <double>[];

    if (seeker.shiftPattern != null && candidate.shiftPattern != null) {
      scores.add(seeker.shiftPattern == candidate.shiftPattern ? 1 : 0.6);
    }

    if (seeker.sleepRange != null && candidate.sleepRange != null) {
      final double ratio = seeker.sleepRange!.overlapRatio(
        candidate.sleepRange!,
      );
      scores.add(ratio.clamp(0, 1));
    }

    if (seeker.weekendStyles.isNotEmpty && candidate.weekendStyles.isNotEmpty) {
      final Set<String> intersection = seeker.weekendStyles.intersection(
        candidate.weekendStyles,
      );
      final Set<String> union = seeker.weekendStyles.union(
        candidate.weekendStyles,
      );
      scores.add(
        intersection.isEmpty ? 0.4 : intersection.length / union.length,
      );
    }

    if (seeker.consumptionStyle != null && candidate.consumptionStyle != null) {
      scores.add(
        seeker.consumptionStyle == candidate.consumptionStyle ? 1 : 0.6,
      );
    }

    if (scores.isEmpty) {
      return 0.5;
    }
    return scores.average;
  }

  double _distanceScore(
    MatchPreferences seeker,
    MatchPreferences candidatePrefs, {
    required UserProfile currentUser,
    required UserProfile candidate,
  }) {
    final List<double> scores = <double>[];

    if (seeker.area != null && candidatePrefs.area != null) {
      final bool sameArea = seeker.area == candidatePrefs.area;
      scores.add(sameArea ? 1 : 0.5);
    } else if (currentUser.region.isNotEmpty && candidate.region.isNotEmpty) {
      scores.add(currentUser.region == candidate.region ? 1 : 0.5);
    }

    if (seeker.maxTravelMinutes != null &&
        candidatePrefs.maxTravelMinutes != null) {
      final int diff =
          (seeker.maxTravelMinutes! - candidatePrefs.maxTravelMinutes!).abs();
      final double normalized = (1 - min(diff, 120) / 120).clamp(0, 1);
      scores.add(normalized);
    }

    if (seeker.longDistancePreference != null &&
        candidatePrefs.longDistancePreference != null) {
      if (seeker.longDistancePreference == LongDistancePreference.no ||
          candidatePrefs.longDistancePreference == LongDistancePreference.no) {
        final bool bothNo =
            seeker.longDistancePreference == LongDistancePreference.no &&
            candidatePrefs.longDistancePreference == LongDistancePreference.no;
        scores.add(bothNo ? 1 : 0.4);
      } else if (seeker.longDistancePreference ==
          candidatePrefs.longDistancePreference) {
        scores.add(1);
      } else {
        scores.add(0.6);
      }
    }

    if (scores.isEmpty) {
      return 0.5;
    }
    return scores.average;
  }

  double _familyPlanScore(MatchPreferences seeker, MatchPreferences candidate) {
    final List<double> scores = <double>[];

    if (seeker.marriageTimeline != null && candidate.marriageTimeline != null) {
      scores.add(
        seeker.marriageTimeline == candidate.marriageTimeline ? 1 : 0.5,
      );
    }

    if (seeker.childrenPlan != null && candidate.childrenPlan != null) {
      scores.add(seeker.childrenPlan == candidate.childrenPlan ? 1 : 0.5);
    }

    if (seeker.financeStyle != null && candidate.financeStyle != null) {
      scores.add(seeker.financeStyle == candidate.financeStyle ? 1 : 0.6);
    }

    if (seeker.parentsCare != null && candidate.parentsCare != null) {
      scores.add(seeker.parentsCare == candidate.parentsCare ? 1 : 0.6);
    }

    if (scores.isEmpty) {
      return 0.5;
    }
    return scores.average;
  }

  double _trustSignalScore(UserProfile candidate) {
    final double levelScore = min(candidate.level, 10) / 10;
    final double badgeScore = (candidate.badges.length / 5).clamp(0, 1);
    final double pointScore = (candidate.points / 1000).clamp(0, 1);
    return <double>[levelScore, badgeScore, pointScore].average;
  }

  double _preferenceTagScore(UserProfile currentUser, UserProfile candidate) {
    final Set<String> myTags = currentUser.interests.toSet();
    final Set<String> candidateTags = candidate.interests.toSet();
    if (myTags.isEmpty || candidateTags.isEmpty) {
      return 0.5;
    }
    final Set<String> intersection = myTags.intersection(candidateTags);
    final Set<String> union = myTags.union(candidateTags);
    if (union.isEmpty) {
      return 0.5;
    }
    return intersection.isEmpty ? 0.4 : intersection.length / union.length;
  }

  List<String> _buildHighlights({
    required MatchPreferences seekerPrefs,
    required MatchPreferences candidatePrefs,
    required UserProfile currentUser,
    required UserProfile candidate,
    required List<CompatibilityBreakdown> breakdowns,
  }) {
    final List<String> highlights = <String>[];

    if (seekerPrefs.weekendStyles.isNotEmpty) {
      final Set<String> overlap = seekerPrefs.weekendStyles.intersection(
        candidatePrefs.weekendStyles,
      );
      if (overlap.isNotEmpty) {
        highlights.add('주말엔 함께 ${overlap.join('·')} 즐겨요');
      }
    }

    if (seekerPrefs.marriageTimeline != null &&
        seekerPrefs.marriageTimeline == candidatePrefs.marriageTimeline) {
      highlights.add('결혼 시점 기대가 같습니다 (${seekerPrefs.marriageTimeline!.label})');
    }

    if (seekerPrefs.childrenPlan != null &&
        seekerPrefs.childrenPlan == candidatePrefs.childrenPlan) {
      highlights.add('자녀 계획 인식이 통합니다 (${seekerPrefs.childrenPlan!.label})');
    }

    final Set<String> sharedTags = currentUser.interests.toSet().intersection(
      candidate.interests.toSet(),
    );
    if (sharedTags.isNotEmpty) {
      highlights.add('공통 관심사: ${sharedTags.join(', ')}');
    }

    if (candidatePrefs.sleepRange != null && seekerPrefs.sleepRange != null) {
      final double overlapRatio = seekerPrefs.sleepRange!.overlapRatio(
        candidatePrefs.sleepRange!,
      );
      if (overlapRatio >= 0.6) {
        highlights.add('수면 리듬이 ${(overlapRatio * 100).round()}% 겹쳐요');
      }
    }

    if (highlights.length < 3) {
      final List<CompatibilityBreakdown> sortedBreakdowns = breakdowns.sorted(
        (CompatibilityBreakdown a, CompatibilityBreakdown b) =>
            b.weightedScore.compareTo(a.weightedScore),
      );
      for (final CompatibilityBreakdown breakdown in sortedBreakdowns) {
        if (highlights.length >= 3) {
          break;
        }
        final String reason = switch (breakdown.dimension) {
          CompatibilityDimension.coreValues => '가치관 대화 방식이 잘 맞아요',
          CompatibilityDimension.lifestyle => '생활 리듬 호환성이 높아요',
          CompatibilityDimension.distance => '이동 거리 기대가 유사해요',
          CompatibilityDimension.familyPlan => '가족 계획 방향성이 비슷해요',
          CompatibilityDimension.trustSignals => '성실도 지표가 안정적이에요',
          CompatibilityDimension.preferenceTags => '취향 태그가 겹쳐요',
        };
        if (!highlights.contains(reason)) {
          highlights.add(reason);
        }
      }
    }

    return highlights.take(3).toList(growable: false);
  }
}

extension _IterableAverage on Iterable<double> {
  double get average {
    if (isEmpty) {
      return 0;
    }
    final double sum = fold<double>(
      0,
      (double acc, double value) => acc + value,
    );
    return sum / length;
  }
}
