import 'dart:math';

import 'package:gong_mu_talk/features/calculator/domain/constants/salary_table.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/annual_salary.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/lifetime_salary.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/monthly_salary_detail.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/performance_bonus_projection.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/performance_grade.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/position.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/teacher_profile.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/teaching_allowance_bonus.dart';
import 'package:gong_mu_talk/features/calculator/domain/services/tax_calculation_service.dart';

/// 급여 계산 서비스
class SalaryCalculationService {
  final TaxCalculationService _taxService;

  SalaryCalculationService(this._taxService);

  /// 연도별 급여 계산
  List<AnnualSalary> calculateAnnualSalaries({
    required TeacherProfile profile,
    int? targetRetirementAge,
  }) {
    final results = <AnnualSalary>[];
    final currentYear = DateTime.now().year;
    final retirementAge = targetRetirementAge ?? profile.retirementAge;
    final birthYear = profile.employmentStartDate.year - 25; // 대략적인 출생년도 (25세 입직 가정)
    final retirementYear = birthYear + retirementAge;

    // 성과상여금 예측 계산기
    final performanceBonusProjection = PerformanceBonusProjection();

    int grade = profile.currentGrade;

    for (int year = currentYear; year <= retirementYear; year++) {
      // 40호봉 이상은 유지
      if (grade > 40) grade = 40;

      // 1. 본봉 조회
      final basePay = _getBasePay(grade, profile.position);

      // 2. 수당 계산
      final positionAllowance = _calculatePositionAllowance(profile.position);
      final homeroomAllowance = profile.allowances.homeroom;
      final familyAllowance = profile.allowances.family;
      final otherAllowances =
          profile.allowances.headTeacher +
          profile.allowances.veteran +
          profile.allowances.other1 +
          profile.allowances.other2;

      // 3. 성과상여금 계산 (미래 예측 포함)
      final performanceBonus = performanceBonusProjection.calculateFutureBonus(
        targetYear: year,
      );

      // 4. 총 급여 (세전)
      final grossPay =
          basePay + positionAllowance + homeroomAllowance + familyAllowance + otherAllowances;

      // 5. 세금 및 4대보험
      final incomeTax = _taxService.calculateIncomeTax(grossPay);
      final localTax = _taxService.calculateLocalIncomeTax(incomeTax);
      final insurance = _taxService.calculateTotalInsurance(grossPay);
      final totalDeductions = incomeTax + localTax + insurance;

      // 6. 실수령액 (월급)
      final netPay = grossPay - totalDeductions;

      // 7. 연간 총 급여 (월급 * 12 + 성과상여금)
      // 성과상여금은 3월에 지급되므로 연간 1회만 포함
      final annualTotalPay = (netPay * 12) + performanceBonus;

      results.add(
        AnnualSalary(
          year: year,
          grade: grade,
          basePay: basePay,
          positionAllowance: positionAllowance,
          homeroomAllowance: homeroomAllowance,
          familyAllowance: familyAllowance,
          otherAllowances: otherAllowances,
          performanceBonus: performanceBonus,
          incomeTax: incomeTax + localTax,
          insurance: insurance,
          netPay: netPay,
          annualTotalPay: annualTotalPay,
        ),
      );

      // 다음 연도 호봉 승급
      grade++;
    }

    return results;
  }

  /// 생애 급여 계산
  LifetimeSalary calculateLifetimeSalary({
    required TeacherProfile profile,
    double inflationRate = 0.025, // 연 2.5% 인플레이션
  }) {
    final annualSalaries = calculateAnnualSalaries(profile: profile);

    // 1. 명목 총 소득
    final totalIncome = annualSalaries.fold<int>(0, (sum, salary) => sum + salary.annualTotalPay);

    // 2. 현재 가치 환산 (인플레이션 반영)
    int presentValue = 0;
    for (int i = 0; i < annualSalaries.length; i++) {
      final discountFactor = pow(1 + inflationRate, i);
      presentValue += (annualSalaries[i].annualTotalPay / discountFactor).round();
    }

    // 3. 평균 연봉
    final avgAnnualSalary = annualSalaries.isEmpty
        ? 0
        : (totalIncome / annualSalaries.length).round();

    return LifetimeSalary(
      annualSalaries: annualSalaries,
      totalIncome: totalIncome,
      presentValue: presentValue,
      avgAnnualSalary: avgAnnualSalary,
      inflationRate: inflationRate,
    );
  }

