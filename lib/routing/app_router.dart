import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../app/app_shell.dart';
import '../di/di.dart';
import '../features/auth/presentation/cubit/auth_cubit.dart';
import '../features/auth/presentation/views/auth_page.dart';
import '../features/community/presentation/cubit/community_feed_cubit.dart';
import '../features/community/presentation/cubit/search_cubit.dart';
import '../features/community/presentation/cubit/scrap_cubit.dart';
import '../features/community/presentation/cubit/liked_posts_cubit.dart';
import '../features/community/presentation/cubit/user_comments_cubit.dart';
import '../features/community/presentation/views/community_feed_page.dart';
import '../features/community/presentation/views/scrap_page.dart';
import '../features/community/presentation/views/liked_posts_page.dart';
import '../features/community/presentation/views/user_comments_page.dart';

// TEMPORARILY DISABLED DUE TO IOS BUILD ISSUE
// import '../features/pension/presentation/views/pension_calculator_gate_page.dart';
// import '../features/pension/presentation/views/pension_calculator_page.dart';
// import '../features/pension/presentation/views/pension_quick_input_page.dart';
// import '../features/pension/presentation/views/pension_mz_result_page.dart';
// import '../features/pension/presentation/cubit/pension_calculator_cubit.dart';
// import '../features/pension/presentation/cubit/pension_cubit.dart';
// import '../features/pension/domain/entities/calculation_result.dart';
import '../features/community/domain/models/post.dart';
import '../features/community/presentation/views/post_create_page.dart';
import '../features/community/presentation/views/post_detail_view.dart';
import '../features/community/presentation/views/search_page.dart';
import '../features/profile/presentation/views/profile_page.dart';
import '../features/profile/presentation/views/member_profile_page.dart';
import '../features/profile/presentation/views/paystub_verification_page.dart';
import '../features/profile/presentation/views/blocked_users_page.dart';
import '../features/profile/presentation/views/profile_settings_page.dart';
import '../features/profile/presentation/widgets/profile_settings/custom_license_page.dart';
import '../features/profile/presentation/views/privacy_policy_page.dart';
import '../features/profile/presentation/views/terms_of_service_page.dart';
import '../features/calculator/presentation/views/calculator_home_page.dart';
import '../features/calculator/presentation/cubit/calculator_cubit.dart';

import '../features/notifications/presentation/views/notification_history_page.dart';
import '../features/notifications/presentation/views/notification_settings_page.dart';
import '../features/notifications/presentation/cubit/notification_history_cubit.dart';
import 'router_refresh_stream.dart';

