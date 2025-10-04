import 'package:intl/intl.dart';

/// 숫자 포맷팅 유틸리티
class NumberFormatter {
  /// 통화 형식으로 변환 (예: 1,234,567원)
  static String formatCurrency(int amount) {
    final formatter = NumberFormat('#,###', 'ko_KR');
    return '${formatter.format(amount)}원';
  }

  /// 통화 형식으로 변환 (만원 단위, 예: 123만원)
  static String formatCurrencyCompact(int amount) {
    if (amount >= 100000000) {
      // 1억 이상
      final eok = amount ~/ 100000000;
      final man = (amount % 100000000) ~/ 10000;
      if (man > 0) {
        return '$eok억 ${man}만원';
      }
      return '$eok억원';
    } else if (amount >= 10000) {
      // 1만 이상
      final man = amount ~/ 10000;
      final remainder = amount % 10000;
      if (remainder > 0) {
        return '${formatNumber(man)}만 ${formatNumber(remainder)}원';
      }
      return '${formatNumber(man)}만원';
    }
    return '${formatNumber(amount)}원';
  }

  /// 숫자에 천 단위 콤마 추가
  static String formatNumber(int number) {
    final formatter = NumberFormat('#,###', 'ko_KR');
    return formatter.format(number);
  }

  /// 퍼센트 형식으로 변환
  static String formatPercent(double value, {int decimalPlaces = 1}) {
    return '${(value * 100).toStringAsFixed(decimalPlaces)}%';
  }

  /// 소수점 형식으로 변환
  static String formatDecimal(double value, {int decimalPlaces = 2}) {
    return value.toStringAsFixed(decimalPlaces);
  }
}
