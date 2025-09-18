import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/salary_allowance_type.dart';
import '../../domain/entities/salary_breakdown.dart';
import '../../domain/entities/salary_input.dart';
import '../../domain/usecases/calculate_salary.dart';

part 'salary_calculator_event.dart';
part 'salary_calculator_state.dart';

class SalaryCalculatorBloc extends Bloc<SalaryCalculatorEvent, SalaryCalculatorState> {
  SalaryCalculatorBloc({required CalculateSalaryUseCase calculateSalary})
      : _calculateSalary = calculateSalary,
        super(SalaryCalculatorState.initial()) {
    on<SalaryCalculatorBaseSalaryChanged>(_onBaseSalaryChanged);
    on<SalaryCalculatorAllowanceChanged>(_onAllowanceChanged);
    on<SalaryCalculatorWorkingDaysChanged>(_onWorkingDaysChanged);
    on<SalaryCalculatorAnnualBonusChanged>(_onAnnualBonusChanged);
    on<SalaryCalculatorPensionRateChanged>(_onPensionRateChanged);
    on<SalaryCalculatorSubmitted>(_onSubmitted);
    on<SalaryCalculatorReset>(_onResetRequested);
  }

  final CalculateSalaryUseCase _calculateSalary;

  void _onBaseSalaryChanged(
    SalaryCalculatorBaseSalaryChanged event,
    Emitter<SalaryCalculatorState> emit,
  ) {
    emit(
      state.copyWith(
        status: SalaryCalculatorStatus.editing,
        input: state.input.copyWith(baseMonthlySalary: event.baseSalary),
        clearError: true,
      ),
    );
  }

  void _onAllowanceChanged(
    SalaryCalculatorAllowanceChanged event,
    Emitter<SalaryCalculatorState> emit,
  ) {
    final updatedAllowances = Map<SalaryAllowanceType, double>.from(state.input.allowances)
      ..[event.type] = event.amount;

    emit(
      state.copyWith(
        status: SalaryCalculatorStatus.editing,
        input: state.input.copyWith(allowances: updatedAllowances),
        clearError: true,
      ),
    );
  }

  void _onWorkingDaysChanged(
    SalaryCalculatorWorkingDaysChanged event,
    Emitter<SalaryCalculatorState> emit,
  ) {
    final int workingDays = event.workingDays.clamp(1, 31);

    emit(
      state.copyWith(
        status: SalaryCalculatorStatus.editing,
        input: state.input.copyWith(workingDaysPerMonth: workingDays),
        clearError: true,
      ),
    );
  }

  void _onAnnualBonusChanged(
    SalaryCalculatorAnnualBonusChanged event,
    Emitter<SalaryCalculatorState> emit,
  ) {
    emit(
      state.copyWith(
        status: SalaryCalculatorStatus.editing,
        input: state.input.copyWith(annualBonus: event.annualBonus),
        clearError: true,
      ),
    );
  }

  void _onPensionRateChanged(
    SalaryCalculatorPensionRateChanged event,
    Emitter<SalaryCalculatorState> emit,
  ) {
    final double normalizedRate = event.pensionRate.clamp(0.0, 1.0);

    emit(
      state.copyWith(
        status: SalaryCalculatorStatus.editing,
        input: state.input.copyWith(pensionContributionRate: normalizedRate),
        clearError: true,
      ),
    );
  }

  Future<void> _onSubmitted(
    SalaryCalculatorSubmitted event,
    Emitter<SalaryCalculatorState> emit,
  ) async {
    if (state.input.baseMonthlySalary <= 0) {
      emit(
        state.copyWith(
          status: SalaryCalculatorStatus.failure,
          errorMessage: '기본 월급을 입력해주세요.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: SalaryCalculatorStatus.loading,
        clearError: true,
      ),
    );

    try {
      final SalaryBreakdown breakdown = await _calculateSalary(state.input);
      emit(
        state.copyWith(
          status: SalaryCalculatorStatus.success,
          result: breakdown,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: SalaryCalculatorStatus.failure,
          errorMessage: '계산 중 오류가 발생했어요. 다시 시도해주세요.',
        ),
      );
    }
  }

  void _onResetRequested(
    SalaryCalculatorReset event,
    Emitter<SalaryCalculatorState> emit,
  ) {
    emit(SalaryCalculatorState.initial());
  }
}
