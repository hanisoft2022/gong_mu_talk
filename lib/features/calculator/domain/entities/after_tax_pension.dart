import 'package:equatable/equatable.dart';

/// 세후 연금 정보
class AfterTaxPension extends Equatable {
  const AfterTaxPension({
    required this.monthlyPensionBeforeTax,
    required this.incomeTax,
    required this.localTax,
    required this.healthInsurance,
    required this.longTermCareInsurance,
    required this.monthlyPensionAfterTax,
    required this.annualPensionAfterTax,
    required this.age,
  });

  /// 월 연금액 (세전)
  final int monthlyPensionBeforeTax;

  /// 소득세
  final int incomeTax;

  /// 주민세 (소득세의 10%)
  final int localTax;

  /// 건강보험료
  final int healthInsurance;

  /// 장기요양보험료
  final int longTermCareInsurance;

  /// 월 연금액 (세후)
  final int monthlyPensionAfterTax;

  /// 연간 연금액 (세후, 13개월 기준)
  final int annualPensionAfterTax;

  /// 수령 시점 연령
  final int age;

  /// 총 공제액
  int get totalDeductions =>
      incomeTax + localTax + healthInsurance + longTermCareInsurance;

  /// 공제율 (%)
  double get deductionRate {
    if (monthlyPensionBeforeTax == 0) return 0.0;
    return (totalDeductions / monthlyPensionBeforeTax) * 100;
  }

  /// 실수령률 (%)
  double get netRate {
    if (monthlyPensionBeforeTax == 0) return 0.0;
    return (monthlyPensionAfterTax / monthlyPensionBeforeTax) * 100;
  }

  @override
  List<Object?> get props => [
        monthlyPensionBeforeTax,
        incomeTax,
        localTax,
        healthInsurance,
        longTermCareInsurance,
        monthlyPensionAfterTax,
        annualPensionAfterTax,
        age,
      ];

  AfterTaxPension copyWith({
    int? monthlyPensionBeforeTax,
    int? incomeTax,
    int? localTax,
    int? healthInsurance,
    int? longTermCareInsurance,
    int? monthlyPensionAfterTax,
    int? annualPensionAfterTax,
    int? age,
  }) {
    return AfterTaxPension(
      monthlyPensionBeforeTax:
          monthlyPensionBeforeTax ?? this.monthlyPensionBeforeTax,
      incomeTax: incomeTax ?? this.incomeTax,
      localTax: localTax ?? this.localTax,
      healthInsurance: healthInsurance ?? this.healthInsurance,
      longTermCareInsurance:
          longTermCareInsurance ?? this.longTermCareInsurance,
      monthlyPensionAfterTax:
          monthlyPensionAfterTax ?? this.monthlyPensionAfterTax,
      annualPensionAfterTax:
          annualPensionAfterTax ?? this.annualPensionAfterTax,
      age: age ?? this.age,
    );
  }
}
