import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:gong_mu_talk/core/utils/number_formatter.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/pension_estimate.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/after_tax_pension.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/teacher_profile.dart';
import 'package:gong_mu_talk/features/calculator/presentation/views/pension_detail_page.dart';
import 'package:gong_mu_talk/features/calculator/presentation/widgets/calculation_breakdown_section.dart';

/// 퇴직 후 연금 실수령액 카드 (세전 + 세후 통합)
class PensionNetIncomeCard extends StatelessWidget {
  final bool isLocked;
  final PensionEstimate? pensionEstimate;
  final AfterTaxPension? afterTaxPension;
  final TeacherProfile? profile;

  const PensionNetIncomeCard({
    super.key,
    required this.isLocked,
    this.pensionEstimate,
    this.afterTaxPension,
    this.profile,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: isLocked || pensionEstimate == null
            ? null
            : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PensionDetailPage(
                      pensionEstimate: pensionEstimate!,
                      afterTaxPension: afterTaxPension,
                    ),
                  ),
                );
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
                        Icons.savings,
                        size: 28,
                        color: isLocked ? Colors.grey : Colors.green,
                      ),
                    ),
                    const Gap(12),
                    Expanded(
                      child: Text(
                        '퇴직 후 연금 실수령액',
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

                const Gap(12),

                const Gap(20),

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
                        const Gap(8),
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
                else if (pensionEstimate != null && afterTaxPension != null)
                  // 활성화 상태
                  Column(
                    children: [
                      // 메인 강조: 세후 월 실수령액
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.green.withValues(alpha: 0.2),
                              Colors.green.withValues(alpha: 0.1),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.green.withValues(alpha: 0.4),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green[800],
                                  size: 24,
                                ),
                                const Gap(8),
                                Text(
                                  '월 실수령액 (세후)',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: Colors.green[900],
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                            const Gap(12),
                            Text(
                              NumberFormatter.formatCurrency(
                                afterTaxPension!.monthlyPensionAfterTax,
                              ),
                              style: Theme.of(context).textTheme.headlineLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[900],
                                  ),
                            ),
                          ],
                        ),
                      ),

                      const Gap(20),

                      // 수령 기간 및 총액
                      _buildInfoRow(
                        context,
                        '📅 수령 기간',
                        '${pensionEstimate!.retirementAge}세~${pensionEstimate!.lifeExpectancy}세 (${pensionEstimate!.receivingYears}년)',
                      ),

                      const Gap(12),

                      _buildInfoRow(
                        context,
                        '💰 총 수령 예상액',
                        NumberFormatter.formatCurrency(
                          pensionEstimate!.totalPension,
                        ),
                        isHighlight: true,
                      ),

                      const Gap(16),

                      // 계산 근거 섹션
                      if (pensionEstimate != null && afterTaxPension != null)
                        _buildCalculationBreakdown(context),

                      const Gap(20),

                      // 상세 정보 (Expandable)
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: Row(
                          children: [
                            Icon(
                              Icons.list_alt,
                              size: 20,
                              color: Colors.grey[700],
                            ),
                            const Gap(8),
                            Text(
                              '세전/공제 상세 보기',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Colors.grey[800],
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                // 세전 연금
                                _buildDetailRow(
                                  context,
                                  '세전 월 연금액',
                                  NumberFormatter.formatCurrency(
                                    afterTaxPension!.monthlyPensionBeforeTax,
                                  ),
                                ),

                                const Gap(12),
                                const Divider(height: 1),
                                const Gap(12),

                                // 공제 항목
                                Text(
                                  '공제 내역',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                                const Gap(8),

                                _buildDeductionRow(
                                  context,
                                  '소득세',
                                  afterTaxPension!.incomeTax,
                                ),
                                const Gap(4),
                                _buildDeductionRow(
                                  context,
                                  '지방세',
                                  afterTaxPension!.localTax,
                                ),
                                const Gap(4),
                                _buildDeductionRow(
                                  context,
                                  '건강보험',
                                  afterTaxPension!.healthInsurance,
                                ),
                                const Gap(4),
                                _buildDeductionRow(
                                  context,
                                  '장기요양보험',
                                  afterTaxPension!.longTermCareInsurance,
                                ),

                                const Gap(12),
                                const Divider(height: 1),
                                const Gap(12),

                                // 총 공제액
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '총 공제액 (${afterTaxPension!.deductionRate.toStringAsFixed(1)}%)',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    Text(
                                      '- ${NumberFormatter.formatCurrency(afterTaxPension!.totalDeductions)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red[700],
                                          ),
                                    ),
                                  ],
                                ),

                                const Gap(12),

                                // 연간 실수령액
                                _buildDetailRow(
                                  context,
                                  '연간 실수령액 (13개월)',
                                  NumberFormatter.formatCurrency(
                                    afterTaxPension!.annualPensionAfterTax,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const Gap(16),

                      // 연금 공백 경고 (62세 정년인 경우)
                      if (pensionEstimate!.retirementAge == 62)
                        _buildPensionGapWarning(context),

                      // 상세 페이지 버튼
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PensionDetailPage(
                                  pensionEstimate: pensionEstimate!,
                                  afterTaxPension: afterTaxPension,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.analytics, size: 18),
                          label: const Text('연령별 시뮬레이션'),
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
      ),
    );
  }

  Widget _buildCalculationBreakdown(BuildContext context) {
    if (pensionEstimate == null || afterTaxPension == null) {
      return const SizedBox.shrink();
    }

    final items = <BreakdownItem>[
      BreakdownItem(
        label: '📅 재직기간: ${pensionEstimate!.serviceYears}년',
        amount: 0,
        description: '연금 지급률 산정 기준',
      ),
      BreakdownItem(
        label: '📊 평균 기준소득',
        amount: pensionEstimate!.avgBaseIncome,
        description: '재직 기간 평균',
      ),
      BreakdownItem(
        label:
            '📈 연금 지급률: ${(pensionEstimate!.pensionRate * 100).toStringAsFixed(1)}%',
        amount: 0,
        description: '1.9% × ${pensionEstimate!.serviceYears}년',
      ),
      const BreakdownItem(label: '', amount: 0), // Divider
      BreakdownItem(
        label: '세전 월 연금액',
        amount: afterTaxPension!.monthlyPensionBeforeTax,
        description: '기준소득 × 지급률',
      ),
    ];

    final deductions = <BreakdownItem>[
      BreakdownItem(
        label: '소득세',
        amount: afterTaxPension!.incomeTax,
        isDeduction: true,
      ),
      BreakdownItem(
        label: '지방세',
        amount: afterTaxPension!.localTax,
        isDeduction: true,
      ),
      BreakdownItem(
        label: '건강보험',
        amount: afterTaxPension!.healthInsurance,
        isDeduction: true,
      ),
      BreakdownItem(
        label: '장기요양보험',
        amount: afterTaxPension!.longTermCareInsurance,
        isDeduction: true,
      ),
    ];

    return CalculationBreakdownSection(
      items: [...items, ...deductions],
      totalAmount: afterTaxPension!.monthlyPensionAfterTax,
      totalLabel: '월 실수령액 (세후)',
    );
  }

  Widget _buildInfoRow(
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
            color: isHighlight ? Colors.green[900] : Colors.grey[700],
            fontWeight: isHighlight ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: isHighlight ? Colors.green[800] : Colors.green[700],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
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
            color: Colors.grey[900],
          ),
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
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
        Text(
          '- ${NumberFormatter.formatCurrency(amount)}',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.red[600]),
        ),
      ],
    );
  }

  Widget _buildPensionGapWarning(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 20,
            color: Colors.orange[700],
          ),
          const Gap(8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '연금 공백 주의',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[900],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '62~65세 사이 3년간 연금 수령 불가',
                  style: TextStyle(fontSize: 12, color: Colors.orange[800]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
