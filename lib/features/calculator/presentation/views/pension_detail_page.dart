import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:gong_mu_talk/core/utils/number_formatter.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/pension_estimate.dart';

/// 예상 연금 수령액 상세 페이지
class PensionDetailPage extends StatelessWidget {
  final PensionEstimate pensionEstimate;

  const PensionDetailPage({
    super.key,
    required this.pensionEstimate,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('예상 연금 수령액'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 연금 계산 결과 카드
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '💰 연금 계산 결과',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      context,
                      '📅 퇴직 예정 연령',
                      '${pensionEstimate.retirementAge}세',
                    ),
                    _buildInfoRow(
                      context,
                      '📊 재직 기간',
                      '${pensionEstimate.serviceYears}년',
                    ),
                    _buildInfoRow(
                      context,
                      '💵 평균 기준소득',
                      NumberFormatter.formatCurrency(pensionEstimate.avgBaseIncome),
                    ),
                    _buildInfoRow(
                      context,
                      '📈 연금 지급률',
                      NumberFormatter.formatPercent(pensionEstimate.pensionRate),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 월 수령액 카드
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      '💎 월 수령액',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      NumberFormatter.formatCurrency(pensionEstimate.monthlyPension),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '연간 ${NumberFormatter.formatCurrency(pensionEstimate.annualPension)} (13개월 기준)',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[700],
                          ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 총 수령 예상액 카드
            Card(
              color: Colors.green[50],
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      '📊 총 수령 예상액',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      NumberFormatter.formatCurrency(pensionEstimate.totalPension),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green[900],
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${pensionEstimate.retirementAge}세~${pensionEstimate.lifeExpectancy}세 (${pensionEstimate.receivingYears}년 수령)',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[700],
                          ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 연금 수령 시뮬레이션 차트
            _buildPensionSimulationChart(context),

            const SizedBox(height: 24),

            // 상세 분석
            Text(
              '🔍 상세 분석',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),

            Card(
              child: ExpansionTile(
                title: const Text('기여금 납부 내역'),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildDetailRow(
                          '총 납부액',
                          NumberFormatter.formatCurrency(
                            pensionEstimate.totalContribution,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildDetailRow(
                          '총 수령액',
                          NumberFormatter.formatCurrency(
                            pensionEstimate.totalPension,
                          ),
                        ),
                        const Divider(height: 24),
                        _buildDetailRow(
                          '투자 수익률',
                          NumberFormatter.formatPercent(
                            pensionEstimate.returnRate,
                            decimalPlaces: 0,
                          ),
                          isHighlight: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // 안내 메시지
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '* 실제 연금액은 개정된 법률 및 개인별 상황에 따라 달라질 수 있습니다.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isHighlight = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isHighlight ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isHighlight ? Colors.green[700] : null,
          ),
        ),
      ],
    );
  }

  Widget _buildPensionSimulationChart(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📊 연금 누적 수령액 시뮬레이션',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 300,
              child: _buildAreaChart(theme),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAreaChart(ThemeData theme) {
    // 연금 누적 수령액 시뮬레이션 데이터 생성
    final cumulativeData = <FlSpot>[];
    final contributionLineData = <FlSpot>[];
    int cumulative = 0;

    for (int i = 0; i <= pensionEstimate.receivingYears; i++) {
      // 누적 수령액
      cumulative = pensionEstimate.annualPension * i;
      cumulativeData.add(FlSpot(i.toDouble(), cumulative.toDouble()));

      // 기여금 총액 (비교용)
      contributionLineData.add(FlSpot(i.toDouble(), pensionEstimate.totalContribution.toDouble()));
    }

    final maxValue = pensionEstimate.totalPension.toDouble();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxValue / 5,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${(value / 100000000).toStringAsFixed(0)}억',
                  style: theme.textTheme.bodySmall,
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 5,
              getTitlesWidget: (value, meta) {
                if (value.toInt() % 5 != 0) return const SizedBox();
                final age = pensionEstimate.retirementAge + value.toInt();
                return Text(
                  '$age세',
                  style: theme.textTheme.bodySmall,
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
        borderData: FlBorderData(show: false),
        lineBarsData: [
          // 기여금 총액 라인 (점선)
          LineChartBarData(
            spots: contributionLineData,
            isCurved: false,
            color: Colors.orange.withValues(alpha: 0.7),
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            dashArray: [5, 5],
          ),
          // 누적 수령액 라인 (실선 + 영역)
          LineChartBarData(
            spots: cumulativeData,
            isCurved: true,
            color: theme.colorScheme.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.3),
                  theme.colorScheme.primary.withValues(alpha: 0.05),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final years = spot.x.toInt();
                final age = pensionEstimate.retirementAge + years;
                final isContribution = spot.barIndex == 0;

                if (isContribution) {
                  return LineTooltipItem(
                    '$age세\n총 납부액: ${NumberFormatter.formatCurrency(spot.y.toInt())}',
                    theme.textTheme.bodySmall!.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                } else {
                  return LineTooltipItem(
                    '$age세 ($years년)\n누적 수령액: ${NumberFormatter.formatCurrency(spot.y.toInt())}',
                    theme.textTheme.bodySmall!.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }
              }).toList();
            },
          ),
        ),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            // 기여금 총액 기준선
            HorizontalLine(
              y: pensionEstimate.totalContribution.toDouble(),
              color: Colors.orange.withValues(alpha: 0.3),
              strokeWidth: 1,
              dashArray: [5, 5],
            ),
          ],
        ),
      ),
    );
  }
}
