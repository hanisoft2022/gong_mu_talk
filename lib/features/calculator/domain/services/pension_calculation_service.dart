import 'dart:math';

import 'package:gong_mu_talk/features/calculator/domain/entities/pension_estimate.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/teacher_profile.dart';

/// 연금 계산 서비스
class PensionCalculationService {
  /// 연금 예상액 계산
  PensionEstimate calculatePension({
    required TeacherProfile profile,
    required int avgBaseIncome,
    int? customRetirementAge,
    int? customLifeExpectancy,
  }) {
    final retirementAge = customRetirementAge ?? profile.retirementAge;
    final lifeExpectancy = customLifeExpectancy ?? 85;

    // 1. 재직 년수 계산
    final now = DateTime.now();
    final serviceYears = retirementAge - (now.year - profile.employmentStartDate.year);

    // 2. 연금 지급률 계산
    final pensionRate = _calculatePensionRate(serviceYears);

    // 3. 월 연금액
    final monthlyPension = (avgBaseIncome * pensionRate).round();

    // 4. 연간 연금액 (13개월 기준)
    final annualPension = monthlyPension * 13;

    // 5. 총 수령 예상액
    final receivingYears = lifeExpectancy - retirementAge;
    final totalPension = annualPension * receivingYears;

    // 6. 기여금 총 납부액 추정 (기준소득의 9% * 재직월수)
    final totalContribution = (avgBaseIncome * 0.09 * serviceYears * 12).round();

    return PensionEstimate(
      monthlyPension: monthlyPension,
      annualPension: annualPension,
      totalPension: totalPension,
      retirementAge: retirementAge,
      lifeExpectancy: lifeExpectancy,
      serviceYears: serviceYears,
      avgBaseIncome: avgBaseIncome,
      pensionRate: pensionRate,
      totalContribution: totalContribution,
    );
  }

  /// 조기연금 시나리오 비교 (60~65세)
  List<PensionEstimate> compareEarlyRetirement({
    required TeacherProfile profile,
    required int avgBaseIncome,
  }) {
    final scenarios = <PensionEstimate>[];

    for (int age = 60; age <= 65; age++) {
      final estimate = calculatePension(
        profile: profile,
        avgBaseIncome: avgBaseIncome,
        customRetirementAge: age,
      );

      // 조기연금 감액 적용
      final adjustedEstimate = _applyEarlyPensionReduction(estimate, age);
      scenarios.add(adjustedEstimate);
    }

    return scenarios;
  }

  /// 연금 지급률 계산
  /// - 10년 미만: 0%
  /// - 10~20년: 50% + (년수-10) * 2%
  /// - 20년 이상: 70% + (년수-20) * 1% (최대 76%)
  double _calculatePensionRate(int serviceYears) {
    if (serviceYears < 10) return 0.0;
    if (serviceYears < 20) {
      return 0.5 + (serviceYears - 10) * 0.02;
    }
    return min(0.7 + (serviceYears - 20) * 0.01, 0.76);
  }

  /// 조기연금 감액 적용
  /// - 65세 기준, 1년당 6% 감액 (최대 30%)
  PensionEstimate _applyEarlyPensionReduction(
    PensionEstimate estimate,
    int actualRetirementAge,
  ) {
    const standardAge = 65;
    if (actualRetirementAge >= standardAge) return estimate;

    final yearsDiff = standardAge - actualRetirementAge;
    final reductionRate = min(yearsDiff * 0.06, 0.30);
    final adjustmentFactor = 1.0 - reductionRate;

    return estimate.copyWith(
      monthlyPension: (estimate.monthlyPension * adjustmentFactor).round(),
      annualPension: (estimate.annualPension * adjustmentFactor).round(),
      totalPension: (estimate.totalPension * adjustmentFactor).round(),
      retirementAge: actualRetirementAge,
    );
  }

  /// 일시금 vs 연금 비교
  /// 일시금은 대략 기준소득의 60배로 가정
  Map<String, dynamic> compareLumpSumVsPension({
    required PensionEstimate pensionEstimate,
    double investmentReturnRate = 0.05, // 연 5% 수익률 가정
  }) {
    // 1. 일시금 추정액 (매우 간략화)
    final lumpSum = (pensionEstimate.avgBaseIncome * 60);

    // 2. 일시금 투자 시 미래 가치
    final years = pensionEstimate.receivingYears;
    final futureValue = lumpSum * pow(1 + investmentReturnRate, years);

    // 3. 연금 총 수령액
    final pensionTotal = pensionEstimate.totalPension;

    return {
      'lumpSum': lumpSum,
      'lumpSumFutureValue': futureValue.round(),
      'pensionTotal': pensionTotal,
      'difference': (futureValue - pensionTotal).round(),
      'recommendPension': futureValue < pensionTotal,
    };
  }
}
