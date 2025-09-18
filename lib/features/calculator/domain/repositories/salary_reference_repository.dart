import '../entities/salary_grade_option.dart';
import '../entities/salary_track.dart';

abstract class SalaryReferenceRepository {
  Future<List<SalaryGradeOption>> fetchGrades({
    required SalaryTrack track,
    required int year,
  });

  Future<double?> fetchBaseSalary({
    required SalaryTrack track,
    required int year,
    required String gradeId,
    required int step,
  });
}
