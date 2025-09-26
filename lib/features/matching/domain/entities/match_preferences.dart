import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';

enum AgeBand {
  twentyToTwentyFour('20-24'),
  twentyFiveToTwentyNine('25-29'),
  thirtyToThirtyFour('30-34'),
  thirtyFiveToThirtyNine('35-39'),
  fortyPlus('40+'),
  unknown('unknown');

  const AgeBand(this.label);
  final String label;

  static AgeBand? fromLabel(String? label) {
    if (label == null) {
      return null;
    }
    return AgeBand.values.firstWhereOrNull(
      (AgeBand band) => band.label == label,
    );
  }
}

enum HeightBand {
  under160('<160'),
  oneSixtyToOneSixtyFour('160-164'),
  oneSixtyFiveToOneSixtyNine('165-169'),
  oneSeventyToOneSeventyFour('170-174'),
  oneSeventyFivePlus('175+');

  const HeightBand(this.label);
  final String label;

  static HeightBand? fromLabel(String? label) {
    if (label == null) {
      return null;
    }
    return HeightBand.values.firstWhereOrNull(
      (HeightBand band) => band.label == label,
    );
  }
}

enum SmokingHabit {
  none('no'),
  occasionally('occasionally'),
  yes('yes');

  const SmokingHabit(this.label);
  final String label;

  static SmokingHabit? fromLabel(String? label) {
    if (label == null) {
      return null;
    }
    return SmokingHabit.values.firstWhereOrNull(
      (SmokingHabit habit) => habit.label == label,
    );
  }
}

enum DrinkingHabit {
  none('no'),
  social('social'),
  frequently('frequently');

  const DrinkingHabit(this.label);
  final String label;

  static DrinkingHabit? fromLabel(String? label) {
    if (label == null) {
      return null;
    }
    return DrinkingHabit.values.firstWhereOrNull(
      (DrinkingHabit habit) => habit.label == label,
    );
  }
}

enum ReligionPreference {
  none('none'),
  protestant('protestant'),
  catholic('catholic'),
  buddhist('buddhist'),
  other('other');

  const ReligionPreference(this.label);
  final String label;

  static ReligionPreference? fromLabel(String? label) {
    if (label == null) {
      return null;
    }
    return ReligionPreference.values.firstWhereOrNull(
      (ReligionPreference value) => value.label == label,
    );
  }
}

enum ShiftPattern {
  day('day'),
  twoShift('2-shift'),
  threeShift('3-shift'),
  night('night');

  const ShiftPattern(this.label);
  final String label;

  static ShiftPattern? fromLabel(String? label) {
    if (label == null) {
      return null;
    }
    return ShiftPattern.values.firstWhereOrNull(
      (ShiftPattern value) => value.label == label,
    );
  }
}

enum MarriageTimelinePreference {
  withinOneYear('1년 내'),
  twoToThreeYears('2-3년'),
  fourPlusYears('4년+'),
  undecided('미정');

  const MarriageTimelinePreference(this.label);
  final String label;

  static MarriageTimelinePreference? fromLabel(String? label) {
    if (label == null) {
      return null;
    }
    return MarriageTimelinePreference.values.firstWhereOrNull(
      (MarriageTimelinePreference value) => value.label == label,
    );
  }
}

enum ChildrenPlanPreference {
  want('원함'),
  undecided('미정'),
  notInterested('원치않음');

  const ChildrenPlanPreference(this.label);
  final String label;

  static ChildrenPlanPreference? fromLabel(String? label) {
    if (label == null) {
      return null;
    }
    return ChildrenPlanPreference.values.firstWhereOrNull(
      (ChildrenPlanPreference value) => value.label == label,
    );
  }
}

enum FinanceStylePreference {
  shared('공동'),
  partialShared('부분공동'),
  separate('분리');

  const FinanceStylePreference(this.label);
  final String label;

  static FinanceStylePreference? fromLabel(String? label) {
    if (label == null) {
      return null;
    }
    return FinanceStylePreference.values.firstWhereOrNull(
      (FinanceStylePreference value) => value.label == label,
    );
  }
}

enum ParentsCarePreference {
  coLivingOk('함께거주 가능'),
  nearby('가까이'),
  preferIndependence('독립선호');

  const ParentsCarePreference(this.label);
  final String label;

  static ParentsCarePreference? fromLabel(String? label) {
    if (label == null) {
      return null;
    }
    return ParentsCarePreference.values.firstWhereOrNull(
      (ParentsCarePreference value) => value.label == label,
    );
  }
}

enum DecisionStylePreference {
  dialogue('대화로 합의'),
  roleSharing('역할분담'),
  situational('상황별');

  const DecisionStylePreference(this.label);
  final String label;

