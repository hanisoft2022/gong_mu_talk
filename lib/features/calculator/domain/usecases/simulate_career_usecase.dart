import 'package:injectable/injectable.dart';

import '../entities/career_event.dart';
import '../entities/career_simulation_result.dart';
import '../entities/salary_input.dart';
import '../services/career_simulation_engine.dart';

/// 경력 시뮬레이션 Use Case
@lazySingleton
class SimulateCareerUseCase {
  SimulateCareerUseCase({
    required CareerSimulationEngine engine,
  }) : _engine = engine;

  final CareerSimulationEngine _engine;

  /// 단일 시나리오 시뮬레이션
  Future<CareerSimulationResult> call({
    required SalaryInput initialInput,
    required CareerScenario scenario,
    required int birthYear,
    required int retirementYear,
  }) {
    return _engine.simulate(
      initialInput: initialInput,
      scenario: scenario,
      birthYear: birthYear,
      retirementYear: retirementYear,
    );
  }

  /// 여러 시나리오 비교
  Future<List<CareerSimulationResult>> compareScenarios({
    required SalaryInput initialInput,
    required List<CareerScenario> scenarios,
    required int birthYear,
    required int retirementYear,
  }) {
    return _engine.compareScenarios(
      initialInput: initialInput,
      scenarios: scenarios,
      birthYear: birthYear,
      retirementYear: retirementYear,
    );
  }
}
