/// Profile Logged In Scaffold
///
/// Main scaffold for authenticated profile view.
/// - Shows profile overview with tabs
/// - Settings accessible via top-right icon
/// - Message display with debouncing logic
/// - BLoC listener for auth state messages
///
/// Phase 4 - Extracted from profile_page.dart
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/utils/snackbar_helpers.dart';
import '../../../../../routing/app_router.dart';
import '../../../../auth/presentation/cubit/auth_cubit.dart';
import '../profile_overview/profile_overview_tab.dart';

class ProfileLoggedInScaffold extends StatefulWidget {
  const ProfileLoggedInScaffold({super.key});

  @override
  State<ProfileLoggedInScaffold> createState() =>
      _ProfileLoggedInScaffoldState();
}

class _ProfileLoggedInScaffoldState extends State<ProfileLoggedInScaffold> {
  String? _lastShownMessage;
  DateTime? _lastMessageTime;

  /// Shows message with debouncing to prevent duplicate snackbars
  void _showMessageIfDifferent(BuildContext context, String message, {bool isError = false}) {
    final now = DateTime.now();

    // 같은 메시지를 1초 이내에 연속으로 표시하지 않음
    if (_lastShownMessage == message &&
        _lastMessageTime != null &&
        now.difference(_lastMessageTime!).inMilliseconds < 1000) {
      return;
    }

    // Use SnackbarHelpers for consistent styling
    if (isError) {
      SnackbarHelpers.showError(context, message);
    } else {
      SnackbarHelpers.showSuccess(context, message);
    }

    _lastShownMessage = message;
    _lastMessageTime = now;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (AuthState previous, AuthState current) =>
          previous.lastMessage != current.lastMessage &&
          current.lastMessage != null,
      listener: (BuildContext context, AuthState state) {
        final String? message = state.lastMessage;
        if (message == null) {
          return;
        }
        _showMessageIfDifferent(context, message, isError: state.authError != null);
        context.read<AuthCubit>().clearLastMessage();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: () => context.pop()),
          title: const Text('마이페이지'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => context.push(ProfileSettingsRoute.path),
              tooltip: '앱 설정',
            ),
          ],
        ),
        body: const ProfileOverviewTab(),
      ),
    );
  }
}
