import 'package:equatable/equatable.dart';

class SalaryGradeOption extends Equatable {
  const SalaryGradeOption({
    required this.id,
    required this.name,
    required this.minStep,
    required this.maxStep,
  });

  final String id;
  final String name;
  final int minStep;
  final int maxStep;

  @override
  List<Object?> get props => [id, name, minStep, maxStep];
}
