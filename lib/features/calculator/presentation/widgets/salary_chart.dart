import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../common/utils/currency_formatter.dart';
import '../../domain/entities/salary_breakdown.dart';

/// 급여 정보 시각화 차트 위젯
/// 
/// 급여 구성과 공제 내역을 파이 차트로 표시합니다.
class SalaryChart extends StatelessWidget {
  const SalaryChart({
    required this.breakdown,
    super.key,
  });

  final SalaryBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    // 차트 데이터가 없으면 표시하지 않음
    if (breakdown.monthlyTotal <= 0) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withAlpha(128),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.pie_chart_outline,
                  size: 22,
                  color: colorScheme.primary,
                ),
                const Gap(8),
                Text(
                  '급여 구성 분석',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const Gap(24),
            
            // 급여 구성 파이 차트
            _buildSalaryCompositionChart(context),
            const Gap(32),
            
            // 세전/세후 비교 차트
            _buildNetPayComparisonChart(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSalaryCompositionChart(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    final double baseSalary = breakdown.monthlyTotal - breakdown.allowancesTotal;
    final double allowances = breakdown.allowancesTotal;

    final List<PieChartSectionData> sections = [
      if (baseSalary > 0)
        PieChartSectionData(
          color: colorScheme.primary,
          value: baseSalary,
          title: '${(baseSalary / breakdown.monthlyTotal * 100).toStringAsFixed(1)}%',
          radius: 100,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      if (allowances > 0)
        PieChartSectionData(
          color: colorScheme.secondary,
          value: allowances,
          title: '${(allowances / breakdown.monthlyTotal * 100).toStringAsFixed(1)}%',
          radius: 100,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '월급 구성',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.secondary,
          ),
        ),
        const Gap(16),
        SizedBox(
          height: 220,
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: PieChart(
                  PieChartData(
                    sections: sections,
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
              const Gap(20),
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ChartLegendItem(
                      color: colorScheme.primary,
                      label: '기본 월급',
                      value: formatCurrency(baseSalary),
                    ),
                    const Gap(12),
                    _ChartLegendItem(
                      color: colorScheme.secondary,
                      label: '수당',
                      value: formatCurrency(allowances),
                    ),
                    const Divider(height: 24),
                    _ChartLegendItem(
                      color: colorScheme.onSurface,
                      label: '총액',
                      value: formatCurrency(breakdown.monthlyTotal),
                      isBold: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNetPayComparisonChart(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    final double maxValue = breakdown.monthlyTotal;
    final double deductionHeight = breakdown.totalDeductions / maxValue;
    final double netHeight = breakdown.netPay / maxValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '세전/세후 비교',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.secondary,
          ),
        ),
        const Gap(16),
        Row(
          children: [
            // 세전 막대
            Expanded(
              child: Column(
                children: [
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withAlpha(51),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.primary.withAlpha(128),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.account_balance_wallet_outlined,
                          color: colorScheme.primary,
                          size: 32,
                        ),
                        const Gap(8),
                        Text(
                          '세전',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Gap(4),
                        Text(
                          formatCurrency(breakdown.monthlyTotal),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Gap(20),
            // 화살표
            Icon(
              Icons.arrow_forward,
              color: colorScheme.outline,
              size: 32,
            ),
            const Gap(20),
            // 세후 막대 (공제 표시)
            Expanded(
              child: Column(
                children: [
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.outline.withAlpha(77),
                      ),
                    ),
                    child: Column(
                      children: [
                        // 공제 부분
                        if (breakdown.totalDeductions > 0)
                          Expanded(
                            flex: (deductionHeight * 100).toInt(),
                            child: Container(
                              decoration: BoxDecoration(
                                color: colorScheme.error.withAlpha(51),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(11),
                                ),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.remove_circle_outline,
                                      color: colorScheme.error,
                                      size: 20,
                                    ),
                                    const Gap(4),
                                    Text(
                                      '공제',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: colorScheme.error,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      formatCurrency(breakdown.totalDeductions),
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: colorScheme.error,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        // 실수령 부분
                        Expanded(
                          flex: (netHeight * 100).toInt(),
                          child: Container(
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: breakdown.totalDeductions > 0
                                  ? const BorderRadius.vertical(
                                      bottom: Radius.circular(11),
                                    )
                                  : BorderRadius.circular(11),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.check_circle_outline,
                                    color: colorScheme.onPrimaryContainer,
                                    size: 24,
                                  ),
                                  const Gap(4),
                                  Text(
                                    '실수령',
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: colorScheme.onPrimaryContainer,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const Gap(2),
                                  Text(
                                    formatCurrency(breakdown.netPay),
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      color: colorScheme.onPrimaryContainer,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
        const Gap(16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withAlpha(128),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                label: '공제율',
                value: '${(breakdown.totalDeductions / breakdown.monthlyTotal * 100).toStringAsFixed(1)}%',
                color: colorScheme.error,
              ),
              Container(
                width: 1,
                height: 30,
                color: colorScheme.outline.withAlpha(77),
              ),
              _StatItem(
                label: '실수령률',
                value: '${(breakdown.netPay / breakdown.monthlyTotal * 100).toStringAsFixed(1)}%',
                color: colorScheme.primary,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChartLegendItem extends StatelessWidget {
  const _ChartLegendItem({
    required this.color,
    required this.label,
    required this.value,
    this.isBold = false,
  });

  final Color color;
  final String label;
  final String value;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const Gap(8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.bodySmall?.copyWith(
                  fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const Gap(4),
        Text(
          value,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
