import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gong_mu_talk/features/calculator/presentation/cubit/calculator_cubit.dart';
import 'package:gong_mu_talk/features/calculator/presentation/cubit/calculator_state.dart';
import 'package:gong_mu_talk/features/calculator/presentation/widgets/annual_salary_card.dart';
import 'package:gong_mu_talk/features/calculator/presentation/widgets/pension_card.dart';
import 'package:gong_mu_talk/features/calculator/presentation/widgets/salary_info_input_card.dart';

/// 계산기 홈 페이지
class CalculatorHomePage extends StatelessWidget {
  const CalculatorHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('급여/연금 계산기'),
        centerTitle: true,
      ),
      body: BlocBuilder<CalculatorCubit, CalculatorState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.errorMessage!,
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      context.read<CalculatorCubit>().calculate();
                    },
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. 급여 정보 입력 카드
                SalaryInfoInputCard(
                  isDataEntered: state.isDataEntered,
                  profile: state.profile,
                ),

                const SizedBox(height: 16),

                // 2. 연도별 급여 계산 카드
                AnnualSalaryCard(
                  isLocked: !state.isDataEntered,
                  lifetimeSalary: state.lifetimeSalary,
                ),

                const SizedBox(height: 16),

                // 3. 예상 연금 수령액 카드
                PensionCard(
                  isLocked: !state.isDataEntered,
                  pensionEstimate: state.pensionEstimate,
                ),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}
