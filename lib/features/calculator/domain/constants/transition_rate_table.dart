/// 이행률표 (2010년 공무원연금 제도 개편 반영)
///
/// 2010년 1월 1일을 기준으로 경력을 3개 기간으로 구분하여
/// 각 기간의 비율에 따라 다른 이행률을 적용함.
///
/// - 1기간: 2010.1.1 이전 경력
/// - 2기간: 2010.1.1 ~ 2015.12.31 경력
/// - 3기간: 2016.1.1 이후 경력
class TransitionRateTable {
  /// 기간별 경력 비율에 따른 이행률 테이블
  ///
  /// Key: "1기간_비율_2기간_비율_3기간_비율" (백분율, 정수)
  /// Value: 이행률
  static const Map<String, double> rates = {
    // 1기간 100%
    '1기간_100_2기간_0_3기간_0': 1.9,

    // 1기간 + 2기간
    '1기간_90_2기간_10_3기간_0': 1.805,
    '1기간_80_2기간_20_3기간_0': 1.710,
    '1기간_70_2기간_30_3기간_0': 1.615,
    '1기간_60_2기간_40_3기간_0': 1.520,
    '1기간_50_2기간_50_3기간_0': 1.425,
    '1기간_40_2기간_60_3기간_0': 1.330,
    '1기간_30_2기간_70_3기간_0': 1.235,
    '1기간_20_2기간_80_3기간_0': 1.140,
    '1기간_10_2기간_90_3기간_0': 1.045,

    // 2기간 100%
    '1기간_0_2기간_100_3기간_0': 0.95,

    // 2기간 + 3기간
    '1기간_0_2기간_90_3기간_10': 0.955,
    '1기간_0_2기간_80_3기간_20': 0.960,
    '1기간_0_2기간_70_3기간_30': 0.965,
    '1기간_0_2기간_60_3기간_40': 0.970,
    '1기간_0_2기간_50_3기간_50': 0.975,
    '1기간_0_2기간_40_3기간_60': 0.980,
    '1기간_0_2기간_30_3기간_70': 0.985,
    '1기간_0_2기간_20_3기간_80': 0.990,
    '1기간_0_2기간_10_3기간_90': 0.995,

    // 3기간 100%
    '1기간_0_2기간_0_3기간_100': 1.0,

    // 1기간 + 3기간 (2기간 없음)
    '1기간_90_2기간_0_3기간_10': 1.810,
    '1기간_80_2기간_0_3기간_20': 1.720,
    '1기간_70_2기간_0_3기간_30': 1.630,
    '1기간_60_2기간_0_3기간_40': 1.540,
    '1기간_50_2기간_0_3기간_50': 1.450,
    '1기간_40_2기간_0_3기간_60': 1.360,
    '1기간_30_2기간_0_3기간_70': 1.270,
    '1기간_20_2기간_0_3기간_80': 1.180,
    '1기간_10_2기간_0_3기간_90': 1.090,

    // 3기간 혼합 케이스 (균등 분배)
    '1기간_33_2기간_33_3기간_33': 1.267,
    '1기간_25_2기간_25_3기간_50': 1.188,
    '1기간_25_2기간_50_3기간_25': 1.163,
    '1기간_50_2기간_25_3기간_25': 1.338,

    // 추가 혼합 케이스
    '1기간_20_2기간_30_3기간_50': 1.140,
    '1기간_30_2기간_20_3기간_50': 1.220,
    '1기간_40_2기간_30_3기간_30': 1.310,
    '1기간_30_2기간_40_3기간_30': 1.215,
    '1기간_20_2기간_40_3기간_40': 1.130,
  };

