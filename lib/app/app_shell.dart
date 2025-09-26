import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/theme_cubit.dart';
import '../features/auth/presentation/cubit/auth_cubit.dart';
import '../features/community/domain/models/feed_filters.dart';
import '../features/community/presentation/cubit/community_feed_cubit.dart';
import '../features/profile/domain/career_track.dart';
import '../routing/app_router.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  bool get _isCommunityTab => navigationShell.currentIndex == 0;

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
          final ColorScheme colorScheme = Theme.of(context).colorScheme;
          return Scaffold(
            appBar: AppBar(
              title: isCommunityTab
                  ? const _LoungeScopeSelector()
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/app_logo.png',
                          height: 28,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _titleForIndex(navigationShell.currentIndex),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
              actions: [
                if (isCommunityTab)
                  IconButton(
                    tooltip: '검색',
                    onPressed: () =>
                        GoRouter.of(context).push(CommunityRoute.searchPath),
                    icon: const Icon(Icons.search),
                  ),
                IconButton(
                  tooltip: isDark ? '라이트 모드' : '다크 모드',
                  onPressed: () => context.read<ThemeCubit>().toggle(),
                  icon: Icon(
                    isDark
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                  ),
                ),
                IconButton(
                  tooltip: '마이페이지',
                  onPressed: () => GoRouter.of(context).push(ProfileRoute.path),
                  icon: const Icon(Icons.person_outline),
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
                  icon: Icon(Icons.favorite_outline),
                  selectedIcon: Icon(Icons.favorite),
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
        return '라이프';
      default:
        return '공무톡';
    }
  }
}

class _LoungeScopeSelector extends StatelessWidget {
  const _LoungeScopeSelector();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CommunityFeedCubit, CommunityFeedState>(
      builder: (context, state) {
        final ThemeData theme = Theme.of(context);
        final bool hasSerialAccess =
            state.careerTrack != CareerTrack.none && state.serial != 'unknown';

        final TextStyle labelStyle =
            theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ) ??
            const TextStyle(fontSize: 13, fontWeight: FontWeight.w600);

        final ButtonStyle compactStyle = ButtonStyle(
          visualDensity: VisualDensity.compact,
          padding: WidgetStateProperty.resolveWith(
            (states) => const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          textStyle: WidgetStateProperty.resolveWith((states) => labelStyle),
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

        return SegmentedButton<LoungeScope>(
          style: compactStyle,
          segments: [
            const ButtonSegment<LoungeScope>(
              value: LoungeScope.all,
              label: Text('전체'),
              icon: Icon(Icons.public_outlined),
            ),
            ButtonSegment<LoungeScope>(
              value: LoungeScope.serial,
              label: const Text('내 직렬'),
              icon: const Icon(Icons.group_outlined),
              enabled: hasSerialAccess,
            ),
          ],
          selected: <LoungeScope>{state.scope},
          onSelectionChanged: (selection) {
            final LoungeScope nextScope = selection.first;
            if (nextScope != state.scope) {
              context.read<CommunityFeedCubit>().changeScope(nextScope);
            }
          },
        );
      },
    );
  }
}
