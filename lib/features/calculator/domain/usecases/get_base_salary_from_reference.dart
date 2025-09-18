import '../entities/salary_track.dart';
import '../repositories/salary_reference_repository.dart';

class GetBaseSalaryFromReferenceUseCase {
  const GetBaseSalaryFromReferenceUseCase({required SalaryReferenceRepository repository})
      : _repository = repository;

  final SalaryReferenceRepository _repository;

  Future<double?> call({
    required SalaryTrack track,
    required int year,
    required String gradeId,
    required int step,
  }) {
    return _repository.fetchBaseSalary(
      track: track,
      year: year,
      gradeId: gradeId,
      step: step,
    );
  }
}
