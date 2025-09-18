import 'dart:math';

import 'package:intl/intl.dart';

import '../../domain/entities/salary_breakdown.dart';
import '../models/salary_input_dto.dart';

class SalaryCalculatorLocalDataSource {
  Future<SalaryBreakdown> calculate(SalaryInputDto dto) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));

    final double allowancesTotal = dto.allowances.values.fold(0, (sum, value) => sum + value);
    final double monthlyTotal = dto.baseMonthlySalary + allowancesTotal;
    final double dailyRate = dto.workingDaysPerMonth == 0
        ? 0
        : monthlyTotal / dto.workingDaysPerMonth;
    final double yearlyTotal = monthlyTotal * 12 + dto.annualBonus;
    final double pensionContribution = monthlyTotal * dto.pensionContributionRate;

    final int currentYear = DateTime.now().year;
    final double minimumHourlyWage =
        _minimumHourlyWageByYear[currentYear] ??
        _minimumHourlyWageByYear[_minimumHourlyWageByYear.keys.reduce(max)]!;
    final double minimumDailyWage = minimumHourlyWage * 8;
    final double wageGap = dailyRate - minimumDailyWage;

    final NumberFormat formatter = NumberFormat.currency(locale: 'ko_KR', symbol: '₩');
    final NumberFormat numberFormatter = NumberFormat.decimalPattern('ko_KR');

    return SalaryBreakdown(
      monthlyTotal: monthlyTotal,
      dailyRate: dailyRate,
      yearlyTotal: yearlyTotal,
      allowancesTotal: allowancesTotal,
      pensionContribution: pensionContribution,
      minimumDailyWage: minimumDailyWage,
      minimumWageGap: wageGap,
      notes: [
        '기본 월급: \\${numberFormatter.format(dto.baseMonthlySalary)}',
        '연간 보너스: ${formatter.format(dto.annualBonus)}',
        '최저임금(일): ${formatter.format(minimumDailyWage)}',
      ],
    );
  }
}

const Map<int, double> _minimumHourlyWageByYear = <int, double>{
  2023: 9620,
  2024: 9860,
  2025: 10100,
};
