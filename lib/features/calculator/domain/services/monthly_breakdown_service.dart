import 'package:gong_mu_talk/features/calculator/domain/entities/monthly_net_income.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/calculation_context.dart';
import 'package:gong_mu_talk/features/calculator/domain/constants/salary_table.dart';
import 'package:gong_mu_talk/features/calculator/domain/constants/holiday_payment_table.dart';
import 'package:gong_mu_talk/features/calculator/domain/services/tax_calculation_service.dart';
import 'package:gong_mu_talk/features/calculator/domain/services/salary_calculation_service.dart';
import 'package:gong_mu_talk/features/calculator/domain/calculation_core/service_years_calculator.dart';

/// 월별 실수령액 계산 서비스
class MonthlyBreakdownService {
  final TaxCalculationService _taxService;
  final SalaryCalculationService _salaryService;

  MonthlyBreakdownService(this._taxService, this._salaryService);

  /// 12개월 실수령액 계산
  ///
  /// [context] 계산 컨텍스트 (프로필, 년도, 가족 정보, 담임/보직 여부 등)
  ///
  /// Returns: 12개월 실수령액 목록
  List<MonthlyNetIncome> calculateMonthlyBreakdown(CalculationContext context) {
    final monthlyIncomes = <MonthlyNetIncome>[];

    // 재직 년수 계산 (ServiceYearsCalculator 사용)
    final serviceInfo = ServiceYearsCalculator.calculate(
      context.profile.employmentStartDate,
      DateTime(context.year, 12, 31), // 해당 년도 말 기준
    );
    final serviceYears = serviceInfo.fullYears;

    // 기본급
    final baseSalary = SalaryTable.getBasePay(context.profile.currentGrade);

    // 교직수당 (모든 교사)
    const teachingAllowance = AllowanceTable.teachingAllowance;

    // 담임수당
    final homeroomAllowance = context.isHomeroom ? AllowanceTable.homeroomAllowance : 0;

    // 보직교사수당
    final positionAllowance = context.hasPosition ? AllowanceTable.headTeacherAllowance : 0;

    // 교직수당 가산금 (개별 항목)
    final specialEducationAllowance = _salaryService.calculateSpecialEducationAllowance(
      context.profile.teachingAllowanceBonuses,
    );
    final vocationalEducationAllowance = _salaryService.calculateVocationalEducationAllowance(
      context.profile.teachingAllowanceBonuses,
      context.profile.currentGrade,
    );
    final healthTeacherAllowance = _salaryService.calculateHealthTeacherAllowance(
      context.profile.teachingAllowanceBonuses,
    );
    final concurrentPositionAllowance = _salaryService.calculateConcurrentPositionAllowance(
      context.profile.teachingAllowanceBonuses,
      context.profile.position,
    );
    final nutritionTeacherAllowance = _salaryService.calculateNutritionTeacherAllowance(
      context.profile.teachingAllowanceBonuses,
    );
    final librarianAllowance = _salaryService.calculateLibrarianAllowance(
      context.profile.teachingAllowanceBonuses,
    );
    final counselorAllowance = _salaryService.calculateCounselorAllowance(
      context.profile.teachingAllowanceBonuses,
    );

    // 원로교사수당 (30년 이상 + 55세 이상)
    final veteranAllowance = _salaryService.calculateVeteranAllowance(
      bonuses: context.profile.teachingAllowanceBonuses,
      serviceYears: serviceYears,
      birthYear: context.profile.birthYear,
      birthMonth: context.profile.birthMonth,
      currentYear: context.year,
      currentMonth: 1, // 월별로 큰 차이 없으므로 1로 고정
    );

    final familyAllowanceResult = _salaryService.calculateFamilyAllowance(
      numberOfChildren: context.numberOfChildren,
      youngChildrenBirthDates: context.profile.youngChildrenBirthDates, // 현재는 UI가 없어 빈 목록 전달
      currentYear: context.year,
      hasSpouse: context.hasSpouse,
      numberOfParents: context.profile.numberOfParents,
    );
    final familyAllowance = familyAllowanceResult.total;
    final nonTaxableFamilyAllowance = familyAllowanceResult.nonTaxable;

    // 연구비
    final researchAllowance = _salaryService.calculateResearchAllowance(
      position: context.profile.position,
      schoolType: context.profile.schoolType,
      teachingExperienceYears: serviceYears, // 교육경력 대신 재직년수 사용
    );

    // 시간외근무수당 정액분
    final overtimeAllowance = _salaryService.calculateOvertimeAllowance(context.profile.currentGrade);

    // 정근수당 가산금 (매월)
    final longevityMonthly = _salaryService.calculateLongevityMonthlyAllowance(serviceYears);

    // 월별 계산
    for (int month = 1; month <= 12; month++) {
      // 각종 수당 합계
      final totalAllowances =
          teachingAllowance +
          homeroomAllowance +
          positionAllowance +
          specialEducationAllowance +
          vocationalEducationAllowance +
          healthTeacherAllowance +
          concurrentPositionAllowance +
          nutritionTeacherAllowance +
          librarianAllowance +
          counselorAllowance +
          veteranAllowance +
          familyAllowance +
          researchAllowance +
          overtimeAllowance +
          longevityMonthly;

      // 정근수당 (1월/7월만)
      final longevityBonus = _salaryService.calculateLongevityBonus(
        serviceYears: serviceYears,
        monthlySalary: baseSalary + totalAllowances, // 월급 기준
        month: month,
      );

      // 명절상여금 (설날/추석, HolidayPaymentTable 사용)
      final holidayBonus = HolidayPaymentTable.calculateHolidayBonus(
        baseSalary: baseSalary,
        year: context.year,
        month: month,
      );

      // 성과상여금 (3월만)
      final performanceBonus = _salaryService.calculatePerformanceBonus(
        grade: context.performanceGrade,
        month: month,
      );

      // 총 지급액 (세전)
      final grossSalary =
          baseSalary + totalAllowances + longevityBonus + holidayBonus + performanceBonus;

      // 과세 대상 소득 (소득세 계산용)
      final taxableIncome = grossSalary - researchAllowance - nonTaxableFamilyAllowance;

      // 부양가족 수 계산 (본인 제외)
      final dependents = (context.hasSpouse ? 1 : 0) + context.numberOfChildren + context.profile.numberOfParents;

      // 소득세 (과세 대상 소득 기준)
      final incomeTax = _taxService.calculateIncomeTax(taxableIncome, dependents: dependents);

      // 지방소득세 (소득세의 10%)
      final localTax = _taxService.calculateLocalIncomeTax(incomeTax);

      // 국민연금 (일반 근로자용, 공무원은 미사용)
      const nationalPension = 0; // 공무원은 공무원연금 적용

      // 공무원연금 기여금 계산 (9%)
      // 기준소득월액 = 본봉 + 정기수당 + 정근수당 + 명절휴가비
      // 제외: 시간외근무수당(정액분), 성과상여금, 비과세수당
      final pensionBaseIncome =
          baseSalary +
          teachingAllowance +
          homeroomAllowance +
          positionAllowance +
          veteranAllowance +
          familyAllowance -
          nonTaxableFamilyAllowance +
          longevityMonthly +
          longevityBonus +
          holidayBonus;

      final pensionContribution = (pensionBaseIncome * 0.09).round();

      // 건강보험 (2025년 요율: 7.09%)
      // 보수월액 = 총 급여 - 비과세 수당 (교원연구비, 6세이하 자녀수당)
      final monthlyPayroll = grossSalary - researchAllowance - nonTaxableFamilyAllowance;
      final healthInsurance = (monthlyPayroll * 0.03545).round(); // 본인부담 3.545%

      // 장기요양보험 (건강보험료의 12.95%, 2025년 요율)
      final longTermCareInsurance = (healthInsurance * 0.1295).round();

      // 고용보험 (공무원 제외)
      const employmentInsurance = 0; // 공무원은 고용보험 적용 제외

      // 급식비 공제 (추정치)
      final mealDeduction = _salaryService.calculateMealDeduction();

      // 총 공제액
      final totalDeductions =
          incomeTax +
          localTax +
          pensionContribution +
          healthInsurance +
          longTermCareInsurance +
          employmentInsurance +
          mealDeduction;

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
          longevityMonthly: longevityMonthly,
          veteranAllowance: veteranAllowance,
          familyAllowance: familyAllowance,
          researchAllowance: researchAllowance,
          overtimeAllowance: overtimeAllowance,
          specialEducationAllowance: specialEducationAllowance,
          vocationalEducationAllowance: vocationalEducationAllowance,
          healthTeacherAllowance: healthTeacherAllowance,
          concurrentPositionAllowance: concurrentPositionAllowance,
          nutritionTeacherAllowance: nutritionTeacherAllowance,
          librarianAllowance: librarianAllowance,
          counselorAllowance: counselorAllowance,
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
    return monthlyIncomes.fold<int>(0, (sum, income) => sum + income.totalDeductions);
  }
}
