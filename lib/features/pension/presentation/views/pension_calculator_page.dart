import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../cubit/pension_calculator_cubit.dart';
import '../cubit/pension_calculator_state.dart';
import '../widgets/pension_input_section.dart';
import '../widgets/pension_result_card.dart';
import '../widgets/pension_projection_chart.dart';

/// 공무원연금 계산기 페이지
class PensionCalculatorPage extends StatelessWidget {
  const PensionCalculatorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('공무원연금 계산기'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () => context.read<PensionCalculatorCubit>().reset(),
            tooltip: '초기화',
          ),
        ],
      ),
      body: BlocConsumer<PensionCalculatorCubit, PensionCalculatorState>(
        listener: (context, state) {
          if (state.status == PensionCalculatorStatus.error &&
              state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 안내 카드
                _buildInfoCard(context),
                const SizedBox(height: 24),

                // 입력 섹션
                PensionInputSection(
                  profile: state.profile,
                  onBirthYearChanged: (year) {
                    context.read<PensionCalculatorCubit>().updateBirthYear(year);
                  },
                  onAppointmentYearChanged: (year) {
                    context.read<PensionCalculatorCubit>().updateAppointmentYear(year);
                  },
                  onRetirementYearChanged: (year) {
                    context.read<PensionCalculatorCubit>().updateRetirementYear(year);
                  },
                  onAverageIncomeChanged: (income) {
                    context.read<PensionCalculatorCubit>().updateAverageMonthlyIncome(income);
                  },
                  onServiceYearsChanged: (years) {
                    context.read<PensionCalculatorCubit>().updateServiceYears(years);
                  },
                  onLifespanChanged: (age) {
                    context.read<PensionCalculatorCubit>().updateExpectedLifespan(age);
                  },
                  onInflationRateChanged: (rate) {
                    context.read<PensionCalculatorCubit>().updateInflationRate(rate);
                  },
                ),
                const SizedBox(height: 24),

                // 계산 버튼
                FilledButton.icon(
                  onPressed: state.status == PensionCalculatorStatus.calculating
                      ? null
                      : () => context.read<PensionCalculatorCubit>().calculate(),
                  icon: state.status == PensionCalculatorStatus.calculating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.calculate_outlined),
                  label: Text(
                    state.status == PensionCalculatorStatus.calculating
                        ? '계산 중...'
                        : '연금 계산하기',
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 24),

                // 결과 섹션
                if (state.result != null) ...[
                  PensionResultCard(
                    result: state.result!,
                    comparison: state.comparison,
                  ),
                  const SizedBox(height: 24),

                  PensionProjectionChart(
                    projections: state.result!.yearlyProjection,
                  ),
                  const SizedBox(height: 24),

                  _buildProjectionTable(context, state),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  '연금 계산기 안내',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '• 공무원연금법에 따른 퇴직연금 계산\n'
              '• 재직기간 20년 미만: 연수 × 1.9%\n'
              '• 재직기간 20년 이상: 38% + (연수-20) × 2.0%\n'
              '• 조기퇴직 시 연 5% 감액 (최대 25%)',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectionTable(
    BuildContext context,
    PensionCalculatorState state,
  ) {
    final theme = Theme.of(context);
    final formatter = NumberFormat.currency(
      locale: 'ko_KR',
      symbol: '₩',
      decimalDigits: 0,
    );

    final projections = state.result!.yearlyProjection;
    // 처음 10년과 마지막 5년만 표시
    final displayProjections = [
      ...projections.take(10),
      if (projections.length > 15) ...[
        ...projections.skip(projections.length - 5),
      ],
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '연도별 연금 수급 예상',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Table(
              border: TableBorder.all(
                color: theme.colorScheme.outline.withAlpha(77),
              ),
              columnWidths: const {
                0: FlexColumnWidth(1),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(1.5),
                3: FlexColumnWidth(1.5),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                  ),
                  children: [
                    _buildTableCell('연도', isHeader: true),
                    _buildTableCell('나이', isHeader: true),
                    _buildTableCell('월 수급액', isHeader: true),
                    _buildTableCell('누적 총액', isHeader: true),
                  ],
                ),
                ...displayProjections.map((projection) {
                  return TableRow(
                    children: [
                      _buildTableCell('${projection.year}'),
                      _buildTableCell('${projection.age}세'),
                      _buildTableCell(
                        formatter.format(projection.monthlyAmount),
                      ),
                      _buildTableCell(
                        formatter.format(projection.cumulativeTotal),
                      ),
                    ],
                  );
                }),
              ],
            ),
            if (projections.length > 15) ...[
              const SizedBox(height: 8),
              Text(
                '※ 중간 연도 생략 (총 ${projections.length}년)',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTableCell(String text, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          fontSize: isHeader ? 13 : 12,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
