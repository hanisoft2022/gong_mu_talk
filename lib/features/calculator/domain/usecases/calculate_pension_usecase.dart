import 'package:gong_mu_talk/features/calculator/domain/entities/pension_estimate.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/teacher_profile.dart';
import 'package:gong_mu_talk/features/calculator/domain/services/pension_calculation_service.dart';

/// 연금 계산 UseCase
class CalculatePensionUseCase {
  final PensionCalculationService _pensionService;

  CalculatePensionUseCase(this._pensionService);

  /// 연금 예상액 계산 실행
  PensionEstimate call({
    required TeacherProfile profile,
    required int avgBaseIncome,
    int? customRetirementAge,
    int? customLifeExpectancy,
  }) {
    return _pensionService.calculatePension(
      profile: profile,
      avgBaseIncome: avgBaseIncome,
      customRetirementAge: customRetirementAge,
      customLifeExpectancy: customLifeExpectancy,
    );
  }

  /// 조기연금 시나리오 비교
  List<PensionEstimate> compareEarlyRetirement({
    required TeacherProfile profile,
    required int avgBaseIncome,
  }) {
    return _pensionService.compareEarlyRetirement(
      profile: profile,
      avgBaseIncome: avgBaseIncome,
    );
  }

  /// 일시금 vs 연금 비교
  Map<String, dynamic> compareLumpSumVsPension({
    required PensionEstimate pensionEstimate,
    double? investmentReturnRate,
  }) {
    return _pensionService.compareLumpSumVsPension(
      pensionEstimate: pensionEstimate,
      investmentReturnRate: investmentReturnRate ?? 0.05,
    );
  }
}
