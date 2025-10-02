import 'package:equatable/equatable.dart';

class SalaryBreakdown extends Equatable {
  const SalaryBreakdown({
    required this.monthlyTotal,
    required this.dailyRate,
    required this.yearlyTotal,
    required this.allowancesTotal,
    required this.pensionContribution,
    required this.minimumDailyWage,
    required this.minimumWageGap,
    required this.notes,
    this.incomeTax = 0,
    this.localIncomeTax = 0,
    this.healthInsurance = 0,
    this.longTermCare = 0,
    this.totalDeductions = 0,
    this.netPay = 0,
    this.yearlyNet = 0,
  });

  /// 월 총급여
  final double monthlyTotal;
  
  /// 일급
  final double dailyRate;
  
  /// 연 총급여
  final double yearlyTotal;
  
  /// 수당 합계
  final double allowancesTotal;
  
  /// 공무원연금 기여금
  final double pensionContribution;
  
  /// 소득세
  final double incomeTax;
  
  /// 지방소득세
  final double localIncomeTax;
  
  /// 건강보험료
  final double healthInsurance;
  
  /// 장기요양보험료
  final double longTermCare;
  
  /// 총 공제액
  final double totalDeductions;
  
  /// 월 실수령액
  final double netPay;
  
  /// 연 실수령액
  final double yearlyNet;
  
  /// 최저일급
  final double minimumDailyWage;
  
  /// 최저임금 대비 차액
  final double minimumWageGap;
  
  /// 상세 내역
  final List<String> notes;

  factory SalaryBreakdown.empty() => const SalaryBreakdown(
    monthlyTotal: 0,
    dailyRate: 0,
    yearlyTotal: 0,
    allowancesTotal: 0,
    pensionContribution: 0,
    minimumDailyWage: 0,
    minimumWageGap: 0,
    notes: <String>[],
  );

  @override
  List<Object?> get props => [
    monthlyTotal,
    dailyRate,
    yearlyTotal,
    allowancesTotal,
    pensionContribution,
    incomeTax,
    localIncomeTax,
    healthInsurance,
    longTermCare,
    totalDeductions,
    netPay,
    yearlyNet,
    minimumDailyWage,
    minimumWageGap,
    notes,
  ];
}
