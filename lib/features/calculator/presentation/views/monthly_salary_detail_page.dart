import 'package:flutter/material.dart';
import 'package:gong_mu_talk/core/utils/number_formatter.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/monthly_salary_detail.dart';

/// 월별 급여명세서 페이지
///
/// 12개월 급여 상세 내역을 카드 형태로 표시
class MonthlySalaryDetailPage extends StatelessWidget {
  final List<MonthlySalaryDetail> monthlyDetails;

  const MonthlySalaryDetailPage({
    super.key,
    required this.monthlyDetails,
  });

  @override
  Widget build(BuildContext context) {
    // 연간 총 급여 계산
    final annualGrossSalary = monthlyDetails.fold<int>(
      0,
      (sum, detail) => sum + detail.grossSalary,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('월별 급여명세서'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 연간 총액 요약
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.blue.shade600],
              ),
            ),
            child: Column(
              children: [
                const Text(
                  '연간 총 급여',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  NumberFormatter.formatCurrency(annualGrossSalary),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '평균 월 ${NumberFormatter.formatCurrency(annualGrossSalary ~/ 12)}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // 월별 급여 리스트
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: monthlyDetails.length,
              itemBuilder: (context, index) {
                return _MonthCard(detail: monthlyDetails[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// 월별 급여 카드
class _MonthCard extends StatelessWidget {
  final MonthlySalaryDetail detail;

  const _MonthCard({required this.detail});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ExpansionTile(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: detail.hasLongevityBonus
                    ? Colors.orange.shade100
                    : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${detail.month}월',
                style: TextStyle(
                  color: detail.hasLongevityBonus
                      ? Colors.orange.shade900
                      : Colors.blue.shade900,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            if (detail.hasLongevityBonus) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '정근수당',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            '총 지급액: ${NumberFormatter.formatCurrency(detail.grossSalary)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _SalaryRow('본봉', detail.baseSalary),
                const SizedBox(height: 8),
                _SalaryRow('교직수당', detail.teachingAllowance),
                
                if (detail.homeroomAllowance > 0) ...[
                  const SizedBox(height: 8),
                  _SalaryRow('담임수당', detail.homeroomAllowance),
                ],
                
                if (detail.positionAllowance > 0) ...[
                  const SizedBox(height: 8),
                  _SalaryRow('보직교사수당', detail.positionAllowance),
                ],
                
                if (detail.veteranAllowance > 0) ...[
                  const SizedBox(height: 8),
                  _SalaryRow(
                    '원로교사수당',
                    detail.veteranAllowance,
                    icon: Icons.star,
                  ),
                ],
                
                const SizedBox(height: 8),
                _SalaryRow('가족수당', detail.familyAllowance),
                
                const SizedBox(height: 8),
                _SalaryRow('교원연구비', detail.researchAllowance),
                
                if (detail.mealAllowance > 0) ...[
                  const SizedBox(height: 8),
                  _SalaryRow('정액급식비', detail.mealAllowance),
                ],
                
                const SizedBox(height: 8),
                _SalaryRow('시간외근무수당', detail.overtimeAllowance),
                
                const SizedBox(height: 8),
                _SalaryRow('정근수당 가산금', detail.longevityMonthly),
                
                if (detail.longevityBonus > 0) ...[
                  const SizedBox(height: 8),
                  _SalaryRow(
                    '정근수당 (${detail.month}월)',
                    detail.longevityBonus,
                    highlight: true,
                    icon: Icons.celebration,
                  ),
                ],
                
                const Divider(height: 24),
                
                _SalaryRow(
                  '총 지급액',
                  detail.grossSalary,
                  isTotal: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 급여 항목 행
class _SalaryRow extends StatelessWidget {
  final String label;
  final int amount;
  final bool isTotal;
  final bool highlight;
  final IconData? icon;

  const _SalaryRow(
    this.label,
    this.amount, {
    this.isTotal = false,
    this.highlight = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: isTotal
          ? const EdgeInsets.symmetric(vertical: 12, horizontal: 16)
          : EdgeInsets.zero,
      decoration: isTotal
          ? BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            )
          : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: highlight ? Colors.orange : Colors.grey,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: isTotal ? 16 : 14,
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                  color: highlight
                      ? Colors.orange.shade900
                      : (isTotal ? Colors.blue.shade900 : Colors.black87),
                ),
              ),
            ],
          ),
          Text(
            NumberFormatter.formatCurrency(amount),
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal || highlight
                  ? FontWeight.bold
                  : FontWeight.normal,
              color: highlight
                  ? Colors.orange.shade900
                  : (isTotal ? Colors.blue.shade900 : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}
