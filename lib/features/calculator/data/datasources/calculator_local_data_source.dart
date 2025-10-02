import 'dart:math';

import 'package:intl/intl.dart';

import '../../domain/entities/salary_breakdown.dart';
import '../../domain/services/insurance_calculator.dart';
import '../../domain/services/tax_calculator.dart';
import '../models/salary_input_dto.dart';

class SalaryCalculatorLocalDataSource {
  SalaryCalculatorLocalDataSource({
    TaxCalculator? taxCalculator,
    InsuranceCalculator? insuranceCalculator,
  })  : _taxCalculator = taxCalculator ?? TaxCalculator(),
        _insuranceCalculator = insuranceCalculator ?? InsuranceCalculator();

  final TaxCalculator _taxCalculator;
  final InsuranceCalculator _insuranceCalculator;

  Future<SalaryBreakdown> calculate(SalaryInputDto dto) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));

    // 1. 총급여 계산
    final double allowancesTotal = dto.allowances.values.fold(
      0,
      (sum, value) => sum + value,
    );
    final double monthlyGross = dto.baseMonthlySalary + allowancesTotal;
    
    // 2. 세금 계산
    final taxBreakdown = _taxCalculator.calculateTotalTax(
      monthlyGross: monthlyGross,
      dependents: 1, // 기본값
    );
    
    // 3. 4대 보험 계산
    // 공무원연금 기준소득월액 상하한 적용
    final pensionBase = _insuranceCalculator.applyPensionBaseLimit(monthlyGross);
    final insuranceBreakdown = _insuranceCalculator.calculateTotalInsurance(
      monthlyGross: monthlyGross,
      pensionBase: pensionBase,
    );
    
    // 4. 총 공제액 계산
    final double totalDeductions = 
        taxBreakdown.totalTax + insuranceBreakdown.totalInsurance;
    
    // 5. 실수령액 계산
    final double netPay = monthlyGross - totalDeductions;
    
    // 6. 연봉 계산
    final double yearlyGross = monthlyGross * 12 + dto.annualBonus;
    final double yearlyTax = taxBreakdown.totalTax * 12;
    final double yearlyInsurance = insuranceBreakdown.totalInsurance * 12;
    final double yearlyNet = yearlyGross - yearlyTax - yearlyInsurance;
    
    // 7. 일급 계산
    final double dailyRate = dto.workingDaysPerMonth == 0
        ? 0
        : monthlyGross / dto.workingDaysPerMonth;
    
    // 8. 최저임금 비교
    final int currentYear = DateTime.now().year;
    final double minimumHourlyWage =
        _minimumHourlyWageByYear[currentYear] ??
        _minimumHourlyWageByYear[_minimumHourlyWageByYear.keys.reduce(max)]!;
    final double minimumDailyWage = minimumHourlyWage * 8;
    final double wageGap = dailyRate - minimumDailyWage;

    // 9. 상세 내역 생성
    final NumberFormat formatter = NumberFormat.currency(
      locale: 'ko_KR',
      symbol: '₩',
      decimalDigits: 0,
    );

    return SalaryBreakdown(
      monthlyTotal: monthlyGross,
      dailyRate: dailyRate,
      yearlyTotal: yearlyGross,
      allowancesTotal: allowancesTotal,
      pensionContribution: insuranceBreakdown.pensionContribution,
      incomeTax: taxBreakdown.incomeTax,
      localIncomeTax: taxBreakdown.localIncomeTax,
      healthInsurance: insuranceBreakdown.healthInsurance,
      longTermCare: insuranceBreakdown.longTermCare,
      totalDeductions: totalDeductions,
      netPay: netPay,
      yearlyNet: yearlyNet,
      minimumDailyWage: minimumDailyWage,
      minimumWageGap: wageGap,
      notes: [
        '■ 월급 상세',
        '기본 월급: ${formatter.format(dto.baseMonthlySalary)}',
        '수당 합계: ${formatter.format(allowancesTotal)}',
        '월 총급여: ${formatter.format(monthlyGross)}',
        '',
        '■ 공제 상세',
        '소득세: ${formatter.format(taxBreakdown.incomeTax)}',
        '지방소득세: ${formatter.format(taxBreakdown.localIncomeTax)}',
        '공무원연금 (9%): ${formatter.format(insuranceBreakdown.pensionContribution)}',
        '건강보험: ${formatter.format(insuranceBreakdown.healthInsurance)}',
        '장기요양보험: ${formatter.format(insuranceBreakdown.longTermCare)}',
        '총 공제액: ${formatter.format(totalDeductions)}',
        '',
        '■ 실수령액',
        '월 실수령액: ${formatter.format(netPay)}',
        '연 실수령액: ${formatter.format(yearlyNet)}',
        '',
        '■ 기타',
        '일급: ${formatter.format(dailyRate)}',
        '최저일급: ${formatter.format(minimumDailyWage)}',
        '최저임금 대비: ${wageGap >= 0 ? '+' : ''}${formatter.format(wageGap)}',
      ],
    );
  }
}

const Map<int, double> _minimumHourlyWageByYear = <int, double>{
  2023: 9620,
  2024: 9860,
  2025: 10030,
};
