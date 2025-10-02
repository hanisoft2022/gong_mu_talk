/// Profile Page - Main Entry Point
///
/// Clean, minimal entry point for the profile feature.
/// All UI components have been extracted to dedicated widget files.
///
/// Structure:
/// - ProfilePage: Main widget with auth state check
///   - If not logged in: ProfileLoggedOut
///   - If logged in: ProfileLoggedInScaffold
///
/// Phase 5 - Final cleanup after extraction of 30+ components
/// Original size: 3,131 lines
/// Final size: ~100 lines
/// Token reduction: ~30,000 → ~1,000 tokens (97% reduction)
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../di/di.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../cubit/profile_relations_cubit.dart';
import '../cubit/profile_timeline_cubit.dart';
import '../widgets/profile_scaffold/profile_logged_in_scaffold.dart';
import '../widgets/profile_scaffold/profile_logged_out.dart';

/// Main Profile Page
///
/// Displays user profile with two states:
/// 1. Logged out: Shows login prompt
/// 2. Logged in: Shows profile overview and settings tabs
///
/// For other profile-related pages:
/// - ProfileEditPage: Edit profile information
/// - LicensesPage: View app licenses
/// - PaystubVerificationPage: Upload/verify paystub
/// - MemberProfilePage: View other users' profiles
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, this.targetUserId});

  /// Target user ID for viewing other profiles
  /// If null, shows current user's profile
  final String? targetUserId;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return BlocBuilder<AuthCubit, AuthState>(
      buildWhen: (AuthState previous, AuthState current) =>
          previous.isLoggedIn != current.isLoggedIn,
      builder: (BuildContext context, AuthState state) {
        // Not logged in: Show login prompt
        if (!state.isLoggedIn) {
          return Scaffold(
            appBar: AppBar(
              leading: BackButton(onPressed: () => Navigator.of(context).pop()),
              title: const Text('마이페이지'),
            ),
            body: ProfileLoggedOut(theme: theme),
          );
        }

        // Logged in: Show profile with timeline and relations
        return MultiBlocProvider(
          providers: [
            BlocProvider<ProfileTimelineCubit>(
              create: (_) => getIt<ProfileTimelineCubit>()..loadInitial(),
            ),
            BlocProvider<ProfileRelationsCubit>(
              create: (_) => getIt<ProfileRelationsCubit>(),
            ),
          ],
          child: const ProfileLoggedInScaffold(),
        );
      },
    );
  }
}
