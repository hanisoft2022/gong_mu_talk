import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../di/di.dart';
import '../../domain/entities/salary_allowance_type.dart';
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
  late final Map<SalaryAllowanceType, TextEditingController> _allowanceControllers;

  @override
  void initState() {
    super.initState();
    final SalaryCalculatorState state = context.read<SalaryCalculatorBloc>().state;
    _baseSalaryController = TextEditingController(text: _formatInitialValue(state.input.baseMonthlySalary));
    _annualBonusController = TextEditingController(text: _formatInitialValue(state.input.annualBonus));
    _pensionRateController = TextEditingController(text: (state.input.pensionContributionRate * 100).toStringAsFixed(1));
    _workingDaysController = TextEditingController(text: state.input.workingDaysPerMonth.toString());
    _allowanceControllers = {
      for (final SalaryAllowanceType type in SalaryAllowanceType.values)
        type: TextEditingController(text: _formatInitialValue(state.input.allowances[type] ?? 0)),
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
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == SalaryCalculatorStatus.failure && state.errorMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        }

        if (state.status == SalaryCalculatorStatus.initial) {
          _resetControllers(state);
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isWide = constraints.maxWidth > 720;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BlocBuilder<SalaryCalculatorBloc, SalaryCalculatorState>(
                  builder: (context, state) {
                    final bool isLoading = state.status == SalaryCalculatorStatus.loading;
                    return Skeletonizer(
                      enabled: isLoading,
                      child: SalaryResultCard(
                        breakdown: state.result,
                        isEmpty: state.result.monthlyTotal <= 0,
                      ),
                    );
                  },
                ),
                const Gap(28),
                Text('월급 입력', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const Gap(12),
                isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildBaseSalaryField(bloc)),
                          const Gap(20),
                          Expanded(child: _buildBonusField(bloc)),
                        ],
                      )
                    : Column(
                        children: [
                          _buildBaseSalaryField(bloc),
                          const Gap(16),
                          _buildBonusField(bloc),
                        ],
                      ),
                const Gap(28),
                Text('수당 입력', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const Gap(12),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: SalaryAllowanceType.values
                      .map(
                        (type) => SizedBox(
                          width: isWide ? (constraints.maxWidth - 72) / 2 : double.infinity,
                          child: _buildAllowanceField(type, bloc),
                        ),
                      )
                      .toList(),
                ),
                const Gap(28),
                Text('근무 조건', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
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
                        onPressed: () => bloc.add(const SalaryCalculatorSubmitted()),
                        child: const Text('월급 계산하기'),
                      ),
                    ),
                    const Gap(12),
                    OutlinedButton(
                      onPressed: () => bloc.add(const SalaryCalculatorReset()),
                      child: const Text('입력 초기화'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBaseSalaryField(SalaryCalculatorBloc bloc) {
    return TextField(
      controller: _baseSalaryController,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,]'))],
      decoration: const InputDecoration(
        labelText: '기본 월급 (₩)',
        hintText: '예: 3,200,000',
        prefixIcon: Icon(Icons.badge_outlined),
      ),
      onChanged: (value) => bloc.add(
        SalaryCalculatorBaseSalaryChanged(_parseDouble(value)),
      ),
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
      onChanged: (value) => bloc.add(
        SalaryCalculatorAnnualBonusChanged(_parseDouble(value)),
      ),
    );
  }

  Widget _buildAllowanceField(SalaryAllowanceType type, SalaryCalculatorBloc bloc) {
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
      onChanged: (value) => bloc.add(
        SalaryCalculatorWorkingDaysChanged(_parseInt(value)),
      ),
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
      onChanged: (value) => bloc.add(
        SalaryCalculatorPensionRateChanged(_parsePercent(value)),
      ),
    );
  }

  void _resetControllers(SalaryCalculatorState state) {
    _baseSalaryController.text = _formatInitialValue(state.input.baseMonthlySalary);
    _annualBonusController.text = _formatInitialValue(state.input.annualBonus);
    _pensionRateController.text = (state.input.pensionContributionRate * 100).toStringAsFixed(1);
    _workingDaysController.text = state.input.workingDaysPerMonth.toString();
    for (final entry in _allowanceControllers.entries) {
      entry.value.text = _formatInitialValue(state.input.allowances[entry.key] ?? 0);
    }
  }

  String _formatInitialValue(double value) {
    if (value == 0) {
      return '';
    }
    return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1);
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
