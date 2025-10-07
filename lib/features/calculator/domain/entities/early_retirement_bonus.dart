import 'package:equatable/equatable.dart';

/// 명예퇴직금 정보
class EarlyRetirementBonus extends Equatable {
  const EarlyRetirementBonus({
    required this.baseAmount,
    required this.bonusAmount,
    required this.totalAmount,
    required this.remainingYears,
    required this.remainingMonths,
    required this.retirementAge,
    required this.baseSalary,
    required this.currentGrade,
  });

  /// 기본 명퇴금
  final int baseAmount;

  /// 가산금
  final int bonusAmount;

  /// 총액 (기본 명퇴금 + 가산금)
  final int totalAmount;

  /// 잔여 년수
  final int remainingYears;

  /// 잔여 개월수
  final int remainingMonths;

  /// 명퇴 시점 연령
  final int retirementAge;

  /// 기본급 (명퇴금 계산 기준)
  final int baseSalary;

  /// 현재 호봉
  final int currentGrade;

  /// 잔여 기간 (년수 + 개월수)
  double get totalRemainingYears => remainingYears + (remainingMonths / 12);

  @override
  List<Object?> get props => [
    baseAmount,
    bonusAmount,
    totalAmount,
    remainingYears,
    remainingMonths,
    retirementAge,
    baseSalary,
    currentGrade,
  ];

  EarlyRetirementBonus copyWith({
    int? baseAmount,
    int? bonusAmount,
    int? totalAmount,
    int? remainingYears,
    int? remainingMonths,
    int? retirementAge,
    int? baseSalary,
    int? currentGrade,
  }) {
    return EarlyRetirementBonus(
      baseAmount: baseAmount ?? this.baseAmount,
      bonusAmount: bonusAmount ?? this.bonusAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      remainingYears: remainingYears ?? this.remainingYears,
      remainingMonths: remainingMonths ?? this.remainingMonths,
      retirementAge: retirementAge ?? this.retirementAge,
      baseSalary: baseSalary ?? this.baseSalary,
      currentGrade: currentGrade ?? this.currentGrade,
    );
  }
}
