import 'package:flutter/material.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/lifetime_salary.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/monthly_net_income.dart';
import 'package:gong_mu_talk/core/utils/number_formatter.dart';
import 'package:fl_chart/fl_chart.dart';

/// 급여 분석 통합 페이지
///
/// 월별 급여명세, 연도별 급여 증가, 생애 시뮬레이션을 탭으로 통합
class SalaryAnalysisPage extends StatelessWidget {
  final LifetimeSalary lifetimeSalary;
  final List<MonthlyNetIncome>? monthlyBreakdown;

  const SalaryAnalysisPage({
    super.key,
    required this.lifetimeSalary,
    this.monthlyBreakdown,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('급여 분석'),
          centerTitle: true,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.calendar_month), text: '월별 명세'),
              Tab(icon: Icon(Icons.trending_up), text: '연도별 증가'),
              Tab(icon: Icon(Icons.timeline), text: '생애 시뮬레이션'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // 탭 1: 월별 급여명세
            _MonthlyBreakdownTab(monthlyBreakdown: monthlyBreakdown),
            // 탭 2: 연도별 급여 증가
            _AnnualGrowthTab(lifetimeSalary: lifetimeSalary),
            // 탭 3: 생애 시뮬레이션
            _LifetimeSimulationTab(lifetimeSalary: lifetimeSalary),
          ],
        ),
      ),
    );
  }
}

/// 탭 1: 월별 급여명세
class _MonthlyBreakdownTab extends StatelessWidget {
  final List<MonthlyNetIncome>? monthlyBreakdown;

  const _MonthlyBreakdownTab({this.monthlyBreakdown});

