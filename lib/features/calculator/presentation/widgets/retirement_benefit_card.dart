import 'package:flutter/material.dart';
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
                          : Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.savings,
                      size: 28,
                      color: isLocked ? Colors.grey : Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '퇴직급여',
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
                        '정보 입력 후 이용 가능',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              else if (retirementBenefit != null)
                // 활성화 상태
                Column(
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
                      NumberFormatter.formatCurrency(
                        retirementBenefit!.retirementAllowance,
                      ),
                    ),

                    const SizedBox(height: 12),
                    
                    // 총 퇴직급여
                    _buildSummaryRow(
                      context,
                      '💰 총 퇴직급여',
                      NumberFormatter.formatCurrency(
                        retirementBenefit!.totalBenefit,
                      ),
                      isHighlight: true,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '기간별 퇴직급여',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[700],
              ),
        ),
        Text(
          NumberFormatter.formatCurrency(amount),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.orange[700],
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isHighlight ? Colors.orange[900] : Colors.grey[700],
                fontWeight: isHighlight ? FontWeight.w600 : FontWeight.normal,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isHighlight ? Colors.orange[700] : Colors.orange[600],
              ),
        ),
      ],
    );
  }
}
