import 'package:flutter/material.dart';
import 'package:gong_mu_talk/common/widgets/lockable_info_card.dart';
import 'package:gong_mu_talk/core/theme/app_color_extension.dart';
import 'package:gong_mu_talk/core/utils/number_formatter.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/retirement_benefit.dart';

/// 퇴직급여 카드
class RetirementBenefitCard extends StatelessWidget {
  final bool isLocked;
  final RetirementBenefit? retirementBenefit;

  const RetirementBenefitCard({
    super.key,
    required this.isLocked,
    this.retirementBenefit,
  });

  @override
  Widget build(BuildContext context) {
    return LockableInfoCard(
      isLocked: isLocked,
      title: '퇴직급여',
      icon: Icons.savings,
      iconColor: context.appColors.highlight,
      content: retirementBenefit != null ? _buildContent(context) : const SizedBox.shrink(),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      children: [
        // 기간별 퇴직급여
        _buildPeriodSection(context),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 16),

        // 퇴직수당
        _buildSummaryRow(
          context,
          '퇴직수당 (1기간 + 2~3기간×0.6)',
          NumberFormatter.formatCurrency(retirementBenefit!.retirementAllowance),
        ),
        const SizedBox(height: 12),

        // 총 퇴직급여
        _buildSummaryRow(
          context,
          '💰 총 퇴직급여',
          NumberFormatter.formatCurrency(retirementBenefit!.totalBenefit),
          isHighlight: true,
        ),
      ],
    );
  }

  Widget _buildPeriodSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '기간별 퇴직급여',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),

        // 1기간
        if (retirementBenefit!.period1Years > 0)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: _buildPeriodRow(
              context,
              '1기간 (${retirementBenefit!.period1Years}년)',
              retirementBenefit!.period1Benefit,
            ),
          ),

        // 2기간
        if (retirementBenefit!.period2Years > 0)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: _buildPeriodRow(
              context,
              '2기간 (${retirementBenefit!.period2Years}년)',
              retirementBenefit!.period2Benefit,
            ),
          ),

        // 3기간
        if (retirementBenefit!.period3Years > 0)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: _buildPeriodRow(
              context,
              '3기간 (${retirementBenefit!.period3Years}년)',
              retirementBenefit!.period3Benefit,
            ),
          ),
      ],
    );
  }

  Widget _buildPeriodRow(BuildContext context, String label, int amount) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          NumberFormatter.formatCurrency(amount),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: context.appColors.highlight,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(
    BuildContext context,
    String label,
    String value, {
    bool isHighlight = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isHighlight ? context.appColors.highlight : colorScheme.onSurfaceVariant,
            fontWeight: isHighlight ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: context.appColors.highlight,
          ),
        ),
      ],
    );
  }
}
