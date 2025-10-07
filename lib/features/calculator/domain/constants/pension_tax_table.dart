/// 연금 소득세 계산 상수 테이블
///
/// 출처: 국세청, 소득세법 (2025년 기준)
class PensionTaxTable {
  /// 연금소득 공제액 (나이별)
  ///
  /// Key: 최소 나이
  /// Value: 연간 공제액
  static const Map<int, int> pensionDeductions = {
    80: 10000000, // 80세 이상: 1,000만원
    70: 7000000, // 70~79세: 700만원
    0: 5000000, // 70세 미만: 500만원
  };

  /// 소득세 누진세율표 (2025년 기준)
  ///
  /// [과세표준, 세율, 누진공제액]
  static const List<Map<String, dynamic>> incomeTaxBrackets = [
    {'limit': 14000000, 'rate': 0.06, 'deduction': 0},
    {'limit': 50000000, 'rate': 0.15, 'deduction': 840000},
    {'limit': 88000000, 'rate': 0.24, 'deduction': 6240000},
    {'limit': 150000000, 'rate': 0.35, 'deduction': 15360000},
    {'limit': 300000000, 'rate': 0.38, 'deduction': 37060000},
    {'limit': 500000000, 'rate': 0.40, 'deduction': 94060000},
    {'limit': 1000000000, 'rate': 0.42, 'deduction': 174060000},
    {'limit': double.infinity, 'rate': 0.45, 'deduction': 384060000},
  ];

  /// 주민세율
  ///
  /// 주민세 = 소득세 × 10%
  static const double localTaxRate = 0.1;

  /// 건강보험료율 (연금소득자)
  ///
  /// 2025년 기준: 6.99% (본인부담 50%)
  static const double healthInsuranceRate = 0.0699;
  static const double healthInsuranceSelfPaymentRate = 0.5; // 본인부담 50%

  /// 장기요양보험료율
  ///
  /// 건강보험료의 12.95%
  static const double longTermCareInsuranceRate = 0.1295;

  /// 나이별 연금 공제액 조회
  ///
  /// [age] 나이
  ///
  /// Returns: 연간 공제액
  static int getPensionDeduction(int age) {
    if (age >= 80) return pensionDeductions[80]!;
    if (age >= 70) return pensionDeductions[70]!;
    return pensionDeductions[0]!;
  }

  /// 과세표준에 따른 소득세 계산
  ///
  /// [taxableIncome] 과세표준 (연간)
  ///
  /// Returns: 연간 소득세
  static int calculateIncomeTax(int taxableIncome) {
    if (taxableIncome <= 0) return 0;

    for (final bracket in incomeTaxBrackets) {
      final limit = bracket['limit'] as num;
      if (taxableIncome <= limit) {
        final rate = bracket['rate'] as double;
        final deduction = bracket['deduction'] as int;
        return ((taxableIncome * rate) - deduction).round();
      }
    }

    return 0;
  }

  /// 연금소득 세금 총액 계산
  ///
  /// [monthlyPension] 월 연금액
  /// [age] 나이
  ///
  /// Returns: {incomeTax, localTax, healthInsurance, longTermCareInsurance, total}
  static Map<String, int> calculateTotalTax({
    required int monthlyPension,
    required int age,
  }) {
    // 1. 연간 연금액 (12개월)
    final annualPension = monthlyPension * 12;

    // 2. 공제액
    final deduction = getPensionDeduction(age);

    // 3. 과세표준
    final taxableIncome = (annualPension - deduction)
        .clamp(0, double.infinity)
        .toInt();

    // 4. 소득세 (연간)
    final annualIncomeTax = calculateIncomeTax(taxableIncome);

    // 5. 주민세 (소득세의 10%)
    final annualLocalTax = (annualIncomeTax * localTaxRate).round();

    // 6. 건강보험료 (월 연금액의 6.99% × 본인부담 50%)
    final monthlyHealthInsurance =
        (monthlyPension * healthInsuranceRate * healthInsuranceSelfPaymentRate)
            .round();

    // 7. 장기요양보험료 (건강보험료의 12.95%)
    final monthlyLongTermCareInsurance =
        (monthlyHealthInsurance * longTermCareInsuranceRate).round();

    // 8. 월별 세금 (소득세, 주민세는 연간 금액을 12로 나눔)
    final monthlyIncomeTax = (annualIncomeTax / 12).round();
    final monthlyLocalTax = (annualLocalTax / 12).round();

    // 9. 월 총 공제액
    final monthlyTotal =
        monthlyIncomeTax +
        monthlyLocalTax +
        monthlyHealthInsurance +
        monthlyLongTermCareInsurance;

    return {
      'incomeTax': monthlyIncomeTax,
      'localTax': monthlyLocalTax,
      'healthInsurance': monthlyHealthInsurance,
      'longTermCareInsurance': monthlyLongTermCareInsurance,
      'total': monthlyTotal,
    };
  }
}
