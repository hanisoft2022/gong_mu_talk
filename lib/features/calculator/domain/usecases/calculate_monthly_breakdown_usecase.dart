import 'package:gong_mu_talk/features/calculator/domain/entities/monthly_net_income.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/teacher_profile.dart';
import 'package:gong_mu_talk/features/calculator/domain/services/monthly_breakdown_service.dart';

/// 월별 실수령액 계산 UseCase
class CalculateMonthlyBreakdownUseCase {
  final MonthlyBreakdownService _service;

  CalculateMonthlyBreakdownUseCase(this._service);

  /// 12개월 실수령액 계산 실행
  ///
  /// [profile] 교사 프로필
  /// [year] 계산 년도
  /// [hasSpouse] 배우자 유무
  /// [numberOfChildren] 자녀 수
  /// [isHomeroom] 담임 여부
  /// [hasPosition] 보직 여부
  ///
  /// Returns: 12개월 실수령액 목록
  List<MonthlyNetIncome> call({
    required TeacherProfile profile,
    required int year,
    required bool hasSpouse,
    required int numberOfChildren,
    bool isHomeroom = false,
    bool hasPosition = false,
  }) {
    return _service.calculateMonthlyBreakdown(
      profile: profile,
      year: year,
      hasSpouse: hasSpouse,
      numberOfChildren: numberOfChildren,
      isHomeroom: isHomeroom,
      hasPosition: hasPosition,
    );
  }

  /// 연간 총 실수령액 계산
  ///
  /// [monthlyIncomes] 월별 실수령액 목록
  ///
  /// Returns: 연간 총 실수령액
  int calculateAnnualNetIncome(List<MonthlyNetIncome> monthlyIncomes) {
    return _service.calculateAnnualNetIncome(monthlyIncomes);
  }

  /// 연간 총 공제액 계산
  ///
  /// [monthlyIncomes] 월별 실수령액 목록
  ///
  /// Returns: 연간 총 공제액
  int calculateAnnualDeductions(List<MonthlyNetIncome> monthlyIncomes) {
    return _service.calculateAnnualDeductions(monthlyIncomes);
  }

  /// 연도별 실수령액 비교
  ///
  /// [profile] 교사 프로필
  /// [startYear] 시작 년도
  /// [endYear] 종료 년도
  /// [hasSpouse] 배우자 유무
  /// [numberOfChildren] 자녀 수
  /// [isHomeroom] 담임 여부
  /// [hasPosition] 보직 여부
  ///
  /// Returns: 연도별 월별 실수령액 맵
  Map<int, List<MonthlyNetIncome>> compareByYear({
    required TeacherProfile profile,
    required int startYear,
    required int endYear,
    required bool hasSpouse,
    required int numberOfChildren,
    bool isHomeroom = false,
    bool hasPosition = false,
  }) {
    final results = <int, List<MonthlyNetIncome>>{};

    for (int year = startYear; year <= endYear; year++) {
      final monthlyIncomes = _service.calculateMonthlyBreakdown(
        profile: profile,
        year: year,
        hasSpouse: hasSpouse,
        numberOfChildren: numberOfChildren,
        isHomeroom: isHomeroom,
        hasPosition: hasPosition,
      );
      results[year] = monthlyIncomes;
    }

    return results;
  }

  /// 월별 평균 실수령액 계산
  ///
  /// [monthlyIncomes] 월별 실수령액 목록
  ///
  /// Returns: 월별 평균 실수령액
  int calculateAverageMonthlyIncome(List<MonthlyNetIncome> monthlyIncomes) {
    if (monthlyIncomes.isEmpty) return 0;

    final total = monthlyIncomes.fold<int>(
      0,
      (sum, income) => sum + income.netIncome,
    );

    return (total / monthlyIncomes.length).round();
  }

  /// 정근수당 지급 월 조회
  ///
  /// [monthlyIncomes] 월별 실수령액 목록
  ///
  /// Returns: 정근수당이 지급된 월 목록
  List<int> getLongevityBonusMonths(List<MonthlyNetIncome> monthlyIncomes) {
    return monthlyIncomes
        .where((income) => income.hasLongevityBonus)
        .map((income) => income.month)
        .toList();
  }
}
