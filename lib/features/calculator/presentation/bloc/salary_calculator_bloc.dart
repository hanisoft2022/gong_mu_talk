import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/salary_allowance_type.dart';
import '../../domain/entities/salary_breakdown.dart';
import '../../domain/entities/salary_grade_option.dart';
import '../../domain/entities/salary_input.dart';
import '../../domain/entities/salary_track.dart';
import '../../domain/usecases/calculate_salary.dart';
import '../../domain/usecases/get_base_salary_from_reference.dart';
import '../../domain/usecases/get_salary_grades.dart';

part 'salary_calculator_event.dart';
part 'salary_calculator_state.dart';

class SalaryCalculatorBloc extends Bloc<SalaryCalculatorEvent, SalaryCalculatorState> {
  SalaryCalculatorBloc({
    required CalculateSalaryUseCase calculateSalary,
    required GetSalaryGradesUseCase getSalaryGrades,
    required GetBaseSalaryFromReferenceUseCase getBaseSalaryFromReference,
  })  : _calculateSalary = calculateSalary,
        _getSalaryGrades = getSalaryGrades,
        _getBaseSalaryFromReference = getBaseSalaryFromReference,
        super(SalaryCalculatorState.initial()) {
    on<SalaryCalculatorReferenceInitialized>(_onReferenceInitialized);
    on<SalaryCalculatorTrackChanged>(_onTrackChanged);
    on<SalaryCalculatorGradeChanged>(_onGradeChanged);
    on<SalaryCalculatorStepChanged>(_onStepChanged);
    on<SalaryCalculatorAppointmentYearChanged>(_onAppointmentYearChanged);
    on<SalaryCalculatorBaseSalaryChanged>(_onBaseSalaryChanged);
    on<SalaryCalculatorAllowanceChanged>(_onAllowanceChanged);
    on<SalaryCalculatorWorkingDaysChanged>(_onWorkingDaysChanged);
    on<SalaryCalculatorAnnualBonusChanged>(_onAnnualBonusChanged);
    on<SalaryCalculatorPensionRateChanged>(_onPensionRateChanged);
    on<SalaryCalculatorSubmitted>(_onSubmitted);
    on<SalaryCalculatorReset>(_onResetRequested);

    add(const SalaryCalculatorReferenceInitialized());
  }

  final CalculateSalaryUseCase _calculateSalary;
  final GetSalaryGradesUseCase _getSalaryGrades;
  final GetBaseSalaryFromReferenceUseCase _getBaseSalaryFromReference;

  Future<void> _onReferenceInitialized(
    SalaryCalculatorReferenceInitialized event,
    Emitter<SalaryCalculatorState> emit,
  ) async {
    await _loadReferenceData(emit);
  }

  Future<void> _onTrackChanged(
    SalaryCalculatorTrackChanged event,
    Emitter<SalaryCalculatorState> emit,
  ) async {
    await _loadReferenceData(
      emit,
      track: event.track,
      gradeId: null,
      preserveBaseOnMissing: false,
    );
  }

  Future<void> _onGradeChanged(
    SalaryCalculatorGradeChanged event,
    Emitter<SalaryCalculatorState> emit,
  ) async {
    await _loadReferenceData(
      emit,
      gradeId: event.gradeId,
    );
  }

  Future<void> _onStepChanged(
    SalaryCalculatorStepChanged event,
    Emitter<SalaryCalculatorState> emit,
  ) async {
    await _loadReferenceData(
      emit,
      step: event.step,
    );
  }

  Future<void> _onAppointmentYearChanged(
    SalaryCalculatorAppointmentYearChanged event,
    Emitter<SalaryCalculatorState> emit,
  ) async {
    await _loadReferenceData(
      emit,
      year: event.year,
    );
  }

  void _onBaseSalaryChanged(
    SalaryCalculatorBaseSalaryChanged event,
    Emitter<SalaryCalculatorState> emit,
  ) {
    emit(
      state.copyWith(
        status: SalaryCalculatorStatus.editing,
        input: state.input
            .copyWith(baseMonthlySalary: event.baseSalary, isAutoCalculated: false),
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
    add(const SalaryCalculatorReferenceInitialized());
  }

  Future<void> _loadReferenceData(
    Emitter<SalaryCalculatorState> emit, {
    SalaryTrack? track,
    String? gradeId,
    int? step,
    int? year,
    bool preserveBaseOnMissing = true,
  }) async {
    final SalaryTrack targetTrack = track ?? state.input.track;
    final int targetYear = year ?? state.input.appointmentYear;
    final String currentGradeId = gradeId ?? state.input.gradeId;
    final int currentStep = step ?? state.input.step;

    emit(
      state.copyWith(
        isReferenceLoading: true,
        input: state.input.copyWith(
          track: targetTrack,
          appointmentYear: targetYear,
          gradeId: currentGradeId,
          step: currentStep,
        ),
      ),
    );

    try {
      final List<SalaryGradeOption> grades = await _getSalaryGrades(
        track: targetTrack,
        year: targetYear,
      );

      String resolvedGradeId = currentGradeId;
      if (grades.where((grade) => grade.id == resolvedGradeId).isEmpty) {
        resolvedGradeId = grades.isNotEmpty ? grades.first.id : currentGradeId;
      }

      int resolvedStep = currentStep;
      SalaryGradeOption? gradeOption;
      for (final option in grades) {
        if (option.id == resolvedGradeId) {
          gradeOption = option;
          break;
        }
      }
      gradeOption ??= grades.isNotEmpty ? grades.first : null;
      if (gradeOption != null) {
        resolvedStep = resolvedStep.clamp(gradeOption.minStep, gradeOption.maxStep);
      }

      double? baseSalary;
      if (gradeOption != null) {
        baseSalary = await _getBaseSalaryFromReference(
          track: targetTrack,
          year: targetYear,
          gradeId: resolvedGradeId,
          step: resolvedStep,
        );
      }

      emit(
        state.copyWith(
          isReferenceLoading: false,
          gradeOptions: grades,
          status: SalaryCalculatorStatus.editing,
          input: state.input.copyWith(
            track: targetTrack,
            appointmentYear: targetYear,
            gradeId: resolvedGradeId,
            step: resolvedStep,
            baseMonthlySalary: baseSalary ??
                (preserveBaseOnMissing ? state.input.baseMonthlySalary : 0),
            isAutoCalculated: baseSalary != null,
          ),
          clearError: baseSalary != null,
          errorMessage: baseSalary == null
              ? '선택한 조건에 해당하는 기준 월급 데이터를 찾지 못했습니다. 수동 입력을 이용해주세요.'
              : null,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          isReferenceLoading: false,
          status: SalaryCalculatorStatus.failure,
          errorMessage: '기준 급여 데이터를 불러오는 중 오류가 발생했습니다.',
        ),
      );
    }
  }
}
