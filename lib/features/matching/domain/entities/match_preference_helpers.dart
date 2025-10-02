/// Extracted from match_preferences.dart for better file organization
/// Helper classes for matching preferences

library;
import 'package:equatable/equatable.dart';

import 'match_preference_enums.dart';

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
