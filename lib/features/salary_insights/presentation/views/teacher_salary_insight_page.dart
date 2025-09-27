import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../domain/annual_salary.dart';
import '../../domain/monthly_salary.dart';
import '../../domain/teacher_salary_profile.dart';

class TeacherSalaryInsightPage extends StatefulWidget {
  const TeacherSalaryInsightPage({super.key});

  @override
  State<TeacherSalaryInsightPage> createState() =>
      _TeacherSalaryInsightPageState();
}

class _TeacherSalaryInsightPageState extends State<TeacherSalaryInsightPage> {
  late final MonthlySalary _currentSalary;
  late TeacherSalaryProfile _profile;
  late final NumberFormat _currencyFormat;
  late final int _currentYear;
  late final int _defaultRetirementYear;
  late int _retirementYear;
  late final TextEditingController _performanceController;
  late final TextEditingController _holidayController;
  late final TextEditingController _longevityController;
  String _selectedPerformanceGrade = 'A';
  double _raiseRate = 0.02;
  double _allowanceGrowthRate = 0.01;

  @override
  void initState() {
    super.initState();
    _currencyFormat = NumberFormat.currency(
      locale: 'ko_KR',
      symbol: '₩',
      decimalDigits: 0,
    );
    _currentYear = DateTime.now().year;
    _currentSalary = const MonthlySalary(
      basePay: 2567600,
      longevityAllowance: 30000,
      mealAllowance: 140000,
      teacherAllowance: 250000,
      teacherExtraAllowance: 200000,
      familyAllowance: 20000,
      overtimeAllowance: 123630,
      researchAllowance: 75000,
      otherAllowances: 0,
      incomeTax: 131560,
      localIncomeTax: 13150,
      pensionContribution: 303810,
      healthInsurance: 115980,
      longTermCare: 15020,
      unionFee: 300640,
      otherDeductions: 20000,
    );
    _defaultRetirementYear = _currentYear + 23;
    _retirementYear = _defaultRetirementYear;

    _performanceController = TextEditingController(
      text: _performanceAmountForGrade(
        _selectedPerformanceGrade,
      ).round().toString(),
    );
    _holidayController = TextEditingController(
      text: (_currentSalary.basePay * 1.2 * 2).round().toString(),
    );
    _longevityController = TextEditingController(
      text: (_currentSalary.basePay * 0.05 * 2).round().toString(),
    );

    _profile = _buildProfileFromState();
  }

