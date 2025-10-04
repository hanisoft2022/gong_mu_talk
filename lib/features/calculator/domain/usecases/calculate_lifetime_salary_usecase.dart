import 'package:gong_mu_talk/features/calculator/domain/entities/lifetime_salary.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/teacher_profile.dart';
import 'package:gong_mu_talk/features/calculator/domain/services/salary_calculation_service.dart';

/// 생애 급여 계산 UseCase
class CalculateLifetimeSalaryUseCase {
  final SalaryCalculationService _salaryService;

  CalculateLifetimeSalaryUseCase(this._salaryService);

  /// 생애 급여 계산 실행
  LifetimeSalary call({
    required TeacherProfile profile,
    double? customInflationRate,
  }) {
    return _salaryService.calculateLifetimeSalary(
      profile: profile,
      inflationRate: customInflationRate ?? 0.025,
    );
  }
}
