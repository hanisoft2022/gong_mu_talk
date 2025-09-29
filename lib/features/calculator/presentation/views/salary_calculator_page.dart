import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../di/di.dart';
import '../../domain/entities/salary_allowance_type.dart';
import '../../domain/entities/salary_grade_option.dart';
import '../../domain/entities/salary_track.dart';
import '../bloc/salary_calculator_bloc.dart';
import '../widgets/salary_result_card.dart';

class SalaryCalculatorPage extends StatelessWidget {
  const SalaryCalculatorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SalaryCalculatorBloc>(),
      child: const SalaryCalculatorView(),
    );
  }
}

class SalaryCalculatorView extends StatefulWidget {
  const SalaryCalculatorView({super.key});

  @override
  State<SalaryCalculatorView> createState() => _SalaryCalculatorViewState();
}

class _SalaryCalculatorViewState extends State<SalaryCalculatorView> {
  late final TextEditingController _baseSalaryController;
  late final TextEditingController _annualBonusController;
  late final TextEditingController _pensionRateController;
  late final TextEditingController _workingDaysController;
  late final Map<SalaryAllowanceType, TextEditingController>
  _allowanceControllers;

  @override
  void initState() {
    super.initState();
    final SalaryCalculatorState state = context
        .read<SalaryCalculatorBloc>()
        .state;
    _baseSalaryController = TextEditingController(
      text: _formatInitialValue(state.input.baseMonthlySalary),
    );
    _annualBonusController = TextEditingController(
      text: _formatInitialValue(state.input.annualBonus),
    );
    _pensionRateController = TextEditingController(
      text: (state.input.pensionContributionRate * 100).toStringAsFixed(1),
    );
    _workingDaysController = TextEditingController(
      text: state.input.workingDaysPerMonth.toString(),
    );
    _allowanceControllers = {
      for (final SalaryAllowanceType type in SalaryAllowanceType.values)
        type: TextEditingController(
          text: _formatInitialValue(state.input.allowances[type] ?? 0),
        ),
    };
  }

