/// Extracted from teacher_salary_insight_page.dart for better file organization
/// This widget displays the annual salary projection chart

library;
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/annual_salary.dart';

class SalaryProjectionChart extends StatelessWidget {
  const SalaryProjectionChart({
    required this.data,
    super.key,
  });

  final List<AnnualSalary> data;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    if (data.length < 2) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            '연도별 추세를 표시하려면 최소 2년 이상의 데이터가 필요합니다.',
            style: theme.textTheme.bodyMedium,
          ),
        ),
      );
    }

    final List<FlSpot> grossSpots = <FlSpot>[];
    final List<FlSpot> netSpots = <FlSpot>[];
    for (int index = 0; index < data.length; index++) {
      final AnnualSalary entry = data[index];
      grossSpots.add(FlSpot(index.toDouble(), entry.gross / 1000000));
      netSpots.add(FlSpot(index.toDouble(), entry.net / 1000000));
    }

    final Color grossColor = theme.colorScheme.primary;
    final Color netColor = theme.colorScheme.secondary;
    final NumberFormat currencyFormat = NumberFormat.currency(
      locale: 'ko_KR',
      symbol: '₩',
      decimalDigits: 0,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '연도별 연봉 추이 (단위: 백만원)',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 280,
              child: LineChart(
                LineChartData(
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: theme.colorScheme.surface.withValues(
                        alpha: 0.94,
                      ),
                      getTooltipItems: (List<LineBarSpot> spots) {
                        return spots
                            .map((LineBarSpot spot) {
                              final int index = spot.x.round().clamp(
                                0,
                                data.length - 1,
                              );
                              final AnnualSalary entry = data[index];
                              final bool isGross = spot.barIndex == 0;
                              final num amount = isGross
                                  ? entry.gross
                                  : entry.net;
                              final Color color = isGross
                                  ? grossColor
                                  : netColor;
                              return LineTooltipItem(
                                '${entry.year}년 ${isGross ? '세전' : '세후'}\n${currencyFormat.format(amount.round())}',
                                TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            })
                            .toList(growable: false);
                      },
                    ),
                  ),
                  minX: 0,
                  maxX: (data.length - 1).toDouble(),
                  minY: 0,
                  lineBarsData: <LineChartBarData>[
                    LineChartBarData(
                      spots: grossSpots,
                      isCurved: true,
                      barWidth: 3,
                      color: grossColor,
                      dotData: const FlDotData(show: false),
                    ),
                    LineChartBarData(
                      spots: netSpots,
                      isCurved: true,
                      barWidth: 3,
                      color: netColor,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: _horizontalInterval(data),
                    getDrawingHorizontalLine: (double value) => FlLine(
                      color: theme.colorScheme.outlineVariant,
                      strokeWidth: 0.6,
                    ),
                    getDrawingVerticalLine: (double value) => FlLine(
                      color: theme.colorScheme.outlineVariant,
                      strokeWidth: 0.6,
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          if (value < 0) {
                            return const SizedBox.shrink();
                          }
                          return Text(value.toStringAsFixed(0));
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: max(1, (data.length / 6).floorToDouble()),
                        getTitlesWidget: (double value, TitleMeta meta) {
                          final int index = value.round();
                          if (index < 0 || index >= data.length) {
                            return const SizedBox.shrink();
                          }
                          final AnnualSalary entry = data[index];
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text('${entry.year % 100}년'),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _horizontalInterval(List<AnnualSalary> data) {
    final double maxValue = data
        .map((AnnualSalary entry) => entry.gross / 1000000)
        .fold<double>(0, max);
    if (maxValue == 0) {
      return 10;
    }
    final double roughInterval = maxValue / 5;
    return max(5, roughInterval.roundToDouble());
  }
}
