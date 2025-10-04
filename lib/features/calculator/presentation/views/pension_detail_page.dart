import 'package:flutter/material.dart';
import 'package:gong_mu_talk/core/utils/number_formatter.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/pension_estimate.dart';

/// 예상 연금 수령액 상세 페이지
class PensionDetailPage extends StatelessWidget {
  final PensionEstimate pensionEstimate;

  const PensionDetailPage({
    super.key,
    required this.pensionEstimate,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('예상 연금 수령액'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 연금 계산 결과 카드
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '💰 연금 계산 결과',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      context,
                      '📅 퇴직 예정 연령',
                      '${pensionEstimate.retirementAge}세',
                    ),
                    _buildInfoRow(
                      context,
                      '📊 재직 기간',
                      '${pensionEstimate.serviceYears}년',
                    ),
                    _buildInfoRow(
                      context,
                      '💵 평균 기준소득',
                      NumberFormatter.formatCurrency(pensionEstimate.avgBaseIncome),
                    ),
                    _buildInfoRow(
                      context,
                      '📈 연금 지급률',
                      NumberFormatter.formatPercent(pensionEstimate.pensionRate),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 월 수령액 카드
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      '💎 월 수령액',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      NumberFormatter.formatCurrency(pensionEstimate.monthlyPension),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '연간 ${NumberFormatter.formatCurrency(pensionEstimate.annualPension)} (13개월 기준)',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[700],
                          ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 총 수령 예상액 카드
            Card(
              color: Colors.green[50],
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      '📊 총 수령 예상액',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      NumberFormatter.formatCurrency(pensionEstimate.totalPension),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green[900],
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${pensionEstimate.retirementAge}세~${pensionEstimate.lifeExpectancy}세 (${pensionEstimate.receivingYears}년 수령)',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[700],
                          ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 상세 분석
            Text(
              '🔍 상세 분석',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),

            Card(
              child: ExpansionTile(
                title: const Text('기여금 납부 내역'),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildDetailRow(
                          '총 납부액',
                          NumberFormatter.formatCurrency(
                            pensionEstimate.totalContribution,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildDetailRow(
                          '총 수령액',
                          NumberFormatter.formatCurrency(
                            pensionEstimate.totalPension,
                          ),
                        ),
                        const Divider(height: 24),
                        _buildDetailRow(
                          '투자 수익률',
                          NumberFormatter.formatPercent(
                            pensionEstimate.returnRate,
                            decimalPlaces: 0,
                          ),
                          isHighlight: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // 안내 메시지
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '* 실제 연금액은 개정된 법률 및 개인별 상황에 따라 달라질 수 있습니다.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[900],
                      ),
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

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isHighlight = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isHighlight ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isHighlight ? Colors.green[700] : null,
          ),
        ),
      ],
    );
  }
}
