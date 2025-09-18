import '../entities/salary_breakdown.dart';
import '../entities/salary_input.dart';
import '../repositories/calculator_repository.dart';

class CalculateSalaryUseCase {
  CalculateSalaryUseCase({required SalaryCalculatorRepository repository})
      : _repository = repository;

  final SalaryCalculatorRepository _repository;

  Future<SalaryBreakdown> call(SalaryInput input) {
    return _repository.calculateSalary(input);
  }
}
