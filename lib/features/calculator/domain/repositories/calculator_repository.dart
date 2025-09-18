import '../entities/salary_breakdown.dart';
import '../entities/salary_input.dart';

abstract class SalaryCalculatorRepository {
  Future<SalaryBreakdown> calculateSalary(SalaryInput input);
}
