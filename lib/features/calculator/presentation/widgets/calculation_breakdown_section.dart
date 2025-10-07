import 'package:flutter/material.dart';
import 'package:gong_mu_talk/core/utils/number_formatter.dart';

/// 계산 근거 표시 섹션 (ExpansionTile)
///
/// Progressive Disclosure 패턴으로 계산 상세를 접기/펼치기
class CalculationBreakdownSection extends StatelessWidget {
  final List<BreakdownItem> items;
  final int? totalAmount;
  final String? totalLabel;
  final bool initiallyExpanded;

  const CalculationBreakdownSection({
    super.key,
    required this.items,
    this.totalAmount,
    this.totalLabel,
    this.initiallyExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: 16,
          ),
          title: Row(
            children: [
              Icon(Icons.calculate, size: 18, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Text(
                '계산 근거 보기',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade900,
                ),
              ),
            ],
          ),
          children: [
            ...items.map((item) => _buildBreakdownItem(context, item)),
            if (totalAmount != null) ...[
              const SizedBox(height: 12),
              const Divider(thickness: 1.5),
              const SizedBox(height: 12),
              _buildTotalRow(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownItem(BuildContext context, BreakdownItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 아이콘 (있는 경우)
          if (item.icon != null) ...[
            Icon(
              item.icon,
              size: 16,
              color: item.isHighlight
                  ? Colors.orange.shade700
                  : (item.isDeduction ? Colors.red.shade600 : Colors.grey[600]),
            ),
            const SizedBox(width: 8),
          ],
          // 레이블
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: item.isHighlight
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: item.isHighlight
                        ? Colors.orange.shade900
                        : (item.isDeduction
                              ? Colors.red.shade700
                              : Colors.black87),
                  ),
                ),
                if (item.description != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.description!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // 금액
          if (item.amount > 0 || item.isDeduction)
            Text(
              item.isDeduction
                  ? '- ${NumberFormatter.formatCurrency(item.amount)}'
                  : NumberFormatter.formatCurrency(item.amount),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: item.isHighlight
                    ? Colors.orange.shade900
                    : (item.isDeduction ? Colors.red.shade700 : Colors.black87),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            totalLabel ?? '합계',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade900,
            ),
          ),
          Text(
            NumberFormatter.formatCurrency(totalAmount!),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade900,
            ),
          ),
        ],
      ),
    );
  }
}

/// 계산 근거 항목
class BreakdownItem {
  final String label;
  final int amount;
  final String? description;
  final IconData? icon;
  final bool isHighlight;
  final bool isDeduction;

  const BreakdownItem({
    required this.label,
    required this.amount,
    this.description,
    this.icon,
    this.isHighlight = false,
    this.isDeduction = false,
  });
}

/// 계산 근거 그룹 (섹션 구분용)
class BreakdownGroup extends StatelessWidget {
  final String title;
  final List<BreakdownItem> items;
  final Color? titleColor;

  const BreakdownGroup({
    super.key,
    required this.title,
    required this.items,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: titleColor ?? Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (item.icon != null) ...[
                      Icon(item.icon, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      item.label,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                Text(
                  item.isDeduction
                      ? '- ${NumberFormatter.formatCurrency(item.amount)}'
                      : NumberFormatter.formatCurrency(item.amount),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: item.isDeduction ? Colors.red[700] : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
