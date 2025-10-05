/// 퇴직급여 계산 상수 테이블
///
/// 출처: 공무원연금법, 인사혁신처 (2025년 기준)
class RetirementBenefitTable {
  /// 기간별 퇴직급여 계수
  ///
  /// - 1기간(~2009.12.31): 1.0
  /// - 2기간(2010.1.1~2015.12.31): 0.95
  /// - 3기간(2016.1.1~): 1.0
  static const Map<String, double> periodCoefficients = {
    'period1': 1.0, // ~2009.12.31
    'period2': 0.95, // 2010.1.1~2015.12.31
    'period3': 1.0, // 2016.1.1~
  };

  /// 퇴직수당 계수
  ///
  /// 퇴직수당 = 1기간 퇴직급여 + (2~3기간 퇴직급여 × 0.6)
  static const double retirementAllowanceCoefficient = 0.6;

  /// 일시금 계산 기여율
  ///
  /// 일시금 = 평균 기준소득월액 × 재직월수 × 기여율
  static const double lumpSumContributionRate = 0.09;

  /// 퇴직급여 산정 기준일
  static const period1EndDate = '2009-12-31';
  static const period2StartDate = '2010-01-01';
  static const period2EndDate = '2015-12-31';
  static const period3StartDate = '2016-01-01';

  /// 최소 재직 기간 (일시금 수급 자격)
  static const int minimumServiceYearsForLumpSum = 1;

  /// 최소 재직 기간 (연금 수급 자격)
  static const int minimumServiceYearsForPension = 10;

  /// 최대 재직 기간 (연금 계산)
  static const int maximumServiceYearsForPension = 36; // 2016년 이후
  static const int maximumServiceYearsForPensionBefore2016 = 33; // 2016년 이전
}
