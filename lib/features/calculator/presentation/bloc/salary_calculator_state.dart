part of 'salary_calculator_bloc.dart';

enum SalaryCalculatorStatus { initial, editing, loading, success, failure }

class SalaryCalculatorState extends Equatable {
  const SalaryCalculatorState({
    required this.input,
    required this.result,
    required this.status,
    required this.errorMessage,
  });

  final SalaryInput input;
  final SalaryBreakdown result;
  final SalaryCalculatorStatus status;
  final String? errorMessage;

  factory SalaryCalculatorState.initial() => SalaryCalculatorState(
        input: SalaryInput.initial(),
        result: SalaryBreakdown.empty(),
        status: SalaryCalculatorStatus.initial,
        errorMessage: null,
      );

  SalaryCalculatorState copyWith({
    SalaryInput? input,
    SalaryBreakdown? result,
    SalaryCalculatorStatus? status,
    String? errorMessage,
    bool clearError = false,
  }) {
    final String? resolvedError = clearError
        ? null
        : (errorMessage ?? this.errorMessage);

    return SalaryCalculatorState(
      input: input ?? this.input,
      result: result ?? this.result,
      status: status ?? this.status,
      errorMessage: resolvedError,
    );
  }

  @override
  List<Object?> get props => [input, result, status, errorMessage];
}
