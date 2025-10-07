/// Notification Settings Section Widget
///
/// Provides UI for managing notification preferences.
///
/// **Purpose**:
/// - Allow users to toggle global notification settings
/// - Configure individual notification types (likes, comments, follows)
/// - Provide visual feedback for notification states
///
/// **Features**:
/// - Master toggle for all notifications
/// - Individual toggles for specific notification types
/// - Disabled state for sub-toggles when master toggle is off
/// - Visual indicators (icons, colors) for enabled/disabled states
///
/// **Notification Types**:
/// - Global notifications: Master control for all notifications
/// - Like notifications: When posts receive likes
/// - Comment notifications: When posts receive comments
/// - Follow notifications: When new followers are gained
///
/// **Future Improvements**:
/// - SharedPreferences integration for sub-notification persistence
/// - Backend sync for notification preferences
/// - Push notification token management

library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../auth/presentation/cubit/auth_cubit.dart';
import 'settings_section.dart';

/// Notification settings section with master and individual toggles
class NotificationSettingsSection extends StatefulWidget {
  const NotificationSettingsSection({super.key});

  @override
  State<NotificationSettingsSection> createState() =>
      _NotificationSettingsSectionState();
}

class _NotificationSettingsSectionState
    extends State<NotificationSettingsSection> {
  // 알림 설정 상태 (향후 SharedPreferences로 저장 예정)
  bool _likeNotifications = true;
  bool _commentNotifications = true;
  bool _followNotifications = true;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (BuildContext context, AuthState state) {
        final bool isProcessing = state.isProcessing;
        final bool notificationsEnabled = state.notificationsEnabled;

        return SettingsSection(
          title: '알림 설정',
          children: [
            // 전체 알림 토글 (마스터 스위치)
            ListTile(
              contentPadding: const EdgeInsets.only(left: 16),
              leading: const Icon(Icons.notifications_outlined, size: 20),
              title: const Text('전체 알림'),
              subtitle: const Text('모든 알림을 받을지 설정합니다.'),
              trailing: Switch.adaptive(
                value: notificationsEnabled,
                onChanged: isProcessing
                    ? null
                    : (bool value) => context
                          .read<AuthCubit>()
                          .updateNotificationsEnabled(value),
              ),
            ),
            const Divider(),

            // 좋아요 알림
            _buildSubNotificationTile(
              context: context,
              icon: Icons.favorite_outline,
              title: '좋아요 알림',
              subtitle: '내 게시물에 좋아요가 달렸을 때',
              value: _likeNotifications,
              enabled: notificationsEnabled && !isProcessing,
              onChanged: (value) {
                setState(() {
                  _likeNotifications = value;
                });
                // SharedPreferences 저장 로직은 향후 구현 예정
              },
            ),

            // 댓글 알림
            _buildSubNotificationTile(
              context: context,
              icon: Icons.comment_outlined,
              title: '댓글 알림',
              subtitle: '내 게시물에 댓글이 달렸을 때',
              value: _commentNotifications,
              enabled: notificationsEnabled && !isProcessing,
              onChanged: (value) {
                setState(() {
                  _commentNotifications = value;
                });
                // SharedPreferences 저장 로직은 향후 구현 예정
              },
            ),

            // 팔로우 알림
            _buildSubNotificationTile(
              context: context,
              icon: Icons.person_add_outlined,
              title: '팔로우 알림',
              subtitle: '새로운 팔로워가 생겼을 때',
              value: _followNotifications,
              enabled: notificationsEnabled && !isProcessing,
              onChanged: (value) {
                setState(() {
                  _followNotifications = value;
                });
                // SharedPreferences 저장 로직은 향후 구현 예정
              },
            ),
          ],
        );
      },
    );
  }

  /// Builds a sub-notification list tile with conditional styling
  Widget _buildSubNotificationTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required bool enabled,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    final color = enabled
        ? null
        : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5);

    return ListTile(
      contentPadding: const EdgeInsets.only(left: 16),
      leading: Icon(icon, size: 20, color: color),
      title: Text(title, style: TextStyle(color: color)),
      subtitle: Text(subtitle, style: TextStyle(color: color)),
      trailing: Switch.adaptive(
        value: enabled ? value : false,
        onChanged: enabled ? onChanged : null,
      ),
    );
  }
}