  static DecisionStylePreference? fromLabel(String? label) {
    if (label == null) {
      return null;
    }
    return DecisionStylePreference.values.firstWhereOrNull(
      (DecisionStylePreference value) => value.label == label,
    );
  }
}

enum ConflictResolutionPreference {
  immediateTalk('즉시대화'),
  giveTime('시간두기'),
  preferMediation('중재선호');

  const ConflictResolutionPreference(this.label);
  final String label;

  static ConflictResolutionPreference? fromLabel(String? label) {
    if (label == null) {
      return null;
    }
    return ConflictResolutionPreference.values.firstWhereOrNull(
      (ConflictResolutionPreference value) => value.label == label,
    );
  }
}

enum LongDistancePreference {
  yes('yes'),
  no('no'),
  maybe('maybe');

  const LongDistancePreference(this.label);
  final String label;

  static LongDistancePreference? fromLabel(String? label) {
    if (label == null) {
      return null;
    }
    return LongDistancePreference.values.firstWhereOrNull(
      (LongDistancePreference value) => value.label == label,
    );
  }
}

enum ConsumptionStylePreference {
  saving('saving'),
  experience('experience');

  const ConsumptionStylePreference(this.label);
  final String label;

  static ConsumptionStylePreference? fromLabel(String? label) {
    if (label == null) {
      return null;
    }
    return ConsumptionStylePreference.values.firstWhereOrNull(
      (ConsumptionStylePreference value) => value.label == label,
    );
  }
}

class TimeRangePreference extends Equatable {
  const TimeRangePreference({
    required this.startMinutes,
    required this.endMinutes,
  });

  factory TimeRangePreference.fromMap(Map<String, Object?> map) {
    return TimeRangePreference(
      startMinutes: (map['startMinutes'] as num?)?.toInt() ?? 0,
      endMinutes: (map['endMinutes'] as num?)?.toInt() ?? 0,
    );
  }

  final int startMinutes;
  final int endMinutes;

  bool overlaps(TimeRangePreference other) {
    final int s1 = startMinutes % (24 * 60);
    final int e1 = endMinutes % (24 * 60);
    final int s2 = other.startMinutes % (24 * 60);
    final int e2 = other.endMinutes % (24 * 60);
    return !(e1 <= s2 || e2 <= s1);
  }

  double overlapRatio(TimeRangePreference other) {
    final int start = startMinutes;
    final int end = endMinutes;
    final int otherStart = other.startMinutes;
    final int otherEnd = other.endMinutes;
    final int intersectionStart = start > otherStart ? start : otherStart;
    final int intersectionEnd = end < otherEnd ? end : otherEnd;
    if (intersectionEnd <= intersectionStart) {
      return 0;
    }
    final int unionStart = start < otherStart ? start : otherStart;
    final int unionEnd = end > otherEnd ? end : otherEnd;
    if (unionEnd <= unionStart) {
      return 0;
    }
    return (intersectionEnd - intersectionStart) / (unionEnd - unionStart);
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'startMinutes': startMinutes,
      'endMinutes': endMinutes,
    };
  }

  @override
  List<Object?> get props => <Object?>[startMinutes, endMinutes];
}

class MatchHardFilters extends Equatable {
  const MatchHardFilters({
    this.excludeSmoking = false,
    this.excludedReligions = const <ReligionPreference>{},
    this.excludePetOwners = false,
  });

  factory MatchHardFilters.fromMap(Map<String, Object?> map) {
    final Iterable<Object?> rawReligions =
        (map['exclude_religion'] as Iterable<Object?>?) ?? const <Object?>[];
    return MatchHardFilters(
      excludeSmoking: map['exclude_smoking'] as bool? ?? false,
      excludedReligions: rawReligions
          .map(
            (Object? value) => ReligionPreference.fromLabel(value as String?),
          )
          .whereType<ReligionPreference>()
          .toSet(),
      excludePetOwners: map['exclude_pet_owners'] as bool? ?? false,
    );
  }

  final bool excludeSmoking;
  final Set<ReligionPreference> excludedReligions;
  final bool excludePetOwners;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'exclude_smoking': excludeSmoking,
      'exclude_religion': excludedReligions
          .map((ReligionPreference value) => value.label)
          .toList(growable: false),
      'exclude_pet_owners': excludePetOwners,
    };
  }

  @override
  List<Object?> get props => <Object?>[
    excludeSmoking,
    excludedReligions,
    excludePetOwners,
  ];
}

