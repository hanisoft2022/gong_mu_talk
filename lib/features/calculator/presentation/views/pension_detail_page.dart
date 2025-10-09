import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:gong_mu_talk/core/utils/number_formatter.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/pension_estimate.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/after_tax_pension.dart';
import 'package:gong_mu_talk/common/widgets/info_dialog.dart';

/// 예상 연금 수령액 상세 페이지 (세후 실수령액 중심)
class PensionDetailPage extends StatelessWidget {
  final PensionEstimate pensionEstimate;
  final AfterTaxPension? afterTaxPension;

  const PensionDetailPage({
    super.key,
    required this.pensionEstimate,
    this.afterTaxPension,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('연금 실수령액 상세'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 세후 실수령액 메인 카드 (있는 경우)
            if (afterTaxPension != null) ...[
              Card(
                elevation: 4,
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 32,
                            color: Colors.green[800],
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '월 실수령액 (세후)',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[900],
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        NumberFormatter.formatCurrency(
                          afterTaxPension!.monthlyPensionAfterTax,
                        ),
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green[900],
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '연간 ${NumberFormatter.formatCurrency(afterTaxPension!.annualPensionAfterTax)} (13개월 기준)',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
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
                      NumberFormatter.formatCurrency(
                        pensionEstimate.avgBaseIncome,
                      ),
                    ),
                    _buildInfoRow(
                      context,
                      '📈 연금 지급률',
                      NumberFormatter.formatPercent(
                        pensionEstimate.pensionRate,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 세전/공제 상세 (afterTaxPension이 있는 경우)
            if (afterTaxPension != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '💰 세전/공제 상세',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 세전 월 연금
                      _buildTaxDetailRow(
                        context,
                        '세전 월 연금액',
                        NumberFormatter.formatCurrency(
                          afterTaxPension!.monthlyPensionBeforeTax,
                        ),
                      ),

                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),

                      // 공제 항목
                      Text(
                        '공제 내역',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),

                      _buildDeductionRow(
                        context,
                        '소득세',
                        afterTaxPension!.incomeTax,
                      ),
                      const SizedBox(height: 8),
                      _buildDeductionRow(
                        context,
                        '지방세',
                        afterTaxPension!.localTax,
                      ),
                      const SizedBox(height: 8),
                      _buildDeductionRow(
                        context,
                        '건강보험',
                        afterTaxPension!.healthInsurance,
                      ),
                      const SizedBox(height: 8),
                      _buildDeductionRow(
                        context,
                        '장기요양보험',
                        afterTaxPension!.longTermCareInsurance,
                      ),

                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),

                      // 총 공제액
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '총 공제액 (${afterTaxPension!.deductionRate.toStringAsFixed(1)}%)',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '- ${NumberFormatter.formatCurrency(afterTaxPension!.totalDeductions)}',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red[700],
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              // afterTaxPension이 없으면 기존 세전 카드만 표시
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        '💎 월 수령액 (세전)',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        NumberFormatter.formatCurrency(
                          pensionEstimate.monthlyPension,
                        ),
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
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
            ],

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
                      NumberFormatter.formatCurrency(
                        pensionEstimate.totalPension,
                      ),
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green[900],
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${pensionEstimate.retirementAge}세~${pensionEstimate.lifeExpectancy}세 (${pensionEstimate.receivingYears}년 수령)',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 소득 공백 경고 (62세 정년인 경우)
            if (pensionEstimate.retirementAge == 62)
              _buildIncomeGapWarning(context),

            const SizedBox(height: 24),

            // 연금 수령 시뮬레이션 차트
            _buildPensionSimulationChart(context),

            const SizedBox(height: 24),

            // 상세 분석
            Text(
              '🔍 상세 분석',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
                            decimals: 0,
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
                      style: TextStyle(fontSize: 12, color: Colors.blue[900]),
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

  void _showDetailDialog(BuildContext context, String label, String value) {
    final String title = label.replaceAll(RegExp(r'[📅📊💵📈]'), '').trim();
    String description = '';

    // 항목별 상세 설명 매핑
    if (label.contains('재직 기간') || label.contains('재직기간')) {
      description = '연금 지급률 산정의 기준이 되는 재직 기간입니다.\n\n재직 기간이 길수록 연금 지급률이 높아집니다.\n\n지급률 = 1.9% × 재직년수';
    } else if (label.contains('평균 기준소득')) {
      description = '재직 기간 동안의 평균 기준소득입니다.\n\n매년 받은 급여의 평균값으로, 연금액 계산의 기준이 됩니다.';
    } else if (label.contains('연금 지급률')) {
      description =
          '연금 지급률은 재직 기간에 비례하여 결정됩니다.\n\n계산식: 1.9% × ${pensionEstimate.serviceYears}년 = ${(pensionEstimate.pensionRate * 100).toStringAsFixed(1)}%';
    } else if (label.contains('세전 월 연금액')) {
      description =
          '공제 전 월 연금액입니다.\n\n계산식: 평균 기준소득 × 연금 지급률\n= ${NumberFormatter.formatCurrency(pensionEstimate.avgBaseIncome)} × ${(pensionEstimate.pensionRate * 100).toStringAsFixed(1)}%';
    } else if (label.contains('소득세')) {
      description = '연금 소득에 대한 소득세입니다.\n\n연금 수령액에 따라 누진세율이 적용됩니다.';
    } else if (label.contains('지방세')) {
      description = '소득세의 10%가 지방소득세로 부과됩니다.\n\n지방세 = 소득세 × 10%';
    } else if (label.contains('건강보험')) {
      description = '연금 수령자도 건강보험료를 납부해야 합니다.\n\n연금액의 일정 비율로 계산됩니다.';
    } else if (label.contains('장기요양보험')) {
      description = '건강보험료에 비례하여 장기요양보험료가 부과됩니다.\n\n장기요양 = 건강보험료 × 장기요양보험료율';
    }

    InfoDialog.showWidget(
      context,
      title: title,
      icon: Icons.info_outline,
      iconColor: Colors.green.shade600,
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
              const Text('금액', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    // Skip adding tap functionality for "퇴직 예정 연령" as it's not a calculation result
    final bool isTappable = !label.contains('퇴직 예정 연령');

    return InkWell(
      onTap: isTappable ? () => _showDetailDialog(context, label, value) : null,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(label, style: Theme.of(context).textTheme.bodyMedium),
                if (isTappable) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                ],
              ],
            ),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
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

  Widget _buildPensionSimulationChart(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📊 연금 누적 수령액 시뮬레이션',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(height: 300, child: _buildAreaChart(theme)),
          ),
        ),
      ],
    );
  }

  Widget _buildAreaChart(ThemeData theme) {
    // 연금 누적 수령액 시뮬레이션 데이터 생성
    final cumulativeData = <FlSpot>[];
    final contributionLineData = <FlSpot>[];
    int cumulative = 0;

    for (int i = 0; i <= pensionEstimate.receivingYears; i++) {
      // 누적 수령액
      cumulative = pensionEstimate.annualPension * i;
      cumulativeData.add(FlSpot(i.toDouble(), cumulative.toDouble()));

      // 기여금 총액 (비교용)
      contributionLineData.add(
        FlSpot(i.toDouble(), pensionEstimate.totalContribution.toDouble()),
      );
    }

    final maxValue = pensionEstimate.totalPension.toDouble();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxValue / 5,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${(value / 100000000).toStringAsFixed(0)}억',
                  style: theme.textTheme.bodySmall,
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 5,
              getTitlesWidget: (value, meta) {
                if (value.toInt() % 5 != 0) return const SizedBox();
                final age = pensionEstimate.retirementAge + value.toInt();
                return Text('$age세', style: theme.textTheme.bodySmall);
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          // 기여금 총액 라인 (점선)
          LineChartBarData(
            spots: contributionLineData,
            isCurved: false,
            color: Colors.orange.withValues(alpha: 0.7),
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            dashArray: [5, 5],
          ),
          // 누적 수령액 라인 (실선 + 영역)
          LineChartBarData(
            spots: cumulativeData,
            isCurved: true,
            color: theme.colorScheme.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.3),
                  theme.colorScheme.primary.withValues(alpha: 0.05),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final years = spot.x.toInt();
                final age = pensionEstimate.retirementAge + years;
                final isContribution = spot.barIndex == 0;

                if (isContribution) {
                  return LineTooltipItem(
                    '$age세\n총 납부액: ${NumberFormatter.formatCurrency(spot.y.toInt())}',
                    theme.textTheme.bodySmall!.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                } else {
                  return LineTooltipItem(
                    '$age세 ($years년)\n누적 수령액: ${NumberFormatter.formatCurrency(spot.y.toInt())}',
                    theme.textTheme.bodySmall!.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }
              }).toList();
            },
          ),
        ),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            // 기여금 총액 기준선
            HorizontalLine(
              y: pensionEstimate.totalContribution.toDouble(),
              color: Colors.orange.withValues(alpha: 0.3),
              strokeWidth: 1,
              dashArray: [5, 5],
            ),
          ],
        ),
      ),
    );
  }

  /// 소득 공백 경고 위젯 (2027년 이후 퇴직자, 62세 정년)
  Widget _buildIncomeGapWarning(BuildContext context) {
    // 연금 수령 시작 나이 (일반적으로 65세)
    const pensionStartAge = 65;

    // 소득 공백 기간 계산
    final gapYears = pensionStartAge - pensionEstimate.retirementAge;

    // 2027년 이전 퇴직자는 경고 불필요 (임시 면제 기간)
    final currentYear = DateTime.now().year;
    if (currentYear < 2027 && gapYears > 0) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade300),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange.shade700,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '⚠️ 소득 공백 주의',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '정년 퇴직 후 ${pensionEstimate.retirementAge}세~$pensionStartAge세 사이 $gapYears년간 연금 수령이 불가능합니다.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.orange.shade900,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '💡 대응 방안',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildSuggestion('별도 생활비 준비 (약 $gapYears년분)'),
                        _buildSuggestion('정년 연장 법안 통과 시 65세까지 재직'),
                        _buildSuggestion('퇴직 후 시간제 근무 또는 재취업'),
                        _buildSuggestion('개인연금/퇴직연금 활용'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  /// 대응 방안 항목
  Widget _buildSuggestion(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(fontSize: 13, color: Colors.orange.shade700),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
            ),
          ),
        ],
      ),
    );
  }

  /// 세전/공제 상세 정보 행
  Widget _buildTaxDetailRow(BuildContext context, String label, String value) {
    return InkWell(
      onTap: () => _showDetailDialog(context, label, value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                ),
                const SizedBox(width: 4),
                Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
              ],
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey[900],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 공제 항목 행
  Widget _buildDeductionRow(BuildContext context, String label, int amount) {
    return InkWell(
      onTap: () => _showDetailDialog(context, label, '- ${NumberFormatter.formatCurrency(amount)}'),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                ),
                const SizedBox(width: 4),
                Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
              ],
            ),
            Text(
              '- ${NumberFormatter.formatCurrency(amount)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.red[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
