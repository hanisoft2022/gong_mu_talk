import 'package:flutter/material.dart';
import 'package:gong_mu_talk/common/widgets/lockable_info_card.dart';
import 'package:gong_mu_talk/core/theme/app_color_extension.dart';
import 'package:gong_mu_talk/core/utils/number_formatter.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/lifetime_salary.dart';
import 'package:gong_mu_talk/features/calculator/presentation/views/annual_salary_detail_page.dart';
import 'package:gong_mu_talk/features/calculator/presentation/views/lifetime_earnings_page.dart';

/// 연도별 급여 계산 카드
class AnnualSalaryCard extends StatelessWidget {
  final bool isLocked;
  final LifetimeSalary? lifetimeSalary;

  const AnnualSalaryCard({
    super.key,
    required this.isLocked,
    this.lifetimeSalary,
  });

  @override
  Widget build(BuildContext context) {
    return LockableInfoCard(
      isLocked: isLocked,
      title: '연도별 급여 계산',
      icon: Icons.trending_up,
      iconColor: context.appColors.success,
      showArrowWhenUnlocked: true,
      onTap: lifetimeSalary != null
          ? () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AnnualSalaryDetailPage(lifetimeSalary: lifetimeSalary!),
                ),
              )
          : null,
      content: lifetimeSalary != null ? _buildContent(context) : const SizedBox.shrink(),
      ctaButton: lifetimeSalary != null ? _buildCTAButtons(context) : null,
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      children: [
        // 요약 정보
        _buildSummaryRow(
          context,
          '💼 생애 총 소득',
          NumberFormatter.formatCurrency(lifetimeSalary!.totalIncome),
        ),
        const SizedBox(height: 12),
        _buildSummaryRow(
          context,
          '💵 현재 가치 환산',
          NumberFormatter.formatCurrency(lifetimeSalary!.presentValue),
          subtitle:
              '(인플레이션 ${(lifetimeSalary!.inflationRate * 100).toStringAsFixed(1)}% 반영)',
        ),
        const SizedBox(height: 12),
        _buildSummaryRow(
          context,
          '📈 평균 연봉',
          NumberFormatter.formatCurrency(lifetimeSalary!.avgAnnualSalary),
        ),
      ],
    );
  }

  Widget _buildCTAButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LifetimeEarningsPage(lifetimeSalary: lifetimeSalary!),
                ),
              );
            },
            icon: const Icon(Icons.analytics_outlined, size: 18),
            label: const Text('시뮬레이션'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AnnualSalaryDetailPage(lifetimeSalary: lifetimeSalary!),
                ),
              );
            },
            icon: const Icon(Icons.list_alt, size: 18),
            label: const Text('상세보기'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(
    BuildContext context,
    String label,
    String value, {
    String? subtitle,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: context.appColors.success,
          ),
        ),
      ],
    );
  }
}
