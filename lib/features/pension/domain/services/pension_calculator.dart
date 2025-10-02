import 'dart:math';

import 'package:injectable/injectable.dart';

import '../entities/pension_calculation_result.dart';
import '../entities/pension_profile.dart';

/// 공무원연금 계산 서비스
/// 
/// 계산 기준:
/// - 공무원연금법 제46조 (퇴직연금)
/// - 2025년 기준
@lazySingleton
class PensionCalculator {
  /// 월 연금액 계산
  /// 
  /// 공식: 평균 기준소득월액 × 지급률 × (1 - 조기퇴직감액률)
  /// 
  /// [profile]: 연금 프로필
  /// Returns: 월 연금액
  double calculateMonthlyPension(PensionProfile profile) {
    final paymentRate = _getPaymentRate(profile.totalServiceYears);
    final reductionRate = _getEarlyRetirementReduction(
      profile.earlyRetirementYears,
    );

    final monthlyPension = profile.averageMonthlyIncome *
        paymentRate *
        (1 - reductionRate);

    return monthlyPension;
  }

  /// 재직기간별 지급률 계산
  /// 
  /// 공무원연금법 제46조:
  /// - 20년 미만: 재직연수 × 1.9%
  /// - 20년 이상: 38% + (재직연수 - 20) × 2.0%
  /// - 최대: 76% (33년 이상)
  double _getPaymentRate(int serviceYears) {
    if (serviceYears < 20) {
      return serviceYears * 0.019;
    } else if (serviceYears <= 33) {
      return 0.38 + (serviceYears - 20) * 0.020;
    } else {
      return 0.76; // 최대 76%
    }
  }

  /// 조기퇴직 감액률 계산
  /// 
  /// 정년 이전 퇴직 시 연 5% 감액
  /// 최대 25% (5년 조기퇴직)
  double _getEarlyRetirementReduction(int yearsEarly) {
    if (yearsEarly <= 0) return 0;
    final reduction = yearsEarly * 0.05;
    return min(reduction, 0.25); // 최대 25%
  }

  /// 전체 연금 계산
  /// 
  /// [profile]: 연금 프로필
  /// Returns: 연금 계산 결과
  PensionCalculationResult calculatePension(PensionProfile profile) {
    // 1. 기본 연금액 계산
    final monthlyPension = calculateMonthlyPension(profile);
    final yearlyPension = monthlyPension * 12;

    // 2. 지급률 및 감액률
    final paymentRate = _getPaymentRate(profile.totalServiceYears);
    final reductionRate = _getEarlyRetirementReduction(
      profile.earlyRetirementYears,
    );

    // 3. 연도별 예상 수급액 계산 (물가상승 반영)
    final yearlyProjection = _calculateYearlyProjection(
      profile: profile,
      basePension: monthlyPension,
    );

    // 4. 평생 총액 계산 (현재가치)
    final lifetimeTotal = yearlyProjection.fold<double>(
      0,
      (sum, year) => sum + year.yearlyAmount,
    );

    // 5. 일시금 옵션 계산
    final lumpSum = _calculateLumpSum(profile);

    // 6. 참고사항 생성
    final notes = _generateNotes(
      profile: profile,
      paymentRate: paymentRate,
      reductionRate: reductionRate,
    );

    return PensionCalculationResult(
      monthlyPension: monthlyPension,
      yearlyPension: yearlyPension,
      lifetimeTotal: lifetimeTotal,
      paymentRate: paymentRate,
      earlyRetirementReduction: reductionRate,
      lumpSumOption: lumpSum,
      yearlyProjection: yearlyProjection,
      notes: notes,
    );
  }

  /// 연도별 연금 수급 예상 계산
  List<YearlyPensionProjection> _calculateYearlyProjection({
    required PensionProfile profile,
    required double basePension,
  }) {
    final projections = <YearlyPensionProjection>[];
    double cumulativeTotal = 0;

    for (int i = 0; i < profile.pensionDuration; i++) {
      final year = profile.retirementYear + i;
      final age = profile.pensionStartAge + i;

      // 물가상승 반영
      final inflationFactor = pow(1 + profile.inflationRate, i);
      final monthlyAmount = basePension * inflationFactor;
      final yearlyAmount = monthlyAmount * 12;

      cumulativeTotal += yearlyAmount;

      projections.add(
        YearlyPensionProjection(
          year: year,
          age: age,
          monthlyAmount: monthlyAmount,
          yearlyAmount: yearlyAmount,
          cumulativeTotal: cumulativeTotal,
        ),
      );
    }

    return projections;
  }

