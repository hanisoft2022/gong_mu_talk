import 'package:equatable/equatable.dart';

import '../../domain/entities/salary_allowance_type.dart';
import '../../domain/entities/salary_input.dart';

class SalaryInputDto extends Equatable {
  const SalaryInputDto({
    required this.baseMonthlySalary,
    required this.workingDaysPerMonth,
    required this.allowances,
    required this.annualBonus,
    required this.pensionContributionRate,
  });

  final double baseMonthlySalary;
  final int workingDaysPerMonth;
  final Map<String, double> allowances;
  final double annualBonus;
  final double pensionContributionRate;

  factory SalaryInputDto.fromDomain(SalaryInput input) {
    return SalaryInputDto(
      baseMonthlySalary: input.baseMonthlySalary,
      workingDaysPerMonth: input.workingDaysPerMonth,
      allowances: input.allowances.map(
        (key, value) => MapEntry(key.name, value),
      ),
      annualBonus: input.annualBonus,
      pensionContributionRate: input.pensionContributionRate,
    );
  }

  SalaryInput toDomain() {
    return SalaryInput(
      baseMonthlySalary: baseMonthlySalary,
      workingDaysPerMonth: workingDaysPerMonth,
      allowances: allowances.map(
        (key, value) => MapEntry(_allowanceTypeFromKey(key), value),
      ),
      annualBonus: annualBonus,
      pensionContributionRate: pensionContributionRate,
    );
  }

  Map<String, dynamic> toJson() => {
        'baseMonthlySalary': baseMonthlySalary,
        'workingDaysPerMonth': workingDaysPerMonth,
        'allowances': allowances,
        'annualBonus': annualBonus,
        'pensionContributionRate': pensionContributionRate,
      };

  factory SalaryInputDto.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> allowanceJson =
        Map<String, dynamic>.from(json['allowances'] as Map);

    return SalaryInputDto(
      baseMonthlySalary: (json['baseMonthlySalary'] as num).toDouble(),
      workingDaysPerMonth: json['workingDaysPerMonth'] as int,
      allowances: allowanceJson.map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      ),
      annualBonus: (json['annualBonus'] as num).toDouble(),
      pensionContributionRate:
          (json['pensionContributionRate'] as num).toDouble(),
    );
  }

  static SalaryAllowanceType _allowanceTypeFromKey(String key) {
    return SalaryAllowanceType.values.firstWhere(
      (type) => type.name == key,
      orElse: () => SalaryAllowanceType.replacement,
    );
  }

  @override
  List<Object?> get props => [
        baseMonthlySalary,
        workingDaysPerMonth,
        allowances.entries
            .map((entry) => '${entry.key}:${entry.value}')
            .join('|'),
        annualBonus,
        pensionContributionRate,
      ];
}
