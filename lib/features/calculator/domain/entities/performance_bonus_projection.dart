import 'dart:math';

/// 성과상여금 미래 예측 계산 클래스
///
/// 교원 성과상여금의 미래 가치를 물가상승률을 반영하여 예측합니다.
/// A등급 기준 고정, 차등지급률 50% 기준으로 계산됩니다.
class PerformanceBonusProjection {
  /// 기준 연도
  static const int baseYear = 2025;

  /// A등급 기준 금액 (2025년)
  static const int baseAmountGradeA = 4273220;

  /// 물가상승률 (연 2.3%)
  static const double inflationRate = 0.023;

  /// 차등지급률 (50% 고정)
  static const double differentialPaymentRate = 0.50;

  /// 미래 특정 연도의 성과상여금 예측
  ///
  /// [targetYear]: 예측할 연도 (예: 2030, 2040)
  /// 반환값: 예상 성과상여금 (원 단위, 천원 미만 절사)
  ///
  /// 계산식: baseAmountGradeA × (1.023)^(targetYear - baseYear)
  ///
  /// 예시:
  /// - 2030년 (5년 후): 4,273,220 × 1.023^5 ≈ 4,791,000원
  /// - 2040년 (15년 후): 4,273,220 × 1.023^15 ≈ 6,054,000원
  int calculateFutureBonus({required int targetYear}) {
    if (targetYear < baseYear) {
      throw ArgumentError('targetYear는 $baseYear 이상이어야 합니다.');
    }

    final yearDiff = targetYear - baseYear;
    final futureAmount = baseAmountGradeA * pow(1 + inflationRate, yearDiff);

    // 소수점만 반올림
    return futureAmount.round();
  }

  /// 특정 기간 동안의 성과상여금 총합 계산
  ///
  /// [startYear]: 시작 연도
  /// [endYear]: 종료 연도 (포함)
  /// 반환값: 해당 기간 동안의 성과상여금 총액
  ///
  /// 각 연도별 예측값을 합산합니다.
  int calculatePeriodTotal({
    required int startYear,
    required int endYear,
  }) {
    if (startYear > endYear) {
      throw ArgumentError('startYear는 endYear보다 작거나 같아야 합니다.');
    }

    int total = 0;
    for (int year = startYear; year <= endYear; year++) {
      total += calculateFutureBonus(targetYear: year);
    }
    return total;
  }

  /// 특정 연도의 성과상여금 세부 정보 반환
  ///
  /// [targetYear]: 조회할 연도
  /// 반환값: 성과상여금 정보 맵
  Map<String, dynamic> getBonusInfo({required int targetYear}) {
    final amount = calculateFutureBonus(targetYear: targetYear);
    final yearDiff = targetYear - baseYear;

    return {
      'year': targetYear,
      'amount': amount,
      'yearDiff': yearDiff,
      'inflationRate': inflationRate,
      'grade': 'A',
      'differentialPaymentRate': differentialPaymentRate,
    };
  }
}
