import 'package:equatable/equatable.dart';

import 'annual_salary.dart';
import 'monthly_salary.dart';

class TeacherSalaryProfile extends Equatable {
  const TeacherSalaryProfile({
    required this.currentYear,
    required this.currentSalary,
    required this.retirementYear,
    this.annualPerformanceBonus = 0,
    this.annualHolidayBonus = 0,
    this.semiAnnualLongevity = 0,
    this.projectedRaiseRate = 0.02,
    this.allowanceGrowthRate = 0.01,
    this.projection = const <AnnualSalary>[],
  });

  final int currentYear;
  final MonthlySalary currentSalary;
  final int retirementYear;
  final double annualPerformanceBonus;
  final double annualHolidayBonus;
  final double semiAnnualLongevity;
  final double projectedRaiseRate;
  final double allowanceGrowthRate;
  final List<AnnualSalary> projection;

  int get remainingYears => (retirementYear - currentYear).clamp(0, 80);

  double get currentGrossAnnual =>
      currentSalary.totalAllowances * 12 +
      annualPerformanceBonus +
      annualHolidayBonus +
      semiAnnualLongevity;

  double get currentNetAnnual =>
      currentSalary.netPay * 12 +
      (annualPerformanceBonus + annualHolidayBonus + semiAnnualLongevity) *
          (1 - currentSalary.deductionRatio * 0.2);

  TeacherSalaryProfile withProjection({
    double? raiseRate,
    double? allowanceGrowth,
  }) {
    final double nextRaiseRate = raiseRate ?? projectedRaiseRate;
    final double nextAllowanceGrowth = allowanceGrowth ?? allowanceGrowthRate;
    final List<AnnualSalary> nextProjection = _buildProjection(
      raiseRate: nextRaiseRate,
      allowanceGrowth: nextAllowanceGrowth,
    );
    return copyWith(
      projectedRaiseRate: nextRaiseRate,
      allowanceGrowthRate: nextAllowanceGrowth,
      projection: nextProjection,
    );
  }

  List<AnnualSalary> _buildProjection({
    required double raiseRate,
    required double allowanceGrowth,
  }) {
    final List<AnnualSalary> results = <AnnualSalary>[];
    double base = currentSalary.basePay.toDouble();
    double allowances = (currentSalary.totalAllowances - currentSalary.basePay)
        .toDouble();
    double deductionRatio = currentSalary.deductionRatio;

    double performance = annualPerformanceBonus.toDouble();
    double holiday = annualHolidayBonus.toDouble();
    double longevity = semiAnnualLongevity.toDouble();

    for (int year = currentYear; year <= retirementYear; year++) {
      if (year > currentYear) {
        base *= 1 + raiseRate;
        allowances *= 1 + allowanceGrowth;
        performance *= 1 + allowanceGrowth;
        holiday *= 1 + allowanceGrowth;
        longevity *= 1 + allowanceGrowth;
      }

      final double monthlyGross = base + allowances;
      final double monthlyNet = monthlyGross * (1 - deductionRatio);

      final double annualGross =
          monthlyGross * 12 + performance + holiday + longevity;
      final double annualNet =
          monthlyNet * 12 +
          (performance + holiday + longevity) * (1 - deductionRatio * 0.25);

      results.add(AnnualSalary(year: year, gross: annualGross, net: annualNet));
    }

    return List<AnnualSalary>.unmodifiable(results);
  }

  double get projectedLifetimeGross => projection.fold<double>(
    0,
    (double total, AnnualSalary entry) => total + entry.gross,
  );

  double get projectedLifetimeNet => projection.fold<double>(
    0,
    (double total, AnnualSalary entry) => total + entry.net,
  );

  TeacherSalaryProfile copyWith({
    int? currentYear,
    MonthlySalary? currentSalary,
    int? retirementYear,
    double? annualPerformanceBonus,
    double? annualHolidayBonus,
    double? semiAnnualLongevity,
    double? projectedRaiseRate,
    double? allowanceGrowthRate,
    List<AnnualSalary>? projection,
  }) {
    return TeacherSalaryProfile(
      currentYear: currentYear ?? this.currentYear,
      currentSalary: currentSalary ?? this.currentSalary,
      retirementYear: retirementYear ?? this.retirementYear,
      annualPerformanceBonus:
          annualPerformanceBonus ?? this.annualPerformanceBonus,
      annualHolidayBonus: annualHolidayBonus ?? this.annualHolidayBonus,
      semiAnnualLongevity: semiAnnualLongevity ?? this.semiAnnualLongevity,
      projectedRaiseRate: projectedRaiseRate ?? this.projectedRaiseRate,
      allowanceGrowthRate: allowanceGrowthRate ?? this.allowanceGrowthRate,
      projection: projection ?? this.projection,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    currentYear,
    currentSalary,
    retirementYear,
    annualPerformanceBonus,
    annualHolidayBonus,
    semiAnnualLongevity,
    projectedRaiseRate,
    allowanceGrowthRate,
    projection,
  ];
}
