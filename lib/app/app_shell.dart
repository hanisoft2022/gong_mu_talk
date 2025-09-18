import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/theme_cubit.dart';
import '../features/auth/presentation/cubit/auth_cubit.dart';

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
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(message)),
          );
      },
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          final bool isDark = themeMode == ThemeMode.dark;
          return Scaffold(
            appBar: AppBar(
              title: Text(_titleForIndex(navigationShell.currentIndex)),
              actions: [
                IconButton(
                  tooltip: isDark ? '라이트 모드' : '다크 모드',
                  onPressed: () => context.read<ThemeCubit>().toggle(),
                  icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
                ),
              ],
            ),
            body: navigationShell,
            bottomNavigationBar: NavigationBar(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: (index) {
                navigationShell.goBranch(index);
              },
              destinations: const [
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
        return '나의 월급';
      case 1:
        return '연금 계산 서비스';
      default:
        return '공무톡';
    }
  }
}
