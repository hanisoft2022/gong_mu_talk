import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/teacher_profile.dart';
import 'package:gong_mu_talk/features/calculator/domain/usecases/calculate_lifetime_salary_usecase.dart';
import 'package:gong_mu_talk/features/calculator/domain/usecases/calculate_pension_usecase.dart';
import 'package:gong_mu_talk/features/calculator/presentation/cubit/calculator_state.dart';

class CalculatorCubit extends Cubit<CalculatorState> {
  final CalculateLifetimeSalaryUseCase _calculateLifetimeSalaryUseCase;
  final CalculatePensionUseCase _calculatePensionUseCase;

  CalculatorCubit({
    required CalculateLifetimeSalaryUseCase calculateLifetimeSalaryUseCase,
    required CalculatePensionUseCase calculatePensionUseCase,
  })  : _calculateLifetimeSalaryUseCase = calculateLifetimeSalaryUseCase,
        _calculatePensionUseCase = calculatePensionUseCase,
        super(const CalculatorState());

  /// 교사 프로필 저장
  void saveProfile(TeacherProfile profile) {
    emit(state.copyWith(
      profile: profile,
      isDataEntered: true,
    ));

    // 자동으로 계산 실행
    calculate();
  }

  /// 급여 및 연금 계산 실행
  Future<void> calculate() async {
    if (state.profile == null) return;

    try {
      emit(state.copyWith(isLoading: true, errorMessage: null));

      // 1. 생애 급여 계산
      final lifetimeSalary = _calculateLifetimeSalaryUseCase(
        profile: state.profile!,
      );

      // 2. 평균 기준소득 계산 (연도별 급여의 평균)
      final avgBaseIncome = lifetimeSalary.annualSalaries.isEmpty
          ? 0
          : (lifetimeSalary.annualSalaries
                      .map((e) => e.basePay)
                      .reduce((a, b) => a + b) /
                  lifetimeSalary.annualSalaries.length)
              .round();

      // 3. 연금 계산
      final pensionEstimate = _calculatePensionUseCase(
        profile: state.profile!,
        avgBaseIncome: avgBaseIncome,
      );

      emit(state.copyWith(
        lifetimeSalary: lifetimeSalary,
        pensionEstimate: pensionEstimate,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: '계산 중 오류가 발생했습니다: ${e.toString()}',
      ));
    }
  }

  /// 프로필 초기화
  void clearProfile() {
    emit(const CalculatorState());
  }
}
