import 'package:equatable/equatable.dart';

/// 연도별 급여 정보
class AnnualSalary extends Equatable {
  const AnnualSalary({
    required this.year,
    required this.grade,
    required this.basePay,
    this.positionAllowance = 0,
    this.homeroomAllowance = 0,
    this.familyAllowance = 0,
    this.otherAllowances = 0,
    this.incomeTax = 0,
    this.insurance = 0,
    required this.netPay,
    required this.annualTotalPay,
  });

  /// 연도
  final int year;

  /// 호봉
  final int grade;

  /// 본봉 (월)
  final int basePay;

  /// 직책수당
  final int positionAllowance;

  /// 담임수당
  final int homeroomAllowance;

  /// 가족수당
  final int familyAllowance;

  /// 기타수당 합계
  final int otherAllowances;

  /// 소득세
  final int incomeTax;

  /// 4대보험 합계
  final int insurance;

  /// 실수령액 (월)
  final int netPay;

  /// 연간 총 급여 (실수령액 * 12 + 보너스 등)
  final int annualTotalPay;

  /// 총 수당
  int get totalAllowances =>
      positionAllowance + homeroomAllowance + familyAllowance + otherAllowances;

  /// 총 공제액
  int get totalDeductions => incomeTax + insurance;

  /// 세전 급여
  int get grossPay => basePay + totalAllowances;

  @override
  List<Object?> get props => [
    year,
    grade,
    basePay,
    positionAllowance,
    homeroomAllowance,
    familyAllowance,
    otherAllowances,
    incomeTax,
    insurance,
    netPay,
    annualTotalPay,
  ];

  AnnualSalary copyWith({
    int? year,
    int? grade,
    int? basePay,
    int? positionAllowance,
    int? homeroomAllowance,
    int? familyAllowance,
    int? otherAllowances,
    int? incomeTax,
    int? insurance,
    int? netPay,
    int? annualTotalPay,
  }) {
    return AnnualSalary(
      year: year ?? this.year,
      grade: grade ?? this.grade,
      basePay: basePay ?? this.basePay,
      positionAllowance: positionAllowance ?? this.positionAllowance,
      homeroomAllowance: homeroomAllowance ?? this.homeroomAllowance,
      familyAllowance: familyAllowance ?? this.familyAllowance,
      otherAllowances: otherAllowances ?? this.otherAllowances,
      incomeTax: incomeTax ?? this.incomeTax,
      insurance: insurance ?? this.insurance,
      netPay: netPay ?? this.netPay,
      annualTotalPay: annualTotalPay ?? this.annualTotalPay,
    );
  }
}
