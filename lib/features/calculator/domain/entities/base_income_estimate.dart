import 'package:equatable/equatable.dart';

/// 기준소득월액 추정 정보
class BaseIncomeEstimate extends Equatable {
  const BaseIncomeEstimate({
    required this.grossIncome,
    required this.excludedPerformance,
    required this.excludedOvertime,
    required this.excludedResearch,
    required this.excludedMeal,
    required this.includedAvgPerformance,
    required this.includedAvgOvertime,
    required this.includedYearEndBonus,
    required this.baseIncome,
  });

  /// 총 급여 (세전)
  final int grossIncome;

  /// 제외: 성과급
  final int excludedPerformance;

  /// 제외: 시간외근무수당 (정액+초과)
  final int excludedOvertime;

  /// 제외: 연구비
  final int excludedResearch;

  /// 제외: 식대보조비
  final int excludedMeal;

  /// 포함: 성과급 평균액
  final int includedAvgPerformance;

  /// 포함: 시간외 평균액
  final int includedAvgOvertime;

  /// 포함: 연가보상 평균액
  final int includedYearEndBonus;

  /// 최종 기준소득월액
  final int baseIncome;

  /// 총 제외액
  int get totalExcluded =>
      excludedPerformance + excludedOvertime + excludedResearch + excludedMeal;

  /// 총 포함액
  int get totalIncluded =>
      includedAvgPerformance + includedAvgOvertime + includedYearEndBonus;

  @override
  List<Object?> get props => [
    grossIncome,
    excludedPerformance,
    excludedOvertime,
    excludedResearch,
    excludedMeal,
    includedAvgPerformance,
    includedAvgOvertime,
    includedYearEndBonus,
    baseIncome,
  ];

  BaseIncomeEstimate copyWith({
    int? grossIncome,
    int? excludedPerformance,
    int? excludedOvertime,
    int? excludedResearch,
    int? excludedMeal,
    int? includedAvgPerformance,
    int? includedAvgOvertime,
    int? includedYearEndBonus,
    int? baseIncome,
  }) {
    return BaseIncomeEstimate(
      grossIncome: grossIncome ?? this.grossIncome,
      excludedPerformance: excludedPerformance ?? this.excludedPerformance,
      excludedOvertime: excludedOvertime ?? this.excludedOvertime,
      excludedResearch: excludedResearch ?? this.excludedResearch,
      excludedMeal: excludedMeal ?? this.excludedMeal,
      includedAvgPerformance:
          includedAvgPerformance ?? this.includedAvgPerformance,
      includedAvgOvertime: includedAvgOvertime ?? this.includedAvgOvertime,
      includedYearEndBonus: includedYearEndBonus ?? this.includedYearEndBonus,
      baseIncome: baseIncome ?? this.baseIncome,
    );
  }
}
