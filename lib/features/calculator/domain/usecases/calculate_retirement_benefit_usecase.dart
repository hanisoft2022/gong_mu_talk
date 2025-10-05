import 'package:gong_mu_talk/features/calculator/domain/entities/retirement_benefit.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/teacher_profile.dart';
import 'package:gong_mu_talk/features/calculator/domain/services/retirement_benefit_calculation_service.dart';

/// 퇴직급여 계산 UseCase
class CalculateRetirementBenefitUseCase {
  final RetirementBenefitCalculationService _service;

  CalculateRetirementBenefitUseCase(this._service);

  /// 퇴직급여 계산 실행
  ///
  /// [profile] 교사 프로필
  /// [avgBaseIncome] 평균 기준소득월액
  ///
  /// Returns: 퇴직급여 정보
  RetirementBenefit call({
    required TeacherProfile profile,
    required int avgBaseIncome,
  }) {
    final retirementDate = profile.expectedRetirementDate ??
        profile.calculateRetirementDate();

    return _service.calculateRetirementBenefit(
      employmentStartDate: profile.employmentStartDate,
      retirementDate: retirementDate,
      avgBaseIncome: avgBaseIncome,
    );
  }

  /// 일시금 계산 (10년 미만자)
  ///
  /// [profile] 교사 프로필
  /// [avgBaseIncome] 평균 기준소득월액
  ///
  /// Returns: 일시금 (10년 미만인 경우만, 아니면 0)
  int calculateLumpSum({
    required TeacherProfile profile,
    required int avgBaseIncome,
  }) {
    final retirementDate = profile.expectedRetirementDate ??
        profile.calculateRetirementDate();

    final serviceYears = retirementDate
            .difference(profile.employmentStartDate)
            .inDays ~/
        365;

    return _service.calculateLumpSum(
      serviceYears: serviceYears,
      avgBaseIncome: avgBaseIncome,
    );
  }

  /// 경력별 퇴직급여 비교
  ///
  /// [profile] 교사 프로필
  /// [avgBaseIncome] 평균 기준소득월액
  /// [maxYears] 최대 경력 년수
  ///
  /// Returns: 경력별 퇴직급여 및 일시금 목록
  List<Map<String, dynamic>> compareByYears({
    required TeacherProfile profile,
    required int avgBaseIncome,
    int maxYears = 40,
  }) {
    return _service.compareRetirementBenefitByYears(
      employmentStartDate: profile.employmentStartDate,
      avgBaseIncome: avgBaseIncome,
      maxYears: maxYears,
    );
  }
}
