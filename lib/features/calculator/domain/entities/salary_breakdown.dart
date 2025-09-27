import 'package:equatable/equatable.dart';

class SalaryBreakdown extends Equatable {
  const SalaryBreakdown({
    required this.monthlyTotal,
    required this.dailyRate,
    required this.yearlyTotal,
    required this.allowancesTotal,
    required this.pensionContribution,
    required this.minimumDailyWage,
    required this.minimumWageGap,
    required this.notes,
  });

  final double monthlyTotal;
  final double dailyRate;
  final double yearlyTotal;
  final double allowancesTotal;
  final double pensionContribution;
  final double minimumDailyWage;
  final double minimumWageGap;
  final List<String> notes;

  factory SalaryBreakdown.empty() => const SalaryBreakdown(
    monthlyTotal: 0,
    dailyRate: 0,
    yearlyTotal: 0,
    allowancesTotal: 0,
    pensionContribution: 0,
    minimumDailyWage: 0,
    minimumWageGap: 0,
    notes: <String>[],
  );

  @override
  List<Object?> get props => [
    monthlyTotal,
    dailyRate,
    yearlyTotal,
    allowancesTotal,
    pensionContribution,
    minimumDailyWage,
    minimumWageGap,
    notes,
  ];
}
