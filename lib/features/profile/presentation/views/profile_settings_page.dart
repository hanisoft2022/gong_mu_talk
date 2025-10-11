/// Profile Settings Page
///
/// Standalone page for app settings, accessible from profile page.
///
/// **Purpose**:
/// - Organize settings into logical sections
/// - Provide centralized settings UI
/// - Handle settings-related state management
///
/// **Features**:
/// - Notification settings (global + individual toggles)
/// - Password change functionality
/// - Customer support (feedback)
/// - Privacy policy and terms links
/// - App information (version, developer, licenses)
/// - Account deletion
///
/// **Sections**:
/// 1. NotificationSettingsSection: Notification preferences
/// 2. BlockedUsersSection: Blocked users management
/// 3. PasswordChangeSection: Password change form
/// 4. CustomerSupportSection: Feedback and support
/// 5. PrivacyTermsSection: Privacy policy and terms
/// 6. AppInfoSection: App version and info
/// 7. AccountManagementSection: Account deletion
///
/// **State Management**:
/// - Uses AuthCubit for user authentication state
/// - Timer-based SnackBar management to prevent overlaps
/// - StatefulWidget for managing controllers and timers
///
/// **Improvements**:
/// - Sections managed as data (easy to reorder/add/remove)
/// - ListView.separated for cleaner Gap handling
/// - No hardcoded indices

library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/snackbar_helpers.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../widgets/profile_settings/notification_settings_section.dart';
import '../widgets/profile_settings/blocked_users_section.dart';
import '../widgets/profile_settings/password_change_section.dart';
import '../widgets/profile_settings/customer_support_section.dart';
import '../widgets/profile_settings/privacy_terms_section.dart';
import '../widgets/profile_settings/app_info_section.dart';
import '../widgets/profile_settings/account_management_section.dart';

/// Profile settings page with all settings sections
class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({super.key});

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  Timer? _snackBarTimer;

  @override
  void dispose() {
    _snackBarTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('앱 설정'),
      ),
      body: _SettingsListContent(showMessage: _showMessage),
    );
  }

  /// Shows a SnackBar message with timer-based overlap prevention
  ///
  /// This prevents multiple SnackBars from appearing simultaneously
  /// by canceling any existing timer before showing a new one.
  void _showMessage(BuildContext context, String message) {
    // 이전 타이머 취소
    _snackBarTimer?.cancel();

    // 짧은 지연 후 새 스낵바 표시 (연속 호출 방지)
    _snackBarTimer = Timer(const Duration(milliseconds: 100), () {
      if (context.mounted) {
        // Use SnackbarHelpers for consistent styling
        SnackbarHelpers.showSuccess(context, message);
      }
    });
  }
}

/// Settings list content widget (reusable)
///
/// This widget contains the actual settings sections list.
/// Can be used both in ProfileSettingsPage and ProfileSettingsTab.
///
/// **Dynamic Sections**:
/// - Password Change: Only shown for email/password sign-in users
/// - Hidden for Google/other OAuth users (no password to change)
class _SettingsListContent extends StatelessWidget {
  const _SettingsListContent({required this.showMessage});

  final void Function(BuildContext context, String message) showMessage;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        // Settings sections as a list (easy to reorder/add/remove)
        final List<Widget> sections = [
          const NotificationSettingsSection(),
          const BlockedUsersSection(),
          // Only show password change for email/password sign-in
          if (authState.isPasswordProvider)
            PasswordChangeSection(showMessage: showMessage),
          CustomerSupportSection(showMessage: showMessage),
          PrivacyTermsSection(showMessage: showMessage),
          const AppInfoSection(),
          const AccountManagementSection(),
        ];

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: sections.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) => sections[index],
        );
      },
    );
  }
}
