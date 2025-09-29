import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';

import '../../../../common/widgets/app_logo_button.dart';
import '../../../../common/widgets/global_app_bar_actions.dart';
import '../../../../routing/app_router.dart';

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
    _scrollController = ScrollController();
    _scrollController.addListener(_handleScrollOffset);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScrollOffset);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScrollOffset() {
    if (!_scrollController.hasClients) {
      return;
    }
    final bool shouldElevate = _scrollController.offset > 4;
    if (shouldElevate != _isAppBarElevated) {
      setState(() => _isAppBarElevated = shouldElevate);
    }
  }

  SliverAppBar _buildCalculatorSliverAppBar(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final Color background = Color.lerp(
      colorScheme.surface.withValues(alpha: 0.9),
      colorScheme.surface,
      _isAppBarElevated ? 1 : 0,
    )!;
    final double radius = _isAppBarElevated ? 12 : 18;
    const double toolbarHeight = 64;

    return SliverAppBar(
      floating: true,
      snap: true,
      stretch: true,
      forceElevated: _isAppBarElevated,
      elevation: _isAppBarElevated ? 3 : 0,
      scrolledUnderElevation: 6,
      toolbarHeight: toolbarHeight,
      titleSpacing: 12,
      leadingWidth: toolbarHeight,
      backgroundColor: background,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withValues(alpha: _isAppBarElevated ? 0.08 : 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(radius)),
      ),
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: AppLogoButton(
          compact: true,
          onTap: () {
            if (!_scrollController.hasClients) return;
            _scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 360),
              curve: Curves.easeOutCubic,
            );
          },
        ),
      ),
      title: const Text('계산기', style: TextStyle(fontWeight: FontWeight.w700)),
      actions: [
        GlobalAppBarActions(
          compact: true,
          opacity: _isAppBarElevated ? 1 : 0.92,
          onProfileTap: () => GoRouter.of(context).push(ProfileRoute.path),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, _) => <Widget>[_buildCalculatorSliverAppBar(context)],
        body: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Gap(32),
                Expanded(
                  child: GridView.count(
                    padding: const EdgeInsets.only(bottom: 20),
                    crossAxisCount: 2,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 0.75,
                    children: [
                      _buildCalculatorCard(
                        context: context,
                        title: '월급 계산기',
                        subtitle: '월급 리포트 &\n연봉 시뮬레이션',
                        icon: Icons.calculate_outlined,
                        color: colorScheme.primary,
                        onTap: () => context.push('/calculator/salary'),
                        isAvailable: true,
                      ),
                      _buildCalculatorCard(
                        context: context,
                        title: '연금 계산기',
                        subtitle: '공무원 연금\n계산 서비스',
                        icon: Icons.savings_outlined,
                        color: colorScheme.secondary,
                        onTap: () => context.push('/calculator/pension'),
                        isAvailable: true,
                      ),
                      _buildCalculatorCard(
                        context: context,
                        title: '퇴직금 계산기',
                        subtitle: '퇴직급여\n예상 계산',
                        icon: Icons.account_balance_wallet_outlined,
                        color: colorScheme.tertiary,
                        onTap: () => _showComingSoonDialog(context, '퇴직금 계산기'),
                        isAvailable: false,
                      ),
                      _buildCalculatorCard(
                        context: context,
                        title: '수당 계산기',
                        subtitle: '각종 수당\n계산 도구',
                        icon: Icons.payments_outlined,
                        color: colorScheme.outline,
                        onTap: () => _showComingSoonDialog(context, '수당 계산기'),
                        isAvailable: false,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCalculatorCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isAvailable,
  }) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isAvailable
                ? (isDark ? colorScheme.surfaceContainerHigh : colorScheme.surface)
                : colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
            border: isAvailable
                ? Border.all(color: color.withValues(alpha: 0.15), width: 1.5)
                : null,
            boxShadow: isAvailable
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: isDark ? 0.1 : 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: isAvailable
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)],
                        )
                      : null,
                  color: isAvailable ? null : colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: isAvailable ? color : colorScheme.onSurfaceVariant,
                ),
              ),
              const Gap(16),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isAvailable ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const Gap(6),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.4,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (!isAvailable) ...[
                const Gap(12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '준비중',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoonDialog(BuildContext context, String calculatorName) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.construction_outlined, color: Theme.of(context).colorScheme.primary),
              const Gap(8),
              const Text('준비중'),
            ],
          ),
          content: Text(
            '$calculatorName는 현재 개발 중입니다.\n곧 만나보실 수 있어요!',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('확인')),
          ],
        );
      },
    );
  }
}
