import 'dart:math';

import 'package:gong_mu_talk/features/calculator/domain/constants/salary_table.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/annual_salary.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/lifetime_salary.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/position.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/teacher_profile.dart';
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

      // 3. 총 급여 (세전)
      final grossPay =
          basePay +
          positionAllowance +
          homeroomAllowance +
          familyAllowance +
          otherAllowances;

      // 4. 세금 및 4대보험
      final incomeTax = _taxService.calculateIncomeTax(grossPay);
      final localTax = _taxService.calculateLocalIncomeTax(incomeTax);
      final insurance = _taxService.calculateTotalInsurance(grossPay);
      final totalDeductions = incomeTax + localTax + insurance;

      // 5. 실수령액
      final netPay = grossPay - totalDeductions;

      // 6. 연간 총 급여 (월급 * 12 + 보너스 등)
      final annualTotalPay = netPay * 13; // 13개월 기준 (보너스 포함)

      results.add(
        AnnualSalary(
          year: year,
          grade: grade,
          basePay: basePay,
          positionAllowance: positionAllowance,
          homeroomAllowance: homeroomAllowance,
          familyAllowance: familyAllowance,
          otherAllowances: otherAllowances,
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
    final totalIncome = annualSalaries.fold<int>(
      0,
      (sum, salary) => sum + salary.annualTotalPay,
    );

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
        return AllowanceTable.teachingAllowance +
            AllowanceTable.vicePrincipalManagementAllowance;
      case Position.principal:
        return AllowanceTable.teachingAllowance +
            AllowanceTable.principalManagementAllowance;
    }
  }
}
