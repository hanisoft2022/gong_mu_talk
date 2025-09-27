import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/theme_cubit.dart';
import '../features/auth/presentation/cubit/auth_cubit.dart';
import '../routing/app_router.dart';
import '../common/widgets/global_app_bar_actions.dart';
import '../common/widgets/app_logo.dart';

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
          final bool hideAppBar = isCommunityTab || isLifeTab;
          final bool removeLogoInTitle =
              navigationShell.currentIndex == 1 ||
              navigationShell.currentIndex == 2;
          final Widget titleWidget = removeLogoInTitle
              ? Text(
                  _titleForIndex(navigationShell.currentIndex),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AppLogo(size: 28),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _titleForIndex(navigationShell.currentIndex),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                );
          return Scaffold(
            appBar: hideAppBar
                ? null
                : AppBar(
                    centerTitle: navigationShell.currentIndex == 2
                        ? false
                        : null,
                    title: titleWidget,
                    actions: [
                      GlobalAppBarActions(
                        isDarkMode: isDark,
                        onToggleTheme: () =>
                            context.read<ThemeCubit>().toggle(),
                        onProfileTap: () =>
                            GoRouter.of(context).push(ProfileRoute.path),
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