  /// 일시금 계산
  /// 
  /// 재직기간 10년 미만: 본인 기여금 + 이자
  /// 재직기간 10년 이상 20년 미만: 본인 기여금 × 1.5
  /// 재직기간 20년 이상: 연금 선택 권장 (일시금 선택 불가)
  PensionLumpSumOption _calculateLumpSum(PensionProfile profile) {
    final contributionRate = 0.09; // 공무원연금 기여율 9%
    final totalContributions = profile.averageMonthlyIncome *
        12 *
        profile.totalServiceYears *
        contributionRate;

    if (profile.totalServiceYears < 10) {
      // 10년 미만: 기여금 + 이자 (단순 계산)
      final interest = totalContributions * 0.03 * profile.totalServiceYears;
      final total = totalContributions + interest;

      return PensionLumpSumOption(
        totalAmount: total,
        returnedContributions: totalContributions,
        additionalAmount: interest,
        description: '재직 10년 미만: 본인 기여금 + 이자',
      );
    } else if (profile.totalServiceYears < 20) {
      // 10년 이상 20년 미만: 기여금 × 1.5
      final total = totalContributions * 1.5;

      return PensionLumpSumOption(
        totalAmount: total,
        returnedContributions: totalContributions,
        additionalAmount: total - totalContributions,
        description: '재직 10년 이상: 본인 기여금 × 1.5',
      );
    } else {
      // 20년 이상: 연금 수급 권장
      return PensionLumpSumOption(
        totalAmount: 0,
        returnedContributions: totalContributions,
        additionalAmount: 0,
        description: '재직 20년 이상: 연금 수급 권장 (일시금 선택 불가)',
      );
    }
  }

  /// 연금 vs 일시금 비교
  PensionVsLumpSumComparison comparePensionVsLumpSum({
    required PensionProfile profile,
    required PensionCalculationResult pensionResult,
  }) {
    final lumpSum = pensionResult.lumpSumOption.totalAmount;

    if (lumpSum == 0) {
      return PensionVsLumpSumComparison(
        lumpSum: 0,
        pensionLifetimeTotal: pensionResult.lifetimeTotal,
        breakEvenAge: 0,
        recommendation: '재직 20년 이상: 연금 수급만 가능',
      );
    }

    // 손익분기 연령 계산
    int breakEvenAge = profile.pensionStartAge;
    double cumulativePension = 0;

    for (final projection in pensionResult.yearlyProjection) {
      cumulativePension = projection.cumulativeTotal;

      if (cumulativePension >= lumpSum) {
        breakEvenAge = projection.age;
        break;
      }
    }

    // 추천
    String recommendation;
    if (breakEvenAge < 70) {
      recommendation = '연금 수급 권장 (손익분기: $breakEvenAge세)';
    } else if (breakEvenAge < 80) {
      recommendation = '상황에 따라 선택 (손익분기: $breakEvenAge세)';
    } else {
      recommendation = '일시금 고려 가능 (손익분기: $breakEvenAge세)';
    }

    return PensionVsLumpSumComparison(
      lumpSum: lumpSum,
      pensionLifetimeTotal: pensionResult.lifetimeTotal,
      breakEvenAge: breakEvenAge,
      recommendation: recommendation,
    );
  }

  /// 참고사항 생성
  List<String> _generateNotes({
    required PensionProfile profile,
    required double paymentRate,
    required double reductionRate,
  }) {
    final notes = <String>[
      '■ 기본 정보',
      '재직기간: ${profile.totalServiceYears}년',
      '평균 기준소득월액: ${_formatCurrency(profile.averageMonthlyIncome)}',
      '',
      '■ 지급률',
      '기본 지급률: ${(paymentRate * 100).toStringAsFixed(1)}%',
    ];

    if (profile.isEarlyRetirement) {
      notes.addAll([
        '조기퇴직 감액: ${(reductionRate * 100).toStringAsFixed(0)}% (${profile.earlyRetirementYears}년 조기)',
        '실제 지급률: ${((paymentRate * (1 - reductionRate)) * 100).toStringAsFixed(1)}%',
      ]);
    }

    notes.addAll([
      '',
      '■ 참고',
      '• 물가상승률 ${(profile.inflationRate * 100).toStringAsFixed(1)}% 가정',
      '• 예상 수명 ${profile.expectedLifespan}세 기준',
      '• 실제 수급액은 법령 개정에 따라 달라질 수 있음',
    ]);

    return notes;
  }

  String _formatCurrency(double amount) {
    return '${(amount / 10000).toStringAsFixed(0)}만원';
  }
}