  @override
  void dispose() {
    _performanceController.dispose();
    _holidayController.dispose();
    _longevityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AuthState authState = context.watch<AuthCubit>().state;
    final int grossMonthly = _currentSalary.totalAllowances;
    final int deductionsMonthly = _currentSalary.totalDeductions;
    final int netMonthly = _currentSalary.netPay;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              TextButton.icon(
                onPressed: _resetToDefaults,
                icon: const Icon(Icons.refresh_outlined),
                label: const Text('기본값으로 초기화'),
              ),
            ],
          ),
          if (authState.nickname.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '대상자: ${authState.nickname}',
              style: theme.textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 6),
          Text(
            '최근 급여명세서 OCR 결과를 기반으로 자동 채운 값입니다. 필요한 항목을 수정하면 바로 반영돼요.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '이번 달 급여 요약',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _SummaryMetric(
                        label: '세전 월급',
                        value: _formatCurrency(grossMonthly),
                      ),
                      _SummaryMetric(
                        label: '총 공제액',
                        value: _formatCurrency(deductionsMonthly),
                      ),
                      _SummaryMetric(
                        label: '실수령액',
                        value: _formatCurrency(netMonthly),
                      ),
                      _SummaryMetric(
                        label: '올해 세전 연봉',
                        value: _formatCurrency(
                          _profile.currentGrossAnnual.round(),
                        ),
                      ),
                      _SummaryMetric(
                        label: '올해 세후 연봉',
                        value: _formatCurrency(
                          _profile.currentNetAnnual.round(),
                        ),
                      ),
                      _SummaryMetric(
                        label: '정년까지 세전 총소득',
                        value: _formatCurrency(
                          _profile.projectedLifetimeGross.round(),
                        ),
                      ),
                      _SummaryMetric(
                        label: '정년까지 실수령 합계',
                        value: _formatCurrency(
                          _profile.projectedLifetimeNet.round(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildInputsCard(theme),
          const SizedBox(height: 24),
          _buildProjectionTable(theme),
          const SizedBox(height: 24),
          _buildProjectionChart(theme),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => context.push('/salary/calculator'),
            icon: const Icon(Icons.calculate_outlined),
            label: const Text('상세 월급 계산기로 이동'),
          ),
        ],
      ),
    );
  }

  Widget _buildInputsCard(ThemeData theme) {
    final String holidayDefault = _formatCurrency(
      (_currentSalary.basePay * 1.2 * 2).round(),
    );
    final String longevityDefault = _formatCurrency(
      (_currentSalary.basePay * 0.05 * 2).round(),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '누락된 급여 구성요소 입력',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '성과상여금, 명절휴가비, 정근수당(본) 등은 직접 확인 후 입력해주세요.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: 220,
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: '성과상여금 등급'),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedPerformanceGrade,
                        isExpanded: true,
                        items: const <DropdownMenuItem<String>>[
                          DropdownMenuItem<String>(
                            value: 'S',
                            child: Text('S 등급 (약 1.5개월)'),
                          ),
                          DropdownMenuItem<String>(
                            value: 'A',
                            child: Text('A 등급 (약 1.2개월)'),
                          ),
                          DropdownMenuItem<String>(
                            value: 'B',
                            child: Text('B 등급 (약 1개월)'),
                          ),
                          DropdownMenuItem<String>(
                            value: 'custom',
                            child: Text('직접 입력'),
                          ),
                        ],
                        onChanged: (String? grade) {
                          if (grade == null) {
                            return;
                          }
                          setState(() {
                            _selectedPerformanceGrade = grade;
                            if (grade != 'custom') {
                              _performanceController.text =
                                  _performanceAmountForGrade(
                                    grade,
                                  ).round().toString();
                            }
                            _profile = _buildProfileFromState();
                          });
                        },
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 260,
                  child: TextField(
                    controller: _performanceController,
                    decoration: const InputDecoration(
                      labelText: '성과상여금 (연간 원화)',
                      helperText: '필요 시 등급 대신 직접 입력하세요.',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: (_) {
                      setState(() {
                        if (_selectedPerformanceGrade != 'custom') {
                          _selectedPerformanceGrade = 'custom';
                        }
                        _profile = _buildProfileFromState();
                      });
                    },
                  ),
                ),
                SizedBox(
                  width: 260,
                  child: TextField(
                    controller: _holidayController,
                    decoration: InputDecoration(
                      labelText: '명절휴가비 (연간 원화)',
                      helperText: '기본값 예시: $holidayDefault',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: (_) => _updateProfile(),
                  ),
                ),
                SizedBox(
                  width: 260,
                  child: TextField(
                    controller: _longevityController,
                    decoration: InputDecoration(
                      labelText: '정근수당(본) 연간 합계 (원)',
                      helperText: '기본값 예시: $longevityDefault',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: (_) => _updateProfile(),
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: '정년퇴직 예정연도'),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _retirementYear,
                        isExpanded: true,
                        items: <DropdownMenuItem<int>>[
                          for (
                            int year = _currentYear + 10;
                            year <= _currentYear + 40;
                            year++
                          )
                            DropdownMenuItem<int>(
                              value: year,
                              child: Text('$year년'),
                            ),
                        ],
                        onChanged: (int? value) {
                          if (value == null) {
                            return;
                          }
                          setState(() {
                            _retirementYear = value;
                            _profile = _buildProfileFromState();
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final bool isWide = constraints.maxWidth > 640;
                final Widget raiseSlider = _ProjectionSlider(
                  label: '매년 봉급 인상률',
                  value: _raiseRate,
                  onChanged: (double value) => setState(() {
                    _raiseRate = value;
                    _profile = _buildProfileFromState();
                  }),
                );
                final Widget allowanceSlider = _ProjectionSlider(
                  label: '수당 증가율',
                  value: _allowanceGrowthRate,
                  onChanged: (double value) => setState(() {
                    _allowanceGrowthRate = value;
                    _profile = _buildProfileFromState();
                  }),
                );

                if (isWide) {
                  return Row(
                    children: [
                      Flexible(child: raiseSlider),
                      const SizedBox(width: 24),
                      Flexible(child: allowanceSlider),
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    raiseSlider,
                    const SizedBox(height: 20),
                    allowanceSlider,
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectionTable(ThemeData theme) {
    final List<AnnualSalary> data = _profile.projection;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '연도별 연봉 예측',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            if (data.isEmpty)
              Text(
                '예측 데이터를 계산할 수 없습니다. 입력값을 확인해주세요.',
                style: theme.textTheme.bodyMedium,
              )
            else
              SizedBox(
                height: min(360, 56.0 * data.length + 56),
                child: SingleChildScrollView(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const <DataColumn>[
                        DataColumn(label: Text('Year')),
                        DataColumn(label: Text('세전 연봉')),
                        DataColumn(label: Text('세후 연봉')),
                      ],
                      rows: data
                          .map(
                            (AnnualSalary entry) => DataRow(
                              cells: <DataCell>[
                                DataCell(Text('${entry.year}년')),
                                DataCell(
                                  Text(_formatCurrency(entry.gross.round())),
                                ),
                                DataCell(
                                  Text(_formatCurrency(entry.net.round())),
                                ),
                              ],
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectionChart(ThemeData theme) {
    final List<AnnualSalary> data = _profile.projection;
    if (data.length < 2) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            '연도별 추세를 표시하려면 최소 2년 이상의 데이터가 필요합니다.',
            style: theme.textTheme.bodyMedium,
          ),
        ),
      );
    }

    final List<FlSpot> grossSpots = <FlSpot>[];
    final List<FlSpot> netSpots = <FlSpot>[];
    for (int index = 0; index < data.length; index++) {
      final AnnualSalary entry = data[index];
      grossSpots.add(FlSpot(index.toDouble(), entry.gross / 1000000));
      netSpots.add(FlSpot(index.toDouble(), entry.net / 1000000));
    }

    final Color grossColor = theme.colorScheme.primary;
    final Color netColor = theme.colorScheme.secondary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '연도별 연봉 추이 (단위: 백만원)',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 280,
              child: LineChart(
                LineChartData(
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: theme.colorScheme.surface.withValues(
                        alpha: 0.94,
                      ),
                      getTooltipItems: (List<LineBarSpot> spots) {
                        return spots
                            .map((LineBarSpot spot) {
                              final int index = spot.x.round().clamp(
                                0,
                                data.length - 1,
                              );
                              final AnnualSalary entry = data[index];
                              final bool isGross = spot.barIndex == 0;
                              final num amount = isGross
                                  ? entry.gross
                                  : entry.net;
                              final Color color = isGross
                                  ? grossColor
                                  : netColor;
                              return LineTooltipItem(
                                '${entry.year}년 ${isGross ? '세전' : '세후'}\n${_formatCurrency(amount.round())}',
                                TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            })
                            .toList(growable: false);
                      },
                    ),
                  ),
                  minX: 0,
                  maxX: (data.length - 1).toDouble(),
                  minY: 0,
                  lineBarsData: <LineChartBarData>[
                    LineChartBarData(
                      spots: grossSpots,
                      isCurved: true,
                      barWidth: 3,
                      color: grossColor,
                      dotData: const FlDotData(show: false),
                    ),
                    LineChartBarData(
                      spots: netSpots,
                      isCurved: true,
                      barWidth: 3,
                      color: netColor,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: _horizontalInterval(data),
                    getDrawingHorizontalLine: (double value) => FlLine(
                      color: theme.colorScheme.outlineVariant,
                      strokeWidth: 0.6,
                    ),
                    getDrawingVerticalLine: (double value) => FlLine(
                      color: theme.colorScheme.outlineVariant,
                      strokeWidth: 0.6,
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          if (value < 0) {
                            return const SizedBox.shrink();
                          }
                          return Text(value.toStringAsFixed(0));
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: max(1, (data.length / 6).floorToDouble()),
                        getTitlesWidget: (double value, TitleMeta meta) {
                          final int index = value.round();
                          if (index < 0 || index >= data.length) {
                            return const SizedBox.shrink();
                          }
                          final AnnualSalary entry = data[index];
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text('${entry.year % 100}년'),
                          );
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _resetToDefaults() {
    setState(() {
      _selectedPerformanceGrade = 'A';
      _raiseRate = 0.02;
      _allowanceGrowthRate = 0.01;
      _retirementYear = _defaultRetirementYear;
      _performanceController.text = _performanceAmountForGrade(
        'A',
      ).round().toString();
      _holidayController.text = (_currentSalary.basePay * 1.2 * 2)
          .round()
          .toString();
      _longevityController.text = (_currentSalary.basePay * 0.05 * 2)
          .round()
          .toString();
      _profile = _buildProfileFromState();
    });
  }

  void _updateProfile() {
    setState(() {
      _profile = _buildProfileFromState();
    });
  }

  TeacherSalaryProfile _buildProfileFromState() {
    final double performance = _parseAmount(
      _performanceController.text,
    ).toDouble();
    final double holiday = _parseAmount(_holidayController.text).toDouble();
    final double longevity = _parseAmount(_longevityController.text).toDouble();

    final TeacherSalaryProfile profile = TeacherSalaryProfile(
      currentYear: _currentYear,
      currentSalary: _currentSalary,
      retirementYear: _retirementYear,
      annualPerformanceBonus: performance,
      annualHolidayBonus: holiday,
      semiAnnualLongevity: longevity,
      projectedRaiseRate: _raiseRate,
      allowanceGrowthRate: _allowanceGrowthRate,
    );
    return profile.withProjection();
  }

  double _performanceAmountForGrade(String grade) {
    switch (grade) {
      case 'S':
        return _currentSalary.basePay * 1.5;
      case 'A':
        return _currentSalary.basePay * 1.2;
      case 'B':
        return _currentSalary.basePay * 1.0;
      default:
        return _parseAmount(_performanceController.text).toDouble();
    }
  }

  int _parseAmount(String value) {
    final String trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 0;
    }
    return int.tryParse(trimmed) ?? 0;
  }

  double _horizontalInterval(List<AnnualSalary> data) {
    final double maxValue = data
        .map((AnnualSalary entry) => entry.gross / 1000000)
        .fold<double>(0, max);
    if (maxValue == 0) {
      return 10;
    }
    final double roughInterval = maxValue / 5;
    return max(5, roughInterval.roundToDouble());
  }

  String _formatCurrency(num value) => _currencyFormat.format(value);
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectionSlider extends StatelessWidget {
  const _ProjectionSlider({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label (${(value * 100).toStringAsFixed(1)}%)',
          style: theme.textTheme.bodyLarge,
        ),
        Slider(
          value: value,
          min: 0,
          max: 0.05,
          divisions: 10,
          label: '${(value * 100).toStringAsFixed(1)}%',
          onChanged: onChanged,
        ),
      ],
    );
  }
}
