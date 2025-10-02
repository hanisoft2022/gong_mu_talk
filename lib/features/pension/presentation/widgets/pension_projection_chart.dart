import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/pension_calculation_result.dart';

/// 연금 수급 예상 차트
class PensionProjectionChart extends StatelessWidget {
  const PensionProjectionChart({
    required this.projections,
    super.key,
  });

  final List<YearlyPensionProjection> projections;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (projections.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '연금 수급액 추이',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '물가상승률을 반영한 연도별 예상 수급액',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 250,
              child: LineChart(
                _buildChartData(context),
              ),
            ),
            const SizedBox(height: 16),
            _buildLegend(context),
          ],
        ),
      ),
    );
  }

  LineChartData _buildChartData(BuildContext context) {
    final theme = Theme.of(context);

    // 월 수급액 데이터
    final monthlySpots = projections.asMap().entries.map((entry) {
      return FlSpot(
        entry.key.toDouble(),
        entry.value.monthlyAmount,
      );
    }).toList();

    // 누적 총액 데이터 (스케일 조정)
    final cumulativeSpots = projections.asMap().entries.map((entry) {
      return FlSpot(
        entry.key.toDouble(),
        entry.value.cumulativeTotal / 12, // 월 단위로 스케일 조정
      );
    }).toList();

    final maxY = projections
        .map((p) => p.cumulativeTotal / 12)
        .reduce((a, b) => a > b ? a : b);

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: maxY / 5,
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 60,
            getTitlesWidget: (value, meta) {
              return Text(
                _formatYAxis(value),
                style: const TextStyle(fontSize: 10),
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
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: projections.length > 10 ? 5 : 2,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index >= 0 && index < projections.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${projections[index].age}세',
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border(
          left: BorderSide(color: theme.colorScheme.outline.withAlpha(77)),
          bottom: BorderSide(color: theme.colorScheme.outline.withAlpha(77)),
        ),
      ),
      lineBarsData: [
        // 월 수급액 라인
        LineChartBarData(
          spots: monthlySpots,
          isCurved: true,
          color: theme.colorScheme.primary,
          barWidth: 3,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: theme.colorScheme.primary.withAlpha(26),
          ),
        ),
        // 누적 총액 라인
        LineChartBarData(
          spots: cumulativeSpots,
          isCurved: true,
          color: theme.colorScheme.secondary,
          barWidth: 2,
          dotData: const FlDotData(show: false),
          dashArray: [5, 5],
        ),
      ],
      minY: 0,
      maxY: maxY * 1.1,
    );
  }

  Widget _buildLegend(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(
          context,
          color: theme.colorScheme.primary,
          label: '월 수급액',
          isDashed: false,
        ),
        const SizedBox(width: 24),
        _buildLegendItem(
          context,
          color: theme.colorScheme.secondary,
          label: '누적 총액 (월평균)',
          isDashed: true,
        ),
      ],
    );
  }

  Widget _buildLegendItem(
    BuildContext context, {
    required Color color,
    required String label,
    required bool isDashed,
  }) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
          child: isDashed
              ? CustomPaint(
                  painter: _DashedLinePainter(color: color),
                )
              : null,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  String _formatYAxis(double value) {
    if (value >= 10000000) {
      return '${(value / 10000000).toStringAsFixed(0)}천만';
    } else if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(0)}백만';
    } else if (value >= 10000) {
      return '${(value / 10000).toStringAsFixed(0)}만';
    } else {
      return value.toStringAsFixed(0);
    }
  }
}

class _DashedLinePainter extends CustomPainter {
  _DashedLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    const dashWidth = 3.0;
    const dashSpace = 3.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
