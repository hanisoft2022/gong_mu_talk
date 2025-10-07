import 'package:gong_mu_talk/features/calculator/domain/entities/retirement_benefit.dart';
import 'package:gong_mu_talk/features/calculator/domain/constants/transition_rate_table.dart';

/// 퇴직급여 계산 서비스
class RetirementBenefitCalculationService {
  /// 퇴직급여 계산 (1~3구간별)
  ///
  /// [employmentStartDate] 임용일
  /// [retirementDate] 퇴직일
  /// [avgBaseIncome] 평균 기준소득월액
  ///
  /// Returns: 퇴직급여 정보
  RetirementBenefit calculateRetirementBenefit({
    required DateTime employmentStartDate,
    required DateTime retirementDate,
    required int avgBaseIncome,
  }) {
    // 1. 기간별 경력 계산
    final periods = TransitionRateTable.calculatePeriodYears(
      employmentStartDate: employmentStartDate,
      retirementDate: retirementDate,
    );

    final period1Years = periods.period1Years;
    final period2Years = periods.period2Years;
    final period3Years = periods.period3Years;

    // 2. 적용 보수 설정
    // 1기간: 평균 기준소득 사용
    // 2~3기간: 평균 기준소득 사용 (동일)
    final period1BaseIncome = avgBaseIncome;
    final period23BaseIncome = avgBaseIncome;

    // 3. 1기간 퇴직급여 계산 (~2009.12.31)
    // 퇴직급여 = 적용보수 × 재직년수 × 1.0
    final period1Benefit = (period1BaseIncome * period1Years).toInt();

    // 4. 2기간 퇴직급여 계산 (2010.1.1~2015.12.31)
    // 퇴직급여 = 적용보수 × 재직년수 × 0.95
    final period2Benefit = (period23BaseIncome * period2Years * 0.95).toInt();

    // 5. 3기간 퇴직급여 계산 (2016.1.1~)
    // 퇴직급여 = 적용보수 × 재직년수 × 1.0
    final period3Benefit = (period23BaseIncome * period3Years * 1.0).toInt();

    // 6. 총 퇴직급여
    final totalBenefit = period1Benefit + period2Benefit + period3Benefit;

    // 7. 퇴직수당 계산
    // 퇴직수당 = 1기간 퇴직급여 + (2~3기간 퇴직급여 × 0.6)
    final period23Benefit = period2Benefit + period3Benefit;
    final retirementAllowance = (period1Benefit + (period23Benefit * 0.6))
        .toInt();

    return RetirementBenefit(
      period1Benefit: period1Benefit,
      period2Benefit: period2Benefit,
      period3Benefit: period3Benefit,
      totalBenefit: totalBenefit,
      retirementAllowance: retirementAllowance,
      period1Years: period1Years,
      period2Years: period2Years,
      period3Years: period3Years,
      period1BaseIncome: period1BaseIncome,
      period23BaseIncome: period23BaseIncome,
    );
  }

  /// 일시금 계산 (10년 미만자)
  ///
  /// [serviceYears] 재직 년수
  /// [avgBaseIncome] 평균 기준소득월액
  ///
  /// Returns: 일시금 (10년 미만인 경우만, 아니면 0)
  int calculateLumpSum({
    required int serviceYears,
    required int avgBaseIncome,
  }) {
    // 10년 미만만 일시금 수령 가능
    if (serviceYears >= 10) return 0;

    // 일시금 = 평균 기준소득월액 × 재직월수 × 기여율(9%)
    final serviceMonths = serviceYears * 12;
    final lumpSum = (avgBaseIncome * serviceMonths * 0.09).toInt();

    return lumpSum;
  }

  /// 퇴직급여 vs 일시금 비교 (경력별)
  ///
  /// [employmentStartDate] 임용일
  /// [avgBaseIncome] 평균 기준소득월액
  /// [maxYears] 최대 경력 년수
  ///
  /// Returns: 경력별 퇴직급여 및 일시금 목록
  List<Map<String, dynamic>> compareRetirementBenefitByYears({
    required DateTime employmentStartDate,
    required int avgBaseIncome,
    int maxYears = 40,
  }) {
    final results = <Map<String, dynamic>>[];

    for (int years = 1; years <= maxYears; years++) {
      final retirementDate = employmentStartDate.add(
        Duration(days: years * 365),
      );

      final benefit = calculateRetirementBenefit(
        employmentStartDate: employmentStartDate,
        retirementDate: retirementDate,
        avgBaseIncome: avgBaseIncome,
      );

      final lumpSum = calculateLumpSum(
        serviceYears: years,
        avgBaseIncome: avgBaseIncome,
      );

      results.add({
        'years': years,
        'retirementBenefit': benefit,
        'lumpSum': lumpSum,
        'retirementAllowance': benefit.retirementAllowance,
      });
    }

    return results;
  }
}
