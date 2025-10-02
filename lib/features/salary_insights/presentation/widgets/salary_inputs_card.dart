/// Extracted from teacher_salary_insight_page.dart for better file organization
/// This widget displays the input form for salary components

library;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'projection_slider.dart';
import '../../domain/monthly_salary.dart';

class SalaryInputsCard extends StatelessWidget {
  const SalaryInputsCard({
    required this.currentSalary,
    required this.selectedPerformanceGrade,
    required this.performanceController,
    required this.holidayController,
    required this.longevityController,
    required this.retirementYear,
    required this.currentYear,
    required this.raiseRate,
    required this.allowanceGrowthRate,
    required this.onPerformanceGradeChanged,
    required this.onPerformanceAmountChanged,
    required this.onHolidayChanged,
    required this.onLongevityChanged,
    required this.onRetirementYearChanged,
    required this.onRaiseRateChanged,
    required this.onAllowanceGrowthRateChanged,
    super.key,
  });

  final MonthlySalary currentSalary;
  final String selectedPerformanceGrade;
  final TextEditingController performanceController;
  final TextEditingController holidayController;
  final TextEditingController longevityController;
  final int retirementYear;
  final int currentYear;
  final double raiseRate;
  final double allowanceGrowthRate;
  final ValueChanged<String?> onPerformanceGradeChanged;
  final VoidCallback onPerformanceAmountChanged;
  final VoidCallback onHolidayChanged;
  final VoidCallback onLongevityChanged;
  final ValueChanged<int?> onRetirementYearChanged;
  final ValueChanged<double> onRaiseRateChanged;
  final ValueChanged<double> onAllowanceGrowthRateChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String holidayDefault = _formatCurrency((currentSalary.basePay * 1.2 * 2).round());
    final String longevityDefault = _formatCurrency((currentSalary.basePay * 0.05 * 2).round());

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
                        value: selectedPerformanceGrade,
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
                        onChanged: onPerformanceGradeChanged,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 260,
                  child: TextField(
                    controller: performanceController,
                    decoration: const InputDecoration(
                      labelText: '성과상여금 (연간 원화)',
                      helperText: '필요 시 등급 대신 직접 입력하세요.',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: (_) => onPerformanceAmountChanged(),
                  ),
                ),
                SizedBox(
                  width: 260,
                  child: TextField(
                    controller: holidayController,
                    decoration: InputDecoration(
                      labelText: '명절휴가비 (연간 원화)',
                      helperText: '기본값 예시: $holidayDefault',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: (_) => onHolidayChanged(),
                  ),
                ),
                SizedBox(
                  width: 260,
                  child: TextField(
                    controller: longevityController,
                    decoration: InputDecoration(
                      labelText: '정근수당(본) 연간 합계 (원)',
                      helperText: '기본값 예시: $longevityDefault',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: (_) => onLongevityChanged(),
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: '정년퇴직 예정연도'),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: retirementYear,
                        isExpanded: true,
                        items: <DropdownMenuItem<int>>[
                          for (
                            int year = currentYear + 10;
                            year <= currentYear + 40;
                            year++
                          )
                            DropdownMenuItem<int>(
                              value: year,
                              child: Text('$year년'),
                            ),
                        ],
                        onChanged: onRetirementYearChanged,
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
                final Widget raiseSlider = ProjectionSlider(
                  label: '매년 봉급 인상률',
                  value: raiseRate,
                  onChanged: onRaiseRateChanged,
                );
                final Widget allowanceSlider = ProjectionSlider(
                  label: '수당 증가율',
                  value: allowanceGrowthRate,
                  onChanged: onAllowanceGrowthRateChanged,
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

  String _formatCurrency(num value) {
    return '₩${value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}';
  }
}
