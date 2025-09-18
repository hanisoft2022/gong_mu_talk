import '../../domain/entities/salary_breakdown.dart';
import '../../domain/entities/salary_input.dart';
import '../../domain/repositories/calculator_repository.dart';
import '../datasources/calculator_local_data_source.dart';
import '../models/salary_input_dto.dart';

class SalaryCalculatorRepositoryImpl implements SalaryCalculatorRepository {
  SalaryCalculatorRepositoryImpl({required SalaryCalculatorLocalDataSource dataSource})
      : _dataSource = dataSource;

  final SalaryCalculatorLocalDataSource _dataSource;

  @override
  Future<SalaryBreakdown> calculateSalary(SalaryInput input) {
    final SalaryInputDto dto = SalaryInputDto.fromDomain(input);
    return _dataSource.calculate(dto);
  }
}
