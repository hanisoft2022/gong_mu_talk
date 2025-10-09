import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:gong_mu_talk/core/utils/number_formatter.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/retirement_benefit.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/early_retirement_bonus.dart';
import 'package:gong_mu_talk/common/widgets/info_dialog.dart';

/// 퇴직 시 일시금 상세 페이지
///
/// 퇴직급여 + 명예퇴직금의 상세 계산 로직 및 시나리오 비교
class RetirementLumpsumDetailPage extends StatelessWidget {
  final RetirementBenefit retirementBenefit;
  final EarlyRetirementBonus? earlyRetirementBonus;

  const RetirementLumpsumDetailPage({
    super.key,
    required this.retirementBenefit,
    this.earlyRetirementBonus,
  });

  @override
  Widget build(BuildContext context) {
    final totalLumpsum = retirementBenefit.totalBenefit + (earlyRetirementBonus?.totalAmount ?? 0);
    final hasEarlyBonus = earlyRetirementBonus != null && earlyRetirementBonus!.totalAmount > 0;

    return Scaffold(
      appBar: AppBar(title: const Text('퇴직 시 일시금 상세'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 총액 카드
            Card(
              elevation: 4,
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.diamond, size: 32, color: Colors.orange[800]),
                        const SizedBox(width: 12),
                        Text(
                          '퇴직 시 수령 총액',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[900],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      NumberFormatter.formatCurrency(totalLumpsum),
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[900],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Gap(20),
            // 퇴직급여 상세
            _buildSectionHeader(context, '📋 퇴직급여', Colors.orange),
            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 기간별 퇴직급여
                    Text(
                      '기간별 퇴직급여',
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    if (retirementBenefit.period1Years > 0) ...[
                      _buildPeriodCard(
                        context,
                        period: '1기간',
                        dateRange: '~2009.12.31',
                        years: retirementBenefit.period1Years,
                        amount: retirementBenefit.period1Benefit,
                        baseIncome: retirementBenefit.period1BaseIncome,
                        explanation: '재직 기간 × 월 보수액',
                      ),
                      const SizedBox(height: 12),
                    ],

                    if (retirementBenefit.period2Years > 0) ...[
                      _buildPeriodCard(
                        context,
                        period: '2기간',
                        dateRange: '2010.1.1~2015.12.31',
                        years: retirementBenefit.period2Years,
                        amount: retirementBenefit.period2Benefit,
                        baseIncome: retirementBenefit.period23BaseIncome,
                        explanation: '재직 기간 × 월 보수액 × 1/12',
                      ),
                      const SizedBox(height: 12),
                    ],

                    if (retirementBenefit.period3Years > 0) ...[
                      _buildPeriodCard(
                        context,
                        period: '3기간',
                        dateRange: '2016.1.1~',
                        years: retirementBenefit.period3Years,
                        amount: retirementBenefit.period3Benefit,
                        baseIncome: retirementBenefit.period23BaseIncome,
                        explanation: '재직 기간 × 월 보수액 × 1/12',
                      ),
                      const SizedBox(height: 12),
                    ],

                    const Divider(height: 32),

                    // 퇴직수당
                    InkWell(
                      onTap: () => _showDetailDialog(
                        context,
                        '퇴직수당',
                        retirementBenefit.retirementAllowance,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '퇴직수당',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange[900],
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.info_outline, size: 16, color: Colors.orange[700]),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '1기간 + (2기간 + 3기간) × 0.6',
                              style: TextStyle(fontSize: 13, color: Colors.orange[800]),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('금액'),
                                Text(
                                  NumberFormatter.formatCurrency(
                                    retirementBenefit.retirementAllowance,
                                  ),
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange[900],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 퇴직급여 총액
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade300, width: 2),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '퇴직급여 총액',
                            style: Theme.of(
                              context,
                            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            NumberFormatter.formatCurrency(retirementBenefit.totalBenefit),
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[900],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 명예퇴직금 (있는 경우만)
            if (hasEarlyBonus) ...[
              const SizedBox(height: 24),
              _buildSectionHeader(context, '🎁 명예퇴직금', Colors.purple),
              const SizedBox(height: 12),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(context, '명퇴 시점 연령', '${earlyRetirementBonus!.retirementAge}세'),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        context,
                        '정년까지 잔여기간',
                        '${earlyRetirementBonus!.remainingYears}년 ${earlyRetirementBonus!.remainingMonths}개월',
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(context, '현재 호봉', '${earlyRetirementBonus!.currentGrade}호봉'),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        context,
                        '기본급',
                        NumberFormatter.formatCurrency(earlyRetirementBonus!.baseSalary),
                      ),

                      const Divider(height: 32),

                      // 계산 상세
                      Text(
                        '계산 방식',
                        style: Theme.of(
                          context,
                        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),

                      InkWell(
                        onTap: () => _showDetailDialog(
                          context,
                          '기본 명퇴금',
                          earlyRetirementBonus!.baseAmount,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '기본 명퇴금 = 기본급 × 잔여기간(개월)',
                                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.info_outline, size: 14, color: Colors.grey[600]),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('기본 명퇴금'),
                                  Text(
                                    NumberFormatter.formatCurrency(earlyRetirementBonus!.baseAmount),
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      if (earlyRetirementBonus!.bonusAmount > 0) ...[
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () => _showDetailDialog(
                            context,
                            '가산금 (10% 추가)',
                            earlyRetirementBonus!.bonusAmount,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.purple.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      '가산금 (55세 이상 10% 추가)',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.purple[700],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(Icons.info_outline, size: 14, color: Colors.purple[600]),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('가산금'),
                                    Text(
                                      NumberFormatter.formatCurrency(
                                        earlyRetirementBonus!.bonusAmount,
                                      ),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.purple[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // 명예퇴직금 총액
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.purple.shade300, width: 2),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '명예퇴직금 총액',
                              style: Theme.of(
                                context,
                              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              NumberFormatter.formatCurrency(earlyRetirementBonus!.totalAmount),
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.purple[900],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // 안내 메시지
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '안내사항',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[900]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• 퇴직급여는 재직 기간에 따라 1~3기간으로 구분되어 계산됩니다.\n'
                          '• 명예퇴직금은 정년 전 조기 퇴직 시 지급됩니다.\n'
                          '• 실제 금액은 개인별 상황에 따라 달라질 수 있습니다.',
                          style: TextStyle(fontSize: 13, color: Colors.blue[800], height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, MaterialColor color) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: color[900]),
    );
  }

  Widget _buildPeriodCard(
    BuildContext context, {
    required String period,
    required String dateRange,
    required int years,
    required int amount,
    required int baseIncome,
    required String explanation,
  }) {
    return InkWell(
      onTap: () => _showDetailDialog(context, '$period ($years년)', amount),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          period,
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(dateRange, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
                Text(
                  NumberFormatter.formatCurrency(amount),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            _buildDetailRow('재직 기간', '$years년'),
            const SizedBox(height: 8),
            _buildDetailRow('적용 보수', NumberFormatter.formatCurrency(baseIncome)),
            const SizedBox(height: 8),
            _buildDetailRow('계산식', explanation),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('• $label: ', style: TextStyle(fontSize: 13, color: Colors.grey[700])),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 13, color: Colors.grey[800], fontWeight: FontWeight.w500),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  void _showDetailDialog(BuildContext context, String label, int amount) {
    final String title = label;
    String description = '';

    // 항목별 상세 설명 매핑
    if (label.contains('1기간')) {
      description = '2009년 12월 31일 이전 재직 기간에 대한 퇴직급여입니다.\n\n평균보수 × 재직월수 ÷ 12로 계산됩니다.';
    } else if (label.contains('2기간')) {
      description =
          '2010년 1월 1일 ~ 2015년 12월 31일 재직 기간에 대한 퇴직급여입니다.\n\n평균보수 × 재직월수 ÷ 12로 계산됩니다.';
    } else if (label.contains('3기간')) {
      description = '2016년 1월 1일 이후 재직 기간에 대한 퇴직급여입니다.\n\n평균보수 × 재직월수 ÷ 12로 계산됩니다.';
    } else if (label.contains('퇴직수당')) {
      description = '재직기간에 따라 지급되는 가산금입니다.\n\n5년 이상 재직 시 지급되며, 재직 기간이 길수록 증가합니다.';
    } else if (label.contains('기본 명퇴금')) {
      description = '정년 전 조기 퇴직 시 지급되는 기본 명예퇴직금입니다.\n\n정년까지 남은 기간에 따라 지급액이 결정됩니다.';
    } else if (label.contains('가산금')) {
      description = '기본 명예퇴직금의 10%를 추가로 지급하는 가산금입니다.\n\n조기 퇴직 장려를 위해 지급됩니다.';
    }

    InfoDialog.showWidget(
      context,
      title: title,
      icon: Icons.info_outline,
      iconColor: Colors.orange.shade600,
      confirmText: '닫기',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(description, style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.5)),
          const Gap(16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('지급액', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              Text(
                NumberFormatter.formatCurrency(amount),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.orange.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
