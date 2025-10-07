import 'package:equatable/equatable.dart';

/// 월별 실수령액 정보
class MonthlyNetIncome extends Equatable {
  const MonthlyNetIncome({
    required this.month,
    required this.baseSalary,
    required this.totalAllowances,
    required this.longevityBonus,
    required this.holidayBonus,
    required this.grossSalary,
    required this.incomeTax,
    required this.localTax,
    required this.nationalPension,
    required this.healthInsurance,
    required this.longTermCareInsurance,
    required this.employmentInsurance,
    required this.totalDeductions,
    required this.netIncome,
  });

  /// 월 (1~12)
  final int month;

  /// 기본급
  final int baseSalary;

  /// 각종 수당 합계
  final int totalAllowances;

  /// 정근수당 (1월/7월만)
  final int longevityBonus;

  /// 명절상여금 (2월 설날, 9월 추석)
  final int holidayBonus;

  /// 총 지급액 (세전)
  final int grossSalary;

  /// 소득세
  final int incomeTax;

  /// 주민세
  final int localTax;

  /// 국민연금
  final int nationalPension;

  /// 건강보험
  final int healthInsurance;

  /// 장기요양보험
  final int longTermCareInsurance;

  /// 고용보험
  final int employmentInsurance;

  /// 총 공제액
  final int totalDeductions;

  /// 실수령액 (세후)
  final int netIncome;

  /// 정근수당 지급 여부
  bool get hasLongevityBonus => longevityBonus > 0;

  /// 명절상여금 지급 여부
  bool get hasHolidayBonus => holidayBonus > 0;

  /// 공제율 (%)
  double get deductionRate {
    if (grossSalary == 0) return 0.0;
    return (totalDeductions / grossSalary) * 100;
  }

  @override
  List<Object?> get props => [
    month,
    baseSalary,
    totalAllowances,
    longevityBonus,
    holidayBonus,
    grossSalary,
    incomeTax,
    localTax,
    nationalPension,
    healthInsurance,
    longTermCareInsurance,
    employmentInsurance,
    totalDeductions,
    netIncome,
  ];

  MonthlyNetIncome copyWith({
    int? month,
    int? baseSalary,
    int? totalAllowances,
    int? longevityBonus,
    int? holidayBonus,
    int? grossSalary,
    int? incomeTax,
    int? localTax,
    int? nationalPension,
    int? healthInsurance,
    int? longTermCareInsurance,
    int? employmentInsurance,
    int? totalDeductions,
    int? netIncome,
  }) {
    return MonthlyNetIncome(
      month: month ?? this.month,
      baseSalary: baseSalary ?? this.baseSalary,
      totalAllowances: totalAllowances ?? this.totalAllowances,
      longevityBonus: longevityBonus ?? this.longevityBonus,
      holidayBonus: holidayBonus ?? this.holidayBonus,
      grossSalary: grossSalary ?? this.grossSalary,
      incomeTax: incomeTax ?? this.incomeTax,
      localTax: localTax ?? this.localTax,
      nationalPension: nationalPension ?? this.nationalPension,
      healthInsurance: healthInsurance ?? this.healthInsurance,
      longTermCareInsurance:
          longTermCareInsurance ?? this.longTermCareInsurance,
      employmentInsurance: employmentInsurance ?? this.employmentInsurance,
      totalDeductions: totalDeductions ?? this.totalDeductions,
      netIncome: netIncome ?? this.netIncome,
    );
  }
}
