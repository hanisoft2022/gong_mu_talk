import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/pension_profile.dart';

/// 연금 계산 입력 섹션
class PensionInputSection extends StatelessWidget {
  const PensionInputSection({
    required this.profile,
    required this.onBirthYearChanged,
    required this.onAppointmentYearChanged,
    required this.onRetirementYearChanged,
    required this.onAverageIncomeChanged,
    required this.onServiceYearsChanged,
    required this.onLifespanChanged,
    required this.onInflationRateChanged,
    super.key,
  });

  final PensionProfile profile;
  final ValueChanged<int> onBirthYearChanged;
  final ValueChanged<int> onAppointmentYearChanged;
  final ValueChanged<int> onRetirementYearChanged;
  final ValueChanged<double> onAverageIncomeChanged;
  final ValueChanged<int> onServiceYearsChanged;
  final ValueChanged<int> onLifespanChanged;
  final ValueChanged<double> onInflationRateChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentYear = DateTime.now().year;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '기본 정보',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // 출생연도
            _buildYearInput(
              label: '출생연도',
              value: profile.birthYear,
              onChanged: onBirthYearChanged,
              minYear: 1950,
              maxYear: currentYear - 20,
              suffix: '년',
            ),
            const SizedBox(height: 12),

            // 임용연도
            _buildYearInput(
              label: '임용연도',
              value: profile.appointmentYear,
              onChanged: onAppointmentYearChanged,
              minYear: 1980,
              maxYear: currentYear,
              suffix: '년',
            ),
            const SizedBox(height: 12),

            // 퇴직연도
            _buildYearInput(
              label: '퇴직(예정)연도',
              value: profile.retirementYear,
              onChanged: onRetirementYearChanged,
              minYear: currentYear,
              maxYear: currentYear + 50,
              suffix: '년',
              helper: '퇴직 시 나이: ${profile.retirementAge}세',
            ),
            const SizedBox(height: 12),

            // 재직기간 (자동 계산, 수동 변경 가능)
            _buildNumberInput(
              label: '재직기간',
              value: profile.totalServiceYears.toDouble(),
              onChanged: (value) => onServiceYearsChanged(value.toInt()),
              min: 1,
              max: 50,
              suffix: '년',
              helper: '${profile.appointmentYear}년 ~ ${profile.retirementYear}년',
            ),
            const SizedBox(height: 20),

            Text(
              '급여 정보',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // 평균 기준소득월액
            _buildCurrencyInput(
              label: '평균 기준소득월액',
              value: profile.averageMonthlyIncome,
              onChanged: onAverageIncomeChanged,
              min: 300000,
              max: 10000000,
              helper: '전체 재직기간 평균 (봉급 + 수당)',
            ),
            const SizedBox(height: 20),

            Text(
              '시뮬레이션 옵션',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // 예상 수명
            _buildNumberInput(
              label: '예상 수명',
              value: profile.expectedLifespan.toDouble(),
              onChanged: (value) => onLifespanChanged(value.toInt()),
              min: 60,
              max: 100,
              suffix: '세',
            ),
            const SizedBox(height: 12),

            // 물가상승률
            _buildPercentageInput(
              label: '물가상승률',
              value: profile.inflationRate,
              onChanged: onInflationRateChanged,
              min: 0,
              max: 0.1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYearInput({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
    required int minYear,
    required int maxYear,
    String? suffix,
    String? helper,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: value.toDouble(),
                min: minYear.toDouble(),
                max: maxYear.toDouble(),
                divisions: maxYear - minYear,
                label: value.toString(),
                onChanged: (val) => onChanged(val.toInt()),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 80,
              child: TextFormField(
                initialValue: value.toString(),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  isDense: true,
                  suffix: suffix != null ? Text(suffix) : null,
                ),
                onChanged: (text) {
                  final parsed = int.tryParse(text);
                  if (parsed != null && parsed >= minYear && parsed <= maxYear) {
                    onChanged(parsed);
                  }
                },
              ),
            ),
          ],
        ),
        if (helper != null) ...[
          const SizedBox(height: 4),
          Text(
            helper,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ],
    );
  }

  Widget _buildNumberInput({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
    required double min,
    required double max,
    String? suffix,
    String? helper,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: value,
                min: min,
                max: max,
                divisions: (max - min).toInt(),
                label: value.toInt().toString(),
                onChanged: onChanged,
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 80,
              child: TextFormField(
                initialValue: value.toInt().toString(),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  isDense: true,
                  suffix: suffix != null ? Text(suffix) : null,
                ),
                onChanged: (text) {
                  final parsed = double.tryParse(text);
                  if (parsed != null && parsed >= min && parsed <= max) {
                    onChanged(parsed);
                  }
                },
              ),
            ),
          ],
        ),
        if (helper != null) ...[
          const SizedBox(height: 4),
          Text(
            helper,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ],
    );
  }

  Widget _buildCurrencyInput({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
    required double min,
    required double max,
    String? helper,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: value.toInt().toString(),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            prefixText: '₩ ',
            helperText: helper,
          ),
          onChanged: (text) {
            final parsed = double.tryParse(text);
            if (parsed != null && parsed >= min && parsed <= max) {
              onChanged(parsed);
            }
          },
        ),
      ],
    );
  }

  Widget _buildPercentageInput({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
    required double min,
    required double max,
  }) {
    final percentage = value * 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: percentage,
                min: min * 100,
                max: max * 100,
                divisions: ((max - min) * 100).toInt(),
                label: '${percentage.toStringAsFixed(1)}%',
                onChanged: (val) => onChanged(val / 100),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 80,
              child: Text(
                '${percentage.toStringAsFixed(1)}%',
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
