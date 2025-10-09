import 'package:flutter/material.dart';
import 'package:gong_mu_talk/core/utils/number_formatter.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/monthly_net_income.dart';

/// 월별 실수령액 분석 카드
class MonthlyBreakdownCard extends StatelessWidget {
  final bool isLocked;
  final List<MonthlyNetIncome>? monthlyBreakdown;

  const MonthlyBreakdownCard({super.key, required this.isLocked, this.monthlyBreakdown});

  @override
  Widget build(BuildContext context) {
    // 평균 계산
    final avgNetIncome = monthlyBreakdown != null && monthlyBreakdown!.isNotEmpty
        ? (monthlyBreakdown!.map((m) => m.netIncome).reduce((a, b) => a + b) /
                  monthlyBreakdown!.length)
              .round()
        : 0;

    final annualNetIncome = monthlyBreakdown != null && monthlyBreakdown!.isNotEmpty
        ? monthlyBreakdown!.map((m) => m.netIncome).reduce((a, b) => a + b)
        : 0;

    return Card(
      elevation: 2,
      child: Opacity(
        opacity: isLocked ? 0.5 : 1.0,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isLocked
                          ? Colors.grey.withValues(alpha: 0.1)
                          : Colors.teal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.calendar_month,
                      size: 28,
                      color: isLocked ? Colors.grey : Colors.teal,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '월별 실수령액 분석',
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (isLocked) const Icon(Icons.lock, color: Colors.grey),
                ],
              ),

              const SizedBox(height: 20),

              if (isLocked)
                // 잠금 상태
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.lock_outline, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text(
                        '정보 입력 후 이용 가능',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                )
              else if (monthlyBreakdown != null && monthlyBreakdown!.isNotEmpty)
                // 활성화 상태
                Column(
                  children: [
                    // 요약 정보
                    _buildSummaryRow(
                      context,
                      '월 평균 실수령액',
                      NumberFormatter.formatCurrency(avgNetIncome),
                    ),

                    const SizedBox(height: 12),

                    _buildSummaryRow(
                      context,
                      '💎 연간 실수령액',
                      NumberFormatter.formatCurrency(annualNetIncome),
                      isHighlight: true,
                    ),

                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),

                    // 월별 특이사항
                    Text(
                      '월별 상세 (정기상여금 포함)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 정기상여금이 있는 달 표시
                    ...monthlyBreakdown!
                        .where((m) => m.longevityBonus > 0)
                        .map(
                          (m) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${m.month}월 (정기상여금)',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.copyWith(color: Colors.teal[700]),
                                ),
                                Text(
                                  NumberFormatter.formatCurrency(m.netIncome),
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.teal[700],
                                  ),
                                ),
                              ],
                            ),
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

  Widget _buildSummaryRow(
    BuildContext context,
    String label,
    String value, {
    bool isHighlight = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isHighlight ? Colors.teal[900] : Colors.grey[700],
            fontWeight: isHighlight ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isHighlight ? Colors.teal[700] : Colors.teal[600],
          ),
        ),
      ],
    );
  }
}
