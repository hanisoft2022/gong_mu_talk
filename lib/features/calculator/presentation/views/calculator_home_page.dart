import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gong_mu_talk/core/constants/app_colors.dart';
import 'package:gong_mu_talk/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:gong_mu_talk/features/calculator/presentation/cubit/calculator_cubit.dart';
import 'package:gong_mu_talk/features/calculator/presentation/cubit/calculator_state.dart';
import 'package:gong_mu_talk/features/calculator/presentation/widgets/salary_info_input_card.dart';
import 'package:gong_mu_talk/features/calculator/presentation/widgets/current_salary_card.dart';
import 'package:gong_mu_talk/features/calculator/presentation/widgets/retirement_lumpsum_card.dart';
import 'package:gong_mu_talk/features/calculator/presentation/widgets/pension_net_income_card.dart';
import 'package:gong_mu_talk/common/widgets/app_logo_button.dart';

/// 계산기 홈 페이지 (3단계 시간축 기반 재구성)
///
/// 구조:
/// 1. Section 1: 재직 중 급여 (현재)
/// 2. Section 2: 퇴직 시 일시금 (퇴직 시점)
/// 3. Section 3: 퇴직 후 연금 (퇴직 후)
class CalculatorHomePage extends StatefulWidget {
  const CalculatorHomePage({super.key});

  @override
  State<CalculatorHomePage> createState() => _CalculatorHomePageState();
}

class _CalculatorHomePageState extends State<CalculatorHomePage> {
  late final ScrollController _scrollController;
  bool _isAppBarElevated = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final bool shouldElevate =
        _scrollController.hasClients && _scrollController.offset > 4;
    if (shouldElevate != _isAppBarElevated && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && shouldElevate != _isAppBarElevated) {
          setState(() => _isAppBarElevated = shouldElevate);
        }
      });
    }
  }

  void _scrollToTop() {
    if (!_scrollController.hasClients) return;

    try {
      HapticFeedback.mediumImpact();
    } catch (_) {
      // Ignore if haptic feedback not supported
    }

    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final Color background = Color.lerp(
      colorScheme.surface.withValues(alpha: 0.9),
      colorScheme.surface,
      _isAppBarElevated ? 1 : 0,
    )!;
    final double radius = _isAppBarElevated ? 12 : 18;
    const double toolbarHeight = 64;

    return Scaffold(
      body: BlocBuilder<CalculatorCubit, CalculatorState>(
        builder: (context, state) {
          if (state.isLoading) {
            return NestedScrollView(
              controller: _scrollController,
              headerSliverBuilder: (context, _) => [
                _buildSliverAppBar(
                  background: background,
                  radius: radius,
                  toolbarHeight: toolbarHeight,
                ),
              ],
              body: const Center(child: CircularProgressIndicator()),
            );
          }

          if (state.errorMessage != null) {
            return NestedScrollView(
              controller: _scrollController,
              headerSliverBuilder: (context, _) => [
                _buildSliverAppBar(
                  background: background,
                  radius: radius,
                  toolbarHeight: toolbarHeight,
                ),
              ],
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: AppColors.error),
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
              ),
            );
          }

          return NestedScrollView(
            controller: _scrollController,
            headerSliverBuilder: (context, _) => [
              _buildSliverAppBar(
                background: background,
                radius: radius,
                toolbarHeight: toolbarHeight,
              ),
            ],
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                // 내 정보 입력 카드
                SalaryInfoInputCard(isDataEntered: state.isDataEntered, profile: state.profile),

                const SizedBox(height: 16),

                Divider(color: AppColors.neutral.withValues(alpha: 0.3), thickness: 1),

                const SizedBox(height: 16),

                // ═══════════════════════════════════════════
                // Section 1: 💼 재직 중 급여
                // ═══════════════════════════════════════════
                Text(
                  ' 💼  재직 중 급여',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),

                // const _SectionHeader(
                //   icon: Icons.work,
                //   title: '재직 중 급여',
                //   subtitle: '현재 받고 있는 월급과 연간 실수령액',
                // ),
                const SizedBox(height: 12),

                CurrentSalaryCard(
                  isLocked: !state.isDataEntered,
                  monthlyBreakdown: state.monthlyBreakdown,
                  lifetimeSalary: state.lifetimeSalary,
                  profile: state.profile,
                  nickname: context.read<AuthCubit>().state.nickname,
                ),

                const SizedBox(height: 16),

                Divider(color: AppColors.neutral.withValues(alpha: 0.3), thickness: 1),

                const SizedBox(height: 16),

                // ═══════════════════════════════════════════
                // Section 2: 💰 퇴직 시 일시금
                // ═══════════════════════════════════════════
                Text(
                  ' 💰  퇴직 시 일시금',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),

                // const _SectionHeader(
                //   icon: Icons.card_giftcard,
                //   title: '퇴직 시 일시금',
                //   subtitle: '퇴직할 때 한 번에 받는 금액',
                // ),
                const SizedBox(height: 12),

                RetirementLumpsumCard(
                  isLocked: !state.isDataEntered,
                  retirementBenefit: state.retirementBenefit,
                  earlyRetirementBonus: state.earlyRetirementBonus,
                  profile: state.profile,
                ),

                const SizedBox(height: 16),

                Divider(color: AppColors.neutral.withValues(alpha: 0.3), thickness: 1),

                const SizedBox(height: 16),

                // ═══════════════════════════════════════════
                // Section 3: 💵 퇴직 후 연금
                // ═══════════════════════════════════════════
                Text(
                  ' 💵  퇴직 후 연금',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),

                // const _SectionHeader(
                //   icon: Icons.savings,
                //   title: '퇴직 후 연금',
                //   subtitle: '퇴직 후 매월 받는 연금 실수령액',
                // ),
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
            ),
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar({
    required Color background,
    required double radius,
    required double toolbarHeight,
  }) {
    return SliverAppBar(
      floating: true,
      snap: true,
      stretch: true,
      forceElevated: _isAppBarElevated,
      elevation: _isAppBarElevated ? 3 : 0,
      scrolledUnderElevation: 6,
      titleSpacing: 12,
      toolbarHeight: toolbarHeight,
      leadingWidth: toolbarHeight,
      backgroundColor: background,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withValues(alpha: _isAppBarElevated ? 0.08 : 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(radius)),
      ),
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: AppLogoButton(compact: true, onTap: _scrollToTop),
      ),
      title: const Text(
        '공무톡 계산기',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}