class MatchPreferences extends Equatable {
  const MatchPreferences({
    this.ageBand,
    this.heightBand,
    this.smoking,
    this.drinking,
    this.religion,
    this.marriageTimeline,
    this.childrenPlan,
    this.financeStyle,
    this.parentsCare,
    this.decisionStyle,
    this.conflictStyle,
    this.shiftPattern,
    this.sleepRange,
    this.weekendStyles = const <String>{},
    this.consumptionStyle,
    this.maxTravelMinutes,
    this.longDistancePreference,
    this.hardFilters = const MatchHardFilters(),
    this.pets = const <String>{},
    this.valuesWeight = 0.35,
    this.lifestyleWeight = 0.2,
    this.distanceWeight = 0.15,
    this.familyPlanWeight = 0.15,
    this.trustSignalWeight = 0.1,
    this.tagWeight = 0.05,
    this.area,
    this.premiumQuestionPreference,
  });

  factory MatchPreferences.fromMap(Map<String, Object?>? map) {
    if (map == null) {
      return const MatchPreferences();
    }

    return MatchPreferences(
      ageBand: AgeBand.fromLabel(map['age_band'] as String?),
      heightBand: HeightBand.fromLabel(map['height_band'] as String?),
      smoking: SmokingHabit.fromLabel(map['smoking'] as String?),
      drinking: DrinkingHabit.fromLabel(map['drinking'] as String?),
      religion: ReligionPreference.fromLabel(map['religion'] as String?),
      marriageTimeline: MarriageTimelinePreference.fromLabel(
        map['marriage_timeline'] as String?,
      ),
      childrenPlan: ChildrenPlanPreference.fromLabel(
        map['children_plan'] as String?,
      ),
      financeStyle: FinanceStylePreference.fromLabel(
        map['finance_style'] as String?,
      ),
      parentsCare: ParentsCarePreference.fromLabel(
        map['parents_care'] as String?,
      ),
      decisionStyle: DecisionStylePreference.fromLabel(
        map['decision_style'] as String?,
      ),
      conflictStyle: ConflictResolutionPreference.fromLabel(
        map['conflict_style'] as String?,
      ),
      shiftPattern: ShiftPattern.fromLabel(map['shift'] as String?),
      sleepRange: map['sleep'] is Map<String, Object?>
          ? TimeRangePreference.fromMap(map['sleep'] as Map<String, Object?>)
          : null,
      weekendStyles:
          ((map['weekend_style'] as Iterable<Object?>?) ?? const <Object?>[])
              .whereType<String>()
              .toSet(),
      consumptionStyle: ConsumptionStylePreference.fromLabel(
        map['consumption_style'] as String?,
      ),
      maxTravelMinutes: (map['max_travel_minutes'] as num?)?.toInt(),
      longDistancePreference: LongDistancePreference.fromLabel(
        map['long_distance_ok'] as String?,
      ),
      hardFilters: map['filters'] is Map<String, Object?>
          ? MatchHardFilters.fromMap(map['filters'] as Map<String, Object?>)
          : const MatchHardFilters(),
      pets: ((map['pets'] as Iterable<Object?>?) ?? const <Object?>[])
          .whereType<String>()
          .toSet(),
      area: map['area'] as String?,
      premiumQuestionPreference: map['first_message_behavior'] as String?,
      valuesWeight: (map['values_weight'] as num?)?.toDouble() ?? 0.35,
      lifestyleWeight: (map['lifestyle_weight'] as num?)?.toDouble() ?? 0.2,
      distanceWeight: (map['distance_weight'] as num?)?.toDouble() ?? 0.15,
      familyPlanWeight: (map['family_plan_weight'] as num?)?.toDouble() ?? 0.15,
      trustSignalWeight:
          (map['trust_signal_weight'] as num?)?.toDouble() ?? 0.1,
      tagWeight: (map['tag_weight'] as num?)?.toDouble() ?? 0.05,
    );
  }

  final AgeBand? ageBand;
  final HeightBand? heightBand;
  final SmokingHabit? smoking;
  final DrinkingHabit? drinking;
  final ReligionPreference? religion;
  final MarriageTimelinePreference? marriageTimeline;
  final ChildrenPlanPreference? childrenPlan;
  final FinanceStylePreference? financeStyle;
  final ParentsCarePreference? parentsCare;
  final DecisionStylePreference? decisionStyle;
  final ConflictResolutionPreference? conflictStyle;
  final ShiftPattern? shiftPattern;
  final TimeRangePreference? sleepRange;
  final Set<String> weekendStyles;
  final ConsumptionStylePreference? consumptionStyle;
  final int? maxTravelMinutes;
  final LongDistancePreference? longDistancePreference;
  final MatchHardFilters hardFilters;
  final Set<String> pets;
  final double valuesWeight;
  final double lifestyleWeight;
  final double distanceWeight;
  final double familyPlanWeight;
  final double trustSignalWeight;
  final double tagWeight;
  final String? area;
  final String? premiumQuestionPreference;

