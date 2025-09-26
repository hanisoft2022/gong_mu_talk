import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/theme_cubit.dart';
import '../features/auth/presentation/cubit/auth_cubit.dart';
import '../features/life/domain/life_section.dart';
import '../features/life/presentation/cubit/life_section_cubit.dart';
import '../routing/app_router.dart';
import '../common/widgets/global_app_bar_actions.dart';
import '../common/widgets/app_logo_button.dart';
import '../features/life/presentation/utils/life_scroll_coordinator.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  bool get _isCommunityTab => navigationShell.currentIndex == 0;
  bool get _isLifeTab => navigationShell.currentIndex == 3;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (previous, current) =>
          previous.lastMessage != current.lastMessage,
      listener: (context, state) {
        final String? message = state.lastMessage;
        if (message == null) {
          return;
        }
        final ModalRoute<dynamic>? route = ModalRoute.of(context);
        if (route != null && !route.isCurrent) {
          return;
        }

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
        context.read<AuthCubit>().clearLastMessage();
      },
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          final bool isDark = themeMode == ThemeMode.dark;
          final bool isCommunityTab = _isCommunityTab;
          final bool isLifeTab = _isLifeTab;
          final ColorScheme colorScheme = Theme.of(context).colorScheme;
          return Scaffold(
            appBar: isCommunityTab
                ? null
                : AppBar(
                    leadingWidth: isLifeTab ? 56 : null,
                    leading: isLifeTab
                        ? Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: AppLogoButton(
                              compact: true,
                              onTap: LifeScrollCoordinator.instance.requestScrollToTop,
                            ),
                          )
                        : null,
                    titleSpacing: isLifeTab ? 0 : null,
                    title: isLifeTab
                        ? const _LifeSectionSelector()
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                'assets/images/app_logo.png',
                                height: 28,
                                errorBuilder: (_, __, ___) =>
                                    const SizedBox.shrink(),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  _titleForIndex(navigationShell.currentIndex),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                    actions: [
                      GlobalAppBarActions(
                        isDarkMode: isDark,
                        onToggleTheme: () => context.read<ThemeCubit>().toggle(),
                        onProfileTap: () => GoRouter.of(context).push(ProfileRoute.path),
                      ),
                    ],
                  ),
            body: navigationShell,
            bottomNavigationBar: NavigationBar(
              height: 64,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              backgroundColor: colorScheme.surface,
              indicatorColor: colorScheme.primary.withAlpha(40),
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: (index) {
                navigationShell.goBranch(
                  index,
                  initialLocation: index == navigationShell.currentIndex,
                );
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.forum_outlined),
                  selectedIcon: Icon(Icons.forum),
                  label: '라운지',
                ),
                NavigationDestination(
                  icon: Icon(Icons.calculate_outlined),
                  selectedIcon: Icon(Icons.calculate),
                  label: '월급',
                ),
                NavigationDestination(
                  icon: Icon(Icons.savings_outlined),
                  selectedIcon: Icon(Icons.savings),
                  label: '연금',
                ),
                NavigationDestination(
                  icon: Icon(Icons.groups_outlined),
                  selectedIcon: Icon(Icons.groups),
                  label: '라이프',
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _titleForIndex(int index) {
    switch (index) {
      case 0:
        return '라운지';
      case 1:
        return '월급 리포트 & 연봉 시뮬레이션';
      case 2:
        return '연금 계산 서비스';
      case 3:
        return '모임/매칭';
      default:
        return '공무톡';
    }
  }
}

class _LifeSectionSelector extends StatelessWidget {
  const _LifeSectionSelector();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LifeSectionCubit, LifeSection>(
      builder: (context, section) {
        final ThemeData theme = Theme.of(context);
        final TextStyle labelStyle =
            theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ) ??
            const TextStyle(fontSize: 13, fontWeight: FontWeight.w600);

        final ButtonStyle style = ButtonStyle(
          visualDensity: VisualDensity.compact,
          padding: WidgetStateProperty.resolveWith(
            (states) => const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          textStyle: WidgetStatePropertyAll<TextStyle>(labelStyle),
          shape: WidgetStateProperty.resolveWith(
            (states) => const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return theme.colorScheme.primary.withAlpha(40);
            }
            return theme.colorScheme.surfaceContainerHighest;
          }),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
          side: WidgetStateProperty.resolveWith(
            (states) => BorderSide(
              color: states.contains(WidgetState.selected)
                  ? theme.colorScheme.primary.withAlpha(153)
                  : theme.dividerColor,
            ),
          ),
        );

        return SegmentedButton<LifeSection>(
          style: style,
          segments: const <ButtonSegment<LifeSection>>[
            ButtonSegment<LifeSection>(
              value: LifeSection.meetings,
              label: Text('모임'),
              icon: Icon(Icons.groups_outlined),
            ),
            ButtonSegment<LifeSection>(
              value: LifeSection.matching,
              label: Text('매칭'),
              icon: Icon(Icons.favorite_outline),
            ),
          ],
          selected: <LifeSection>{section},
          onSelectionChanged: (Set<LifeSection> value) {
            final LifeSection next = value.first;
            context.read<LifeSectionCubit>().setSection(next);
          },
        );
      },
    );
  }
}
