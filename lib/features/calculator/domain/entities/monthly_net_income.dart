import 'package:equatable/equatable.dart';

/// 월별 실수령액 정보
class MonthlyNetIncome extends Equatable {
  const MonthlyNetIncome({
    required this.month,
    required this.baseSalary,
    required this.totalAllowances,
    this.teachingAllowance = 0,
    this.homeroomAllowance = 0,
    this.positionAllowance = 0,
    this.longevityMonthly = 0,
    this.veteranAllowance = 0,
    this.familyAllowance = 0,
    this.researchAllowance = 0,
    this.overtimeAllowance = 0,
    this.specialEducationAllowance = 0,
    this.vocationalEducationAllowance = 0,
    this.healthTeacherAllowance = 0,
    this.concurrentPositionAllowance = 0,
    this.nutritionTeacherAllowance = 0,
    this.librarianAllowance = 0,
    this.counselorAllowance = 0,
    required this.performanceBonus,
    required this.longevityBonus,
    required this.holidayBonus,
    required this.grossSalary,
    required this.incomeTax,
    required this.localTax,
    required this.nationalPension,
    required this.pensionContribution,
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

  /// 교직수당 (25만원, 모든 교사)
  final int teachingAllowance;

  /// 담임 수당 (가산금 4)
  final int homeroomAllowance;

  /// 보직교사 수당 (가산금 3)
  final int positionAllowance;

  /// 정근수당 가산금 (매월)
  final int longevityMonthly;

  /// 원로교사수당 (30년 이상 + 55세 이상)
  final int veteranAllowance;

  /// 가족수당
  final int familyAllowance;

  /// 연구비
  final int researchAllowance;

  /// 시간외근무수당
  final int overtimeAllowance;

  /// 특수교사 가산금
  final int specialEducationAllowance;

  /// 특성화교사 가산금
  final int vocationalEducationAllowance;

  /// 보건교사 가산금
  final int healthTeacherAllowance;

  /// 겸직수당
  final int concurrentPositionAllowance;

  /// 영양교사 가산금
  final int nutritionTeacherAllowance;

  /// 사서교사 가산금
  final int librarianAllowance;

  /// 전문상담교사 가산금
  final int counselorAllowance;

  /// 성과상여금 (3월만)
  final int performanceBonus;

  /// 정근수당 (1월/7월만)
  final int longevityBonus;

  /// 명절상여금 (설날/추석, 음력 기준)
  final int holidayBonus;

  /// 총 지급액 (세전)
  final int grossSalary;

  /// 소득세
  final int incomeTax;

  /// 주민세
  final int localTax;

  /// 국민연금 (일반 근로자용, 공무원은 미사용)
  final int nationalPension;

  /// 공무원연금 기여금 (9%)
  final int pensionContribution;

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

  /// 성과상여금 지급 여부
  bool get hasPerformanceBonus => performanceBonus > 0;

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
    teachingAllowance,
    homeroomAllowance,
    positionAllowance,
    longevityMonthly,
    veteranAllowance,
    familyAllowance,
    researchAllowance,
    overtimeAllowance,
    specialEducationAllowance,
    vocationalEducationAllowance,
    healthTeacherAllowance,
    concurrentPositionAllowance,
    nutritionTeacherAllowance,
    librarianAllowance,
    counselorAllowance,
    performanceBonus,
    longevityBonus,
    holidayBonus,
    grossSalary,
    incomeTax,
    localTax,
    nationalPension,
    pensionContribution,
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
    int? teachingAllowance,
    int? homeroomAllowance,
    int? positionAllowance,
    int? longevityMonthly,
    int? veteranAllowance,
    int? familyAllowance,
    int? researchAllowance,
    int? overtimeAllowance,
    int? specialEducationAllowance,
    int? vocationalEducationAllowance,
    int? healthTeacherAllowance,
    int? concurrentPositionAllowance,
    int? nutritionTeacherAllowance,
    int? librarianAllowance,
    int? counselorAllowance,
    int? performanceBonus,
    int? longevityBonus,
    int? holidayBonus,
    int? grossSalary,
    int? incomeTax,
    int? localTax,
    int? nationalPension,
    int? pensionContribution,
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
      teachingAllowance: teachingAllowance ?? this.teachingAllowance,
      homeroomAllowance: homeroomAllowance ?? this.homeroomAllowance,
      positionAllowance: positionAllowance ?? this.positionAllowance,
      longevityMonthly: longevityMonthly ?? this.longevityMonthly,
      veteranAllowance: veteranAllowance ?? this.veteranAllowance,
      familyAllowance: familyAllowance ?? this.familyAllowance,
      researchAllowance: researchAllowance ?? this.researchAllowance,
      overtimeAllowance: overtimeAllowance ?? this.overtimeAllowance,
      specialEducationAllowance: specialEducationAllowance ?? this.specialEducationAllowance,
      vocationalEducationAllowance: vocationalEducationAllowance ?? this.vocationalEducationAllowance,
      healthTeacherAllowance: healthTeacherAllowance ?? this.healthTeacherAllowance,
      concurrentPositionAllowance: concurrentPositionAllowance ?? this.concurrentPositionAllowance,
      nutritionTeacherAllowance: nutritionTeacherAllowance ?? this.nutritionTeacherAllowance,
      librarianAllowance: librarianAllowance ?? this.librarianAllowance,
      counselorAllowance: counselorAllowance ?? this.counselorAllowance,
      performanceBonus: performanceBonus ?? this.performanceBonus,
      longevityBonus: longevityBonus ?? this.longevityBonus,
      holidayBonus: holidayBonus ?? this.holidayBonus,
      grossSalary: grossSalary ?? this.grossSalary,
      incomeTax: incomeTax ?? this.incomeTax,
      localTax: localTax ?? this.localTax,
      nationalPension: nationalPension ?? this.nationalPension,
      pensionContribution: pensionContribution ?? this.pensionContribution,
      healthInsurance: healthInsurance ?? this.healthInsurance,
      longTermCareInsurance:
          longTermCareInsurance ?? this.longTermCareInsurance,
      employmentInsurance: employmentInsurance ?? this.employmentInsurance,
      totalDeductions: totalDeductions ?? this.totalDeductions,
      netIncome: netIncome ?? this.netIncome,
    );
  }
}
