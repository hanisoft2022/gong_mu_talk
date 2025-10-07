import '../../../../core/utils/result.dart';
import '../entities/notification.dart';

abstract class INotificationRepository {
  /// Get notifications for the current user
  Future<AppResult<List<AppNotification>>> getNotifications({
    int limit = 20,
    String? lastDocumentId,
  });

  /// Mark notification as read
  Future<AppResult<void>> markAsRead(String notificationId);

  /// Mark all notifications as read
  Future<AppResult<void>> markAllAsRead();

  /// Delete notification
  Future<AppResult<void>> deleteNotification(String notificationId);

  /// Get unread notifications count
  Future<AppResult<int>> getUnreadCount();

  /// Listen to notifications updates
  Stream<AppResult<List<AppNotification>>> watchNotifications();

  /// Enable/disable notifications
  Future<AppResult<void>> setNotificationsEnabled(bool enabled);

  /// Check if notifications are enabled
  Future<AppResult<bool>> areNotificationsEnabled();

  /// Start listening to notifications for user
  Future<AppResult<void>> startListening(String userId);

  /// Stop listening to notifications
  Future<AppResult<void>> stopListening();
}
