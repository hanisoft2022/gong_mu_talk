import 'package:equatable/equatable.dart';

import 'career_event.dart';

/// 경력 시뮬레이션 결과
class CareerSimulationResult extends Equatable {
  const CareerSimulationResult({
    required this.yearlyProjections,
    required this.totalLifetimeGross,
    required this.totalLifetimeNet,
    required this.totalPensionContributions,
    required this.averageMonthlyIncome,
    required this.scenario,
  });

  /// 연도별 예상
  final List<YearlyCareerProjection> yearlyProjections;

  /// 생애 총 세전 소득
  final double totalLifetimeGross;

  /// 생애 총 세후 소득
  final double totalLifetimeNet;

  /// 총 연금 기여금
  final double totalPensionContributions;

  /// 평균 기준소득월액 (연금 계산용)
  final double averageMonthlyIncome;

  /// 적용된 시나리오
  final CareerScenario scenario;

  @override
  List<Object?> get props => [
        yearlyProjections,
        totalLifetimeGross,
        totalLifetimeNet,
        totalPensionContributions,
        averageMonthlyIncome,
        scenario,
      ];
}

/// 연도별 경력 예상
class YearlyCareerProjection extends Equatable {
  const YearlyCareerProjection({
    required this.year,
    required this.age,
    required this.grade,
    required this.step,
    required this.baseSalary,
    required this.monthlyGross,
    required this.monthlyNet,
    required this.yearlyGross,
    required this.yearlyNet,
    required this.pensionContribution,
    required this.cumulativeGross,
    required this.cumulativeNet,
    required this.cumulativePension,
    this.events = const [],
  });

  /// 연도
  final int year;

  /// 나이
  final int age;

  /// 계급
  final String grade;

  /// 호봉
  final int step;

  /// 기본급
  final double baseSalary;

  /// 월 총급여
  final double monthlyGross;

  /// 월 실수령액
  final double monthlyNet;

  /// 연 총급여
  final double yearlyGross;

  /// 연 실수령액
  final double yearlyNet;

  /// 월 연금 기여금
  final double pensionContribution;

  /// 누적 총급여
  final double cumulativeGross;

  /// 누적 실수령액
  final double cumulativeNet;

  /// 누적 연금 기여금
  final double cumulativePension;

  /// 해당 연도의 이벤트
  final List<CareerEvent> events;

  @override
  List<Object?> get props => [
        year,
        age,
        grade,
        step,
        baseSalary,
        monthlyGross,
        monthlyNet,
        yearlyGross,
        yearlyNet,
        pensionContribution,
        cumulativeGross,
        cumulativeNet,
        cumulativePension,
        events,
      ];
}
