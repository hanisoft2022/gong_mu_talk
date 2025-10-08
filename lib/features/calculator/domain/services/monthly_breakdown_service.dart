import 'package:gong_mu_talk/features/calculator/domain/entities/monthly_net_income.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/teacher_profile.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/performance_grade.dart';
import 'package:gong_mu_talk/features/calculator/domain/constants/salary_table.dart';
import 'package:gong_mu_talk/features/calculator/domain/services/tax_calculation_service.dart';
import 'package:gong_mu_talk/features/calculator/domain/services/salary_calculation_service.dart';

/// 월별 실수령액 계산 서비스
class MonthlyBreakdownService {
  final TaxCalculationService _taxService;
  final SalaryCalculationService _salaryService;

  MonthlyBreakdownService(this._taxService, this._salaryService);

  /// 12개월 실수령액 계산
  ///
  /// [profile] 교사 프로필
  /// [year] 계산 년도
  /// [hasSpouse] 배우자 유무
  /// [numberOfChildren] 자녀 수
  /// [isHomeroom] 담임 여부
  /// [hasPosition] 보직 여부
  /// [performanceGrade] 성과상여금 등급 (기본값: A등급)
  ///
  /// Returns: 12개월 실수령액 목록
  List<MonthlyNetIncome> calculateMonthlyBreakdown({
    required TeacherProfile profile,
    required int year,
    required bool hasSpouse,
    required int numberOfChildren,
    bool isHomeroom = false,
    bool hasPosition = false,
    PerformanceGrade performanceGrade = PerformanceGrade.A,
  }) {
    final monthlyIncomes = <MonthlyNetIncome>[];

    // 재직 년수 계산
    final serviceYears = year - profile.employmentStartDate.year;

    // 기본급
    final baseSalary = SalaryTable.getBasePay(profile.currentGrade);

    // 교직수당 (모든 교사)
    const teachingAllowance = AllowanceTable.teachingAllowance;

    // 담임수당
    final homeroomAllowance = isHomeroom ? AllowanceTable.homeroomAllowance : 0;

    // 보직교사수당
    final positionAllowance = hasPosition
        ? AllowanceTable.headTeacherAllowance
        : 0;

    // 그 외 교직수당 가산금
    final teachingAllowanceBonuses = _salaryService.calculateTeachingAllowanceBonuses(
      bonuses: profile.teachingAllowanceBonuses,
      currentGrade: profile.currentGrade,
      position: profile.position,
    );

    // 원로교사수당 (30년 이상 + 55세 이상)
    final veteranAllowance = _calculateVeteranAllowance(
      serviceYears: serviceYears,
      birthYear: profile.birthYear,
      currentYear: year,
    );

    // 가족수당
    final familyAllowance = _calculateFamilyAllowance(
      hasSpouse: hasSpouse,
      numberOfChildren: numberOfChildren,
      numberOfParents: profile.numberOfParents,
    );

    // 연구비
    final researchAllowance = _calculateResearchAllowance(serviceYears);

    // 시간외근무수당 정액분
    final overtimeAllowance = AllowanceTable.getOvertimeAllowance(
      profile.currentGrade,
    );

    // 정근수당 가산금 (매월)
    final longevityMonthly = _calculateLongevityMonthlyAllowance(serviceYears);

    // 월별 계산
    for (int month = 1; month <= 12; month++) {
      // 각종 수당 합계
      final totalAllowances =
          teachingAllowance +
          homeroomAllowance +
          positionAllowance +
          teachingAllowanceBonuses +
          veteranAllowance +
          familyAllowance +
          researchAllowance +
          overtimeAllowance +
          longevityMonthly;

      // 정근수당 (1월/7월만)
      final longevityBonus = _calculateLongevityBonus(
        serviceYears: serviceYears,
        monthlySalary: baseSalary + totalAllowances,
        month: month,
      );

      // 명절상여금 (설날/추석, 음력 기준)
      final holidayBonus = _calculateHolidayBonus(
        baseSalary: baseSalary,
        month: month,
        year: year,
      );

      // 성과상여금 (3월만)
      final performanceBonus = _calculatePerformanceBonus(
        grade: performanceGrade,
        month: month,
      );

      // 총 지급액 (세전)
      final grossSalary =
          baseSalary + totalAllowances + longevityBonus + holidayBonus + performanceBonus;

      // 소득세
      final incomeTax = _taxService.calculateIncomeTax(grossSalary);

      // 주민세
      final localTax = _taxService.calculateLocalIncomeTax(incomeTax);

      // 국민연금 (일반 근로자용, 공무원은 미사용)
      final nationalPension = 0; // 공무원은 공무원연금 적용

      // 공무원연금 기여금 계산 (9%)
      // 기준소득월액 = 본봉 + 정기수당 + 정근수당 + 명절휴가비
      // 제외: 시간외근무수당, 성과상여금
      final pensionBaseIncome =
          baseSalary +
          teachingAllowance +
          homeroomAllowance +
          positionAllowance +
          veteranAllowance +
          familyAllowance +
          researchAllowance +
          longevityMonthly +
          longevityBonus +
          holidayBonus;

      final pensionContribution = (pensionBaseIncome * 0.09).round();

      // 건강보험 (2025년 요율: 7.09%)
      final healthInsurance = (grossSalary * 0.03545).round(); // 본인부담 3.545%

      // 장기요양보험 (건강보험료의 12.95%, 2025년 요율)
      final longTermCareInsurance = (healthInsurance * 0.1295).round();

      // 고용보험 (공무원 제외)
      final employmentInsurance = 0; // 공무원은 고용보험 적용 제외

      // 총 공제액
      final totalDeductions =
          incomeTax +
          localTax +
          pensionContribution +
          healthInsurance +
          longTermCareInsurance +
          employmentInsurance;

      // 실수령액
      final netIncome = grossSalary - totalDeductions;

      monthlyIncomes.add(
        MonthlyNetIncome(
          month: month,
          baseSalary: baseSalary,
          totalAllowances: totalAllowances,
          teachingAllowance: teachingAllowance,
          homeroomAllowance: homeroomAllowance,
          positionAllowance: positionAllowance,
          teachingAllowanceBonuses: teachingAllowanceBonuses,
          longevityMonthly: longevityMonthly,
          veteranAllowance: veteranAllowance,
          familyAllowance: familyAllowance,
          researchAllowance: researchAllowance,
          overtimeAllowance: overtimeAllowance,
          performanceBonus: performanceBonus,
          longevityBonus: longevityBonus,
          holidayBonus: holidayBonus,
          grossSalary: grossSalary,
          incomeTax: incomeTax,
          localTax: localTax,
          nationalPension: nationalPension,
          pensionContribution: pensionContribution,
          healthInsurance: healthInsurance,
          longTermCareInsurance: longTermCareInsurance,
          employmentInsurance: employmentInsurance,
          totalDeductions: totalDeductions,
          netIncome: netIncome,
        ),
      );
    }

    return monthlyIncomes;
  }

