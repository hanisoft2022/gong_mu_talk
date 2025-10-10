/// Notification Preferences Cubit
///
/// Manages individual notification preferences (likes, comments, follows).
///
/// **Purpose**:
/// - Persist notification preferences using SharedPreferences
/// - Load preferences on app startup
/// - Update preferences and save to storage
///
/// **Features**:
/// - Like notifications toggle
/// - Comment notifications toggle
/// - Follow notifications toggle
/// - Persistent storage (survives app restart)
///
/// **Storage**:
/// - Uses SharedPreferences for local persistence
/// - Keys: 'notif_likes', 'notif_comments', 'notif_follows'
/// - Default: all enabled (true)
///
/// **Related**:
/// - NotificationSettingsSection: UI for preferences
/// - AuthCubit: Global notification toggle (master switch)

library;

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'notification_preferences_state.dart';

/// Cubit for managing notification preferences (User-specific)
class NotificationPreferencesCubit extends Cubit<NotificationPreferencesState> {
  NotificationPreferencesCubit()
      : super(const NotificationPreferencesState()) {
    _loadPreferences();
  }

  // SharedPreferences key prefixes (User-specific)
  static const String _keyLikeNotificationsPrefix = 'notif_likes';
  static const String _keyCommentNotificationsPrefix = 'notif_comments';
  static const String _keyFollowNotificationsPrefix = 'notif_follows';
  static const String _guestSuffix = '_guest';

  String? _currentUserId;

  /// Set current user ID and reload preferences
  Future<void> setUserId(String? userId) async {
    if (_currentUserId == userId) return;
    _currentUserId = userId;
    await _loadPreferences();
  }

  /// Get user-specific key
  String _getUserKey(String prefix) {
    if (_currentUserId == null || _currentUserId!.isEmpty) {
      return '$prefix$_guestSuffix';
    }
    return '${prefix}_$_currentUserId';
  }

  /// Loads preferences from SharedPreferences
  Future<void> _loadPreferences() async {
    emit(state.copyWith(isLoading: true));

    try {
      final prefs = await SharedPreferences.getInstance();

      emit(NotificationPreferencesState(
        likeNotifications: prefs.getBool(
              _getUserKey(_keyLikeNotificationsPrefix),
            ) ??
            true,
        commentNotifications: prefs.getBool(
              _getUserKey(_keyCommentNotificationsPrefix),
            ) ??
            true,
        followNotifications: prefs.getBool(
              _getUserKey(_keyFollowNotificationsPrefix),
            ) ??
            true,
        isLoading: false,
      ));
    } catch (e) {
      // If loading fails, keep default values
      emit(state.copyWith(isLoading: false));
    }
  }

  /// Updates like notifications preference
  Future<void> setLikeNotifications(bool enabled) async {
    emit(state.copyWith(likeNotifications: enabled));
    await _savePreference(_getUserKey(_keyLikeNotificationsPrefix), enabled);
  }

  /// Updates comment notifications preference
  Future<void> setCommentNotifications(bool enabled) async {
    emit(state.copyWith(commentNotifications: enabled));
    await _savePreference(
      _getUserKey(_keyCommentNotificationsPrefix),
      enabled,
    );
  }

  /// Updates follow notifications preference
  Future<void> setFollowNotifications(bool enabled) async {
    emit(state.copyWith(followNotifications: enabled));
    await _savePreference(_getUserKey(_keyFollowNotificationsPrefix), enabled);
  }

  /// Saves a preference to SharedPreferences
  Future<void> _savePreference(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (e) {
      // Silent fail - preference will be lost on app restart
      // but won't crash the app
    }
  }

  /// Clear preferences for current user (logout)
  Future<void> clearPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_getUserKey(_keyLikeNotificationsPrefix));
      await prefs.remove(_getUserKey(_keyCommentNotificationsPrefix));
      await prefs.remove(_getUserKey(_keyFollowNotificationsPrefix));
    } catch (e) {
      // Silent fail
    }
  }
}
