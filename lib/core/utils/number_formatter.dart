// Number formatting utilities
//
// Provides compact number formatting for UI display to prevent overflow
// Combines manual implementation and intl package for flexibility

import 'package:intl/intl.dart';

/// Format large numbers into compact form (1K, 1M, etc.)
///
/// Examples:
/// - 0-999: "0", "42", "999"
/// - 1,000-9,999: "1.2K", "9.9K"
/// - 10,000-99,999: "12K", "99K"
/// - 100,000-999,999: "123K", "999K"
/// - 1,000,000+: "1.2M", "12M", etc.
String formatCompactNumber(int number) {
  if (number < 1000) {
    return number.toString();
  } else if (number < 10000) {
    // 1.0K ~ 9.9K
    final double thousands = number / 1000.0;
    return '${thousands.toStringAsFixed(1)}K';
  } else if (number < 1000000) {
    // 10K ~ 999K
    final int thousands = (number / 1000).round();
    return '${thousands}K';
  } else if (number < 10000000) {
    // 1.0M ~ 9.9M
    final double millions = number / 1000000.0;
    return '${millions.toStringAsFixed(1)}M';
  } else {
    // 10M+
    final int millions = (number / 1000000).round();
    return '${millions}M';
  }
}

/// NumberFormatter class providing static formatting methods
///
/// This class consolidates all number formatting functionality,
/// combining manual implementation and intl package for optimal flexibility.
///
/// Replaces the deprecated CurrencyFormatter (lib/common/utils/currency_formatter.dart)
class NumberFormatter {
  // Private formatters for intl-based formatting
  static final NumberFormat _wonFormatter = NumberFormat.currency(
    locale: 'ko_KR',
    symbol: '₩',
    decimalDigits: 0,
  );

  static final NumberFormat _numberFormatter = NumberFormat.decimalPattern('ko_KR');

  /// Format number with thousands separators (e.g., 1,234,567)
  ///
  /// Manual implementation for lightweight formatting without intl package.
  static String format(int? number) {
    if (number == null) return '-';

    final String numStr = number.toString();
    final StringBuffer result = StringBuffer();
    final int length = numStr.length;

    for (int i = 0; i < length; i++) {
      if (i > 0 && (length - i) % 3 == 0) {
        result.write(',');
      }
      result.write(numStr[i]);
    }

    return result.toString();
  }

  /// Format number as currency with won symbol (e.g., 1,234,567원)
  ///
  /// This is the primary currency formatting method used throughout the app.
  static String formatCurrency(int? number) {
    if (number == null) return '-';
    return '${format(number)}원';
  }

  /// Format number with won currency symbol (e.g., ₩1,234,567)
  ///
  /// Uses intl package for localized formatting.
  static String formatWon(int? number) {
    if (number == null) return '-';
    return _wonFormatter.format(number);
  }

  /// Format number with thousands separator (e.g., 1,234,567)
  ///
  /// Uses intl package for localized formatting.
  /// Alternative to format() method.
  static String formatNumber(num value) {
    return _numberFormatter.format(value);
  }

  /// Format number as percentage (e.g., 15.5%)
  static String formatPercent(double? number, {int decimals = 1}) {
    if (number == null) return '-';
    return '${number.toStringAsFixed(decimals)}%';
  }

  /// Format number as percentage from decimal (e.g., 0.155 → 15.5%)
  ///
  /// Multiplies by 100 before formatting.
  static String formatPercentFromDecimal(double value, {int decimals = 1}) {
    final double percent = value * 100;
    return '${percent.toStringAsFixed(decimals)}%';
  }

  /// Format compact number (delegates to formatCompactNumber)
  static String formatCompact(int number) {
    return formatCompactNumber(number);
  }
}
