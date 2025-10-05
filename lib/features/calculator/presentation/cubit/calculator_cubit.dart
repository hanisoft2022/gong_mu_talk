import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/teacher_profile.dart';
import 'package:gong_mu_talk/features/calculator/domain/usecases/calculate_lifetime_salary_usecase.dart';
import 'package:gong_mu_talk/features/calculator/domain/usecases/calculate_pension_usecase.dart';
import 'package:gong_mu_talk/features/calculator/domain/usecases/calculate_retirement_benefit_usecase.dart';
import 'package:gong_mu_talk/features/calculator/domain/usecases/calculate_early_retirement_usecase.dart';
import 'package:gong_mu_talk/features/calculator/domain/usecases/calculate_after_tax_pension_usecase.dart';
import 'package:gong_mu_talk/features/calculator/domain/usecases/calculate_monthly_breakdown_usecase.dart';
import 'package:gong_mu_talk/features/calculator/domain/services/base_income_estimation_service.dart';
import 'package:gong_mu_talk/features/calculator/presentation/cubit/calculator_state.dart';

class CalculatorCubit extends Cubit<CalculatorState> {
  final CalculateLifetimeSalaryUseCase _calculateLifetimeSalaryUseCase;
  final CalculatePensionUseCase _calculatePensionUseCase;
  final CalculateRetirementBenefitUseCase _calculateRetirementBenefitUseCase;
  final CalculateEarlyRetirementUseCase _calculateEarlyRetirementUseCase;
  final CalculateAfterTaxPensionUseCase _calculateAfterTaxPensionUseCase;
  final CalculateMonthlyBreakdownUseCase _calculateMonthlyBreakdownUseCase;
  final BaseIncomeEstimationService _baseIncomeEstimationService;

  CalculatorCubit({
    required CalculateLifetimeSalaryUseCase calculateLifetimeSalaryUseCase,
    required CalculatePensionUseCase calculatePensionUseCase,
    required CalculateRetirementBenefitUseCase calculateRetirementBenefitUseCase,
    required CalculateEarlyRetirementUseCase calculateEarlyRetirementUseCase,
    required CalculateAfterTaxPensionUseCase calculateAfterTaxPensionUseCase,
    required CalculateMonthlyBreakdownUseCase calculateMonthlyBreakdownUseCase,
    required BaseIncomeEstimationService baseIncomeEstimationService,
  })  : _calculateLifetimeSalaryUseCase = calculateLifetimeSalaryUseCase,
        _calculatePensionUseCase = calculatePensionUseCase,
        _calculateRetirementBenefitUseCase = calculateRetirementBenefitUseCase,
        _calculateEarlyRetirementUseCase = calculateEarlyRetirementUseCase,
        _calculateAfterTaxPensionUseCase = calculateAfterTaxPensionUseCase,
        _calculateMonthlyBreakdownUseCase = calculateMonthlyBreakdownUseCase,
        _baseIncomeEstimationService = baseIncomeEstimationService,
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

      final profile = state.profile!;

      // 1. 생애 급여 계산
      final lifetimeSalary = _calculateLifetimeSalaryUseCase(
        profile: profile,
      );

      // 2. 평균 기준소득 계산 (연도별 급여의 평균)
      final avgBaseIncome = lifetimeSalary.annualSalaries.isEmpty
          ? 0
          : (lifetimeSalary.annualSalaries
                      .map((e) => e.basePay)
                      .reduce((a, b) => a + b) /
                  lifetimeSalary.annualSalaries.length)
              .round();

      // 3. 기준소득월액 추정은 현재 사용하지 않음 (향후 확장 예정)
      // final baseIncomeEstimate = null;

      // 4. 연금 계산
      final pensionEstimate = _calculatePensionUseCase(
        profile: profile,
        avgBaseIncome: avgBaseIncome,
      );

      // 5. 세후 연금 계산
      final afterTaxPension = _calculateAfterTaxPensionUseCase(
        pensionEstimate: pensionEstimate,
        age: profile.retirementAge,
      );

