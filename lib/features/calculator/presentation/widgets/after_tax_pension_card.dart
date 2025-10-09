import 'package:flutter/material.dart';
import 'package:gong_mu_talk/core/utils/number_formatter.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/after_tax_pension.dart';

/// 세후 연금 카드
class AfterTaxPensionCard extends StatelessWidget {
  final bool isLocked;
  final AfterTaxPension? afterTaxPension;

  const AfterTaxPensionCard({super.key, required this.isLocked, this.afterTaxPension});

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
                          : Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.verified,
                      size: 28,
                      color: isLocked ? Colors.grey : Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '세후 연금 (실수령액)',
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
              else if (afterTaxPension != null)
                // 활성화 상태
                Column(
                  children: [
                    // 세전 연금
                    _buildInfoRow(
                      context,
                      '세전 월 연금액',
                      NumberFormatter.formatCurrency(afterTaxPension!.monthlyPensionBeforeTax),
                    ),

                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),

                    // 공제 항목들
                    Text(
                      '공제 내역',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),

                    _buildDeductionRow(context, '소득세', afterTaxPension!.incomeTax),
                    const SizedBox(height: 4),
                    _buildDeductionRow(context, '지방세', afterTaxPension!.localTax),
                    const SizedBox(height: 4),
                    _buildDeductionRow(context, '건강보험', afterTaxPension!.healthInsurance),
                    const SizedBox(height: 4),
                    _buildDeductionRow(context, '장기요양보험', afterTaxPension!.longTermCareInsurance),

                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),

                    // 세후 월 연금
                    _buildSummaryRow(
                      context,
                      '💚 세후 월 실수령액',
                      NumberFormatter.formatCurrency(afterTaxPension!.monthlyPensionAfterTax),
                    ),

                    const SizedBox(height: 12),

                    // 연간 실수령액
                    _buildInfoRow(
                      context,
                      '연간 실수령액',
                      NumberFormatter.formatCurrency(afterTaxPension!.annualPensionAfterTax),
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
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
        ),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: Colors.green[700]),
        ),
      ],
    );
  }

  Widget _buildDeductionRow(BuildContext context, String label, int amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '  - $label',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
        Text(
          '- ${NumberFormatter.formatCurrency(amount)}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.red[600]),
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
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.green[900], fontWeight: FontWeight.w600),
        ),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.green[700]),
        ),
      ],
    );
  }
}
