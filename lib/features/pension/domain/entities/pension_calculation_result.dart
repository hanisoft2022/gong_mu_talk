import 'package:equatable/equatable.dart';

/// 연금 계산 결과
class PensionCalculationResult extends Equatable {
  const PensionCalculationResult({
    required this.monthlyPension,
    required this.yearlyPension,
    required this.lifetimeTotal,
    required this.paymentRate,
    required this.earlyRetirementReduction,
    required this.lumpSumOption,
    required this.yearlyProjection,
    this.notes = const [],
  });

  /// 월 연금액
  final double monthlyPension;

  /// 연 연금액
  final double yearlyPension;

  /// 평생 연금 총액 (현재가치)
  final double lifetimeTotal;

  /// 지급률 (재직기간 기반)
  final double paymentRate;

  /// 조기퇴직 감액률
  final double earlyRetirementReduction;

  /// 일시금 선택 시 금액
  final PensionLumpSumOption lumpSumOption;

  /// 연도별 연금 수급 예상
  final List<YearlyPensionProjection> yearlyProjection;

  /// 참고사항
  final List<String> notes;

  @override
  List<Object?> get props => [
        monthlyPension,
        yearlyPension,
        lifetimeTotal,
        paymentRate,
        earlyRetirementReduction,
        lumpSumOption,
        yearlyProjection,
        notes,
      ];
}

/// 일시금 옵션
class PensionLumpSumOption extends Equatable {
  const PensionLumpSumOption({
    required this.totalAmount,
    required this.returnedContributions,
    required this.additionalAmount,
    required this.description,
  });

  /// 일시금 총액
  final double totalAmount;

  /// 본인 기여금 반환액
  final double returnedContributions;

  /// 추가 지급액
  final double additionalAmount;

  /// 설명
  final String description;

  @override
  List<Object?> get props => [
        totalAmount,
        returnedContributions,
        additionalAmount,
        description,
      ];
}

/// 연도별 연금 수급 예상
class YearlyPensionProjection extends Equatable {
  const YearlyPensionProjection({
    required this.year,
    required this.age,
    required this.monthlyAmount,
    required this.yearlyAmount,
    required this.cumulativeTotal,
  });

  /// 연도
  final int year;

  /// 나이
  final int age;

  /// 월 수급액 (물가상승 반영)
  final double monthlyAmount;

  /// 연 수급액
  final double yearlyAmount;

  /// 누적 총액
  final double cumulativeTotal;

  @override
  List<Object?> get props => [
        year,
        age,
        monthlyAmount,
        yearlyAmount,
        cumulativeTotal,
      ];
}

/// 연금 vs 일시금 비교 결과
class PensionVsLumpSumComparison extends Equatable {
  const PensionVsLumpSumComparison({
    required this.lumpSum,
    required this.pensionLifetimeTotal,
    required this.breakEvenAge,
    required this.recommendation,
  });

  /// 일시금 총액
  final double lumpSum;

  /// 연금 평생 총액
  final double pensionLifetimeTotal;

  /// 손익분기 연령
  /// 연금 누적액이 일시금을 초과하는 나이
  final int breakEvenAge;

  /// 추천 (연금 or 일시금)
  final String recommendation;

  @override
  List<Object?> get props => [
        lumpSum,
        pensionLifetimeTotal,
        breakEvenAge,
        recommendation,
      ];
}
