import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../app/app_shell.dart';
import '../features/community/presentation/views/community_feed_page.dart';
import '../features/blind/presentation/views/blind_feed_page.dart';
import '../features/calculator/presentation/views/salary_calculator_page.dart';
import '../features/pension/presentation/views/pension_calculator_gate_page.dart';
import '../features/matching/presentation/views/matching_page.dart';
import '../di/di.dart';
import '../features/community/presentation/cubit/community_feed_cubit.dart';
import '../features/blind/presentation/cubit/blind_feed_cubit.dart';
import '../features/matching/presentation/cubit/matching_cubit.dart';
import '../features/profile/presentation/views/profile_page.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createRouter() {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: CommunityRoute.path,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: CommunityRoute.path,
                name: CommunityRoute.name,
                builder: (context, state) => BlocProvider<CommunityFeedCubit>(
                  create: (_) => getIt<CommunityFeedCubit>(),
                  child: const CommunityFeedPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: BlindRoute.path,
                name: BlindRoute.name,
                builder: (context, state) => BlocProvider<BlindFeedCubit>(
                  create: (_) => getIt<BlindFeedCubit>(),
                  child: const BlindFeedPage(),
                ),
              ),
            ],
          ),
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
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: MatchingRoute.path,
                name: MatchingRoute.name,
                builder: (context, state) => BlocProvider<MatchingCubit>(
                  create: (_) => getIt<MatchingCubit>(),
                  child: const MatchingPage(),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: ProfileRoute.path,
        name: ProfileRoute.name,
        builder: (context, state) => const ProfilePage(),
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

class ProfileRoute {
  const ProfileRoute._();

  static const String name = 'profile';
  static const String path = '/profile';
}

class MatchingRoute {
  const MatchingRoute._();

  static const String name = 'matching';
  static const String path = '/matching';
}

class CommunityRoute {
  const CommunityRoute._();

  static const String name = 'community';
  static const String path = '/community';
}

class BlindRoute {
  const BlindRoute._();

  static const String name = 'blind';
  static const String path = '/blind';
}