  @override
  Widget build(BuildContext context) {
    if (monthlyBreakdown == null || monthlyBreakdown!.isEmpty) {
      return const Center(child: Text('월별 급여 데이터가 없습니다.'));
    }

    final annualNet = monthlyBreakdown!.fold<int>(
      0,
      (sum, m) => sum + m.netIncome,
    );

    return Column(
      children: [
        // 연간 총액 요약
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal.shade400, Colors.teal.shade600],
            ),
          ),
          child: Column(
            children: [
              const Text(
                '연간 총 실수령액',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                NumberFormatter.formatCurrency(annualNet),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '평균 월 ${NumberFormatter.formatCurrency(annualNet ~/ 12)}',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),

        // 월별 리스트
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: monthlyBreakdown!.length,
            itemBuilder: (context, index) {
              final month = monthlyBreakdown![index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  title: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: month.hasLongevityBonus
                              ? Colors.orange.shade100
                              : Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${month.month}월',
                          style: TextStyle(
                            color: month.hasLongevityBonus
                                ? Colors.orange.shade900
                                : Colors.teal.shade900,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (month.hasLongevityBonus) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '정근수당',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '실수령액: ${NumberFormatter.formatCurrency(month.netIncome)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildDetailRow('기본급', month.baseSalary),
                          const SizedBox(height: 8),
                          _buildDetailRow('각종 수당', month.totalAllowances),
                          if (month.longevityBonus > 0) ...[
                            const SizedBox(height: 8),
                            _buildDetailRow(
                              '정근수당 (${month.month}월)',
                              month.longevityBonus,
                              highlight: true,
                            ),
                          ],
                          const Divider(height: 24),
                          _buildDetailRow(
                            '총 지급액',
                            month.grossSalary,
                            isBold: true,
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            '총 공제액 (${month.deductionRate.toStringAsFixed(1)}%)',
                            -month.totalDeductions,
                            color: Colors.red,
                          ),
                          const Divider(height: 24),
                          _buildDetailRow(
                            '실수령액',
                            month.netIncome,
                            isBold: true,
                            isHighlight: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(
    String label,
    int amount, {
    bool isBold = false,
    bool isHighlight = false,
    bool highlight = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
              color: color ?? (highlight ? Colors.orange.shade900 : null),
            ),
          ),
          Text(
            NumberFormatter.formatCurrency(amount),
            style: TextStyle(
              fontWeight: isBold || highlight
                  ? FontWeight.bold
                  : FontWeight.normal,
              color:
                  color ??
                  (isHighlight
                      ? Colors.teal[700]
                      : (highlight ? Colors.orange.shade900 : null)),
            ),
          ),
        ],
      ),
    );
  }
}

/// 탭 2: 연도별 급여 증가
class _AnnualGrowthTab extends StatelessWidget {
  final LifetimeSalary lifetimeSalary;

  const _AnnualGrowthTab({required this.lifetimeSalary});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 요약 카드
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📊 요약',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSummaryItem(
                    context,
                    '평균 연봉',
                    NumberFormatter.formatCurrency(
                      lifetimeSalary.avgAnnualSalary,
                    ),
                  ),
                  const Divider(height: 24),
                  _buildSummaryItem(
                    context,
                    '총 재직 기간',
                    '${lifetimeSalary.totalYears}년',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 차트
          Text(
            '📈 연도별 급여 증가 추이',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(height: 250, child: _buildLineChart(context)),
            ),
          ),

          const SizedBox(height: 24),

          // 연도별 리스트
          Text(
            '📅 연도별 상세',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: lifetimeSalary.annualSalaries.length,
            itemBuilder: (context, index) {
              final salary = lifetimeSalary.annualSalaries[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(
                    '${salary.year}년 (${salary.grade}호봉)',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '월 실수령: ${NumberFormatter.formatCurrency(salary.netPay)}',
                  ),
                  trailing: Text(
                    NumberFormatter.formatCurrency(salary.annualTotalPay),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.teal[700],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyLarge),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildLineChart(BuildContext context) {
    final theme = Theme.of(context);
    final netPayData = lifetimeSalary.annualSalaries
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.netPay.toDouble()))
        .toList();

    final maxPay = lifetimeSalary.annualSalaries
        .map((s) => s.netPay)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxPay / 5,
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
              interval: 5,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= lifetimeSalary.annualSalaries.length ||
                    value.toInt() % 5 != 0) {
                  return const SizedBox();
                }
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
            spots: netPayData,
            isCurved: true,
            color: theme.colorScheme.primary,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }
}

/// 탭 3: 생애 시뮬레이션
class _LifetimeSimulationTab extends StatelessWidget {
  final LifetimeSalary lifetimeSalary;

  const _LifetimeSimulationTab({required this.lifetimeSalary});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 메인 카드
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.savings,
                    size: 48,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '생애 총 소득',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    NumberFormatter.formatCurrency(lifetimeSalary.totalIncome),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 상세 정보
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '💰 상세 정보',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    context,
                    '명목 가치',
                    NumberFormatter.formatCurrency(lifetimeSalary.totalIncome),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    context,
                    '현재 가치',
                    NumberFormatter.formatCurrency(lifetimeSalary.presentValue),
                    subtitle:
                        '인플레이션 ${NumberFormatter.formatPercent(lifetimeSalary.inflationRate)} 반영',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    context,
                    '평균 연봉',
                    NumberFormatter.formatCurrency(
                      lifetimeSalary.avgAnnualSalary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    context,
                    '재직 기간',
                    '${lifetimeSalary.startYear}년 ~ ${lifetimeSalary.endYear}년 (${lifetimeSalary.totalYears}년)',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 안내 메시지
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '생애 총 소득 계산 방식',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• 명목 가치: 각 연도 급여를 그대로 합산\n'
                        '• 현재 가치: 인플레이션을 고려한 실질 가치\n'
                        '• 실제 수령액은 개인의 승진, 수당 등에 따라 달라질 수 있습니다',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue[800],
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value, {
    String? subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
              textAlign: TextAlign.right,
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          ),
        ],
      ],
    );
  }
}
