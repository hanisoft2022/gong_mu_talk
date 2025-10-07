import 'package:flutter/material.dart';
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
                          : Colors.purple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.card_giftcard,
                      size: 28,
                      color: isLocked ? Colors.grey : Colors.purple,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '명예퇴직금',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
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
                      Icon(
                        Icons.lock_outline,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '55세 이상 퇴직 시 이용 가능',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                )
              else if (earlyRetirementBonus != null)
                // 활성화 상태
                Column(
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
                      NumberFormatter.formatCurrency(
                        earlyRetirementBonus!.baseAmount,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // 가산금
                    if (earlyRetirementBonus!.bonusAmount > 0)
                      _buildInfoRow(
                        context,
                        '가산금 (55세 이상 10% 추가)',
                        NumberFormatter.formatCurrency(
                          earlyRetirementBonus!.bonusAmount,
                        ),
                      ),

                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),

                    // 총 명예퇴직금
                    _buildSummaryRow(
                      context,
                      '🎁 총 명예퇴직금',
                      NumberFormatter.formatCurrency(
                        earlyRetirementBonus!.totalAmount,
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

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.purple[700],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.purple[900],
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.purple[700],
          ),
        ),
      ],
    );
  }
}