  /// 정근수당 계산 (1월/7월만)
  ///
  /// [serviceYears] 재직 년수
  /// [monthlySalary] 월급
  /// [month] 월
  ///
  /// Returns: 정근수당
  int _calculateLongevityBonus({
    required int serviceYears,
    required int monthlySalary,
    required int month,
  }) {
    // 1월/7월만 지급
    if (month != 1 && month != 7) return 0;

    // 재직 년수별 지급률 (공무원 수당 등에 관한 규정)
    double rate;
    if (serviceYears < 2) {
      rate = 0.10; // 2년 미만: 10%
    } else if (serviceYears < 5) {
      rate = 0.20; // 2~5년: 20%
    } else if (serviceYears < 6) {
      rate = 0.25; // 5~6년: 25%
    } else if (serviceYears < 7) {
      rate = 0.30; // 6~7년: 30%
    } else if (serviceYears < 8) {
      rate = 0.35; // 7~8년: 35%
    } else if (serviceYears < 9) {
      rate = 0.40; // 8~9년: 40%
    } else if (serviceYears < 10) {
      rate = 0.45; // 9~10년: 45%
    } else {
      rate = 0.50; // 10년 이상: 50%
    }

    return (monthlySalary * rate).round();
  }

  /// 정근수당 가산금 계산 (매월)
  ///
  /// [serviceYears] 재직 년수
  ///
  /// Returns: 정근수당 가산금
  int _calculateLongevityMonthlyAllowance(int serviceYears) {
    if (serviceYears < 5) return 30000; // 5년 미만: 3만원
    if (serviceYears < 10) return 50000; // 5년 이상 10년 미만: 5만원
    if (serviceYears < 15) return 60000; // 10년 이상 15년 미만: 6만원
    if (serviceYears < 20) return 80000; // 15년 이상 20년 미만: 8만원
    if (serviceYears < 25) return 110000; // 20년 이상 25년 미만: 11만원 (10만원 + 가산금 1만원)
    return 130000; // 25년 이상: 13만원 (10만원 + 가산금 3만원)
  }

