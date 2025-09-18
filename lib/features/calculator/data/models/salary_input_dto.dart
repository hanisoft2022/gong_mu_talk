import 'package:equatable/equatable.dart';

import '../../domain/entities/salary_allowance_type.dart';
import '../../domain/entities/salary_input.dart';
import '../../domain/entities/salary_track.dart';

class SalaryInputDto extends Equatable {
  const SalaryInputDto({
    required this.baseMonthlySalary,
    required this.workingDaysPerMonth,
    required this.allowances,
    required this.annualBonus,
    required this.pensionContributionRate,
    required this.appointmentYear,
    required this.track,
    required this.gradeId,
    required this.step,
    required this.isAutoCalculated,
  });

  final double baseMonthlySalary;
  final int workingDaysPerMonth;
  final Map<String, double> allowances;
  final double annualBonus;
  final double pensionContributionRate;
  final int appointmentYear;
  final String track;
  final String gradeId;
  final int step;
  final bool isAutoCalculated;

  factory SalaryInputDto.fromDomain(SalaryInput input) {
    return SalaryInputDto(
      baseMonthlySalary: input.baseMonthlySalary,
      workingDaysPerMonth: input.workingDaysPerMonth,
      allowances: input.allowances.map(
        (key, value) => MapEntry(key.name, value),
      ),
      annualBonus: input.annualBonus,
      pensionContributionRate: input.pensionContributionRate,
      appointmentYear: input.appointmentYear,
      track: input.track.id,
      gradeId: input.gradeId,
      step: input.step,
      isAutoCalculated: input.isAutoCalculated,
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
      appointmentYear: appointmentYear,
      track: SalaryTrack.values.firstWhere(
        (element) => element.id == track,
        orElse: () => SalaryTrack.general,
      ),
      gradeId: gradeId,
      step: step,
      isAutoCalculated: isAutoCalculated,
    );
  }

  Map<String, dynamic> toJson() => {
        'baseMonthlySalary': baseMonthlySalary,
        'workingDaysPerMonth': workingDaysPerMonth,
        'allowances': allowances,
        'annualBonus': annualBonus,
        'pensionContributionRate': pensionContributionRate,
        'appointmentYear': appointmentYear,
        'track': track,
        'gradeId': gradeId,
        'step': step,
        'isAutoCalculated': isAutoCalculated,
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
      appointmentYear: json['appointmentYear'] as int? ?? DateTime.now().year,
      track: json['track'] as String? ?? SalaryTrack.general.id,
      gradeId: json['gradeId'] as String? ?? '9',
      step: json['step'] as int? ?? 1,
      isAutoCalculated: json['isAutoCalculated'] as bool? ?? false,
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
        appointmentYear,
        track,
        gradeId,
        step,
        isAutoCalculated,
      ];
}
