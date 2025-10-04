import 'package:flutter/material.dart';
import 'package:gong_mu_talk/core/utils/number_formatter.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/lifetime_salary.dart';
import 'package:gong_mu_talk/features/calculator/presentation/views/annual_salary_detail_page.dart';
import 'package:gong_mu_talk/features/calculator/presentation/views/lifetime_earnings_page.dart';

/// 연도별 급여 계산 카드
class AnnualSalaryCard extends StatelessWidget {
  final bool isLocked;
  final LifetimeSalary? lifetimeSalary;

  const AnnualSalaryCard({
    super.key,
    required this.isLocked,
    this.lifetimeSalary,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: isLocked
            ? null
            : () {
                if (lifetimeSalary != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AnnualSalaryDetailPage(
                        lifetimeSalary: lifetimeSalary!,
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
                            : Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.trending_up,
                        size: 28,
                        color: isLocked ? Colors.grey : Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '연도별 급여 계산',
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
                else if (lifetimeSalary != null)
                  // 활성화 상태
                  Column(
                    children: [
                      // 요약 정보
                      _buildSummaryRow(
                        context,
                        '💼 생애 총 소득',
                        NumberFormatter.formatCurrency(
                          lifetimeSalary!.totalIncome,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildSummaryRow(
                        context,
                        '💵 현재 가치 환산',
                        NumberFormatter.formatCurrency(
                          lifetimeSalary!.presentValue,
                        ),
                        subtitle:
                            '(인플레이션 ${(lifetimeSalary!.inflationRate * 100).toStringAsFixed(1)}% 반영)',
                      ),
                      const SizedBox(height: 12),
                      _buildSummaryRow(
                        context,
                        '📈 평균 연봉',
                        NumberFormatter.formatCurrency(
                          lifetimeSalary!.avgAnnualSalary,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // CTA 버튼들
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LifetimeEarningsPage(
                                      lifetimeSalary: lifetimeSalary!,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.analytics_outlined, size: 18),
                              label: const Text('시뮬레이션'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AnnualSalaryDetailPage(
                                      lifetimeSalary: lifetimeSalary!,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.list_alt, size: 18),
                              label: const Text('상세보기'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
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
    String? subtitle,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[700],
                  ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[500],
                      fontSize: 11,
                    ),
              ),
            ],
          ],
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
        ),
      ],
    );
  }
}
