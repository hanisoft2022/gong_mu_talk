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
/// - Master toggle for all notifications (AuthCubit)
/// - Individual toggles for specific notification types (NotificationPreferencesCubit)
/// - Disabled state for sub-toggles when master toggle is off
/// - Visual indicators (icons, colors) for enabled/disabled states
/// - Persistent storage using SharedPreferences
///
/// **Notification Types**:
/// - Global notifications: Master control for all notifications
/// - Like notifications: When posts receive likes
/// - Comment notifications: When posts receive comments
/// - Follow notifications: When new followers are gained
///
/// **State Management**:
/// - AuthCubit: Global notifications toggle (master switch)
/// - NotificationPreferencesCubit: Individual notification toggles
///
/// **Related**:
/// - NotificationPreferencesCubit: Manages individual preferences
/// - AuthCubit: Manages global notification toggle

library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../auth/presentation/cubit/auth_cubit.dart';
import '../../cubit/notification_preferences_cubit.dart';
import 'settings_section.dart';

/// Notification settings section with master and individual toggles
class NotificationSettingsSection extends StatelessWidget {
  const NotificationSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (BuildContext context, AuthState authState) {
        final bool isProcessing = authState.isProcessing;
        final bool notificationsEnabled = authState.notificationsEnabled;

        return BlocBuilder<NotificationPreferencesCubit, NotificationPreferencesState>(
          builder: (BuildContext context, NotificationPreferencesState prefState) {
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
                  value: prefState.likeNotifications,
                  enabled: notificationsEnabled && !isProcessing && !prefState.isLoading,
                  onChanged: (value) => context
                      .read<NotificationPreferencesCubit>()
                      .setLikeNotifications(value),
                ),

                // 댓글 알림
                _buildSubNotificationTile(
                  context: context,
                  icon: Icons.comment_outlined,
                  title: '댓글 알림',
                  subtitle: '내 게시물에 댓글이 달렸을 때',
                  value: prefState.commentNotifications,
                  enabled: notificationsEnabled && !isProcessing && !prefState.isLoading,
                  onChanged: (value) => context
                      .read<NotificationPreferencesCubit>()
                      .setCommentNotifications(value),
                ),

                // 팔로우 알림
                _buildSubNotificationTile(
                  context: context,
                  icon: Icons.person_add_outlined,
                  title: '팔로우 알림',
                  subtitle: '새로운 팔로워가 생겼을 때',
                  value: prefState.followNotifications,
                  enabled: notificationsEnabled && !isProcessing && !prefState.isLoading,
                  onChanged: (value) => context
                      .read<NotificationPreferencesCubit>()
                      .setFollowNotifications(value),
                ),
              ],
            );
          },
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
