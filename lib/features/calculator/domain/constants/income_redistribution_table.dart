/// 소득재분배 적용비율 테이블
///
/// 2010년 이후 공무원연금 개편으로 도입된 소득재분배 시스템.
/// 저소득 공무원에게 유리하도록 평균 기준소득월액에 따라
/// 50%~300%의 차등 적용비율을 적용.
class IncomeRedistributionTable {
  /// 평균 기준소득월액에 따른 소득재분배 적용비율 계산
  ///
  /// [avgMonthlyIncome] 평균 기준소득월액
  /// 
  /// Returns: 소득재분배 적용비율 (0.5 ~ 3.0)
  /// 
  /// 예시:
  /// - 270만원 이하: 300% (3.0)
  /// - 420만원: 200% (2.0)
  /// - 570만원: 100% (1.0)
  /// - 690만원 초과: 50% (0.5)
  static double getRedistributionRate(double avgMonthlyIncome) {
    if (avgMonthlyIncome <= 2700000) return 3.0; // 300%
    if (avgMonthlyIncome <= 3000000) return 2.8;
    if (avgMonthlyIncome <= 3300000) return 2.6;
    if (avgMonthlyIncome <= 3600000) return 2.4;
    if (avgMonthlyIncome <= 3900000) return 2.2;
    if (avgMonthlyIncome <= 4200000) return 2.0; // 200%
    if (avgMonthlyIncome <= 4500000) return 1.8;
    if (avgMonthlyIncome <= 4800000) return 1.6;
    if (avgMonthlyIncome <= 5100000) return 1.4;
    if (avgMonthlyIncome <= 5400000) return 1.2;
    if (avgMonthlyIncome <= 5700000) return 1.0; // 100%
    if (avgMonthlyIncome <= 6000000) return 0.9;
    if (avgMonthlyIncome <= 6300000) return 0.8;
    if (avgMonthlyIncome <= 6600000) return 0.7;
    if (avgMonthlyIncome <= 6900000) return 0.6;
    return 0.5; // 50% (690만원 초과)
  }

  /// 소득 구간별 적용비율 맵 (참고용)
  static const Map<int, double> ratesByIncome = {
    2700000: 3.0,
    3000000: 2.8,
    3300000: 2.6,
    3600000: 2.4,
    3900000: 2.2,
    4200000: 2.0,
    4500000: 1.8,
    4800000: 1.6,
    5100000: 1.4,
    5400000: 1.2,
    5700000: 1.0,
    6000000: 0.9,
    6300000: 0.8,
    6600000: 0.7,
    6900000: 0.6,
    // 690만원 초과: 0.5
  };
}
