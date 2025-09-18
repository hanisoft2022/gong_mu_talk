import '../../domain/entities/salary_grade_option.dart';
import '../../domain/entities/salary_track.dart';
import '../../domain/repositories/salary_reference_repository.dart';
import '../datasources/salary_reference_local_data_source.dart';

class SalaryReferenceRepositoryImpl implements SalaryReferenceRepository {
  SalaryReferenceRepositoryImpl({required SalaryReferenceLocalDataSource dataSource})
      : _dataSource = dataSource;

  final SalaryReferenceLocalDataSource _dataSource;

  @override
  Future<List<SalaryGradeOption>> fetchGrades({
    required SalaryTrack track,
    required int year,
  }) {
    return _dataSource.fetchGrades(track: track, year: year);
  }

  @override
  Future<double?> fetchBaseSalary({
    required SalaryTrack track,
    required int year,
    required String gradeId,
    required int step,
  }) {
    return _dataSource.fetchBaseSalary(
      track: track,
      year: year,
      gradeId: gradeId,
      step: step,
    );
  }
}
