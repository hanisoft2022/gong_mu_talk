part of 'salary_calculator_bloc.dart';

abstract class SalaryCalculatorEvent extends Equatable {
  const SalaryCalculatorEvent();

  @override
  List<Object?> get props => [];
}

class SalaryCalculatorBaseSalaryChanged extends SalaryCalculatorEvent {
  const SalaryCalculatorBaseSalaryChanged(this.baseSalary);

  final double baseSalary;

  @override
  List<Object?> get props => [baseSalary];
}

class SalaryCalculatorAllowanceChanged extends SalaryCalculatorEvent {
  const SalaryCalculatorAllowanceChanged({
    required this.type,
    required this.amount,
  });

  final SalaryAllowanceType type;
  final double amount;

  @override
  List<Object?> get props => [type, amount];
}

class SalaryCalculatorWorkingDaysChanged extends SalaryCalculatorEvent {
  const SalaryCalculatorWorkingDaysChanged(this.workingDays);

  final int workingDays;

  @override
  List<Object?> get props => [workingDays];
}

class SalaryCalculatorAnnualBonusChanged extends SalaryCalculatorEvent {
  const SalaryCalculatorAnnualBonusChanged(this.annualBonus);

  final double annualBonus;

  @override
  List<Object?> get props => [annualBonus];
}

class SalaryCalculatorPensionRateChanged extends SalaryCalculatorEvent {
  const SalaryCalculatorPensionRateChanged(this.pensionRate);

  final double pensionRate;

  @override
  List<Object?> get props => [pensionRate];
}

class SalaryCalculatorSubmitted extends SalaryCalculatorEvent {
  const SalaryCalculatorSubmitted();
}

class SalaryCalculatorReset extends SalaryCalculatorEvent {
  const SalaryCalculatorReset();
}
