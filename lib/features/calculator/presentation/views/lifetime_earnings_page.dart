import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:gong_mu_talk/core/utils/number_formatter.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/lifetime_salary.dart';
import 'package:share_plus/share_plus.dart';

/// 생애 소득 시각화 페이지
class LifetimeEarningsPage extends StatelessWidget {
  final LifetimeSalary lifetimeSalary;

  const LifetimeEarningsPage({super.key, required this.lifetimeSalary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('생애 소득 시뮬레이션'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareResults(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 요약 카드
            _buildSummaryCard(theme),
            const SizedBox(height: 16),

            // 성과상여금 안내
            _buildPerformanceBonusNotice(theme),
            const SizedBox(height: 24),

            // 누적 소득 차트
            _buildCumulativeIncomeSection(theme),
            const SizedBox(height: 32),

            // 연도별 월급 변화 차트
            _buildAnnualSalarySection(theme),
            const SizedBox(height: 32),

            // 상세 통계
            _buildDetailedStats(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(ThemeData theme) {
    return Card(
      elevation: 4,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primaryContainer,
              theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              '💰 ${lifetimeSalary.totalYears}년 근무 시',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '총 소득',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer.withValues(
                  alpha: 0.8,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              NumberFormatter.formatCurrency(lifetimeSalary.totalIncome),
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '현재 가치: ${NumberFormatter.formatCurrency(lifetimeSalary.presentValue)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceBonusNotice(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                '📌 성과상여금 예측 안내',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '• 평가 등급: A등급 고정 (중위 50% 배정으로 확률상 가장 높음)\n'
            '• 차등지급률: 50% 고정 (2025년 정부 정책 기준)\n'
            '• 물가상승률: 연 2.3% 적용 (최근 10년 평균)\n'
            '• 지급 시기: 매년 3월',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade800,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded,
                  color: Colors.amber.shade700,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '본 예측은 현재 정책 기준으로 산정된 참고값이며, 실제 지급액은 개인 평가 결과, 학교별 차등지급률, 정부 정책 변경에 따라 달라질 수 있습니다.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade800,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '※ 성과상여금은 공무원연금 기준소득월액 산정 시 개인 금액이 차감되고 직종별 평균액이 가산됩니다.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade600,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCumulativeIncomeSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.trending_up, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              '누적 소득 추이',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 300,
              child: _buildCumulativeIncomeChart(theme),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCumulativeIncomeChart(ThemeData theme) {
    // 누적 소득 계산
    final cumulativeData = <FlSpot>[];
    int cumulative = 0;

    for (int i = 0; i < lifetimeSalary.annualSalaries.length; i++) {
      cumulative += lifetimeSalary.annualSalaries[i].annualTotalPay;
      cumulativeData.add(FlSpot(i.toDouble(), cumulative.toDouble()));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (lifetimeSalary.totalIncome / 5).toDouble(),
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
                return Text(
                  '${value.toInt() + 1}년',
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
          LineChartBarData(
            spots: cumulativeData,
            isCurved: true,
            color: theme.colorScheme.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  '${spot.x.toInt() + 1}년차\n${NumberFormatter.formatCurrency(spot.y.toInt())}',
                  theme.textTheme.bodySmall!.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAnnualSalarySection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.attach_money, color: theme.colorScheme.secondary),
            const SizedBox(width: 8),
            Text(
              '연도별 월급 변화',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(height: 250, child: _buildAnnualSalaryChart(theme)),
          ),
        ),
      ],
    );
  }

  Widget _buildAnnualSalaryChart(ThemeData theme) {
    final salaryData = lifetimeSalary.annualSalaries
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.netPay.toDouble()))
        .toList();

    final maxSalary = lifetimeSalary.annualSalaries
        .map((s) => s.netPay)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxSalary / 5,
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
                  '${(value / 10000).toInt()}만',
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
                final salary = lifetimeSalary.annualSalaries[value.toInt()];
                return Text(
                  '${salary.grade}호봉',
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
          LineChartBarData(
            spots: salaryData,
            isCurved: true,
            color: theme.colorScheme.secondary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 3,
                  color: theme.colorScheme.secondary,
                  strokeWidth: 0,
                );
              },
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final salary = lifetimeSalary.annualSalaries[spot.x.toInt()];
                return LineTooltipItem(
                  '${salary.grade}호봉\n${NumberFormatter.formatCurrency(salary.netPay)}/월',
                  theme.textTheme.bodySmall!.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDetailedStats(ThemeData theme) {
    final firstYearSalary = lifetimeSalary.annualSalaries.first.netPay;
    final lastYearSalary = lifetimeSalary.annualSalaries.last.netPay;
    final salaryIncrease = lastYearSalary - firstYearSalary;
    final increaseRate = (salaryIncrease / firstYearSalary * 100);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📊 상세 통계',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildStatRow(
                  theme,
                  '평균 연봉',
                  NumberFormatter.formatCurrency(
                    lifetimeSalary.avgAnnualSalary,
                  ),
                ),
                const Divider(height: 24),
                _buildStatRow(
                  theme,
                  '첫 해 월급',
                  NumberFormatter.formatCurrency(firstYearSalary),
                ),
                const Divider(height: 24),
                _buildStatRow(
                  theme,
                  '마지막 해 월급',
                  NumberFormatter.formatCurrency(lastYearSalary),
                ),
                const Divider(height: 24),
                _buildStatRow(
                  theme,
                  '월급 증가액',
                  '${NumberFormatter.formatCurrency(salaryIncrease)} (+${increaseRate.toStringAsFixed(0)}%)',
                  valueColor: Colors.green,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.3,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '* 인플레이션 ${NumberFormatter.formatPercent(lifetimeSalary.inflationRate)}를 반영한 현재 가치입니다.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(
    ThemeData theme,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodyLarge),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor ?? theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  void _shareResults(BuildContext context) {
    final totalYears = lifetimeSalary.totalYears;
    final totalIncome = NumberFormatter.formatCurrency(
      lifetimeSalary.totalIncome,
    );
    final avgAnnual = NumberFormatter.formatCurrency(
      lifetimeSalary.avgAnnualSalary,
    );

    final text =
        '''
🎓 생애 소득 시뮬레이션 결과

📅 근무 기간: $totalYears년
💰 총 소득: $totalIncome
📊 평균 연봉: $avgAnnual

공무톡에서 확인하세요!
''';

    // iPad에서 공유 시트 위치 지정 (popover 위치)
    final box = context.findRenderObject() as RenderBox?;
    final sharePositionOrigin = box != null
        ? box.localToGlobal(Offset.zero) & box.size
        : null;

    Share.share(text, sharePositionOrigin: sharePositionOrigin);
  }
}
