import 'package:equatable/equatable.dart';

/// 연금 예상 수령액
class PensionEstimate extends Equatable {
  const PensionEstimate({
    required this.monthlyPension,
    required this.annualPension,
    required this.totalPension,
    required this.retirementAge,
    this.lifeExpectancy = 85,
    required this.serviceYears,
    required this.avgBaseIncome,
    required this.pensionRate,
    this.totalContribution = 0,
  });

  /// 월 연금액
  final int monthlyPension;

  /// 연간 연금액 (13개월 기준: 월 * 13)
  final int annualPension;

  /// 총 수령 예상액 (기대수명까지)
  final int totalPension;

  /// 퇴직 연령
  final int retirementAge;

  /// 기대수명
  final int lifeExpectancy;

  /// 재직 년수
  final int serviceYears;

  /// 평균 기준소득월액
  final int avgBaseIncome;

  /// 연금 지급률 (0.0 ~ 1.0)
  final double pensionRate;

  /// 기여금 총 납부액
  final int totalContribution;

  /// 수령 예상 년수
  int get receivingYears => lifeExpectancy - retirementAge;

  /// 투자 수익률 (기여금 대비 총 수령액 비율)
  double get returnRate {
    if (totalContribution == 0) return 0.0;
    return (totalPension - totalContribution) / totalContribution;
  }

  @override
  List<Object?> get props => [
        monthlyPension,
        annualPension,
        totalPension,
        retirementAge,
        lifeExpectancy,
        serviceYears,
        avgBaseIncome,
        pensionRate,
        totalContribution,
      ];

  PensionEstimate copyWith({
    int? monthlyPension,
    int? annualPension,
    int? totalPension,
    int? retirementAge,
    int? lifeExpectancy,
    int? serviceYears,
    int? avgBaseIncome,
    double? pensionRate,
    int? totalContribution,
  }) {
    return PensionEstimate(
      monthlyPension: monthlyPension ?? this.monthlyPension,
      annualPension: annualPension ?? this.annualPension,
      totalPension: totalPension ?? this.totalPension,
      retirementAge: retirementAge ?? this.retirementAge,
      lifeExpectancy: lifeExpectancy ?? this.lifeExpectancy,
      serviceYears: serviceYears ?? this.serviceYears,
      avgBaseIncome: avgBaseIncome ?? this.avgBaseIncome,
      pensionRate: pensionRate ?? this.pensionRate,
      totalContribution: totalContribution ?? this.totalContribution,
    );
  }
}
