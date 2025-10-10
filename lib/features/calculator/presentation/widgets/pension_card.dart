import 'package:flutter/material.dart';
import 'package:gong_mu_talk/common/widgets/lockable_info_card.dart';
import 'package:gong_mu_talk/core/utils/number_formatter.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/pension_estimate.dart';
import 'package:gong_mu_talk/features/calculator/presentation/views/pension_detail_page.dart';

/// 예상 연금 수령액 카드
class PensionCard extends StatelessWidget {
  final bool isLocked;
  final PensionEstimate? pensionEstimate;

  const PensionCard({super.key, required this.isLocked, this.pensionEstimate});

  @override
  Widget build(BuildContext context) {
    return LockableInfoCard(
      isLocked: isLocked,
      title: '예상 연금 수령액',
      icon: Icons.account_balance,
      iconColor: Theme.of(context).colorScheme.primary,
      showArrowWhenUnlocked: true,
      onTap: pensionEstimate != null
          ? () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PensionDetailPage(pensionEstimate: pensionEstimate!),
                ),
              )
          : null,
      content: pensionEstimate != null ? _buildContent(context) : const SizedBox.shrink(),
      ctaButton: pensionEstimate != null
          ? SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PensionDetailPage(pensionEstimate: pensionEstimate!),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('자세히 보기'),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 16),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      children: [
        // 요약 정보
        _buildSummaryRow(
          context,
          '📅 ${pensionEstimate!.retirementAge}세 퇴직 시',
          '',
        ),
        const SizedBox(height: 12),
        _buildSummaryRow(
          context,
          '월 수령액',
          NumberFormatter.formatCurrency(pensionEstimate!.monthlyPension),
        ),
        const SizedBox(height: 12),
        _buildSummaryRow(
          context,
          '수령 기간',
          '${pensionEstimate!.receivingYears}년 (${pensionEstimate!.retirementAge}~${pensionEstimate!.lifeExpectancy}세)',
        ),
        const SizedBox(height: 12),
        const Divider(),
        const SizedBox(height: 12),
        _buildSummaryRow(
          context,
          '💎 총 수령 예상액',
          NumberFormatter.formatCurrency(pensionEstimate!.totalPension),
          isHighlight: true,
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
            color: isHighlight ? colorScheme.primary : colorScheme.onSurfaceVariant,
            fontWeight: isHighlight ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        if (value.isNotEmpty)
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
      ],
    );
  }
}
