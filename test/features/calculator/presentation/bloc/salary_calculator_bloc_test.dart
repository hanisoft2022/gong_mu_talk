import 'package:flutter_test/flutter_test.dart';

import 'package:gong_mu_talk/features/calculator/domain/entities/salary_breakdown.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/salary_input.dart';
import 'package:gong_mu_talk/features/calculator/domain/repositories/calculator_repository.dart';
import 'package:gong_mu_talk/features/calculator/domain/usecases/calculate_salary.dart';
import 'package:gong_mu_talk/features/calculator/presentation/bloc/salary_calculator_bloc.dart';

void main() {
  late SalaryCalculatorBloc bloc;

  setUp(() {
    final repository = _FakeCalculatorRepository();
    final useCase = CalculateSalaryUseCase(repository: repository);
    bloc = SalaryCalculatorBloc(calculateSalary: useCase);
  });

  tearDown(() {
    bloc.close();
  });

  test('initial state is expected', () {
    expect(bloc.state.status, SalaryCalculatorStatus.initial);
    expect(bloc.state.input.baseMonthlySalary, 0);
  });

  test('emits success when calculation succeeds', () async {
    bloc
      ..add(const SalaryCalculatorBaseSalaryChanged(3_000_000))
      ..add(const SalaryCalculatorSubmitted());

    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(bloc.state.status, SalaryCalculatorStatus.success);
    expect(bloc.state.result.monthlyTotal, 3_000_000);
  });
}

class _FakeCalculatorRepository implements SalaryCalculatorRepository {
  @override
  Future<SalaryBreakdown> calculateSalary(SalaryInput input) async {
    return SalaryBreakdown(
      monthlyTotal: input.baseMonthlySalary,
      dailyRate: 0,
      yearlyTotal: 0,
      allowancesTotal: 0,
      pensionContribution: 0,
      minimumDailyWage: 0,
      minimumWageGap: 0,
      notes: const [],
    );
  }
}
