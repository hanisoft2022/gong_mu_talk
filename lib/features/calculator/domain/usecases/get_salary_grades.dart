import '../entities/salary_grade_option.dart';
import '../entities/salary_track.dart';
import '../repositories/salary_reference_repository.dart';

class GetSalaryGradesUseCase {
  const GetSalaryGradesUseCase({required SalaryReferenceRepository repository})
    : _repository = repository;

  final SalaryReferenceRepository _repository;

  Future<List<SalaryGradeOption>> call({
    required SalaryTrack track,
    required int year,
  }) {
    return _repository.fetchGrades(track: track, year: year);
  }
}