  /// 기간별 경력 년수를 기반으로 이행률 계산
  ///
  /// [yearsBefore2010] 2010.1.1 이전 경력 (년)
  /// [yearsBetween2010And2015] 2010.1.1 ~ 2015.12.31 경력 (년)
  /// [yearsAfter2016] 2016.1.1 이후 경력 (년)
  ///
  /// Returns: 이행률 (0.95 ~ 1.9)
  static double calculateTransitionRate({
    required int yearsBefore2010,
    required int yearsBetween2010And2015,
    required int yearsAfter2016,
  }) {
    final totalYears =
        yearsBefore2010 + yearsBetween2010And2015 + yearsAfter2016;

    // 재직 기간이 없으면 기본값 1.0 반환
    if (totalYears == 0) return 1.0;

    // 각 기간별 비율 계산 (반올림하여 정수로)
    final period1Pct = ((yearsBefore2010 / totalYears) * 100).round();
    final period2Pct = ((yearsBetween2010And2015 / totalYears) * 100).round();
    final period3Pct = ((yearsAfter2016 / totalYears) * 100).round();

    // 비율 합이 100이 되도록 조정 (반올림 오차 보정)
    final totalPct = period1Pct + period2Pct + period3Pct;
    int adjustedPeriod3Pct = period3Pct;
    if (totalPct != 100) {
      adjustedPeriod3Pct += (100 - totalPct);
    }

    // 키 생성
    final key = '1기간_${period1Pct}_2기간_${period2Pct}_3기간_$adjustedPeriod3Pct';

    // 테이블에서 정확히 매칭되는 이행률 반환
    if (rates.containsKey(key)) {
      return rates[key]!;
    }

    // 매칭되지 않으면 보간법으로 근사값 계산
    return _interpolateRate(period1Pct, period2Pct, adjustedPeriod3Pct);
  }

  /// 비율이 정확히 매칭되지 않을 때 보간법으로 이행률 근사
  ///
  /// 간단한 선형 보간:
  /// - 1기간 비율이 높을수록 1.9에 가까움
  /// - 2기간 비율이 높을수록 0.95에 가까움
  /// - 3기간 비율이 높을수록 1.0에 가까움
  static double _interpolateRate(
    int period1Pct,
    int period2Pct,
    int period3Pct,
  ) {
    const period1Rate = 1.9;
    const period2Rate = 0.95;
    const period3Rate = 1.0;

    final interpolated =
        (period1Pct / 100 * period1Rate) +
        (period2Pct / 100 * period2Rate) +
        (period3Pct / 100 * period3Rate);

    return double.parse(interpolated.toStringAsFixed(3));
  }

  /// 임용일을 기반으로 기간별 경력 년수 자동 계산
  ///
  /// [employmentStartDate] 임용일
  /// [retirementDate] 퇴직일 (예정일)
  ///
  /// Returns: (1기간 년수, 2기간 년수, 3기간 년수)
  static ({int period1Years, int period2Years, int period3Years})
  calculatePeriodYears({
    required DateTime employmentStartDate,
    required DateTime retirementDate,
  }) {
    final period1End = DateTime(2009, 12, 31);
    final period2Start = DateTime(2010, 1, 1);
    final period2End = DateTime(2015, 12, 31);
    final period3Start = DateTime(2016, 1, 1);

    int period1Years = 0;
    int period2Years = 0;
    int period3Years = 0;

    // 1기간 계산 (2010.1.1 이전)
    if (employmentStartDate.isBefore(period2Start)) {
      final endDate = retirementDate.isBefore(period1End)
          ? retirementDate
          : period1End;
      final days = endDate.difference(employmentStartDate).inDays;
      period1Years = (days / 365).floor();
    }

    // 2기간 계산 (2010.1.1 ~ 2015.12.31)
    if (retirementDate.isAfter(period2Start)) {
      final startDate = employmentStartDate.isAfter(period2Start)
          ? employmentStartDate
          : period2Start;
      final endDate = retirementDate.isBefore(period2End)
          ? retirementDate
          : period2End;

      if (endDate.isAfter(startDate)) {
        final days = endDate.difference(startDate).inDays;
        period2Years = (days / 365).floor();
      }
    }

    // 3기간 계산 (2016.1.1 이후)
    if (retirementDate.isAfter(period3Start)) {
      final startDate = employmentStartDate.isAfter(period3Start)
          ? employmentStartDate
          : period3Start;
      final days = retirementDate.difference(startDate).inDays;
      period3Years = (days / 365).floor();
    }

    return (
      period1Years: period1Years,
      period2Years: period2Years,
      period3Years: period3Years,
    );
  }
}
