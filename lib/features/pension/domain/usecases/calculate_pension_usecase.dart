import 'package:injectable/injectable.dart';

import '../entities/pension_calculation_result.dart';
import '../entities/pension_profile.dart';
import '../services/pension_calculator.dart';

/// 연금 계산 Use Case
@lazySingleton
class CalculatePensionUseCase {
  CalculatePensionUseCase({
    required PensionCalculator calculator,
  }) : _calculator = calculator;

  final PensionCalculator _calculator;

  /// 연금 계산 실행
  PensionCalculationResult call(PensionProfile profile) {
    return _calculator.calculatePension(profile);
  }

  /// 연금 vs 일시금 비교
  PensionVsLumpSumComparison comparePensionVsLumpSum({
    required PensionProfile profile,
    required PensionCalculationResult pensionResult,
  }) {
    return _calculator.comparePensionVsLumpSum(
      profile: profile,
      pensionResult: pensionResult,
    );
  }
}
