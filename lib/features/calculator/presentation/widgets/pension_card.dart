import 'package:flutter/material.dart';
import 'package:gong_mu_talk/core/utils/number_formatter.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/pension_estimate.dart';
import 'package:gong_mu_talk/features/calculator/presentation/views/pension_detail_page.dart';

/// 예상 연금 수령액 카드
class PensionCard extends StatelessWidget {
  final bool isLocked;
  final PensionEstimate? pensionEstimate;

  const PensionCard({
    super.key,
    required this.isLocked,
    this.pensionEstimate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: isLocked
            ? null
            : () {
                if (pensionEstimate != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PensionDetailPage(
                        pensionEstimate: pensionEstimate!,
                      ),
                    ),
                  );
                }
              },
        borderRadius: BorderRadius.circular(12),
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
                            : Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.account_balance,
                        size: 28,
                        color: isLocked ? Colors.grey : Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '예상 연금 수령액',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    if (isLocked)
                      const Icon(Icons.lock, color: Colors.grey)
                    else
                      const Icon(Icons.arrow_forward_ios, size: 16),
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
                else if (pensionEstimate != null)
                  // 활성화 상태
                  Column(
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
                        NumberFormatter.formatCurrency(
                          pensionEstimate!.monthlyPension,
                        ),
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
                        NumberFormatter.formatCurrency(
                          pensionEstimate!.totalPension,
                        ),
                        isHighlight: true,
                      ),

                      const SizedBox(height: 20),

                      // CTA 버튼
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PensionDetailPage(
                                  pensionEstimate: pensionEstimate!,
                                ),
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
                      ),
                    ],
                  ),
              ],
            ),
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
                color: isHighlight ? Colors.blue[900] : Colors.grey[700],
                fontWeight: isHighlight ? FontWeight.w600 : FontWeight.normal,
              ),
        ),
        if (value.isNotEmpty)
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isHighlight ? Colors.blue[700] : Colors.blue[600],
                ),
          ),
      ],
    );
  }
}
