import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/pension_calculation_result.dart';

/// 연금 계산 결과 카드
class PensionResultCard extends StatelessWidget {
  const PensionResultCard({
    required this.result,
    this.comparison,
    super.key,
  });

  final PensionCalculationResult result;
  final PensionVsLumpSumComparison? comparison;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = NumberFormat.currency(
      locale: 'ko_KR',
      symbol: '₩',
      decimalDigits: 0,
    );

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '연금 계산 결과',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // 월 연금액 (강조)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '월 연금액',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    formatter.format(result.monthlyPension),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 상세 정보
            _buildInfoRow('연 연금액', formatter.format(result.yearlyPension)),
            const Divider(),
            _buildInfoRow(
              '평생 연금 총액',
              formatter.format(result.lifetimeTotal),
            ),
            const Divider(),
            _buildInfoRow(
              '지급률',
              '${(result.paymentRate * 100).toStringAsFixed(1)}%',
            ),
            if (result.earlyRetirementReduction > 0) ...[
              const Divider(),
              _buildInfoRow(
                '조기퇴직 감액',
                '${(result.earlyRetirementReduction * 100).toStringAsFixed(0)}%',
                valueColor: Colors.red,
              ),
            ],

            // 일시금 옵션
            if (result.lumpSumOption.totalAmount > 0) ...[
              const SizedBox(height: 20),
              const Divider(thickness: 2),
              const SizedBox(height: 16),
              Text(
                '일시금 옵션',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                '일시금 총액',
                formatter.format(result.lumpSumOption.totalAmount),
              ),
              const SizedBox(height: 8),
              Text(
                result.lumpSumOption.description,
                style: theme.textTheme.bodySmall,
              ),
            ],

            // 비교 결과
            if (comparison != null && comparison!.lumpSum > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '손익분기: ${comparison!.breakEvenAge}세',
                      style: TextStyle(
                        color: theme.colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      comparison!.recommendation,
                      style: TextStyle(
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // 참고사항
            if (result.notes.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Divider(thickness: 2),
              const SizedBox(height: 16),
              Text(
                '참고사항',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...result.notes.map((note) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      note,
                      style: theme.textTheme.bodySmall,
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
