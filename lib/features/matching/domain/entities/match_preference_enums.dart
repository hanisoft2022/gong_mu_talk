/// Extracted from match_preferences.dart for better file organization
/// Enum types for matching preferences

library;
import 'package:collection/collection.dart';

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
