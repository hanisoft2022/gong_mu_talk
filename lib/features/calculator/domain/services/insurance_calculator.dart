/// 4대 보험 계산 서비스 (공무원 기준)
library;

import 'package:injectable/injectable.dart';

/// 2025년 기준 보험료율 적용
@lazySingleton
class InsuranceCalculator {
  /// 2025년 공무원연금 기여율
  /// 출처: 공무원연금법 제70조
  static const double pensionRate = 0.09; // 9% (본인 부담)

  /// 2025년 건강보험료율
  /// 출처: 국민건강보험법 시행령
  static const double healthInsuranceRate = 0.03545; // 3.545% (본인 부담 50%)

  /// 2025년 장기요양보험료율
  /// 건강보험료의 12.95%
  static const double longTermCareRate = 0.1295;

  /// 공무원연금 기여금 계산
  /// 
  /// [monthlyPensionBase]: 기준소득월액 (보수월액)
  /// Returns: 월 공무원연금 기여금
  double calculatePensionContribution(double monthlyPensionBase) {
    return monthlyPensionBase * pensionRate;
  }

  /// 건강보험료 계산
  /// 
  /// [monthlyInsuranceBase]: 보수월액
  /// Returns: 월 건강보험료 (본인 부담분)
  double calculateHealthInsurance(double monthlyInsuranceBase) {
    return monthlyInsuranceBase * healthInsuranceRate;
  }

  /// 장기요양보험료 계산
  /// 건강보험료에 비례
  /// 
  /// [healthInsurance]: 건강보험료
  /// Returns: 월 장기요양보험료
  double calculateLongTermCare(double healthInsurance) {
    return healthInsurance * longTermCareRate;
  }

  /// 전체 사회보험료 계산
  /// 
  /// [monthlyGross]: 월 총급여
  /// [pensionBase]: 기준소득월액 (null이면 총급여 사용)
  /// Returns: 보험료 상세 내역
  InsuranceBreakdown calculateTotalInsurance({
    required double monthlyGross,
    double? pensionBase,
  }) {
    final double actualPensionBase = pensionBase ?? monthlyGross;

    final pension = calculatePensionContribution(actualPensionBase);
    final health = calculateHealthInsurance(monthlyGross);
    final longTermCare = calculateLongTermCare(health);

    return InsuranceBreakdown(
      pensionContribution: pension,
      healthInsurance: health,
      longTermCare: longTermCare,
      totalInsurance: pension + health + longTermCare,
    );
  }

  /// 기준소득월액 상하한 적용
  /// 
  /// 공무원연금의 기준소득월액은 상한(9,066,000원)과 
  /// 하한(309,000원)이 있음 (2025년 기준)
  double applyPensionBaseLimit(double monthlyGross) {
    const double upperLimit = 9066000; // 2025년 상한
    const double lowerLimit = 309000;  // 2025년 하한

    if (monthlyGross > upperLimit) return upperLimit;
    if (monthlyGross < lowerLimit) return lowerLimit;
    return monthlyGross;
  }

  /// 건강보험 보수월액 상하한 적용
  /// 
  /// 건강보험 보수월액 상한: 8,715,000원 (2025년)
  double applyHealthInsuranceLimit(double monthlyGross) {
    const double upperLimit = 8715000; // 2025년 상한

    if (monthlyGross > upperLimit) return upperLimit;
    return monthlyGross;
  }
}

/// 보험료 계산 결과
class InsuranceBreakdown {
  const InsuranceBreakdown({
    required this.pensionContribution,
    required this.healthInsurance,
    required this.longTermCare,
    required this.totalInsurance,
  });

  final double pensionContribution; // 공무원연금
  final double healthInsurance;     // 건강보험
  final double longTermCare;        // 장기요양보험
  final double totalInsurance;      // 합계

  @override
  String toString() {
    return 'InsuranceBreakdown('
        'pension: $pensionContribution, '
        'health: $healthInsurance, '
        'longTermCare: $longTermCare, '
        'total: $totalInsurance)';
  }
}

/// 공무원 vs 일반직 보험 구분
enum EmployeeType {
  /// 공무원 (공무원연금 적용)
  publicServant,

  /// 일반직 (국민연금 적용)
  general,
}

/// 일반직 국민연금 계산
class NationalPensionCalculator {
  /// 2025년 국민연금 기여율
  static const double pensionRate = 0.045; // 4.5% (본인 부담)

  /// 국민연금 기여금 계산
  double calculatePensionContribution(double monthlyGross) {
    const double upperLimit = 5900000; // 2025년 상한
    const double lowerLimit = 390000;  // 2025년 하한

    double pensionBase = monthlyGross;
    if (pensionBase > upperLimit) pensionBase = upperLimit;
    if (pensionBase < lowerLimit) pensionBase = lowerLimit;

    return pensionBase * pensionRate;
  }
}