      // 6. 퇴직급여 계산
      final retirementBenefit = _calculateRetirementBenefitUseCase(
        profile: profile,
        avgBaseIncome: avgBaseIncome,
      );

      // 7. 명예퇴직금 계산 (55세 이상 퇴직 시)
      final earlyRetirementBonus = profile.retirementAge >= 55
          ? _calculateEarlyRetirementUseCase(
              profile: profile,
            )
          : null;

      // 8. 월별 실수령액 분석
      final monthlyBreakdown = _calculateMonthlyBreakdownUseCase(
        profile: profile,
        year: DateTime.now().year,
        hasSpouse: profile.hasSpouse,
        numberOfChildren: profile.numberOfChildren,
      );

      emit(state.copyWith(
        lifetimeSalary: lifetimeSalary,
        pensionEstimate: pensionEstimate,
        retirementBenefit: retirementBenefit,
        earlyRetirementBonus: earlyRetirementBonus,
        afterTaxPension: afterTaxPension,
        monthlyBreakdown: monthlyBreakdown,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: '계산 중 오류가 발생했습니다: ${e.toString()}',
      ));
    }
  }

  /// 퇴직급여 재계산
  Future<void> calculateRetirementBenefit() async {
    if (state.profile == null) return;

    try {
      final avgBaseIncome = state.lifetimeSalary?.annualSalaries.isEmpty ?? true
          ? 0
          : (state.lifetimeSalary!.annualSalaries
                      .map((e) => e.basePay)
                      .reduce((a, b) => a + b) /
                  state.lifetimeSalary!.annualSalaries.length)
              .round();

      final retirementBenefit = _calculateRetirementBenefitUseCase(
        profile: state.profile!,
        avgBaseIncome: avgBaseIncome,
      );

      emit(state.copyWith(retirementBenefit: retirementBenefit));
    } catch (e) {
      emit(state.copyWith(
        errorMessage: '퇴직급여 계산 중 오류가 발생했습니다: ${e.toString()}',
      ));
    }
  }

  /// 명예퇴직금 재계산
  Future<void> calculateEarlyRetirement() async {
    if (state.profile == null) return;

    try {
      final earlyRetirementBonus = _calculateEarlyRetirementUseCase(
        profile: state.profile!,
      );

      emit(state.copyWith(earlyRetirementBonus: earlyRetirementBonus));
    } catch (e) {
      emit(state.copyWith(
        errorMessage: '명예퇴직금 계산 중 오류가 발생했습니다: ${e.toString()}',
      ));
    }
  }

  /// 세후 연금 재계산
  Future<void> calculateAfterTaxPension() async {
    if (state.pensionEstimate == null) return;

    try {
      final afterTaxPension = _calculateAfterTaxPensionUseCase(
        pensionEstimate: state.pensionEstimate!,
        age: state.profile?.retirementAge ?? 65,
      );

      emit(state.copyWith(afterTaxPension: afterTaxPension));
    } catch (e) {
      emit(state.copyWith(
        errorMessage: '세후 연금 계산 중 오류가 발생했습니다: ${e.toString()}',
      ));
    }
  }

  /// 월별 실수령액 재계산
  Future<void> calculateMonthlyBreakdown() async {
    if (state.profile == null) return;

    try {
      final monthlyBreakdown = _calculateMonthlyBreakdownUseCase(
        profile: state.profile!,
        year: DateTime.now().year,
        hasSpouse: state.profile!.hasSpouse,
        numberOfChildren: state.profile!.numberOfChildren,
      );

      emit(state.copyWith(monthlyBreakdown: monthlyBreakdown));
    } catch (e) {
      emit(state.copyWith(
        errorMessage: '월별 실수령액 계산 중 오류가 발생했습니다: ${e.toString()}',
      ));
    }
  }

  /// 프로필 초기화
  void clearProfile() {
    emit(const CalculatorState());
  }
}