  @override
  void dispose() {
    _baseSalaryController.dispose();
    _annualBonusController.dispose();
    _pensionRateController.dispose();
    _workingDaysController.dispose();
    for (final controller in _allowanceControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SalaryCalculatorBloc bloc = context.read<SalaryCalculatorBloc>();
    final ThemeData theme = Theme.of(context);

    return BlocListener<SalaryCalculatorBloc, SalaryCalculatorState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.input.baseMonthlySalary != current.input.baseMonthlySalary,
      listener: (context, state) {
        if (state.status == SalaryCalculatorStatus.failure &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        }

        if (state.status == SalaryCalculatorStatus.initial) {
          _resetControllers(state);
        } else if (state.input.isAutoCalculated) {
          _baseSalaryController.text = _formatNumber(
            state.input.baseMonthlySalary,
          );
        }
      },
      child: BlocBuilder<SalaryCalculatorBloc, SalaryCalculatorState>(
        builder: (context, state) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final bool isWide = constraints.maxWidth > 720;

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        Skeletonizer(
                          enabled: state.status == SalaryCalculatorStatus.loading,
                          child: SalaryResultCard(
                            breakdown: state.result,
                            isEmpty: state.result.monthlyTotal <= 0,
                          ),
                        ),
                        if (state.status == SalaryCalculatorStatus.loading)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(
                                      color: theme.colorScheme.primary,
                                    ),
                                    const Gap(12),
                                    Text(
                                      '급여 정보를 계산하고 있습니다...',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: theme.colorScheme.onSurface,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const Gap(28),
                    _buildReferenceSection(state, bloc, theme, isWide),
                    const Gap(28),
                    Text(
                      '월급 입력',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Gap(12),
                    isWide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildBaseSalaryField(bloc, state),
                              ),
                              const Gap(20),
                              Expanded(child: _buildBonusField(bloc)),
                            ],
                          )
                        : Column(
                            children: [
                              _buildBaseSalaryField(bloc, state),
                              const Gap(16),
                              _buildBonusField(bloc),
                            ],
                          ),
                    const Gap(28),
                    Text(
                      '수당 입력',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Gap(12),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: SalaryAllowanceType.values
                          .map(
                            (type) => SizedBox(
                              width: isWide
                                  ? (constraints.maxWidth - 72) / 2
                                  : double.infinity,
                              child: _buildAllowanceField(type, bloc),
                            ),
                          )
                          .toList(),
                    ),
                    const Gap(28),
                    Text(
                      '근무 조건',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Gap(12),
                    isWide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildWorkingDaysField(bloc)),
                              const Gap(20),
                              Expanded(child: _buildPensionRateField(bloc)),
                            ],
                          )
                        : Column(
                            children: [
                              _buildWorkingDaysField(bloc),
                              const Gap(16),
                              _buildPensionRateField(bloc),
                            ],
                          ),
                    const Gap(28),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () =>
                                bloc.add(const SalaryCalculatorSubmitted()),
                            child: const Text('월급 계산하기'),
                          ),
                        ),
                        const Gap(12),
                        OutlinedButton(
                          onPressed: () =>
                              bloc.add(const SalaryCalculatorReset()),
                          child: const Text('입력 초기화'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildReferenceSection(
    SalaryCalculatorState state,
    SalaryCalculatorBloc bloc,
    ThemeData theme,
    bool isWide,
  ) {
    final List<int> yearOptions = _generateYearOptions(
      state.input.appointmentYear,
    );
    final List<SalaryGradeOption> gradeOptions = state.gradeOptions;

    final Widget selectors = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '발령 연도 & 호봉 기반 자동 계산',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const Gap(12),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width: isWide ? 220 : double.infinity,
              child: DropdownButtonFormField<SalaryTrack>(
                initialValue: state.input.track,
                decoration: const InputDecoration(
                  labelText: '직군',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                items: SalaryTrack.values
                    .map(
                      (track) => DropdownMenuItem(
                        value: track,
                        child: Text(track.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    bloc.add(SalaryCalculatorTrackChanged(value));
                  }
                },
              ),
            ),
            SizedBox(
              width: isWide ? 160 : double.infinity,
              child: DropdownButtonFormField<int>(
                initialValue: state.input.appointmentYear,
                decoration: const InputDecoration(
                  labelText: '발령 연도',
                  prefixIcon: Icon(Icons.calendar_month_outlined),
                ),
                items: yearOptions
                    .map(
                      (year) => DropdownMenuItem<int>(
                        value: year,
                        child: Text('$year년'),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    bloc.add(SalaryCalculatorAppointmentYearChanged(value));
                  }
                },
              ),
            ),
            SizedBox(
              width: isWide ? 200 : double.infinity,
              child: DropdownButtonFormField<String>(
                initialValue:
                    gradeOptions.any(
                      (option) => option.id == state.input.gradeId,
                    )
                    ? state.input.gradeId
                    : (gradeOptions.isNotEmpty ? gradeOptions.first.id : null),
                decoration: const InputDecoration(
                  labelText: '직급/호봉군',
                  prefixIcon: Icon(Icons.stairs_outlined),
                ),
                items: gradeOptions
                    .map(
                      (option) => DropdownMenuItem<String>(
                        value: option.id,
                        child: Text(option.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    bloc.add(SalaryCalculatorGradeChanged(value));
                  }
                },
              ),
            ),
            SizedBox(
              width: isWide ? 160 : double.infinity,
              child: DropdownButtonFormField<int>(
                initialValue: state.input.step,
                decoration: const InputDecoration(
                  labelText: '호봉',
                  prefixIcon: Icon(Icons.format_list_numbered),
                ),
                items: _buildStepItems(gradeOptions, state.input.gradeId),
                onChanged: (value) {
                  if (value != null) {
                    bloc.add(SalaryCalculatorStepChanged(value));
                  }
                },
              ),
            ),
          ],
        ),
        if (state.isReferenceLoading) ...[
          const Gap(12),
          const LinearProgressIndicator(minHeight: 4),
        ],
        if (state.input.isAutoCalculated)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Icon(
                  Icons.auto_graph_outlined,
                  size: 18,
                  color: theme.colorScheme.secondary,
                ),
                const Gap(8),
                Text(
                  '기준표를 기반으로 기본 월급이 자동 입력되었습니다.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
      ],
    );

    return selectors;
  }

  List<DropdownMenuItem<int>> _buildStepItems(
    List<SalaryGradeOption> gradeOptions,
    String selectedGradeId,
  ) {
    SalaryGradeOption? option;
    for (final grade in gradeOptions) {
      if (grade.id == selectedGradeId) {
        option = grade;
        break;
      }
    }

    option ??= gradeOptions.isNotEmpty ? gradeOptions.first : null;
    final int minStep = option?.minStep ?? 1;
    final int maxStep = option?.maxStep ?? 33;
    final int cappedMax = maxStep.clamp(minStep, minStep + 19).toInt();

    return [
      for (int step = minStep; step <= cappedMax; step++)
        DropdownMenuItem<int>(value: step, child: Text('$step호봉')),
    ];
  }

  Widget _buildBaseSalaryField(
    SalaryCalculatorBloc bloc,
    SalaryCalculatorState state,
  ) {
    return TextField(
      controller: _baseSalaryController,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,]'))],
      decoration: InputDecoration(
        labelText: '기본 월급 (₩)',
        hintText: '예: 3,200,000',
        prefixIcon: const Icon(Icons.attach_money_outlined),
        suffixIcon: state.input.isAutoCalculated
            ? const Tooltip(
                message: '기준표에서 가져온 값입니다. 수정하면 수동 입력으로 전환됩니다.',
                child: Icon(Icons.auto_mode_outlined),
              )
            : null,
      ),
      onChanged: (value) =>
          bloc.add(SalaryCalculatorBaseSalaryChanged(_parseDouble(value))),
    );
  }

  Widget _buildBonusField(SalaryCalculatorBloc bloc) {
    return TextField(
      controller: _annualBonusController,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,]'))],
      decoration: const InputDecoration(
        labelText: '연간 보너스/성과급 (₩)',
        hintText: '예: 2,000,000',
        prefixIcon: Icon(Icons.card_giftcard_outlined),
      ),
      onChanged: (value) =>
          bloc.add(SalaryCalculatorAnnualBonusChanged(_parseDouble(value))),
    );
  }

  Widget _buildAllowanceField(
    SalaryAllowanceType type,
    SalaryCalculatorBloc bloc,
  ) {
    return TextField(
      controller: _allowanceControllers[type],
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,]'))],
      decoration: InputDecoration(
        labelText: '${type.label} (₩)',
        hintText: '0',
        prefixIcon: const Icon(Icons.add_card_outlined),
      ),
      onChanged: (value) => bloc.add(
        SalaryCalculatorAllowanceChanged(
          type: type,
          amount: _parseDouble(value),
        ),
      ),
    );
  }

  Widget _buildWorkingDaysField(SalaryCalculatorBloc bloc) {
    return TextField(
      controller: _workingDaysController,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: const InputDecoration(
        labelText: '월 근무일수',
        hintText: '21',
        prefixIcon: Icon(Icons.calendar_month_outlined),
      ),
      onChanged: (value) =>
          bloc.add(SalaryCalculatorWorkingDaysChanged(_parseInt(value))),
    );
  }

  Widget _buildPensionRateField(SalaryCalculatorBloc bloc) {
    return TextField(
      controller: _pensionRateController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      decoration: const InputDecoration(
        labelText: '연금 부담률 (%)',
        hintText: '9.8',
        prefixIcon: Icon(Icons.percent_outlined),
      ),
      onChanged: (value) =>
          bloc.add(SalaryCalculatorPensionRateChanged(_parsePercent(value))),
    );
  }

  void _resetControllers(SalaryCalculatorState state) {
    _baseSalaryController.text = _formatInitialValue(
      state.input.baseMonthlySalary,
    );
    _annualBonusController.text = _formatInitialValue(state.input.annualBonus);
    _pensionRateController.text = (state.input.pensionContributionRate * 100)
        .toStringAsFixed(1);
    _workingDaysController.text = state.input.workingDaysPerMonth.toString();
    for (final entry in _allowanceControllers.entries) {
      entry.value.text = _formatInitialValue(
        state.input.allowances[entry.key] ?? 0,
      );
    }
  }

  List<int> _generateYearOptions(int selectedYear) {
    final int currentYear = DateTime.now().year;
    final int minYear = currentYear - 15;
    final int maxYear = currentYear + 1;
    final int baseYear = selectedYear.clamp(minYear, maxYear);
    final Set<int> uniqueYears = <int>{};
    for (int offset = -4; offset <= 4; offset++) {
      uniqueYears.add((baseYear + offset).clamp(minYear, maxYear));
    }
    uniqueYears.add(selectedYear.clamp(minYear, maxYear));
    if (!uniqueYears.contains(currentYear)) {
      uniqueYears.add(currentYear);
    }
    final List<int> sorted = uniqueYears.toList()..sort();
    return sorted;
  }

  String _formatInitialValue(double value) {
    if (value == 0) {
      return '';
    }
    return _formatNumber(value);
  }

  String _formatNumber(double value) {
    final num normalized = value.round();
    final String digits = normalized.toString();
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      final int index = digits.length - i - 1;
      buffer.write(digits[index]);
      if ((i + 1) % 3 == 0 && index != 0) {
        buffer.write(',');
      }
    }
    return buffer.toString().split('').reversed.join();
  }

  double _parseDouble(String value) {
    final String sanitized = value.replaceAll(',', '').trim();
    if (sanitized.isEmpty) {
      return 0;
    }
    return double.tryParse(sanitized) ?? 0;
  }

  double _parsePercent(String value) {
    final String sanitized = value.replaceAll(',', '.').trim();
    if (sanitized.isEmpty) {
      return 0;
    }
    final double parsed = double.tryParse(sanitized) ?? 0;
    return parsed / 100;
  }

  int _parseInt(String value) {
    if (value.isEmpty) {
      return 0;
    }
    return int.tryParse(value) ?? 0;
  }
}
