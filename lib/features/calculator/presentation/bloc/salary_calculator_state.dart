part of 'salary_calculator_bloc.dart';

enum SalaryCalculatorStatus { initial, editing, loading, success, failure }

class SalaryCalculatorState extends Equatable {
  const SalaryCalculatorState({
    required this.input,
    required this.result,
    required this.status,
    required this.errorMessage,
    required this.gradeOptions,
    required this.isReferenceLoading,
  });

  final SalaryInput input;
  final SalaryBreakdown result;
  final SalaryCalculatorStatus status;
  final String? errorMessage;
  final List<SalaryGradeOption> gradeOptions;
  final bool isReferenceLoading;

  factory SalaryCalculatorState.initial() => SalaryCalculatorState(
    input: SalaryInput.initial(),
    result: SalaryBreakdown.empty(),
    status: SalaryCalculatorStatus.initial,
    errorMessage: null,
    gradeOptions: const <SalaryGradeOption>[
      SalaryGradeOption(id: '9', name: '9급', minStep: 1, maxStep: 33),
      SalaryGradeOption(id: '8', name: '8급', minStep: 1, maxStep: 33),
    ],
    isReferenceLoading: false,
  );

  SalaryCalculatorState copyWith({
    SalaryInput? input,
    SalaryBreakdown? result,
    SalaryCalculatorStatus? status,
    String? errorMessage,
    bool clearError = false,
    List<SalaryGradeOption>? gradeOptions,
    bool? isReferenceLoading,
  }) {
    final String? resolvedError = clearError
        ? null
        : (errorMessage ?? this.errorMessage);

    return SalaryCalculatorState(
      input: input ?? this.input,
      result: result ?? this.result,
      status: status ?? this.status,
      errorMessage: resolvedError,
      gradeOptions: gradeOptions ?? this.gradeOptions,
      isReferenceLoading: isReferenceLoading ?? this.isReferenceLoading,
    );
  }

  @override
  List<Object?> get props => [
    input,
    result,
    status,
    errorMessage,
    gradeOptions,
    isReferenceLoading,
  ];
}
