import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../app/app_shell.dart';
import '../di/di.dart';
import '../features/auth/presentation/cubit/auth_cubit.dart';
import '../features/auth/presentation/views/auth_page.dart';
import '../features/calculator/presentation/views/salary_calculator_page.dart';
import '../features/community/presentation/cubit/community_feed_cubit.dart';
import '../features/community/presentation/cubit/post_detail_cubit.dart';
import '../features/community/presentation/cubit/search_cubit.dart';
import '../features/community/presentation/views/community_feed_page.dart';
import '../features/community/presentation/views/post_detail_page.dart';

import '../features/pension/presentation/views/pension_calculator_gate_page.dart';
import '../features/pension/presentation/views/pension_calculator_page.dart';
import '../features/pension/presentation/cubit/pension_calculator_cubit.dart';
import '../features/community/domain/models/post.dart';
import '../features/community/presentation/views/post_create_page.dart';
import '../features/community/presentation/views/search_page.dart';
import '../features/profile/presentation/views/profile_page.dart';
import '../features/profile/presentation/views/member_profile_page.dart';
import '../features/profile/presentation/views/paystub_verification_page.dart';
import '../features/salary_insights/presentation/views/teacher_salary_insight_page.dart';
import '../features/calculator/presentation/views/calculator_home_page.dart';

import '../features/notifications/presentation/views/notification_history_page.dart';
import '../features/notifications/presentation/views/notification_settings_page.dart';
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
        builder: (context, state, navigationShell) => BlocProvider<CommunityFeedCubit>(
          create: (_) => getIt<CommunityFeedCubit>(),
          child: AppShell(navigationShell: navigationShell),
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: CommunityRoute.path,
                name: CommunityRoute.name,
                builder: (context, state) => const CommunityFeedPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: CalculatorRoute.path,
                name: CalculatorRoute.name,
                builder: (context, state) => const CalculatorHomePage(),
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
        path: '${ProfileRoute.path}/verify-paystub',
        name: PaystubVerificationRoute.name,
        builder: (context, state) => const PaystubVerificationPage(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '${ProfileRoute.path}/user/:uid',
        name: MemberProfileRoute.name,
        builder: (context, state) {
          final String uid = state.pathParameters['uid']!;
          return MemberProfilePage(uid: uid);
        },
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
        path: '${CommunityRoute.postDetailPath}/:postId',
        name: CommunityPostDetailRoute.name,
        builder: (context, state) {
          final String postId = state.pathParameters['postId']!;
          final Post? initialPost = state.extra is Post
              ? state.extra as Post
              : null;
          final String? replyCommentId = state.uri.queryParameters['reply'];
          return BlocProvider<PostDetailCubit>(
            create: (_) => getIt<PostDetailCubit>(),
            child: PostDetailPage(
              postId: postId,
              initialPost: initialPost,
              replyCommentId: replyCommentId,
            ),
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: CommunityRoute.searchPath,
        name: CommunitySearchRoute.name,
        builder: (context, state) => BlocProvider<SearchCubit>(
          create: (_) => getIt<SearchCubit>(),
          child: SearchPage(initialQuery: state.uri.queryParameters['q']),
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: PostCreateRoute.communityPath,
        name: '${PostCreateRoute.name}-community',
        builder: (context, state) =>
            const PostCreatePage(postType: PostType.chirp),
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
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: NotificationHistoryRoute.path,
        name: NotificationHistoryRoute.name,
        builder: (context, state) => const NotificationHistoryPage(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: NotificationSettingsRoute.path,
        name: NotificationSettingsRoute.name,
        builder: (context, state) => const NotificationSettingsPage(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/calculator/salary',
        name: 'calculator-salary',
        builder: (context, state) => const TeacherSalaryInsightPage(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/calculator/salary/detail',
        name: 'calculator-salary-detail',
        builder: (context, state) => const SalaryCalculatorPage(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/calculator/pension',
        name: 'calculator-pension',
        builder: (context, state) => const PensionCalculatorGatePage(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/calculator/pension/calculate',
        name: 'calculator-pension-calculate',
        builder: (context, state) => BlocProvider<PensionCalculatorCubit>(
          create: (_) => getIt<PensionCalculatorCubit>(),
          child: const PensionCalculatorPage(),
        ),
      ),
    ],
  );
}

class CalculatorRoute {
  const CalculatorRoute._();

  static const String name = 'calculator';
  static const String path = '/calculator';
}

class SalaryCalculatorRoute {
  const SalaryCalculatorRoute._();

  static const String name = 'salary-calculator';
  static const String path = '/salary';
}

class SalaryDetailCalculatorRoute {
  const SalaryDetailCalculatorRoute._();

  static const String name = 'salary-calculator-detail';
  static const String path = 'calculator';
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

class MemberProfileRoute {
  const MemberProfileRoute._();

  static const String name = 'member-profile';
}

class PaystubVerificationRoute {
  const PaystubVerificationRoute._();

  static const String name = 'paystub-verification';
  static const String path = '${ProfileRoute.path}/verify-paystub';
}


class CommunityRoute {
  const CommunityRoute._();

  static const String name = 'community';
  static const String path = '/community';
  static const String writePath = '$path/write';
  static const String editPath = '$path/post/edit';
  static const String postDetailPath = '$path/post';
  static const String searchPath = '$path/search';

  static String postDetailPathWithId(String postId) =>
      '$postDetailPath/$postId';
}

class CommunityPostDetailRoute {
  const CommunityPostDetailRoute._();

  static const String name = 'community-post-detail';
}

class CommunitySearchRoute {
  const CommunitySearchRoute._();

  static const String name = 'community-search';
}

class PostCreateRoute {
  const PostCreateRoute._();

  static const String name = 'post-create';
  static const String communityPath = CommunityRoute.writePath;
}

class LoginRoute {
  const LoginRoute._();

  static const String name = 'login';
  static const String path = '/login';
}

class NotificationHistoryRoute {
  const NotificationHistoryRoute._();

  static const String name = 'notification-history';
  static const String path = '/notifications/history';
}

class NotificationSettingsRoute {
  const NotificationSettingsRoute._();

  static const String name = 'notification-settings';
  static const String path = '/notifications/settings';
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
      return CalculatorRoute.path;
    default:
      return CommunityRoute.path;
  }
}
