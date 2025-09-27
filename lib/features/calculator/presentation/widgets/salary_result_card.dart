import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../common/utils/currency_formatter.dart';
import '../../domain/entities/salary_breakdown.dart';

class SalaryResultCard extends StatelessWidget {
  const SalaryResultCard({
    super.key,
    required this.breakdown,
    this.isEmpty = false,
  });

  final SalaryBreakdown breakdown;
  final bool isEmpty;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: isEmpty
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '나의 월급 리포트',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Gap(12),
                  Text(
                    '기본 월급과 수당을 입력하면 실수령 월급과 연간 소득이 여기에 표시됩니다.',
                    style: textTheme.bodyMedium,
                  ),
                  const Gap(20),
                  FilledButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.auto_graph_outlined),
                    label: const Text('입력 후 계산하기 버튼을 눌러주세요'),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '나의 월급 리포트',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Gap(16),
                  _ResultRow(
                    label: '월 총 수령액',
                    value: formatCurrency(breakdown.monthlyTotal),
                  ),
                  _ResultRow(
                    label: '일 환산 금액',
                    value: formatCurrency(breakdown.dailyRate),
                  ),
                  _ResultRow(
                    label: '연간 총액',
                    value: formatCurrency(breakdown.yearlyTotal),
                  ),
                  _ResultRow(
                    label: '수당 합계',
                    value: formatCurrency(breakdown.allowancesTotal),
                  ),
                  _ResultRow(
                    label: '연금 기여금(월)',
                    value: formatCurrency(breakdown.pensionContribution),
                  ),
                  _ResultRow(
                    label: '최저임금 대비(일)',
                    value: formatCurrency(breakdown.minimumWageGap),
                  ),
                  const Divider(height: 32),
                  Text(
                    '참고 메모',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Gap(8),
                  if (breakdown.notes.isEmpty)
                    Text('입력값을 바탕으로 안내 메모가 제공됩니다.', style: textTheme.bodySmall)
                  else
                    ...breakdown.notes.map(
                      (note) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(note, style: textTheme.bodySmall),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: textTheme.bodyMedium)),
          Text(
            value,
            style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
