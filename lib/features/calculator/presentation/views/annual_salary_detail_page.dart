import 'package:flutter/material.dart';
import 'package:gong_mu_talk/core/utils/number_formatter.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/lifetime_salary.dart';

/// 연도별 급여 상세 페이지
class AnnualSalaryDetailPage extends StatelessWidget {
  final LifetimeSalary lifetimeSalary;

  const AnnualSalaryDetailPage({
    super.key,
    required this.lifetimeSalary,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('연도별 급여 계산'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 요약 카드
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📊 요약',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    _buildSummaryItem(
                      context,
                      '💼 생애 총 소득',
                      NumberFormatter.formatCurrency(lifetimeSalary.totalIncome),
                    ),
                    const Divider(height: 24),
                    _buildSummaryItem(
                      context,
                      '💵 현재 가치 환산',
                      NumberFormatter.formatCurrency(lifetimeSalary.presentValue),
                      subtitle: '인플레이션 ${NumberFormatter.formatPercent(lifetimeSalary.inflationRate)} 반영',
                    ),
                    const Divider(height: 24),
                    _buildSummaryItem(
                      context,
                      '📈 평균 연봉',
                      NumberFormatter.formatCurrency(lifetimeSalary.avgAnnualSalary),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 연도별 상세 내역
            Text(
              '📅 연도별 상세',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),

            // 연도별 리스트
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: lifetimeSalary.annualSalaries.length,
              itemBuilder: (context, index) {
                final salary = lifetimeSalary.annualSalaries[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ExpansionTile(
                    title: Text(
                      '${salary.year}년 (${salary.grade}호봉)',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '실수령: ${NumberFormatter.formatCurrency(salary.netPay)}/월',
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildDetailRow('본봉', salary.basePay),
                            _buildDetailRow('직책수당', salary.positionAllowance),
                            _buildDetailRow('담임수당', salary.homeroomAllowance),
                            _buildDetailRow('가족수당', salary.familyAllowance),
                            _buildDetailRow('기타수당', salary.otherAllowances),
                            const Divider(height: 24),
                            _buildDetailRow(
                              '세전 급여',
                              salary.grossPay,
                              isBold: true,
                            ),
                            const SizedBox(height: 8),
                            _buildDetailRow(
                              '소득세',
                              -salary.incomeTax,
                              color: Colors.red,
                            ),
                            _buildDetailRow(
                              '4대보험',
                              -salary.insurance,
                              color: Colors.red,
                            ),
                            const Divider(height: 24),
                            _buildDetailRow(
                              '실수령액',
                              salary.netPay,
                              isBold: true,
                              isHighlight: true,
                            ),
                            const SizedBox(height: 8),
                            _buildDetailRow(
                              '연간 총액',
                              salary.annualTotalPay,
                              isHighlight: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String label,
    String value, {
    String? subtitle,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ],
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(
    String label,
    int amount, {
    bool isBold = false,
    bool isHighlight = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
              color: color,
            ),
          ),
          Text(
            NumberFormatter.formatCurrency(amount),
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? (isHighlight ? Colors.green[700] : null),
            ),
          ),
        ],
      ),
    );
  }
}
