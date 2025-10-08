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

/// Cubit for managing notification preferences
class NotificationPreferencesCubit extends Cubit<NotificationPreferencesState> {
  NotificationPreferencesCubit() : super(const NotificationPreferencesState()) {
    _loadPreferences();
  }

  // SharedPreferences keys
  static const String _keyLikeNotifications = 'notif_likes';
  static const String _keyCommentNotifications = 'notif_comments';
  static const String _keyFollowNotifications = 'notif_follows';

  /// Loads preferences from SharedPreferences
  Future<void> _loadPreferences() async {
    emit(state.copyWith(isLoading: true));

    try {
      final prefs = await SharedPreferences.getInstance();

      emit(NotificationPreferencesState(
        likeNotifications: prefs.getBool(_keyLikeNotifications) ?? true,
        commentNotifications: prefs.getBool(_keyCommentNotifications) ?? true,
        followNotifications: prefs.getBool(_keyFollowNotifications) ?? true,
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
    await _savePreference(_keyLikeNotifications, enabled);
  }

  /// Updates comment notifications preference
  Future<void> setCommentNotifications(bool enabled) async {
    emit(state.copyWith(commentNotifications: enabled));
    await _savePreference(_keyCommentNotifications, enabled);
  }

  /// Updates follow notifications preference
  Future<void> setFollowNotifications(bool enabled) async {
    emit(state.copyWith(followNotifications: enabled));
    await _savePreference(_keyFollowNotifications, enabled);
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
}
