import 'package:flutter_test/flutter_test.dart';

import 'package:gong_mu_talk/features/calculator/domain/entities/salary_breakdown.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/salary_grade_option.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/salary_input.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/salary_track.dart';
import 'package:gong_mu_talk/features/calculator/domain/repositories/calculator_repository.dart';
import 'package:gong_mu_talk/features/calculator/domain/repositories/salary_reference_repository.dart';
import 'package:gong_mu_talk/features/calculator/domain/usecases/calculate_salary.dart';
import 'package:gong_mu_talk/features/calculator/domain/usecases/get_base_salary_from_reference.dart';
import 'package:gong_mu_talk/features/calculator/domain/usecases/get_salary_grades.dart';
import 'package:gong_mu_talk/features/calculator/presentation/bloc/salary_calculator_bloc.dart';

void main() {
  late SalaryCalculatorBloc bloc;

  setUp(() {
    final repository = _FakeCalculatorRepository();
    final referenceRepository = _FakeSalaryReferenceRepository();
    final useCase = CalculateSalaryUseCase(repository: repository);
    final getGrades = GetSalaryGradesUseCase(repository: referenceRepository);
    final getBaseSalary =
        GetBaseSalaryFromReferenceUseCase(repository: referenceRepository);
    bloc = SalaryCalculatorBloc(
      calculateSalary: useCase,
      getSalaryGrades: getGrades,
      getBaseSalaryFromReference: getBaseSalary,
    );
  });

  tearDown(() {
    bloc.close();
  });

  test('initial state is expected', () {
    expect(bloc.state.status, SalaryCalculatorStatus.initial);
    expect(bloc.state.gradeOptions, isNotEmpty);
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

class _FakeSalaryReferenceRepository implements SalaryReferenceRepository {
  @override
  Future<double?> fetchBaseSalary({
    required SalaryTrack track,
    required int year,
    required String gradeId,
    required int step,
  }) async {
    return 2_400_000 + step * 10_000;
  }

  @override
  Future<List<SalaryGradeOption>> fetchGrades({
    required SalaryTrack track,
    required int year,
  }) async {
    return const [
      SalaryGradeOption(id: '9', name: '9급', minStep: 1, maxStep: 33),
      SalaryGradeOption(id: '8', name: '8급', minStep: 1, maxStep: 33),
    ];
  }
}
