/// Refactored to meet AI token optimization guidelines
/// Main coordinator file for teacher salary insight page
/// Extracted widgets moved to separate files for better organization
/// Target: ≤400 lines (UI file guideline)

library;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../domain/monthly_salary.dart';
import '../../domain/teacher_salary_profile.dart';
import '../widgets/salary_summary_metric.dart';
import '../widgets/salary_inputs_card.dart';
import '../widgets/salary_projection_table.dart';
import '../widgets/salary_projection_chart.dart';

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
          _buildSummaryCard(theme, grossMonthly, deductionsMonthly, netMonthly),
          const SizedBox(height: 24),
          SalaryInputsCard(
            currentSalary: _currentSalary,
            selectedPerformanceGrade: _selectedPerformanceGrade,
            performanceController: _performanceController,
            holidayController: _holidayController,
            longevityController: _longevityController,
            retirementYear: _retirementYear,
            currentYear: _currentYear,
            raiseRate: _raiseRate,
            allowanceGrowthRate: _allowanceGrowthRate,
            onPerformanceGradeChanged: _handlePerformanceGradeChanged,
            onPerformanceAmountChanged: _handlePerformanceAmountChanged,
            onHolidayChanged: _updateProfile,
            onLongevityChanged: _updateProfile,
            onRetirementYearChanged: _handleRetirementYearChanged,
            onRaiseRateChanged: _handleRaiseRateChanged,
            onAllowanceGrowthRateChanged: _handleAllowanceGrowthRateChanged,
          ),
          const SizedBox(height: 24),
          SalaryProjectionTable(data: _profile.projection),
          const SizedBox(height: 24),
          SalaryProjectionChart(data: _profile.projection),
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

  Widget _buildSummaryCard(
    ThemeData theme,
    int grossMonthly,
    int deductionsMonthly,
    int netMonthly,
  ) {
    return Card(
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
                SalarySummaryMetric(
                  label: '세전 월급',
                  value: _formatCurrency(grossMonthly),
                ),
                SalarySummaryMetric(
                  label: '총 공제액',
                  value: _formatCurrency(deductionsMonthly),
                ),
                SalarySummaryMetric(
                  label: '실수령액',
                  value: _formatCurrency(netMonthly),
                ),
                SalarySummaryMetric(
                  label: '올해 세전 연봉',
                  value: _formatCurrency(
                    _profile.currentGrossAnnual.round(),
                  ),
                ),
                SalarySummaryMetric(
                  label: '올해 세후 연봉',
                  value: _formatCurrency(
                    _profile.currentNetAnnual.round(),
                  ),
                ),
                SalarySummaryMetric(
                  label: '정년까지 세전 총소득',
                  value: _formatCurrency(
                    _profile.projectedLifetimeGross.round(),
                  ),
                ),
                SalarySummaryMetric(
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
    );
  }

  void _handlePerformanceGradeChanged(String? grade) {
    if (grade == null) {
      return;
    }
    setState(() {
      _selectedPerformanceGrade = grade;
      if (grade != 'custom') {
        _performanceController.text =
            _performanceAmountForGrade(grade).round().toString();
      }
      _profile = _buildProfileFromState();
    });
  }

  void _handlePerformanceAmountChanged() {
    setState(() {
      if (_selectedPerformanceGrade != 'custom') {
        _selectedPerformanceGrade = 'custom';
      }
      _profile = _buildProfileFromState();
    });
  }

  void _handleRetirementYearChanged(int? value) {
    if (value == null) {
      return;
    }
    setState(() {
      _retirementYear = value;
      _profile = _buildProfileFromState();
    });
  }

  void _handleRaiseRateChanged(double value) {
    setState(() {
      _raiseRate = value;
      _profile = _buildProfileFromState();
    });
  }

  void _handleAllowanceGrowthRateChanged(double value) {
    setState(() {
      _allowanceGrowthRate = value;
      _profile = _buildProfileFromState();
    });
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

  String _formatCurrency(num value) => _currencyFormat.format(value);
}
