import 'package:equatable/equatable.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/lifetime_salary.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/pension_estimate.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/teacher_profile.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/retirement_benefit.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/early_retirement_bonus.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/after_tax_pension.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/monthly_net_income.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/base_income_estimate.dart';

class CalculatorState extends Equatable {
  const CalculatorState({
    this.profile,
    this.lifetimeSalary,
    this.pensionEstimate,
    this.retirementBenefit,
    this.earlyRetirementBonus,
    this.afterTaxPension,
    this.monthlyBreakdown,
    this.baseIncomeEstimate,
    this.isLoading = false,
    this.errorMessage,
    this.isDataEntered = false,
  });

  /// 교사 프로필 (입력 정보)
  final TeacherProfile? profile;

  /// 생애 급여 계산 결과
  final LifetimeSalary? lifetimeSalary;

  /// 연금 예상액
  final PensionEstimate? pensionEstimate;

  /// 퇴직급여
  final RetirementBenefit? retirementBenefit;

  /// 명예퇴직금
  final EarlyRetirementBonus? earlyRetirementBonus;

  /// 세후 연금
  final AfterTaxPension? afterTaxPension;

  /// 월별 실수령액 (12개월)
  final List<MonthlyNetIncome>? monthlyBreakdown;

  /// 기준소득월액 추정
  final BaseIncomeEstimate? baseIncomeEstimate;

  /// 로딩 상태
  final bool isLoading;

  /// 에러 메시지
  final String? errorMessage;

  /// 데이터 입력 완료 여부
  final bool isDataEntered;

  /// 계산 가능 여부
  bool get canCalculate => profile != null;

  @override
  List<Object?> get props => [
    profile,
    lifetimeSalary,
    pensionEstimate,
    retirementBenefit,
    earlyRetirementBonus,
    afterTaxPension,
    monthlyBreakdown,
    baseIncomeEstimate,
    isLoading,
    errorMessage,
    isDataEntered,
  ];

  CalculatorState copyWith({
    TeacherProfile? profile,
    LifetimeSalary? lifetimeSalary,
    PensionEstimate? pensionEstimate,
    RetirementBenefit? retirementBenefit,
    EarlyRetirementBonus? earlyRetirementBonus,
    AfterTaxPension? afterTaxPension,
    List<MonthlyNetIncome>? monthlyBreakdown,
    BaseIncomeEstimate? baseIncomeEstimate,
    bool? isLoading,
    String? errorMessage,
    bool? isDataEntered,
  }) {
    return CalculatorState(
      profile: profile ?? this.profile,
      lifetimeSalary: lifetimeSalary ?? this.lifetimeSalary,
      pensionEstimate: pensionEstimate ?? this.pensionEstimate,
      retirementBenefit: retirementBenefit ?? this.retirementBenefit,
      earlyRetirementBonus: earlyRetirementBonus ?? this.earlyRetirementBonus,
      afterTaxPension: afterTaxPension ?? this.afterTaxPension,
      monthlyBreakdown: monthlyBreakdown ?? this.monthlyBreakdown,
      baseIncomeEstimate: baseIncomeEstimate ?? this.baseIncomeEstimate,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      isDataEntered: isDataEntered ?? this.isDataEntered,
    );
  }
}
