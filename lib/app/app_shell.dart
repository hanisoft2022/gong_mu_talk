import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/theme_cubit.dart';
import '../features/auth/presentation/cubit/auth_cubit.dart';
import '../routing/app_router.dart';
import '../common/widgets/global_app_bar_actions.dart';
import '../common/widgets/app_logo_button.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  bool get _isCommunityTab => navigationShell.currentIndex == 0;
  bool get _isCalculatorTab => navigationShell.currentIndex == 1;

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
          final bool isCommunityTab = _isCommunityTab;
          final bool isCalculatorTab = _isCalculatorTab;
          final ColorScheme colorScheme = Theme.of(context).colorScheme;
          final bool hideAppBar = isCommunityTab || isCalculatorTab;
          return Scaffold(
            appBar: hideAppBar
                ? null
                : AppBar(
                    elevation: 0,
                    scrolledUnderElevation: 6,
                    titleSpacing: 12,
                    toolbarHeight: 64,
                    leadingWidth: 64,
                    backgroundColor: colorScheme.surface,
                    surfaceTintColor: Colors.transparent,
                    leading: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: AppLogoButton(
                        compact: true,
                        onTap: () {},
                      ),
                    ),
                    title: Text(
                      _titleForIndex(navigationShell.currentIndex),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                    actions: [
                      GlobalAppBarActions(
                        compact: true,
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
                  label: '계산기',
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
        return '계산기';
      default:
        return '공무톡';
    }
  }
}
