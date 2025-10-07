import 'package:equatable/equatable.dart';

/// 퇴직급여 정보 (1~3구간별)
class RetirementBenefit extends Equatable {
  const RetirementBenefit({
    required this.period1Benefit,
    required this.period2Benefit,
    required this.period3Benefit,
    required this.totalBenefit,
    required this.retirementAllowance,
    required this.period1Years,
    required this.period2Years,
    required this.period3Years,
    required this.period1BaseIncome,
    required this.period23BaseIncome,
  });

  /// 1기간(~2009.12.31) 퇴직급여
  final int period1Benefit;

  /// 2기간(2010.1.1~2015.12.31) 퇴직급여
  final int period2Benefit;

  /// 3기간(2016.1.1~) 퇴직급여
  final int period3Benefit;

  /// 총 퇴직급여
  final int totalBenefit;

  /// 퇴직수당
  final int retirementAllowance;

  /// 1기간 경력 년수
  final int period1Years;

  /// 2기간 경력 년수
  final int period2Years;

  /// 3기간 경력 년수
  final int period3Years;

  /// 1기간 적용 보수
  final int period1BaseIncome;

  /// 2~3기간 적용 보수
  final int period23BaseIncome;

  /// 총 재직 년수
  int get totalYears => period1Years + period2Years + period3Years;

  @override
  List<Object?> get props => [
    period1Benefit,
    period2Benefit,
    period3Benefit,
    totalBenefit,
    retirementAllowance,
    period1Years,
    period2Years,
    period3Years,
    period1BaseIncome,
    period23BaseIncome,
  ];

  RetirementBenefit copyWith({
    int? period1Benefit,
    int? period2Benefit,
    int? period3Benefit,
    int? totalBenefit,
    int? retirementAllowance,
    int? period1Years,
    int? period2Years,
    int? period3Years,
    int? period1BaseIncome,
    int? period23BaseIncome,
  }) {
    return RetirementBenefit(
      period1Benefit: period1Benefit ?? this.period1Benefit,
      period2Benefit: period2Benefit ?? this.period2Benefit,
      period3Benefit: period3Benefit ?? this.period3Benefit,
      totalBenefit: totalBenefit ?? this.totalBenefit,
      retirementAllowance: retirementAllowance ?? this.retirementAllowance,
      period1Years: period1Years ?? this.period1Years,
      period2Years: period2Years ?? this.period2Years,
      period3Years: period3Years ?? this.period3Years,
      period1BaseIncome: period1BaseIncome ?? this.period1BaseIncome,
      period23BaseIncome: period23BaseIncome ?? this.period23BaseIncome,
    );
  }
}
