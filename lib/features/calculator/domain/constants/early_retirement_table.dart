/// 명예퇴직금 계산 상수 테이블
///
/// 출처: 국가공무원 명예퇴직수당 등 지급 규정 (2025년 기준)
class EarlyRetirementTable {
  /// 명예퇴직 자격 요건
  ///
  /// 최소 재직 년수: 20년
  static const int minimumServiceYears = 20;

  /// 월봉급액 산정 비율
  ///
  /// 명예퇴직수당 산정 기준 = 봉급액 × 81%
  static const double salaryCalculationRate = 0.81;

  /// 잔여 년수별 기본 계수
  ///
  /// Key: 잔여 년수 (최소값)
  /// Value: 기본 계수
  static const Map<int, double> baseCoefficients = {
    10: 1.5, // 10년 이상: 1.5
    7: 1.3, // 7~9년: 1.3
    5: 1.1, // 5~6년: 1.1
    3: 0.9, // 3~4년: 0.9
    1: 0.7, // 1~2년: 0.7
    0: 0.5, // 1년 미만: 0.5
  };

  /// 잔여 년수별 가산율
  ///
  /// Key: 잔여 년수 (최소값)
  /// Value: 가산율
  static const Map<int, double> bonusRates = {
    10: 0.4, // 10년 이상: 40%
    7: 0.3, // 7~9년: 30%
    5: 0.2, // 5~6년: 20%
    3: 0.1, // 3~4년: 10%
    0: 0.0, // 3년 미만: 0%
  };

  /// 연령 가산율
  ///
  /// 55세 이상: 추가 10%
  static const int ageThresholdForBonus = 55;
  static const double ageBonusRate = 0.1;

  /// 명예퇴직 희망 가능 최소 연령
  static const int minimumEarlyRetirementAge = 50;

  /// 정년 연장 년수 (2025년 기준)
  ///
  /// - 2024년까지: 60세
  /// - 2025~2026년: 61세 (1년 연장)
  /// - 2027년 이후: 62세 (2년 연장)
  static const int retirementAgeExtension2025 = 61;
  static const int retirementAgeExtension2027 = 62;

  /// 명예퇴직금 지급 비율 (예산 범위 내)
  ///
  /// 일반적으로 100%~120% 범위 (기관별 상이)
  static const double paymentRateMin = 1.0;
  static const double paymentRateMax = 1.2;

  /// 기본 계수 조회
  ///
  /// [remainingYears] 잔여 년수
  ///
  /// Returns: 기본 계수
  static double getBaseCoefficient(int remainingYears) {
    if (remainingYears >= 10) return baseCoefficients[10]!;
    if (remainingYears >= 7) return baseCoefficients[7]!;
    if (remainingYears >= 5) return baseCoefficients[5]!;
    if (remainingYears >= 3) return baseCoefficients[3]!;
    if (remainingYears >= 1) return baseCoefficients[1]!;
    return baseCoefficients[0]!;
  }

  /// 가산율 조회
  ///
  /// [remainingYears] 잔여 년수
  /// [age] 연령
  ///
  /// Returns: 총 가산율
  static double getBonusRate(int remainingYears, int age) {
    double rate = 0.0;

    // 잔여 년수별 가산율
    if (remainingYears >= 10) {
      rate = bonusRates[10]!;
    } else if (remainingYears >= 7) {
      rate = bonusRates[7]!;
    } else if (remainingYears >= 5) {
      rate = bonusRates[5]!;
    } else if (remainingYears >= 3) {
      rate = bonusRates[3]!;
    }

    // 연령 가산율 (55세 이상 +10%)
    if (age >= ageThresholdForBonus) {
      rate += ageBonusRate;
    }

    return rate;
  }
}
