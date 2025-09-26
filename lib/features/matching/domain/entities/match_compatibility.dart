import 'package:equatable/equatable.dart';

enum CompatibilityDimension {
  coreValues,
  lifestyle,
  distance,
  familyPlan,
  trustSignals,
  preferenceTags,
}

class CompatibilityBreakdown extends Equatable {
  const CompatibilityBreakdown({
    required this.dimension,
    required this.score,
    required this.weight,
  });

  final CompatibilityDimension dimension;
  final double score;
  final double weight;

  double get weightedScore => score * weight;

  @override
  List<Object?> get props => <Object?>[dimension, score, weight];
}

class CompatibilitySummary extends Equatable {
  const CompatibilitySummary({
    required this.totalScore,
    required this.breakdowns,
    required this.highlightReasons,
  });

  final double totalScore;
  final List<CompatibilityBreakdown> breakdowns;
  final List<String> highlightReasons;

  double weightedScoreFor(CompatibilityDimension dimension) {
    final CompatibilityBreakdown breakdown = breakdowns.firstWhere(
      (CompatibilityBreakdown element) => element.dimension == dimension,
      orElse: () => const CompatibilityBreakdown(
        dimension: CompatibilityDimension.coreValues,
        score: 0,
        weight: 0,
      ),
    );
    return breakdown.weightedScore;
  }

  @override
  List<Object?> get props => <Object?>[
    totalScore,
    breakdowns,
    highlightReasons,
  ];
}

class CompatibilityAssessment extends Equatable {
  const CompatibilityAssessment({
    required this.summary,
    required this.passesHardFilters,
  });

  final CompatibilitySummary summary;
  final bool passesHardFilters;

  @override
  List<Object?> get props => <Object?>[summary, passesHardFilters];
}
