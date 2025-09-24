import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../app/app_shell.dart';
import '../di/di.dart';
import '../features/auth/presentation/cubit/auth_cubit.dart';
import '../features/auth/presentation/views/auth_page.dart';
import '../features/blind/presentation/cubit/blind_feed_cubit.dart';
import '../features/blind/presentation/views/blind_feed_page.dart';
import '../features/calculator/presentation/views/salary_calculator_page.dart';
import '../features/community/presentation/cubit/community_feed_cubit.dart';
import '../features/community/presentation/views/community_feed_page.dart';
import '../features/matching/presentation/cubit/matching_cubit.dart';
import '../features/matching/presentation/views/matching_page.dart';
import '../features/pension/presentation/views/pension_calculator_gate_page.dart';
import '../features/community/domain/models/post.dart';
import '../features/community/presentation/views/post_create_page.dart';
import '../features/profile/presentation/views/profile_page.dart';
import 'router_refresh_stream.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createRouter() {
  final AuthCubit authCubit = getIt<AuthCubit>();

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: CommunityRoute.path,
    refreshListenable: GoRouterRefreshStream(authCubit.stream),
    redirect: (context, state) {
      final bool loggedIn = authCubit.state.isLoggedIn;
      final bool loggingIn = state.matchedLocation == LoginRoute.path;

      if (!loggedIn) {
        if (loggingIn) {
          return null;
        }

        final String target = _resolveRequestedPath(state);
        return Uri(
          path: LoginRoute.path,
          queryParameters: <String, String>{'from': target},
        ).toString();
      }

      if (loggingIn) {
        final String from = _sanitizeRedirectTarget(
          state.uri.queryParameters['from'],
        );
        return from;
      }

      return null;
    },
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
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: LoginRoute.path,
        name: LoginRoute.name,
        builder: (context, state) {
          final String redirectPath = _sanitizeRedirectTarget(
            state.uri.queryParameters['from'],
          );
          return AuthPage(redirectPath: redirectPath);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: PostCreateRoute.communityPath,
        name: '${PostCreateRoute.name}-community',
        builder: (context, state) => const PostCreatePage(postType: PostType.chirp),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: PostCreateRoute.blindPath,
        name: '${PostCreateRoute.name}-blind',
        builder: (context, state) => const PostCreatePage(postType: PostType.board),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '${CommunityRoute.editPath}/:postId',
        name: 'post-edit',
        builder: (context, state) {
          final postId = state.pathParameters['postId']!;
          return PostCreatePage(postType: PostType.chirp, postId: postId);
        },
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
  static const String writePath = '$path/write';
  static const String editPath = '$path/post/edit';
}

class PostCreateRoute {
  const PostCreateRoute._();

  static const String name = 'post-create';
  static const String communityPath = CommunityRoute.writePath;
  static const String blindPath = BlindRoute.writePath;
}

class BlindRoute {
  const BlindRoute._();

  static const String name = 'blind';
  static const String path = '/blind';
  static const String writePath = '$path/write';
}

class LoginRoute {
  const LoginRoute._();

  static const String name = 'login';
  static const String path = '/login';
}

String _resolveRequestedPath(GoRouterState state) {
  final Uri uri = state.uri;
  final String path = uri.path;

  if (path.isEmpty || path == LoginRoute.path) {
    return CommunityRoute.path;
  }

  if (path == '/_shell') {
    return _pathForBranch(uri.queryParameters['branch']);
  }

  return uri.toString();
}

String _sanitizeRedirectTarget(String? from) {
  if (from == null || from.isEmpty || from == LoginRoute.path) {
    return CommunityRoute.path;
  }

  final Uri uri = Uri.parse(from);
  if (uri.path == '/_shell') {
    return _pathForBranch(uri.queryParameters['branch']);
  }

  if (uri.path.isEmpty) {
    return CommunityRoute.path;
  }

  return from;
}

String _pathForBranch(String? branchParam) {
  final int branchIndex = int.tryParse(branchParam ?? '') ?? 0;
  switch (branchIndex) {
    case 0:
      return CommunityRoute.path;
    case 1:
      return BlindRoute.path;
    case 2:
      return SalaryCalculatorRoute.path;
    case 3:
      return PensionCalculatorRoute.path;
    case 4:
      return MatchingRoute.path;
    default:
      return CommunityRoute.path;
  }
}
