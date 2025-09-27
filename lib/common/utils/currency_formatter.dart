import 'package:intl/intl.dart';

final NumberFormat _wonFormatter = NumberFormat.currency(
  locale: 'ko_KR',
  symbol: '₩',
);

String formatCurrency(num value) {
  return _wonFormatter.format(value);
}

String formatNumber(num value) {
  final NumberFormat formatter = NumberFormat.decimalPattern('ko_KR');
  return formatter.format(value);
}

String formatPercent(double value) {
  final double percent = value * 100;
  return '${percent.toStringAsFixed(1)}%';
}
