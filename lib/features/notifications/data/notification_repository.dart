import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/notification.dart';

typedef JsonMap = Map<String, Object?>;

class NotificationRepository {
  NotificationRepository({
    FirebaseFirestore? firestore,
    required SharedPreferences preferences,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _preferences = preferences;

  final FirebaseFirestore _firestore;
  final SharedPreferences _preferences;

  StreamSubscription<QuerySnapshot<JsonMap>>? _subscription;

  CollectionReference<JsonMap> _notificationsRef(String uid) =>
      _firestore.collection('users').doc(uid).collection('notifications');

  // NOTE: startListening/stopListening are DEPRECATED
  // Firebase Functions now send FCM notifications directly
  // No need to listen to Firestore 'delivered' field
  // Kept for backward compatibility, will be removed in future release
  Future<void> startListening(String uid) async {
    // No-op: FCM handles foreground notifications automatically
    debugPrint(
      '⚠️  startListening is deprecated - FCM handles notifications directly',
    );
  }

  Future<void> stopListening() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  // NOTE: Client-side notification dispatch methods removed.
  // All notifications are now sent by Firebase Functions:
  // - onCommentNotification: handles commentReply, postComment, scrappedPostComment
  // - onLikeWrite: handles postLike
  // - weeklySerialDigest: handles weekly digest (scheduled, runs every Sunday 9 AM KST)
  // This ensures reliable delivery and prevents notification duplication.

  // NOTE: _storeNotification and _handleIncomingNotification removed.
  // Firebase Functions now handle:
  // 1. Sending FCM push notifications directly
  // 2. Saving notification history to Firestore (without 'delivered' field)
  //
  // The startListening/stopListening methods are kept for backward compatibility
  // but can be removed in a future release as they're no longer needed.

  // 알림 설정 관련 메서드들
  static const String _notificationSettingsKey = 'notification_settings';

  Future<Map<String, bool>> getNotificationSettings() async {
    final String? settingsJson = _preferences.getString(
      _notificationSettingsKey,
    );
    if (settingsJson == null) {
      // 기본 설정 (모든 알림 켜짐)
      return {
        'comments': true,
        'likes': true,
        'new_posts': true,
        'weekly_digest': true,
        'system': true,
      };
    }

    final Map<String, dynamic> decoded = jsonDecode(settingsJson);
    return decoded.cast<String, bool>();
  }

  Future<void> updateNotificationSettings(Map<String, bool> settings) async {
    final String encoded = jsonEncode(settings);
    await _preferences.setString(_notificationSettingsKey, encoded);
  }

  Future<bool> isNotificationEnabled(String type) async {
    final settings = await getNotificationSettings();
    return settings[type] ?? true;
  }

  Future<void> setNotificationEnabled(String type, bool enabled) async {
    final settings = await getNotificationSettings();
    settings[type] = enabled;
    await updateNotificationSettings(settings);
  }

  /// 사용자의 모든 알림 가져오기
  /// Firebase Functions가 저장한 알림 히스토리를 읽어옴
  /// (delivered 필드 사용 안 함)
  Future<List<AppNotification>> getAllNotifications(String userId) async {
    if (userId.isEmpty) {
      return [];
    }

    try {
      final snapshot = await _notificationsRef(
        userId,
      ).orderBy('createdAt', descending: true).limit(100).get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return AppNotification(
          id: doc.id,
          userId: userId,
          kind: NotificationKind.values.firstWhere(
            (k) => k.id == data['type'],
            orElse: () => NotificationKind.postComment,
          ),
          title: data['title'] as String? ?? '',
          body: data['body'] as String? ?? '',
          createdAt:
              (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          isRead: data['read'] as bool? ?? false,
          data: data['data'] as Map<String, dynamic>?,
        );
      }).toList();
    } catch (error, stackTrace) {
      debugPrint('Failed to get all notifications: $error\n$stackTrace');
      return [];
    }
  }

  /// 읽지 않은 알림 개수 실시간 스트림
  Stream<int> watchUnreadCount(String userId) {
    if (userId.isEmpty) {
      return Stream.value(0);
    }

    return _notificationsRef(userId)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  /// 읽지 않은 알림 개수 (일회성)
  Future<int> getUnreadCount(String userId) async {
    if (userId.isEmpty) {
      return 0;
    }

    try {
      final snapshot = await _notificationsRef(userId)
          .where('read', isEqualTo: false)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (error, stackTrace) {
      debugPrint('Failed to get unread count: $error\n$stackTrace');
      return 0;
    }
  }

  /// 특정 알림을 읽음 처리
  Future<void> markAsRead(String userId, String notificationId) async {
    if (userId.isEmpty || notificationId.isEmpty) {
      return;
    }

    try {
      await _notificationsRef(
        userId,
      ).doc(notificationId).update({'read': true, 'readAt': Timestamp.now()});
    } catch (error, stackTrace) {
      debugPrint('Failed to mark notification as read: $error\n$stackTrace');
      rethrow;
    }
  }

  /// 특정 알림 삭제
  Future<void> deleteNotification(String userId, String notificationId) async {
    if (userId.isEmpty || notificationId.isEmpty) {
      return;
    }

    try {
      await _notificationsRef(userId).doc(notificationId).delete();
    } catch (error, stackTrace) {
      debugPrint('Failed to delete notification: $error\n$stackTrace');
      rethrow;
    }
  }

  /// 모든 알림을 읽음 처리
  Future<void> markAllAsRead(String userId) async {
    if (userId.isEmpty) {
      return;
    }

    try {
      final snapshot = await _notificationsRef(
        userId,
      ).where('read', isEqualTo: false).get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'read': true, 'readAt': Timestamp.now()});
      }

      await batch.commit();
    } catch (error, stackTrace) {
      debugPrint(
        'Failed to mark all notifications as read: $error\n$stackTrace',
      );
      rethrow;
    }
  }
}
