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
/// 2. PasswordChangeSection: Password change form
/// 3. CustomerSupportSection: Feedback and support
/// 4. PrivacyTermsSection: Privacy policy and terms
/// 5. AppInfoSection: App version and info
/// 6. AccountManagementSection: Account deletion
///
/// **State Management**:
/// - Uses AuthCubit for user authentication state
/// - Timer-based SnackBar management to prevent overlaps
/// - StatefulWidget for managing controllers and timers
///
/// **Related**:
/// - All section widgets in profile_settings/ directory
/// - AuthCubit for authentication operations

library;
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../../core/utils/performance_optimizations.dart';
import 'notification_settings_section.dart';
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
    return OptimizedListView(
      itemCount: 12,
      itemBuilder: (context, index) {
        if (index == 0) {
          return const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: NotificationSettingsSection(),
          );
        } else if (index == 1) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Gap(16),
          );
        } else if (index == 2) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: PasswordChangeSection(showMessage: _showMessage),
          );
        } else if (index == 3) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Gap(16),
          );
        } else if (index == 4) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: CustomerSupportSection(showMessage: _showMessage),
          );
        } else if (index == 5) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Gap(16),
          );
        } else if (index == 6) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: PrivacyTermsSection(showMessage: _showMessage),
          );
        } else if (index == 7) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Gap(16),
          );
        } else if (index == 8) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: AppInfoSection(),
          );
        } else if (index == 9) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Gap(16),
          );
        } else if (index == 10) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: AccountManagementSection(),
          );
        } else {
          return const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Gap(16),
          );
        }
      },
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
