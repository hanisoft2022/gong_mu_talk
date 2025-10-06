import 'package:flutter/material.dart';
import 'package:gong_mu_talk/core/utils/number_formatter.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/monthly_net_income.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/monthly_salary_detail.dart';
import 'package:gong_mu_talk/features/calculator/presentation/views/salary_analysis_page.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/lifetime_salary.dart';

/// 현재 급여 실수령액 카드 (재직 중)
///
/// 월별 실수령액 분석 카드를 개선하여 사용자의 현재 급여를 강조
class CurrentSalaryCard extends StatelessWidget {
  final bool isLocked;
  final List<MonthlyNetIncome>? monthlyBreakdown;
  final LifetimeSalary? lifetimeSalary;

  const CurrentSalaryCard({
    super.key,
    required this.isLocked,
    this.monthlyBreakdown,
    this.lifetimeSalary,
  });

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
                      Icons.account_balance_wallet,
                      size: 28,
                      color: isLocked ? Colors.grey : Colors.teal,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '현재 급여 실수령액',
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
              else if (monthlyBreakdown != null && monthlyBreakdown!.isNotEmpty)
                // 활성화 상태
                Column(
                  children: [
                    // 메인 강조: 월 평균 실수령액
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.teal.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.teal.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '월 평균 실수령액',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.teal[800],
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            NumberFormatter.formatCurrency(avgNetIncome),
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal[900],
                                ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 연간 실수령액
                    _buildInfoRow(
                      context,
                      '연간 실수령액',
                      NumberFormatter.formatCurrency(annualNetIncome),
                    ),

                    const SizedBox(height: 8),

                    // 정기상여금 포함 안내
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '정기상여금 포함, 세후 기준',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // 액션 버튼
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: lifetimeSalary != null
                            ? () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SalaryAnalysisPage(
                                      lifetimeSalary: lifetimeSalary!,
                                      monthlyBreakdown: monthlyBreakdown,
                                    ),
                                  ),
                                );
                              }
                            : null,
                        icon: const Icon(Icons.analytics, size: 18),
                        label: const Text('상세 분석 보기'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
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

  Widget _buildInfoRow(BuildContext context, String label, String value) {
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
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.teal[700],
              ),
        ),
      ],
    );
  }
}

/// MonthlyNetIncome을 MonthlySalaryDetail로 변환하는 확장 메서드
extension MonthlyNetIncomeExtension on MonthlyNetIncome {
  MonthlySalaryDetail toMonthlySalaryDetail() {
    // MonthlyNetIncome은 실수령액 중심, MonthlySalaryDetail은 수당 항목 중심
    // 여기서는 간단히 매핑 (실제로는 UseCase에서 계산되어야 함)
    return MonthlySalaryDetail(
      month: month,
      baseSalary: baseSalary,
      teachingAllowance: 0, // MonthlyNetIncome에는 세부 수당이 없으므로 0
      familyAllowance: 0,
      researchAllowance: 0,
      longevityBonus: longevityBonus,
      longevityMonthly: 0,
      grossSalary: grossSalary,
    );
  }
}
