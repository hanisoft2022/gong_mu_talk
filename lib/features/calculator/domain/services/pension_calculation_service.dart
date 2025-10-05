import 'dart:math';

import 'package:gong_mu_talk/features/calculator/domain/constants/income_redistribution_table.dart';
import 'package:gong_mu_talk/features/calculator/domain/constants/transition_rate_table.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/pension_estimate.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/teacher_profile.dart';

/// 연금 계산 서비스
class PensionCalculationService {
  /// 연금 예상액 계산 (소득재분배 + 이행률 적용)
  PensionEstimate calculatePension({
    required TeacherProfile profile,
    required int avgBaseIncome,
    int? customRetirementAge,
    int? customLifeExpectancy,
  }) {
    final retirementAge = customRetirementAge ?? profile.retirementAge;
    final lifeExpectancy = customLifeExpectancy ?? 85;

    // 1. 정년퇴직일 계산 (생년월 기반)
    final retirementDate = profile.calculateRetirementDate();

    // 2. 재직 년수 계산 (정확한 날짜 기반)
    final totalDays =
        retirementDate.difference(profile.employmentStartDate).inDays;
    final serviceYears = (totalDays / 365).floor();

    // 3. 기간별 경력 계산 (이행률 적용 위해)
    final periods = TransitionRateTable.calculatePeriodYears(
      employmentStartDate: profile.employmentStartDate,
      retirementDate: retirementDate,
    );

    // 4. 이행률 계산
    final transitionRate = TransitionRateTable.calculateTransitionRate(
      yearsBefore2010: periods.period1Years,
      yearsBetween2010And2015: periods.period2Years,
      yearsAfter2016: periods.period3Years,
    );

    // 5. 소득재분배 적용비율 계산
    final redistributionRate =
        IncomeRedistributionTable.getRedistributionRate(
      avgBaseIncome.toDouble(),
    );

    // 6. 연금 지급률 계산
    final pensionRate = _calculatePensionRate(serviceYears);

    // 7. 월 연금액 = 평균소득월액 × 이행률 × 재분배율 × 지급률
    final monthlyPension = (avgBaseIncome *
            transitionRate *
            redistributionRate *
            pensionRate)
        .round();

    // 8. 연간 연금액 (13개월 기준)
    final annualPension = monthlyPension * 13;

    // 9. 총 수령 예상액
    final receivingYears = lifeExpectancy - retirementAge;
    final totalPension = annualPension * receivingYears;

    // 10. 기여금 총 납부액 추정 (기준소득의 9% × 재직월수)
    final totalContribution =
        (avgBaseIncome * 0.09 * serviceYears * 12).round();

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
      transitionRate: transitionRate,
      redistributionRate: redistributionRate,
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

  /// 연금 지급률 계산 (2009년 이후 기준)
  /// - 10년 미만: 0% (연금 수급 자격 없음)
  /// - 10~19년: 기본 20% + (년수-10) × 3% = 20~47%
  /// - 20년 이상: 50% + (년수-20) × 2% (최대 76%, 33년 이상)
  double _calculatePensionRate(int serviceYears) {
    if (serviceYears < 10) return 0.0;
    if (serviceYears < 20) {
      return 0.20 + (serviceYears - 10) * 0.03;
    }
    return min(0.50 + (serviceYears - 20) * 0.02, 0.76);
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
