/// Refactored to meet AI token optimization guidelines
/// Main match preferences entity - enums extracted to separate files
/// Target: ≤200 lines (domain file guideline)

import 'package:equatable/equatable.dart';

import 'match_preference_enums.dart';
import 'match_preference_helpers.dart';

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
