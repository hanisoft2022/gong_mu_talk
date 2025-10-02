import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../common/utils/currency_formatter.dart';
import '../../domain/entities/salary_breakdown.dart';

class SalaryResultCard extends StatelessWidget {
  const SalaryResultCard({
    super.key,
    required this.breakdown,
    this.isEmpty = false,
  });

  final SalaryBreakdown breakdown;
  final bool isEmpty;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    if (isEmpty) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '나의 월급 리포트',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Gap(12),
              Text(
                '기본 월급과 수당을 입력하면 실수령 월급과 연간 소득이 여기에 표시됩니다.',
                style: textTheme.bodyMedium,
              ),
              const Gap(20),
              FilledButton.icon(
                onPressed: null,
                icon: const Icon(Icons.auto_graph_outlined),
                label: const Text('입력 후 계산하기 버튼을 눌러주세요'),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Text(
              '나의 월급 리포트',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const Gap(20),

            // 핵심 지표 3개
            _buildHighlightMetrics(context),
            const Gap(24),

            // 월급 구성
            _buildSectionTitle(
              context,
              icon: Icons.account_balance_wallet_outlined,
              title: '월급 구성',
            ),
            const Gap(12),
            _ResultRow(
              label: '기본 월급',
              value: formatCurrency(breakdown.monthlyTotal - breakdown.allowancesTotal),
            ),
            _ResultRow(
              label: '수당 합계',
              value: formatCurrency(breakdown.allowancesTotal),
            ),
            const Divider(height: 24),
            _ResultRow(
              label: '월 총급여',
              value: formatCurrency(breakdown.monthlyTotal),
              isHighlight: true,
              highlightColor: colorScheme.primary,
            ),
            const Gap(24),

            // 공제 내역 (간략)
            _buildSectionTitle(
              context,
              icon: Icons.remove_circle_outline,
              title: '공제 요약',
            ),
            const Gap(12),
            _ResultRow(
              label: '세금 (소득세 + 지방소득세)',
              value: formatCurrency(breakdown.incomeTax + breakdown.localIncomeTax),
            ),
            _ResultRow(
              label: '4대 보험',
              value: formatCurrency(
                breakdown.pensionContribution +
                    breakdown.healthInsurance +
                    breakdown.longTermCare,
              ),
            ),
            const Divider(height: 24),
            _ResultRow(
              label: '총 공제액',
              value: formatCurrency(breakdown.totalDeductions),
              isHighlight: true,
              highlightColor: colorScheme.error,
            ),
            const Gap(24),

            // 실수령액
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primaryContainer,
                    colorScheme.primaryContainer.withAlpha(179),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '월 실수령액',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const Gap(4),
                      Text(
                        '세후 순수입',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onPrimaryContainer.withAlpha(179),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    formatCurrency(breakdown.netPay),
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            const Gap(20),

            // 추가 정보
            _buildSectionTitle(
              context,
              icon: Icons.info_outline,
              title: '추가 정보',
            ),
            const Gap(12),
            _ResultRow(
              label: '일급',
              value: formatCurrency(breakdown.dailyRate),
            ),
            _ResultRow(
              label: '연 총급여',
              value: formatCurrency(breakdown.yearlyTotal),
            ),
            _ResultRow(
              label: '연 실수령액',
              value: formatCurrency(breakdown.yearlyNet),
            ),
            _ResultRow(
              label: '최저임금 대비',
              value: breakdown.minimumWageGap >= 0
                  ? '+${formatCurrency(breakdown.minimumWageGap)}'
                  : formatCurrency(breakdown.minimumWageGap),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightMetrics(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: _HighlightMetric(
            label: '월 총급여',
            value: formatCurrency(breakdown.monthlyTotal),
            icon: Icons.payments_outlined,
            color: colorScheme.primary,
          ),
        ),
        const Gap(12),
        Expanded(
          child: _HighlightMetric(
            label: '총 공제',
            value: formatCurrency(breakdown.totalDeductions),
            icon: Icons.remove_circle_outline,
            color: colorScheme.error,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(
    BuildContext context, {
    required IconData icon,
    required String title,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const Gap(8),
        Text(
          title,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _HighlightMetric extends StatelessWidget {
  const _HighlightMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withAlpha(77),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: color),
          const Gap(8),
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Gap(4),
          Text(
            value,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.label,
    required this.value,
    this.isHighlight = false,
    this.highlightColor,
  });

  final String label;
  final String value;
  final bool isHighlight;
  final Color? highlightColor;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final color = highlightColor ?? Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w500,
                color: isHighlight ? color : null,
              ),
            ),
          ),
          Text(
            value,
            style: textTheme.bodyLarge?.copyWith(
              fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w600,
              color: isHighlight ? color : null,
              fontSize: isHighlight ? 18 : null,
            ),
          ),
        ],
      ),
    );
  }
}
