/// Profile Settings Tab Widget
///
/// Main coordinator for all profile settings sections.
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
///
/// **Related**:
/// - All section widgets in profile_settings/ directory
/// - AuthCubit for authentication operations

library;

import 'dart:async';

import 'package:flutter/material.dart';

import 'notification_settings_section.dart';
import 'blocked_users_section.dart';
import 'password_change_section.dart';
import 'customer_support_section.dart';
import 'privacy_terms_section.dart';
import 'app_info_section.dart';
import 'account_management_section.dart';

/// Profile settings tab with all settings sections
class ProfileSettingsTab extends StatefulWidget {
  const ProfileSettingsTab({super.key});

  @override
  State<ProfileSettingsTab> createState() => _ProfileSettingsTabState();
}

class _ProfileSettingsTabState extends State<ProfileSettingsTab> {
  Timer? _snackBarTimer;

  @override
  void dispose() {
    _snackBarTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Settings sections as a list (easy to reorder/add/remove)
    final List<Widget> sections = [
      const NotificationSettingsSection(),
      const BlockedUsersSection(),
      PasswordChangeSection(showMessage: _showMessage),
      CustomerSupportSection(showMessage: _showMessage),
      PrivacyTermsSection(showMessage: _showMessage),
      const AppInfoSection(),
      const AccountManagementSection(),
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: sections.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) => sections[index],
    );
  }

  /// Shows a SnackBar message with timer-based overlap prevention
  ///
  /// This prevents multiple SnackBars from appearing simultaneously
  /// by canceling any existing timer and removing current SnackBar
  /// before showing a new one.
  void _showMessage(BuildContext context, String message) {
    // 이전 타이머 취소
    _snackBarTimer?.cancel();

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // 즉시 이전 스낵바 제거
    scaffoldMessenger.removeCurrentSnackBar();

    // 짧은 지연 후 새 스낵바 표시 (연속 호출 방지)
    _snackBarTimer = Timer(const Duration(milliseconds: 100), () {
      if (context.mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }
}