/// Global navigator key for accessing navigation from services
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createRouter() {
  final AuthCubit authCubit = getIt<AuthCubit>();

  return GoRouter(
    navigatorKey: rootNavigatorKey,
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
            BlocProvider<CommunityFeedCubit>(
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
                builder: (context, state) => BlocProvider(
                  create: (_) => getIt<CalculatorCubit>(),
                  child: const CalculatorHomePage(),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: ProfileRoute.path,
        name: ProfileRoute.name,
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: ProfileSettingsRoute.path,
        name: ProfileSettingsRoute.name,
        builder: (context, state) => const ProfileSettingsPage(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '${ProfileRoute.path}/verify-paystub',
        name: PaystubVerificationRoute.name,
        builder: (context, state) => const PaystubVerificationPage(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '${ProfileRoute.path}/blocked-users',
        name: BlockedUsersRoute.name,
        builder: (context, state) => const BlockedUsersPage(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '${ProfileRoute.path}/licenses',
        name: LicensesRoute.name,
        builder: (context, state) => const CustomLicensePage(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '${ProfileRoute.path}/privacy',
        name: PrivacyPolicyRoute.name,
        builder: (context, state) => const PrivacyPolicyPage(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '${ProfileRoute.path}/terms',
        name: TermsOfServiceRoute.name,
        builder: (context, state) => const TermsOfServicePage(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '${ProfileRoute.path}/scraps',
        name: ScrapRoute.name,
        builder: (context, state) => BlocProvider<ScrapCubit>(
          create: (_) => getIt<ScrapCubit>(),
          child: const ScrapPage(),
        ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '${ProfileRoute.path}/liked-posts',
        name: LikedPostsRoute.name,
        builder: (context, state) => BlocProvider<LikedPostsCubit>(
          create: (_) => getIt<LikedPostsCubit>(),
          child: const LikedPostsPage(),
        ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '${ProfileRoute.path}/user/:uid/comments',
        name: UserCommentsRoute.name,
        builder: (context, state) {
          final String uid = state.pathParameters['uid']!;
          return BlocProvider<UserCommentsCubit>(
            create: (_) => getIt<UserCommentsCubit>(),
            child: UserCommentsPage(authorUid: uid),
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '${ProfileRoute.path}/user/:uid',
        name: MemberProfileRoute.name,
        builder: (context, state) {
          final String uid = state.pathParameters['uid']!;
          return MemberProfilePage(uid: uid);
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
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
        parentNavigatorKey: rootNavigatorKey,
        path: CommunityRoute.searchPath,
        name: CommunitySearchRoute.name,
        builder: (context, state) => BlocProvider<SearchCubit>(
          create: (_) => getIt<SearchCubit>(),
          child: SearchPage(initialQuery: state.uri.queryParameters['q']),
        ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '${CommunityRoute.editPath}/:postId',
        name: 'post-edit',
        builder: (context, state) {
          final postId = state.pathParameters['postId']!;
          return PostCreatePage(postType: PostType.chirp, postId: postId);
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '${CommunityRoute.path}/posts/:postId',
        name: PostDetailRoute.name,
        builder: (context, state) {
          final postId = state.pathParameters['postId']!;
          final commentId = state.uri.queryParameters['commentId'];
          return PostDetailView(
            postId: postId,
            highlightCommentId: commentId,
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: NotificationHistoryRoute.path,
        name: NotificationHistoryRoute.name,
        builder: (context, state) => BlocProvider(
          create: (context) {
            final cubit = getIt<NotificationHistoryCubit>();
            final authState = context.read<AuthCubit>().state;
            if (authState.userId != null) {
              cubit.loadNotifications(authState.userId!);
            }
            return cubit;
          },
          child: const NotificationHistoryPage(),
        ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: NotificationSettingsRoute.path,
        name: NotificationSettingsRoute.name,
        builder: (context, state) => const NotificationSettingsPage(),
      ),
      // CALCULATOR ROUTES TEMPORARILY DISABLED - UNDER REDESIGN
      // GoRoute(
      //   parentNavigatorKey: rootNavigatorKey,
      //   path: '/calculator/salary/detail',
      //   name: 'calculator-salary-detail',
      //   builder: (context, state) => const SalaryCalculatorPage(),
      // ),
      // TEMPORARILY DISABLED DUE TO IOS BUILD ISSUE
      // GoRoute(
      //   parentNavigatorKey: rootNavigatorKey,
      //   path: '/calculator/pension',
      //   name: 'calculator-pension',
      //   builder: (context, state) => const PensionCalculatorGatePage(),
      // ),
      // GoRoute(
      //   parentNavigatorKey: rootNavigatorKey,
      //   path: '/calculator/pension/calculate',
      //   name: 'calculator-pension-calculate',
      //   builder: (context, state) => BlocProvider<PensionCalculatorCubit>(
      //     create: (_) => getIt<PensionCalculatorCubit>(),
      //     child: const PensionCalculatorPage(),
      //   ),
      // ),
      // GoRoute(
      //   parentNavigatorKey: rootNavigatorKey,
      //   path: '/calculator/pension/quick',
      //   name: 'calculator-pension-quick',
      //   builder: (context, state) => BlocProvider<PensionCubit>(
      //     create: (_) => getIt<PensionCubit>(),
      //     child: const PensionQuickInputPage(),
      //   ),
      // ),
      // GoRoute(
      //   parentNavigatorKey: rootNavigatorKey,
      //   path: '/calculator/pension/result',
      //   name: 'calculator-pension-result',
      //   builder: (context, state) {
      //     final result = state.extra as CalculationResult;
      //     return PensionMzResultPage(result: result);
      //   },
      // ),
      // GoRoute(
      //   parentNavigatorKey: rootNavigatorKey,
      //   path: '/calculator/career-simulator',
      //   name: 'calculator-career-simulator',
      //   builder: (context, state) => const CareerSimulatorPage(),
      // ),
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

class ProfileSettingsRoute {
  const ProfileSettingsRoute._();

  static const String name = 'profile-settings';
  static const String path = '/profile/settings';
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

class BlockedUsersRoute {
  const BlockedUsersRoute._();

  static const String name = 'blocked-users';
  static const String path = '${ProfileRoute.path}/blocked-users';
}

class LicensesRoute {
  const LicensesRoute._();

  static const String name = 'licenses';
  static const String path = '${ProfileRoute.path}/licenses';
}

class PrivacyPolicyRoute {
  const PrivacyPolicyRoute._();

  static const String name = 'privacy-policy';
  static const String path = '${ProfileRoute.path}/privacy';
}

class TermsOfServiceRoute {
  const TermsOfServiceRoute._();

  static const String name = 'terms-of-service';
  static const String path = '${ProfileRoute.path}/terms';
}

class ScrapRoute {
  const ScrapRoute._();

  static const String name = 'scraps';
  static const String path = '${ProfileRoute.path}/scraps';
}

class LikedPostsRoute {
  const LikedPostsRoute._();

  static const String name = 'liked-posts';
  static const String path = '${ProfileRoute.path}/liked-posts';
}

class UserCommentsRoute {
  const UserCommentsRoute._();

  static const String name = 'user-comments';
}

class CommunityRoute {
  const CommunityRoute._();

  static const String name = 'community';
  static const String path = '/community';
  static const String editPath = '$path/post/edit';
  static const String searchPath = '$path/search';
}

class CommunitySearchRoute {
  const CommunitySearchRoute._();

  static const String name = 'community-search';
}

class PostDetailRoute {
  const PostDetailRoute._();

  static const String name = 'post-detail';
  static const String path = '${CommunityRoute.path}/posts';
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
