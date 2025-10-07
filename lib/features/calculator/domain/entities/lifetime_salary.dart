import 'package:equatable/equatable.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/annual_salary.dart';

/// 생애 급여 정보
class LifetimeSalary extends Equatable {
  const LifetimeSalary({
    required this.annualSalaries,
    required this.totalIncome,
    required this.presentValue,
    required this.avgAnnualSalary,
    this.inflationRate = 2.5,
  });

  /// 연도별 급여 목록
  final List<AnnualSalary> annualSalaries;

  /// 생애 총 소득 (명목 가치)
  final int totalIncome;

  /// 현재 가치 환산 (실질 가치, 인플레이션 반영)
  final int presentValue;

  /// 평균 연봉
  final int avgAnnualSalary;

  /// 인플레이션율 (연 %)
  final double inflationRate;

  /// 총 근무 년수
  int get totalYears => annualSalaries.length;

  /// 시작 연도
  int get startYear => annualSalaries.isEmpty ? 0 : annualSalaries.first.year;

  /// 종료 연도
  int get endYear => annualSalaries.isEmpty ? 0 : annualSalaries.last.year;

  @override
  List<Object?> get props => [
    annualSalaries,
    totalIncome,
    presentValue,
    avgAnnualSalary,
    inflationRate,
  ];

  LifetimeSalary copyWith({
    List<AnnualSalary>? annualSalaries,
    int? totalIncome,
    int? presentValue,
    int? avgAnnualSalary,
    double? inflationRate,
  }) {
    return LifetimeSalary(
      annualSalaries: annualSalaries ?? this.annualSalaries,
      totalIncome: totalIncome ?? this.totalIncome,
      presentValue: presentValue ?? this.presentValue,
      avgAnnualSalary: avgAnnualSalary ?? this.avgAnnualSalary,
      inflationRate: inflationRate ?? this.inflationRate,
    );
  }
}
