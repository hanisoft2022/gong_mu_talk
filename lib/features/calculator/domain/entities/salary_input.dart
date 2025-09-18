import 'package:equatable/equatable.dart';

import 'salary_allowance_type.dart';
import 'salary_track.dart';

class SalaryInput extends Equatable {
  const SalaryInput({
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
  final Map<SalaryAllowanceType, double> allowances;
  final double annualBonus;
  final double pensionContributionRate;
  final int appointmentYear;
  final SalaryTrack track;
  final String gradeId;
  final int step;
  final bool isAutoCalculated;

  factory SalaryInput.initial() => SalaryInput(
        baseMonthlySalary: 0,
        workingDaysPerMonth: 21,
        allowances: const {
          SalaryAllowanceType.replacement: 0,
          SalaryAllowanceType.nightDuty: 0,
          SalaryAllowanceType.hazard: 0,
        },
        annualBonus: 0,
        pensionContributionRate: 0.098, // 공무원 연금 기본율 참고값
        appointmentYear: DateTime.now().year,
        track: SalaryTrack.general,
        gradeId: '9',
        step: 1,
        isAutoCalculated: false,
      );

  SalaryInput copyWith({
    double? baseMonthlySalary,
    int? workingDaysPerMonth,
    Map<SalaryAllowanceType, double>? allowances,
    double? annualBonus,
    double? pensionContributionRate,
    int? appointmentYear,
    SalaryTrack? track,
    String? gradeId,
    int? step,
    bool? isAutoCalculated,
  }) {
    return SalaryInput(
      baseMonthlySalary: baseMonthlySalary ?? this.baseMonthlySalary,
      workingDaysPerMonth: workingDaysPerMonth ?? this.workingDaysPerMonth,
      allowances: allowances ?? this.allowances,
      annualBonus: annualBonus ?? this.annualBonus,
      pensionContributionRate:
          pensionContributionRate ?? this.pensionContributionRate,
      appointmentYear: appointmentYear ?? this.appointmentYear,
      track: track ?? this.track,
      gradeId: gradeId ?? this.gradeId,
      step: step ?? this.step,
      isAutoCalculated: isAutoCalculated ?? this.isAutoCalculated,
    );
  }

  @override
  List<Object?> get props => [
        baseMonthlySalary,
        workingDaysPerMonth,
        annualBonus,
        pensionContributionRate,
        appointmentYear,
        track,
        gradeId,
        step,
        isAutoCalculated,
        allowances.entries
            .map((entry) => '${entry.key.name}:${entry.value}')
            .join('|'),
      ];
}
