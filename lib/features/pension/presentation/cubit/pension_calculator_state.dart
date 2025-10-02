import 'package:equatable/equatable.dart';

import '../../domain/entities/pension_calculation_result.dart';
import '../../domain/entities/pension_profile.dart';

/// 연금 계산기 상태
class PensionCalculatorState extends Equatable {
  const PensionCalculatorState({
    required this.profile,
    this.result,
    this.comparison,
    this.status = PensionCalculatorStatus.initial,
    this.errorMessage,
  });

  final PensionProfile profile;
  final PensionCalculationResult? result;
  final PensionVsLumpSumComparison? comparison;
  final PensionCalculatorStatus status;
  final String? errorMessage;

  factory PensionCalculatorState.initial() {
    final currentYear = DateTime.now().year;
    
    return PensionCalculatorState(
      profile: PensionProfile(
        birthYear: 1990,
        appointmentYear: 2015,
        retirementYear: currentYear + 20,
        averageMonthlyIncome: 3000000,
        totalServiceYears: 30,
        expectedLifespan: 85,
        inflationRate: 0.02,
      ),
    );
  }

  PensionCalculatorState copyWith({
    PensionProfile? profile,
    PensionCalculationResult? result,
    PensionVsLumpSumComparison? comparison,
    PensionCalculatorStatus? status,
    String? errorMessage,
    bool clearError = false,
    bool clearResult = false,
  }) {
    return PensionCalculatorState(
      profile: profile ?? this.profile,
      result: clearResult ? null : (result ?? this.result),
      comparison: clearResult ? null : (comparison ?? this.comparison),
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        profile,
        result,
        comparison,
        status,
        errorMessage,
      ];
}

enum PensionCalculatorStatus {
  initial,
  calculating,
  success,
  error,
}
