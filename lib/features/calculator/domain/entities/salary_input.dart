import 'package:equatable/equatable.dart';

import 'salary_allowance_type.dart';

class SalaryInput extends Equatable {
  const SalaryInput({
    required this.baseMonthlySalary,
    required this.workingDaysPerMonth,
    required this.allowances,
    required this.annualBonus,
    required this.pensionContributionRate,
  });

  final double baseMonthlySalary;
  final int workingDaysPerMonth;
  final Map<SalaryAllowanceType, double> allowances;
  final double annualBonus;
  final double pensionContributionRate;

  factory SalaryInput.initial() => const SalaryInput(
        baseMonthlySalary: 0,
        workingDaysPerMonth: 21,
        allowances: {
          SalaryAllowanceType.replacement: 0,
          SalaryAllowanceType.nightDuty: 0,
          SalaryAllowanceType.hazard: 0,
        },
        annualBonus: 0,
        pensionContributionRate: 0.098, // 공무원 연금 기본율 참고값
      );

  SalaryInput copyWith({
    double? baseMonthlySalary,
    int? workingDaysPerMonth,
    Map<SalaryAllowanceType, double>? allowances,
    double? annualBonus,
    double? pensionContributionRate,
  }) {
    return SalaryInput(
      baseMonthlySalary: baseMonthlySalary ?? this.baseMonthlySalary,
      workingDaysPerMonth: workingDaysPerMonth ?? this.workingDaysPerMonth,
      allowances: allowances ?? this.allowances,
      annualBonus: annualBonus ?? this.annualBonus,
      pensionContributionRate:
          pensionContributionRate ?? this.pensionContributionRate,
    );
  }

  @override
  List<Object?> get props => [
        baseMonthlySalary,
        workingDaysPerMonth,
        annualBonus,
        pensionContributionRate,
        allowances.entries
            .map((entry) => '${entry.key.name}:${entry.value}')
            .join('|'),
      ];
}
