import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../common/utils/currency_formatter.dart';
import '../../domain/entities/salary_breakdown.dart';

/// 급여 공제 내역 섹션 위젯
/// 
/// 세금과 4대 보험 공제 항목을 상세히 표시합니다.
class SalaryDeductionSection extends StatelessWidget {
  const SalaryDeductionSection({
    required this.breakdown,
    super.key,
  });

  final SalaryBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

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
                  Icons.remove_circle_outline,
                  size: 22,
                  color: colorScheme.error,
                ),
                const Gap(8),
                Text(
                  '공제 내역',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const Gap(16),
            
            // 세금 섹션
            _buildSubsection(
              context: context,
              title: '세금',
              icon: Icons.account_balance_outlined,
              items: [
                _DeductionItem(
                  label: '소득세',
                  amount: breakdown.incomeTax,
                  description: '2025년 누진세율 적용',
                ),
                _DeductionItem(
                  label: '지방소득세',
                  amount: breakdown.localIncomeTax,
                  description: '소득세의 10%',
                ),
              ],
              subtotal: breakdown.incomeTax + breakdown.localIncomeTax,
            ),
            
            const Divider(height: 32),
            
            // 4대 보험 섹션
            _buildSubsection(
              context: context,
              title: '4대 보험',
              icon: Icons.health_and_safety_outlined,
              items: [
                _DeductionItem(
                  label: '공무원연금',
                  amount: breakdown.pensionContribution,
                  description: '기준소득월액의 9%',
                ),
                _DeductionItem(
                  label: '건강보험',
                  amount: breakdown.healthInsurance,
                  description: '보수월액의 3.545%',
                ),
                _DeductionItem(
                  label: '장기요양보험',
                  amount: breakdown.longTermCare,
                  description: '건강보험료의 12.95%',
                ),
              ],
              subtotal: breakdown.pensionContribution + 
                        breakdown.healthInsurance + 
                        breakdown.longTermCare,
            ),
            
            const Divider(height: 32),
            
            // 총 공제액
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withAlpha(77),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '총 공제액',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.error,
                    ),
                  ),
                  Text(
                    formatCurrency(breakdown.totalDeductions),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colorScheme.error,
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

  Widget _buildSubsection({
    required BuildContext context,
    required String title,
    required IconData icon,
    required List<_DeductionItem> items,
    required double subtotal,
  }) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: colorScheme.secondary),
            const Gap(6),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.secondary,
              ),
            ),
          ],
        ),
        const Gap(12),
        ...items.map((item) => _buildDeductionRow(context, item)),
        const Gap(8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.secondaryContainer.withAlpha(77),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$title 소계',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                formatCurrency(subtotal),
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeductionRow(BuildContext context, _DeductionItem item) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (item.description.isNotEmpty) ...[
                  const Gap(2),
                  Text(
                    item.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            formatCurrency(item.amount),
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeductionItem {
  const _DeductionItem({
    required this.label,
    required this.amount,
    this.description = '',
  });

  final String label;
  final double amount;
  final String description;
}