  /// 원로교사수당 계산
  ///
  /// [serviceYears] 재직 년수
  /// [birthYear] 출생 년도
  /// [currentYear] 현재 년도
  ///
  /// Returns: 원로교사수당
  int _calculateVeteranAllowance({
    required int serviceYears,
    required int birthYear,
    required int currentYear,
  }) {
    final age = currentYear - birthYear;

    // 30년 이상 재직 + 55세 이상
    if (serviceYears >= 30 && age >= 55) {
      return AllowanceTable.veteranAllowance;
    }

    return 0;
  }

  /// 가족수당 계산
  ///
  /// [hasSpouse] 배우자 유무
  /// [numberOfChildren] 자녀 수
  /// [numberOfParents] 60세 이상 직계존속 수
  ///
  /// Returns: 가족수당
  int _calculateFamilyAllowance({
    required bool hasSpouse,
    required int numberOfChildren,
    required int numberOfParents,
  }) {
    int total = 0;

    // 배우자: 4만원
    if (hasSpouse) total += 40000;

    // 첫째: 5만원
    if (numberOfChildren >= 1) total += 50000;

    // 둘째: 8만원
    if (numberOfChildren >= 2) total += 80000;

    // 셋째 이상: 각 12만원
    if (numberOfChildren >= 3) {
      total += (numberOfChildren - 2) * 120000;
    }

    // 60세 이상 직계존속: 1인당 2만원 (최대 4명)
    final parentsCount = numberOfParents > 4 ? 4 : numberOfParents;
    total += parentsCount * 20000;

    return total;
  }

  /// 연구비 계산
  ///
  /// [serviceYears] 재직 년수
  ///
  /// Returns: 연구비
  int _calculateResearchAllowance(int serviceYears) {
    return serviceYears < 5 ? 70000 : 60000;
  }

  /// 명절상여금 계산 (설날/추석, 음력 기준)
  ///
  /// [baseSalary] 본봉
  /// [month] 월
  /// [year] 년도
  ///
  /// Returns: 명절상여금 (설날/추석 월에 본봉의 60%)
  int _calculateHolidayBonus({
    required int baseSalary,
    required int month,
    required int year,
  }) {
    // 2025-2030년 설날/추석 양력 날짜 매핑 (음력 기준)
    final lunarHolidays = {
      2025: [1, 10], // 설날 1월 29일, 추석 10월 6일
      2026: [2, 9], // 설날 2월 17일, 추석 9월 25일
      2027: [2, 9], // 설날 2월 6일, 추석 9월 15일
      2028: [1, 9], // 설날 1월 26일, 추석 10월 3일
      2029: [2, 9], // 설날 2월 13일, 추석 9월 23일
      2030: [2, 9], // 설날 2월 3일, 추석 9월 12일
    };

    final months = lunarHolidays[year];
    if (months != null && months.contains(month)) {
      return (baseSalary * 0.6).round();
    }

    return 0;
  }

  /// 성과상여금 계산 (교육공무원 기준)
  ///
  /// [grade] 성과등급 (S/A/B)
  /// [month] 현재 월
  ///
  /// Returns: 성과상여금 (3월만 지급, 그 외 0)
  int _calculatePerformanceBonus({
    required PerformanceGrade grade,
    required int month,
  }) {
    // 3월만 지급
    if (month != 3) return 0;

    // 2025년 교육공무원 성과상여금 (차등지급률 50% 기준)
    return grade.amount;
  }

  /// 연간 총 실수령액 계산
  ///
  /// [monthlyIncomes] 월별 실수령액 목록
  ///
  /// Returns: 연간 총 실수령액
  int calculateAnnualNetIncome(List<MonthlyNetIncome> monthlyIncomes) {
    return monthlyIncomes.fold<int>(0, (sum, income) => sum + income.netIncome);
  }

  /// 연간 총 공제액 계산
  ///
  /// [monthlyIncomes] 월별 실수령액 목록
  ///
  /// Returns: 연간 총 공제액
  int calculateAnnualDeductions(List<MonthlyNetIncome> monthlyIncomes) {
    return monthlyIncomes.fold<int>(
      0,
      (sum, income) => sum + income.totalDeductions,
    );
  }
}
