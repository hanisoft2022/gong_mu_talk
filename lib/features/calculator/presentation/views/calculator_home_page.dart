import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gong_mu_talk/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:gong_mu_talk/features/calculator/presentation/cubit/calculator_cubit.dart';
import 'package:gong_mu_talk/features/calculator/presentation/cubit/calculator_state.dart';
import 'package:gong_mu_talk/features/calculator/presentation/widgets/salary_info_input_card.dart';
import 'package:gong_mu_talk/features/calculator/presentation/widgets/current_salary_card.dart';
import 'package:gong_mu_talk/features/calculator/presentation/widgets/retirement_lumpsum_card.dart';
import 'package:gong_mu_talk/features/calculator/presentation/widgets/pension_net_income_card.dart';

/// 계산기 홈 페이지 (3단계 시간축 기반 재구성)
///
/// 구조:
/// 1. Section 1: 재직 중 급여 (현재)
/// 2. Section 2: 퇴직 시 일시금 (퇴직 시점)
/// 3. Section 3: 퇴직 후 연금 (퇴직 후)
class CalculatorHomePage extends StatelessWidget {
  const CalculatorHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('급여/연금 계산기'), centerTitle: true),
      body: BlocBuilder<CalculatorCubit, CalculatorState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
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
                // 급여 정보 입력 카드
                SalaryInfoInputCard(
                  isDataEntered: state.isDataEntered,
                  profile: state.profile,
                ),

                const SizedBox(height: 16),

                Divider(
                  color: Colors.grey.withValues(alpha: 0.3),
                  thickness: 1,
                ),

                const SizedBox(height: 16),

                // ═══════════════════════════════════════════
                // Section 1: 💼 재직 중 급여
                // ═══════════════════════════════════════════
                const _SectionHeader(
                  icon: Icons.work,
                  title: '재직 중 급여',
                  subtitle: '현재 받고 있는 월급과 연간 실수령액',
                ),

                const SizedBox(height: 12),

                CurrentSalaryCard(
                  isLocked: !state.isDataEntered,
                  monthlyBreakdown: state.monthlyBreakdown,
                  lifetimeSalary: state.lifetimeSalary,
                  profile: state.profile,
                  nickname: context.read<AuthCubit>().state.nickname,
                ),

                const SizedBox(height: 16),

                Divider(
                  color: Colors.grey.withValues(alpha: 0.3),
                  thickness: 1,
                ),

                const SizedBox(height: 16),

                // ═══════════════════════════════════════════
                // Section 2: 🎁 퇴직 시 일시금
                // ═══════════════════════════════════════════
                const _SectionHeader(
                  icon: Icons.card_giftcard,
                  title: '퇴직 시 일시금',
                  subtitle: '퇴직할 때 한 번에 받는 금액',
                ),

                const SizedBox(height: 12),

                RetirementLumpsumCard(
                  isLocked: !state.isDataEntered,
                  retirementBenefit: state.retirementBenefit,
                  earlyRetirementBonus: state.earlyRetirementBonus,
                  profile: state.profile,
                ),

                const SizedBox(height: 16),

                Divider(
                  color: Colors.grey.withValues(alpha: 0.3),
                  thickness: 1,
                ),

                const SizedBox(height: 16),

                // ═══════════════════════════════════════════
                // Section 3: 🏦 퇴직 후 연금
                // ═══════════════════════════════════════════
                const _SectionHeader(
                  icon: Icons.account_balance,
                  title: '퇴직 후 연금',
                  subtitle: '퇴직 후 매달 받는 실수령액',
                ),

                const SizedBox(height: 12),

                PensionNetIncomeCard(
                  isLocked: !state.isDataEntered,
                  pensionEstimate: state.pensionEstimate,
                  afterTaxPension: state.afterTaxPension,
                  profile: state.profile,
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

/// 섹션 헤더 위젯
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: Theme.of(context).primaryColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
