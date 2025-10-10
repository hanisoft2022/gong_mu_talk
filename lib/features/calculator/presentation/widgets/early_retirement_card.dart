import 'package:flutter/material.dart';
import 'package:gong_mu_talk/common/widgets/lockable_info_card.dart';
import 'package:gong_mu_talk/core/utils/number_formatter.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/early_retirement_bonus.dart';

/// 명예퇴직금 카드
class EarlyRetirementCard extends StatelessWidget {
  final bool isLocked;
  final EarlyRetirementBonus? earlyRetirementBonus;

  const EarlyRetirementCard({
    super.key,
    required this.isLocked,
    this.earlyRetirementBonus,
  });

  @override
  Widget build(BuildContext context) {
    return LockableInfoCard(
      isLocked: isLocked,
      title: '명예퇴직금',
      icon: Icons.card_giftcard,
      iconColor: Theme.of(context).colorScheme.secondary,
      lockedMessage: '55세 이상 퇴직 시 이용 가능',
      content: earlyRetirementBonus != null ? _buildContent(context) : const SizedBox.shrink(),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      children: [
        // 정년까지 잔여기간
        _buildInfoRow(
          context,
          '정년까지 잔여기간',
          '${earlyRetirementBonus!.remainingYears}년 ${earlyRetirementBonus!.remainingMonths}개월',
        ),
        const SizedBox(height: 12),

        // 기본 명퇴금
        _buildInfoRow(
          context,
          '기본 명퇴금',
          NumberFormatter.formatCurrency(earlyRetirementBonus!.baseAmount),
        ),
        const SizedBox(height: 12),

        // 가산금
        if (earlyRetirementBonus!.bonusAmount > 0)
          _buildInfoRow(
            context,
            '가산금 (55세 이상 10% 추가)',
            NumberFormatter.formatCurrency(earlyRetirementBonus!.bonusAmount),
          ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 16),

        // 총 명예퇴직금
        _buildSummaryRow(
          context,
          '🎁 총 명예퇴직금',
          NumberFormatter.formatCurrency(earlyRetirementBonus!.totalAmount),
        ),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
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
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(BuildContext context, String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colorScheme.secondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.secondary,
          ),
        ),
      ],
    );
  }
}
