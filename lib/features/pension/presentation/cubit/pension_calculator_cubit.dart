import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/calculate_pension_usecase.dart';
import 'pension_calculator_state.dart';

/// 연금 계산기 Cubit
class PensionCalculatorCubit extends Cubit<PensionCalculatorState> {
  PensionCalculatorCubit({
    required CalculatePensionUseCase calculatePension,
  })  : _calculatePension = calculatePension,
        super(PensionCalculatorState.initial());

  final CalculatePensionUseCase _calculatePension;

  /// 출생연도 변경
  void updateBirthYear(int year) {
    final updatedProfile = state.profile.copyWith(birthYear: year);
    emit(state.copyWith(profile: updatedProfile, clearResult: true));
  }

  /// 임용연도 변경
  void updateAppointmentYear(int year) {
    final updatedProfile = state.profile.copyWith(appointmentYear: year);
    emit(state.copyWith(profile: updatedProfile, clearResult: true));
  }

  /// 퇴직연도 변경
  void updateRetirementYear(int year) {
    final updatedProfile = state.profile.copyWith(retirementYear: year);
    
    // 재직기간 자동 계산
    final serviceYears = year - state.profile.appointmentYear;
    final updatedProfile2 = updatedProfile.copyWith(
      totalServiceYears: serviceYears > 0 ? serviceYears : 0,
    );
    
    emit(state.copyWith(profile: updatedProfile2, clearResult: true));
  }

  /// 평균 기준소득월액 변경
  void updateAverageMonthlyIncome(double income) {
    final updatedProfile = state.profile.copyWith(
      averageMonthlyIncome: income,
    );
    emit(state.copyWith(profile: updatedProfile, clearResult: true));
  }

  /// 재직기간 변경 (수동)
  void updateServiceYears(int years) {
    final updatedProfile = state.profile.copyWith(totalServiceYears: years);
    emit(state.copyWith(profile: updatedProfile, clearResult: true));
  }

  /// 예상 수명 변경
  void updateExpectedLifespan(int age) {
    final updatedProfile = state.profile.copyWith(expectedLifespan: age);
    emit(state.copyWith(profile: updatedProfile, clearResult: true));
  }

  /// 물가상승률 변경
  void updateInflationRate(double rate) {
    final updatedProfile = state.profile.copyWith(inflationRate: rate);
    emit(state.copyWith(profile: updatedProfile, clearResult: true));
  }

  /// 연금 계산 실행
  void calculate() {
    emit(
      state.copyWith(
        status: PensionCalculatorStatus.calculating,
        clearError: true,
      ),
    );

    try {
      // 입력 유효성 검사
      if (state.profile.averageMonthlyIncome <= 0) {
        emit(
          state.copyWith(
            status: PensionCalculatorStatus.error,
            errorMessage: '평균 기준소득월액을 입력해주세요.',
          ),
        );
        return;
      }

      if (state.profile.totalServiceYears <= 0) {
        emit(
          state.copyWith(
            status: PensionCalculatorStatus.error,
            errorMessage: '재직기간을 입력해주세요.',
          ),
        );
        return;
      }

      // 연금 계산
      final result = _calculatePension(state.profile);

      // 연금 vs 일시금 비교
      final comparison = _calculatePension.comparePensionVsLumpSum(
        profile: state.profile,
        pensionResult: result,
      );

      emit(
        state.copyWith(
          status: PensionCalculatorStatus.success,
          result: result,
          comparison: comparison,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: PensionCalculatorStatus.error,
          errorMessage: '계산 중 오류가 발생했습니다: $error',
        ),
      );
    }
  }

  /// 초기화
  void reset() {
    emit(PensionCalculatorState.initial());
  }
}
