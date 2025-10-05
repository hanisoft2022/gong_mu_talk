import 'package:gong_mu_talk/features/calculator/domain/entities/monthly_net_income.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/teacher_profile.dart';
import 'package:gong_mu_talk/features/calculator/domain/constants/salary_table.dart';
import 'package:gong_mu_talk/features/calculator/domain/services/tax_calculation_service.dart';

/// 월별 실수령액 계산 서비스
class MonthlyBreakdownService {
  final TaxCalculationService _taxService;

  MonthlyBreakdownService(this._taxService);

  /// 12개월 실수령액 계산
  ///
  /// [profile] 교사 프로필
  /// [year] 계산 년도
  /// [hasSpouse] 배우자 유무
  /// [numberOfChildren] 자녀 수
  /// [isHomeroom] 담임 여부
  /// [hasPosition] 보직 여부
  ///
  /// Returns: 12개월 실수령액 목록
  List<MonthlyNetIncome> calculateMonthlyBreakdown({
    required TeacherProfile profile,
    required int year,
    required bool hasSpouse,
    required int numberOfChildren,
    bool isHomeroom = false,
    bool hasPosition = false,
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
    final positionAllowance =
        hasPosition ? AllowanceTable.headTeacherAllowance : 0;

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
    );

    // 연구비
    final researchAllowance = _calculateResearchAllowance(serviceYears);

    // 시간외근무수당 정액분
    final overtimeAllowance =
        AllowanceTable.getOvertimeAllowance(profile.currentGrade);

    // 정근수당 가산금 (매월)
    final longevityMonthly =
        _calculateLongevityMonthlyAllowance(serviceYears);

    // 월별 계산
    for (int month = 1; month <= 12; month++) {
      // 각종 수당 합계
      final totalAllowances = teachingAllowance +
          homeroomAllowance +
          positionAllowance +
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

      // 총 지급액 (세전)
      final grossSalary = baseSalary + totalAllowances + longevityBonus;

      // 소득세
      final incomeTax = _taxService.calculateIncomeTax(grossSalary);

      // 주민세
      final localTax = _taxService.calculateLocalIncomeTax(incomeTax);

      // 국민연금 (9%)
      final nationalPension = (grossSalary * 0.045).round(); // 본인부담 4.5%

      // 건강보험 (6.99%)
      final healthInsurance = (grossSalary * 0.03545).round(); // 본인부담 3.545%

      // 장기요양보험 (건강보험료의 12.95%)
      final longTermCareInsurance = (healthInsurance * 0.1295).round();

      // 고용보험 (0.9%)
      final employmentInsurance = (grossSalary * 0.009).round();

      // 총 공제액
      final totalDeductions = incomeTax +
          localTax +
          nationalPension +
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
          longevityBonus: longevityBonus,
          grossSalary: grossSalary,
          incomeTax: incomeTax,
          localTax: localTax,
          nationalPension: nationalPension,
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

    // 재직 년수별 지급률
    double rate;
    if (serviceYears < 1) {
      rate = 0.10; // 1년 미만: 10%
    } else if (serviceYears < 2) {
      rate = 0.15; // 1년 이상: 15%
    } else if (serviceYears < 3) {
      rate = 0.20; // 2년 이상: 20%
    } else if (serviceYears < 5) {
      rate = 0.30; // 3년 이상: 30%
    } else if (serviceYears < 10) {
      rate = 0.40; // 5년 이상: 40%
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
    if (serviceYears < 1) return 30000;
    if (serviceYears < 2) return 40000;
    if (serviceYears < 3) return 50000;
    if (serviceYears < 5) return 70000;
    if (serviceYears < 10) return 100000;
    return 130000;
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
  ///
  /// Returns: 가족수당
  int _calculateFamilyAllowance({
    required bool hasSpouse,
    required int numberOfChildren,
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

  /// 연간 총 실수령액 계산
  ///
  /// [monthlyIncomes] 월별 실수령액 목록
  ///
  /// Returns: 연간 총 실수령액
  int calculateAnnualNetIncome(List<MonthlyNetIncome> monthlyIncomes) {
    return monthlyIncomes.fold<int>(
      0,
      (sum, income) => sum + income.netIncome,
    );
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
