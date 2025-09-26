import 'package:equatable/equatable.dart';

import 'match_compatibility.dart';
import 'match_flow.dart';
import 'match_preferences.dart';
import 'match_profile.dart';

class CuratedMatch extends Equatable {
  const CuratedMatch({
    required this.profile,
    required this.compatibility,
    required this.stage,
    required this.availablePrompts,
    this.preferences,
    this.isHardFilteredOut = false,
  });

  final MatchProfile profile;
  final CompatibilitySummary compatibility;
  final MatchFlowStage stage;
  final List<String> availablePrompts;
  final MatchPreferences? preferences;
  final bool isHardFilteredOut;

  CuratedMatch copyWith({
    MatchFlowStage? stage,
    CompatibilitySummary? compatibility,
    List<String>? availablePrompts,
    MatchPreferences? preferences,
    bool? isHardFilteredOut,
  }) {
    return CuratedMatch(
      profile: profile,
      compatibility: compatibility ?? this.compatibility,
      stage: stage ?? this.stage,
      availablePrompts: availablePrompts ?? this.availablePrompts,
      preferences: preferences ?? this.preferences,
      isHardFilteredOut: isHardFilteredOut ?? this.isHardFilteredOut,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    profile,
    compatibility,
    stage,
    availablePrompts,
    preferences,
    isHardFilteredOut,
  ];
}