  /// 직급별 본봉 조회
  int _getBasePay(int grade, Position position) {
    switch (position) {
      case Position.teacher:
        return SalaryTable.getBasePay(grade);
      case Position.vicePrincipal:
        return SalaryTable.getVicePrincipalPay(grade);
      case Position.principal:
        return SalaryTable.getPrincipalPay(grade);
    }
  }

  /// 직급별 수당 계산
  int _calculatePositionAllowance(Position position) {
    switch (position) {
      case Position.teacher:
        return AllowanceTable.teachingAllowance;
      case Position.vicePrincipal:
        return AllowanceTable.teachingAllowance + AllowanceTable.vicePrincipalManagementAllowance;
      case Position.principal:
        return AllowanceTable.teachingAllowance + AllowanceTable.principalManagementAllowance;
    }
  }

  /// 정근수당 계산 (1월/7월)
  ///
  /// [serviceYears] 재직 년수
  /// [monthlySalary] 월급 (본봉 + 각종 수당)
  /// [month] 월 (1~12)
  ///
  /// Returns: 정근수당 (1월/7월만 지급, 그 외 0)
  int calculateLongevityBonus({
    required int serviceYears,
    required int monthlySalary,
    required int month,
  }) {
    // 1월/7월만 지급
    if (month != 1 && month != 7) return 0;

    // 재직 년수별 지급률 (2025년 개정 기준)
    double rate;
    if (serviceYears < 1) {
      rate = 0.10; // 1년 미만: 10%
    } else if (serviceYears < 2) {
      rate = 0.10; // 1년 이상 2년 미만: 10%
    } else if (serviceYears < 3) {
      rate = 0.20; // 2년 이상 3년 미만: 20%
    } else if (serviceYears < 5) {
      rate = 0.20; // 3년 이상 5년 미만: 20%
    } else if (serviceYears < 10) {
      rate = 0.40; // 5년 이상 10년 미만: 40%
    } else {
      rate = 0.50; // 10년 이상: 50%
    }

    return (monthlySalary * rate).round();
  }

  /// 정근수당 가산금 계산 (매월)
  ///
  /// [serviceYears] 재직 년수
  ///
  /// Returns: 정근수당 가산금 (월 3~13만원)
  int calculateLongevityMonthlyAllowance(int serviceYears) {
    if (serviceYears < 5) return 30000; // 5년 미만: 3만원
    if (serviceYears < 10) return 100000; // 5년 이상 10년 미만: 10만원
    if (serviceYears < 20) return 100000; // 10년 이상 20년 미만: 10만원
    if (serviceYears < 25) return 110000; // 20년 이상 25년 미만: 11만원
    return 130000; // 25년 이상: 13만원
  }

  /// 교원연구비 계산
  ///
  /// [serviceYears] 재직 년수
  ///
  /// Returns: 교원연구비 (5년 미만 7만원, 5년 이상 6만원)
  int calculateResearchAllowance(int serviceYears) {
    return serviceYears < 5 ? 70000 : 60000;
  }

  /// 시간외근무수당 정액분 계산
  ///
  /// [currentGrade] 현재 호봉
  ///
  /// Returns: 시간외근무수당 정액분 (2025년 기준)
  int calculateOvertimeAllowance(int currentGrade) {
    return AllowanceTable.getOvertimeAllowance(currentGrade);
  }

  /// 성과상여금 계산 (교육공무원 기준)
  ///
  /// [grade] 성과등급 (S/A/B)
  /// [month] 현재 월 (3월에만 지급)
  ///
  /// Returns: 성과상여금 (3월만 지급, 그 외 0)
  int calculatePerformanceBonus({required PerformanceGrade grade, required int month}) {
    // 3월만 지급
    if (month != 3) return 0;

    // 2025년 교육공무원 성과상여금 (차등지급률 50% 기준)
    return grade.amount;
  }

  /// 원로교사수당 계산
  ///
  /// [serviceYears] 재직 년수
  /// [birthYear] 출생 년도
  /// [birthMonth] 출생 월
  /// [currentYear] 현재 년도
  /// [currentMonth] 현재 월
  ///
  /// Returns: 원로교사수당 (30년 이상 재직 + 55세 이상 시 5만원, 아니면 0)
  int calculateVeteranAllowance({
    required int serviceYears,
    required int birthYear,
    required int birthMonth,
    required int currentYear,
    required int currentMonth,
  }) {
    // 나이 계산
    final age = currentYear - birthYear - (currentMonth < birthMonth ? 1 : 0);

    // 30년 이상 재직 + 55세 이상
    if (serviceYears >= 30 && age >= 55) {
      return 50000;
    }

    return 0;
  }

