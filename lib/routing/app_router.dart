import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/app_shell.dart';
import '../features/calculator/presentation/views/salary_calculator_page.dart';
import '../features/pension/presentation/views/pension_calculator_gate_page.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createRouter() {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: SalaryCalculatorRoute.path,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: SalaryCalculatorRoute.path,
                name: SalaryCalculatorRoute.name,
                builder: (context, state) => const SalaryCalculatorPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: PensionCalculatorRoute.path,
                name: PensionCalculatorRoute.name,
                builder: (context, state) => const PensionCalculatorGatePage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

class SalaryCalculatorRoute {
  const SalaryCalculatorRoute._();

  static const String name = 'salary-calculator';
  static const String path = '/';
}

class PensionCalculatorRoute {
  const PensionCalculatorRoute._();

  static const String name = 'pension-calculator';
  static const String path = '/pension';
}
