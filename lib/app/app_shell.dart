import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/theme_cubit.dart';
import '../features/auth/presentation/cubit/auth_cubit.dart';
import '../routing/app_router.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (previous, current) => previous.lastMessage != current.lastMessage,
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
          return Scaffold(
            appBar: AppBar(
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/app_logo.png',
                    height: 28,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '공무톡 · ${_titleForIndex(navigationShell.currentIndex)}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  tooltip: isDark ? '라이트 모드' : '다크 모드',
                  onPressed: () => context.read<ThemeCubit>().toggle(),
                  icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
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
                  label: '매칭',
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
        return '나의 월급';
      case 2:
        return '연금 계산 서비스';
      case 3:
        return '매칭';
      default:
        return '공무톡';
    }
  }
}