  /// 가족수당 계산
  ///
  /// [hasSpouse] 배우자 유무
  /// [numberOfChildren] 자녀 수
  ///
  /// Returns: 가족수당 (배우자 4만 + 첫째 5만 + 둘째 8만 + 셋째이상 각12만)
  int calculateFamilyAllowance({required bool hasSpouse, required int numberOfChildren}) {
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

  /// 교직수당 가산금 계산 (담임/보직 제외)
  ///
  /// [bonuses] 선택된 교직수당 가산금 목록
  /// [currentGrade] 현재 호봉 (특성화교사 수당 계산용)
  /// [position] 직급 (겸직수당 계산용)
  ///
  /// Returns: 총 교직수당 가산금
  /// 특수교사 가산금 계산
  int calculateSpecialEducationAllowance(Set<TeachingAllowanceBonus> bonuses) {
    return bonuses.contains(TeachingAllowanceBonus.specialEducation)
        ? AllowanceTable.allowance2SpecialEducation
        : 0;
  }

  /// 특성화교사 가산금 계산 (전문교과)
  int calculateVocationalEducationAllowance(Set<TeachingAllowanceBonus> bonuses, int currentGrade) {
    if (!bonuses.contains(TeachingAllowanceBonus.vocationalEducation)) return 0;

    // 호봉별 구간 금액 (2025년 기준)
    if (currentGrade >= 31) {
      return 50000; // 31~40호봉
    } else if (currentGrade >= 22) {
      return 45000; // 22~30호봉
    } else if (currentGrade >= 14) {
      return 40000; // 14~21호봉
    } else if (currentGrade >= 9) {
      return 35000; // 9~13호봉
    } else if (currentGrade >= 5) {
      return 30000; // 5~8호봉
    } else {
      return 25000; // 1~4호봉
    }
  }

  /// 보건교사 가산금 계산
  int calculateHealthTeacherAllowance(Set<TeachingAllowanceBonus> bonuses) {
    return bonuses.contains(TeachingAllowanceBonus.healthTeacher)
        ? AllowanceTable.allowance6HealthTeacher
        : 0;
  }

  /// 겸직수당 계산
  int calculateConcurrentPositionAllowance(Set<TeachingAllowanceBonus> bonuses, Position position) {
    if (!bonuses.contains(TeachingAllowanceBonus.concurrentPosition)) return 0;

    if (position == Position.principal) {
      return AllowanceTable.allowance7ConcurrentPrincipal;
    } else if (position == Position.vicePrincipal) {
      return AllowanceTable.allowance7ConcurrentVice;
    }
    return 0;
  }

  /// 영양교사 가산금 계산
  int calculateNutritionTeacherAllowance(Set<TeachingAllowanceBonus> bonuses) {
    return bonuses.contains(TeachingAllowanceBonus.nutritionTeacher)
        ? AllowanceTable.allowance8Nutrition
        : 0;
  }

  /// 사서교사 가산금 계산
  int calculateLibrarianAllowance(Set<TeachingAllowanceBonus> bonuses) {
    return bonuses.contains(TeachingAllowanceBonus.librarian)
        ? AllowanceTable.allowance9Librarian
        : 0;
  }

  /// 전문상담교사 가산금 계산
  int calculateCounselorAllowance(Set<TeachingAllowanceBonus> bonuses) {
    return bonuses.contains(TeachingAllowanceBonus.counselor)
        ? AllowanceTable.allowance10Counselor
        : 0;
  }

  /// 월별 급여명세서 계산 (12개월)
  ///
  /// [profile] 교사 프로필
  /// [hasSpouse] 배우자 유무
  /// [numberOfChildren] 자녀 수
  /// [isHomeroom] 담임 여부
  /// [hasPosition] 보직교사 여부
  /// [includeMealAllowance] 정액급식비 포함 여부
  ///
  /// Returns: 12개월 급여명세서 리스트
  List<MonthlySalaryDetail> calculateMonthlySalaries({
    required TeacherProfile profile,
    required bool hasSpouse,
    required int numberOfChildren,
    required bool isHomeroom,
    required bool hasPosition,
    required bool includeMealAllowance,
  }) {
    final monthlyDetails = <MonthlySalaryDetail>[];
    final currentYear = DateTime.now().year;
    final currentMonth = DateTime.now().month;

    // 재직 년수 계산
    final serviceYears = currentYear - profile.employmentStartDate.year;

    // 1. 본봉
    final baseSalary = _getBasePay(profile.currentGrade, profile.position);

    // 2. 교직수당 (25만원, 모든 교사)
    const teachingAllowance = AllowanceTable.teachingAllowance;

    // 3. 담임수당 (20만원, 담임만)
    final homeroomAllowance = isHomeroom ? 200000 : 0;

    // 4. 보직교사수당 (15만원, 보직교사만)
    final positionAllowance = hasPosition ? 150000 : 0;

    // 4-1. 개별 교직수당 가산금
    final specialEducationAllowance = calculateSpecialEducationAllowance(
      profile.teachingAllowanceBonuses,
    );
    final vocationalEducationAllowance = calculateVocationalEducationAllowance(
      profile.teachingAllowanceBonuses,
      profile.currentGrade,
    );
    final healthTeacherAllowance = calculateHealthTeacherAllowance(
      profile.teachingAllowanceBonuses,
    );
    final concurrentPositionAllowance = calculateConcurrentPositionAllowance(
      profile.teachingAllowanceBonuses,
      profile.position,
    );
    final nutritionTeacherAllowance = calculateNutritionTeacherAllowance(
      profile.teachingAllowanceBonuses,
    );
    final librarianAllowance = calculateLibrarianAllowance(
      profile.teachingAllowanceBonuses,
    );
    final counselorAllowance = calculateCounselorAllowance(
      profile.teachingAllowanceBonuses,
    );

    // 5. 원로교사수당 (30년 이상 + 55세 이상)
    final veteranAllowance = calculateVeteranAllowance(
      serviceYears: serviceYears,
      birthYear: profile.birthYear,
      birthMonth: profile.birthMonth,
      currentYear: currentYear,
      currentMonth: currentMonth,
    );

    // 6. 가족수당
    final familyAllowance = calculateFamilyAllowance(
      hasSpouse: hasSpouse,
      numberOfChildren: numberOfChildren,
    );

    // 7. 교원연구비
    final researchAllowance = calculateResearchAllowance(serviceYears);

    // 8. 정액급식비 (14만원, 선택)
    final mealAllowance = includeMealAllowance ? 140000 : 0;

    // 9. 시간외근무수당 정액분
    final overtimeAllowance = calculateOvertimeAllowance(profile.currentGrade);

    // 10. 정근수당 가산금 (매월)
    final longevityMonthly = calculateLongevityMonthlyAllowance(serviceYears);

    // 월별 계산
    for (int month = 1; month <= 12; month++) {
      // 월급 (정근수당 제외)
      final monthlySalary =
          baseSalary +
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
          mealAllowance +
          overtimeAllowance +
          longevityMonthly;

      // 정근수당 (1월/7월만)
      final longevityBonus = calculateLongevityBonus(
        serviceYears: serviceYears,
        monthlySalary: monthlySalary,
        month: month,
      );

      // 총 지급액
      final grossSalary = monthlySalary + longevityBonus;

      // 개별 교직수당 가산금 합계
      final totalTeachingAllowanceBonuses =
          specialEducationAllowance +
          vocationalEducationAllowance +
          healthTeacherAllowance +
          concurrentPositionAllowance +
          nutritionTeacherAllowance +
          librarianAllowance +
          counselorAllowance;

      monthlyDetails.add(
        MonthlySalaryDetail(
          month: month,
          baseSalary: baseSalary,
          teachingAllowance: teachingAllowance,
          homeroomAllowance: homeroomAllowance,
          positionAllowance: positionAllowance,
          teachingAllowanceBonuses: totalTeachingAllowanceBonuses,
          veteranAllowance: veteranAllowance,
          familyAllowance: familyAllowance,
          researchAllowance: researchAllowance,
          mealAllowance: mealAllowance,
          overtimeAllowance: overtimeAllowance,
          longevityBonus: longevityBonus,
          longevityMonthly: longevityMonthly,
          grossSalary: grossSalary,
        ),
      );
    }

    return monthlyDetails;
  }
}
