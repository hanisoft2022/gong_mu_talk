import 'package:gong_mu_talk/features/calculator/domain/entities/early_retirement_bonus.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/teacher_profile.dart';
import 'package:gong_mu_talk/features/calculator/domain/services/early_retirement_calculation_service.dart';

/// 명예퇴직금 계산 UseCase
class CalculateEarlyRetirementUseCase {
  final EarlyRetirementCalculationService _service;

  CalculateEarlyRetirementUseCase(this._service);

  /// 명예퇴직금 계산 실행
  ///
  /// [profile] 교사 프로필
  /// [earlyRetirementDate] 명퇴 예정일 (선택)
  ///
  /// Returns: 명예퇴직금 정보
  EarlyRetirementBonus call({
    required TeacherProfile profile,
    DateTime? earlyRetirementDate,
  }) {
    return _service.calculateEarlyRetirementBonus(
      profile: profile,
      earlyRetirementDate: earlyRetirementDate,
    );
  }

  /// 명퇴 시기별 금액 비교
  ///
  /// [profile] 교사 프로필
  /// [startAge] 시작 연령
  /// [endAge] 종료 연령
  ///
  /// Returns: 연령별 명퇴금 목록
  List<EarlyRetirementBonus> compareScenarios({
    required TeacherProfile profile,
    int? startAge,
    int? endAge,
  }) {
    return _service.compareEarlyRetirementScenarios(
      profile: profile,
      startAge: startAge,
      endAge: endAge,
    );
  }

  /// 명퇴금 월별 적립액 계산
  ///
  /// [totalAmount] 총 명퇴금
  /// [remainingMonths] 잔여 개월수
  ///
  /// Returns: 월별 적립액
  int calculateMonthlyAccumulation({
    required int totalAmount,
    required int remainingMonths,
  }) {
    return _service.calculateMonthlyAccumulation(
      totalAmount: totalAmount,
      remainingMonths: remainingMonths,
    );
  }

  /// 명퇴 vs 정년 총 수령액 비교
  ///
  /// [earlyRetirementBonus] 명퇴금
  /// [earlyRetirementPension] 명퇴 시 연금 (월)
  /// [regularRetirementPension] 정년 시 연금 (월)
  /// [remainingYears] 잔여 년수
  /// [retirementAge] 명퇴 연령
  /// [lifeExpectancy] 기대수명
  ///
  /// Returns: {earlyTotal, regularTotal, difference}
  Map<String, int> compareEarlyVsRegular({
    required int earlyRetirementBonus,
    required int earlyRetirementPension,
    required int regularRetirementPension,
    required int remainingYears,
    required int retirementAge,
    int lifeExpectancy = 85,
  }) {
    return _service.compareEarlyVsRegularRetirement(
      earlyRetirementBonus: earlyRetirementBonus,
      earlyRetirementPension: earlyRetirementPension,
      regularRetirementPension: regularRetirementPension,
      remainingYears: remainingYears,
      retirementAge: retirementAge,
      lifeExpectancy: lifeExpectancy,
    );
  }
}
