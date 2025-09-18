import 'package:flutter_test/flutter_test.dart';

import 'package:gong_mu_talk/features/calculator/domain/entities/salary_breakdown.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/salary_input.dart';
import 'package:gong_mu_talk/features/calculator/domain/repositories/calculator_repository.dart';
import 'package:gong_mu_talk/features/calculator/domain/usecases/calculate_salary.dart';

void main() {
  test('returns breakdown from repository', () async {
    final repository = _FakeCalculatorRepository();
    final useCase = CalculateSalaryUseCase(repository: repository);
    final input = SalaryInput.initial().copyWith(baseMonthlySalary: 3_000_000);

    final result = await useCase(input);

    expect(result.monthlyTotal, 3_000_000);
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