  bool get hasHardFilters =>
      hardFilters.excludeSmoking ||
      hardFilters.excludedReligions.isNotEmpty ||
      hardFilters.excludePetOwners;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'age_band': ageBand?.label,
      'height_band': heightBand?.label,
      'smoking': smoking?.label,
      'drinking': drinking?.label,
      'religion': religion?.label,
      'marriage_timeline': marriageTimeline?.label,
      'children_plan': childrenPlan?.label,
      'finance_style': financeStyle?.label,
      'parents_care': parentsCare?.label,
      'decision_style': decisionStyle?.label,
      'conflict_style': conflictStyle?.label,
      'shift': shiftPattern?.label,
      'sleep': sleepRange?.toMap(),
      'weekend_style': weekendStyles.toList(growable: false),
      'consumption_style': consumptionStyle?.label,
      'max_travel_minutes': maxTravelMinutes,
      'long_distance_ok': longDistancePreference?.label,
      'filters': hardFilters.toMap(),
      'pets': pets.toList(growable: false),
      'values_weight': valuesWeight,
      'lifestyle_weight': lifestyleWeight,
      'distance_weight': distanceWeight,
      'family_plan_weight': familyPlanWeight,
      'trust_signal_weight': trustSignalWeight,
      'tag_weight': tagWeight,
      'area': area,
      'first_message_behavior': premiumQuestionPreference,
    };
  }

  MatchPreferences copyWith({
    AgeBand? ageBand,
    HeightBand? heightBand,
    SmokingHabit? smoking,
    DrinkingHabit? drinking,
    ReligionPreference? religion,
    MarriageTimelinePreference? marriageTimeline,
    ChildrenPlanPreference? childrenPlan,
    FinanceStylePreference? financeStyle,
    ParentsCarePreference? parentsCare,
    DecisionStylePreference? decisionStyle,
    ConflictResolutionPreference? conflictStyle,
    ShiftPattern? shiftPattern,
    TimeRangePreference? sleepRange,
    Set<String>? weekendStyles,
    ConsumptionStylePreference? consumptionStyle,
    int? maxTravelMinutes,
    LongDistancePreference? longDistancePreference,
    MatchHardFilters? hardFilters,
    Set<String>? pets,
    double? valuesWeight,
    double? lifestyleWeight,
    double? distanceWeight,
    double? familyPlanWeight,
    double? trustSignalWeight,
    double? tagWeight,
    String? area,
    String? premiumQuestionPreference,
  }) {
    return MatchPreferences(
      ageBand: ageBand ?? this.ageBand,
      heightBand: heightBand ?? this.heightBand,
      smoking: smoking ?? this.smoking,
      drinking: drinking ?? this.drinking,
      religion: religion ?? this.religion,
      marriageTimeline: marriageTimeline ?? this.marriageTimeline,
      childrenPlan: childrenPlan ?? this.childrenPlan,
      financeStyle: financeStyle ?? this.financeStyle,
      parentsCare: parentsCare ?? this.parentsCare,
      decisionStyle: decisionStyle ?? this.decisionStyle,
      conflictStyle: conflictStyle ?? this.conflictStyle,
      shiftPattern: shiftPattern ?? this.shiftPattern,
      sleepRange: sleepRange ?? this.sleepRange,
      weekendStyles: weekendStyles ?? this.weekendStyles,
      consumptionStyle: consumptionStyle ?? this.consumptionStyle,
      maxTravelMinutes: maxTravelMinutes ?? this.maxTravelMinutes,
      longDistancePreference:
          longDistancePreference ?? this.longDistancePreference,
      hardFilters: hardFilters ?? this.hardFilters,
      pets: pets ?? this.pets,
      valuesWeight: valuesWeight ?? this.valuesWeight,
      lifestyleWeight: lifestyleWeight ?? this.lifestyleWeight,
      distanceWeight: distanceWeight ?? this.distanceWeight,
      familyPlanWeight: familyPlanWeight ?? this.familyPlanWeight,
      trustSignalWeight: trustSignalWeight ?? this.trustSignalWeight,
      tagWeight: tagWeight ?? this.tagWeight,
      area: area ?? this.area,
      premiumQuestionPreference:
          premiumQuestionPreference ?? this.premiumQuestionPreference,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    ageBand,
    heightBand,
    smoking,
    drinking,
    religion,
    marriageTimeline,
    childrenPlan,
    financeStyle,
    parentsCare,
    decisionStyle,
    conflictStyle,
    shiftPattern,
    sleepRange,
    weekendStyles,
    consumptionStyle,
    maxTravelMinutes,
    longDistancePreference,
    hardFilters,
    pets,
    valuesWeight,
    lifestyleWeight,
    distanceWeight,
    familyPlanWeight,
    trustSignalWeight,
    tagWeight,
    area,
    premiumQuestionPreference,
  ];
}
