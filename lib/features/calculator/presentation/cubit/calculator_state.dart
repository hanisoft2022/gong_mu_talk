import 'package:equatable/equatable.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/lifetime_salary.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/pension_estimate.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/teacher_profile.dart';

class CalculatorState extends Equatable {
  const CalculatorState({
    this.profile,
    this.lifetimeSalary,
    this.pensionEstimate,
    this.isLoading = false,
    this.errorMessage,
    this.isDataEntered = false,
  });

  /// 교사 프로필 (입력 정보)
  final TeacherProfile? profile;

  /// 생애 급여 계산 결과
  final LifetimeSalary? lifetimeSalary;

  /// 연금 예상액
  final PensionEstimate? pensionEstimate;

  /// 로딩 상태
  final bool isLoading;

  /// 에러 메시지
  final String? errorMessage;

  /// 데이터 입력 완료 여부
  final bool isDataEntered;

  /// 계산 가능 여부
  bool get canCalculate => profile != null;

  @override
  List<Object?> get props => [
        profile,
        lifetimeSalary,
        pensionEstimate,
        isLoading,
        errorMessage,
        isDataEntered,
      ];

  CalculatorState copyWith({
    TeacherProfile? profile,
    LifetimeSalary? lifetimeSalary,
    PensionEstimate? pensionEstimate,
    bool? isLoading,
    String? errorMessage,
    bool? isDataEntered,
  }) {
    return CalculatorState(
      profile: profile ?? this.profile,
      lifetimeSalary: lifetimeSalary ?? this.lifetimeSalary,
      pensionEstimate: pensionEstimate ?? this.pensionEstimate,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      isDataEntered: isDataEntered ?? this.isDataEntered,
    );
  }
}
