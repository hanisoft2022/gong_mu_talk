import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../../common/utils/currency_formatter.dart';
import '../../domain/entities/calculation_history.dart';

/// 계산 히스토리 목록 위젯
class CalculationHistoryWidget extends StatelessWidget {
  const CalculationHistoryWidget({
    required this.history,
    required this.onItemTap,
    required this.onItemDelete,
    super.key,
  });

  final List<CalculationHistory> history;
  final void Function(CalculationHistory) onItemTap;
  final void Function(String id) onItemDelete;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const _EmptyHistoryView();
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: history.length,
      separatorBuilder: (context, index) => const Gap(12),
      itemBuilder: (context, index) {
        final item = history[index];
        return _HistoryCard(
          history: item,
          onTap: () => onItemTap(item),
          onDelete: () => onItemDelete(item.id),
        );
      },
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.history,
    required this.onTap,
    required this.onDelete,
  });

  final CalculationHistory history;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final dateFormat = DateFormat('yyyy.MM.dd HH:mm');
    final formattedDate = dateFormat.format(history.timestamp);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outlineVariant.withAlpha(128),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (history.label != null) ...[
                          Text(
                            history.label!,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colorScheme.primary,
                            ),
                          ),
                          const Gap(4),
                        ],
                        Text(
                          formattedDate,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: onDelete,
                    color: colorScheme.error,
                    iconSize: 20,
                  ),
                ],
              ),
              const Gap(12),
              const Divider(height: 1),
              const Gap(12),
              Row(
                children: [
                  Expanded(
                    child: _InfoItem(
                      label: '기본급',
                      value: formatCurrency(
                        history.input.baseMonthlySalary,
                      ),
                      icon: Icons.attach_money_outlined,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: colorScheme.outlineVariant.withAlpha(128),
                  ),
                  Expanded(
                    child: _InfoItem(
                      label: '실수령',
                      value: formatCurrency(history.result.netPay),
                      icon: Icons.check_circle_outline,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.onSurface;

    return Column(
      children: [
        Icon(icon, size: 20, color: effectiveColor),
        const Gap(4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const Gap(2),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: effectiveColor,
          ),
        ),
      ],
    );
  }
}

class _EmptyHistoryView extends StatelessWidget {
  const _EmptyHistoryView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant.withAlpha(128),
            ),
            const Gap(16),
            Text(
              '계산 히스토리가 없습니다',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const Gap(8),
            Text(
              '월급을 계산하면 여기에 기록이 표시됩니다',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withAlpha(179),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
