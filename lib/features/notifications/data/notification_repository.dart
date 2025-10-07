import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/notification_service.dart';
import '../../community/domain/models/post.dart';
import '../../profile/domain/career_track.dart';
import '../domain/entities/notification.dart';

typedef JsonMap = Map<String, Object?>;

class NotificationRepository {
  NotificationRepository({
    FirebaseFirestore? firestore,
    required NotificationService notificationService,
    required SharedPreferences preferences,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _notificationService = notificationService,
       _preferences = preferences;

  final FirebaseFirestore _firestore;
  final NotificationService _notificationService;
  final SharedPreferences _preferences;

  StreamSubscription<QuerySnapshot<JsonMap>>? _subscription;
  String? _listeningUid;
  bool _notificationsDisabled = false;

  CollectionReference<JsonMap> _notificationsRef(String uid) =>
      _firestore.collection('users').doc(uid).collection('notifications');

  Future<void> startListening(String uid) async {
    if (uid.isEmpty) {
      return;
    }
    if (_notificationsDisabled) {
      return;
    }
    if (_listeningUid == uid && _subscription != null) {
      return;
    }
    await stopListening();
    _listeningUid = uid;
    try {
      _subscription = _notificationsRef(uid)
          .where('delivered', isEqualTo: false)
          .orderBy('createdAt', descending: false)
          .snapshots()
          .listen((QuerySnapshot<JsonMap> snapshot) {
            for (final QueryDocumentSnapshot<JsonMap> doc in snapshot.docs) {
              _handleIncomingNotification(doc);
            }
          }, onError: _handleStreamError);
    } on FirebaseException catch (error, stackTrace) {
      _handleStreamError(error, stackTrace);
    }
  }

  Future<void> stopListening() async {
    await _subscription?.cancel();
    _subscription = null;
    _listeningUid = null;
  }

  Future<void> notifyCommentReply({
    required String targetUid,
    required String postId,
    required String commentId,
    required String parentCommentId,
    required String replierNickname,
    required String excerpt,
  }) async {
    if (targetUid.isEmpty) {
      return;
    }
    final JsonMap payload = <String, Object?>{
      'type': NotificationKind.commentReply.id,
      'postId': postId,
      'commentId': commentId,
      'parentCommentId': parentCommentId,
    };

    await _storeNotification(
      targetUid: targetUid,
      kind: NotificationKind.commentReply,
      title: '내 댓글에 답글이 달렸어요',
      body: '$replierNickname: $excerpt',
      payload: payload,
    );
  }

  Future<void> notifyScrappedPostComment({
    required String targetUid,
    required String postId,
    required String commenterNickname,
    required String excerpt,
  }) async {
    if (targetUid.isEmpty) {
      return;
    }

    final JsonMap payload = <String, Object?>{
      'type': NotificationKind.scrappedPostComment.id,
      'postId': postId,
    };

    await _storeNotification(
      targetUid: targetUid,
      kind: NotificationKind.scrappedPostComment,
      title: '스크랩한 글에 새 댓글이 도착했어요',
      body: '$commenterNickname: $excerpt',
      payload: payload,
    );
  }

  Future<void> maybeShowWeeklySerialDigest({
    required CareerTrack track,
    required List<Post> posts,
  }) async {
    if (track == CareerTrack.none || posts.isEmpty) {
      return;
    }

    final String key = 'weekly_digest_${track.name}';
    final int now = DateTime.now().millisecondsSinceEpoch;
    final int? last = _preferences.getInt(key);
    if (last != null) {
      final Duration elapsed = Duration(milliseconds: now - last);
      if (elapsed.inDays < 7) {
        return;
      }
    }

    final List<Post> relevant =
        posts
            .where(
              (Post post) =>
                  post.audience == PostAudience.serial &&
                  post.serial == track.name,
            )
            .toList(growable: false)
          ..sort((Post a, Post b) => b.likeCount.compareTo(a.likeCount));

    if (relevant.isEmpty) {
      return;
    }

    final List<Post> top = relevant.take(3).toList(growable: false);

    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < top.length; i += 1) {
      final Post post = top[i];
      final String preview = post.text.trim();
      final String shortened = preview.length <= 30
          ? preview
          : '${preview.substring(0, 30)}...';
      buffer.writeln('${i + 1}. $shortened (${post.likeCount} 좋아요)');
    }

    await _notificationService.showLocalNotification(
      title: '${track.displayName} 인기글 요약',
      body: buffer.toString().trim(),
      channelId: NotificationKind.weeklySerialDigest.channelId,
      payload: jsonEncode(<String, Object?>{
        'type': NotificationKind.weeklySerialDigest.id,
        'track': track.name,
      }),
    );

    await _preferences.setInt(key, now);
  }

  Future<void> _storeNotification({
    required String targetUid,
    required NotificationKind kind,
    required String title,
    required String body,
    required JsonMap payload,
  }) async {
    try {
      await _notificationsRef(targetUid).add(<String, Object?>{
        'type': kind.id,
        'title': title,
        'body': body,
        'payload': payload,
        'createdAt': Timestamp.now(),
        'delivered': false,
        'read': false,
      });
    } catch (error, stackTrace) {
      debugPrint('Failed to enqueue notification: $error\n$stackTrace');
    }
  }

  Future<void> _handleIncomingNotification(
    QueryDocumentSnapshot<JsonMap> doc,
  ) async {
    final Map<String, Object?> data = doc.data();
    final String title = (data['title'] as String?) ?? '새 알림';
    final String body = (data['body'] as String?) ?? '';
    final NotificationKind kind = NotificationKind.values.firstWhere(
      (NotificationKind value) => value.id == data['type'],
      orElse: () => NotificationKind.commentReply,
    );
    final Map<String, Object?> payload =
        (data['payload'] as Map<String, Object?>?) ?? <String, Object?>{};

    try {
      await _notificationService.showLocalNotification(
        title: title,
        body: body,
        channelId: kind.channelId,
        payload: jsonEncode(payload),
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to show local notification: $error\n$stackTrace');
    }

    try {
      await doc.reference.update(<String, Object?>{
        'delivered': true,
        'deliveredAt': Timestamp.now(),
      });
    } catch (error, stackTrace) {
      debugPrint('Failed to mark notification delivered: $error\n$stackTrace');
    }
  }

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

  void _handleStreamError(Object error, StackTrace stackTrace) {
    if (error is FirebaseException && error.code == 'permission-denied') {
      _notificationsDisabled = true;
      // Ignore further Firestore notifications when permissions are missing.
      unawaited(stopListening());
      return;
    }
    debugPrint('Notification listening error: $error\n$stackTrace');
  }

  /// 사용자의 모든 알림 가져오기
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
            orElse: () => NotificationKind.commentReply,
          ),
          title: data['title'] as String? ?? '',
          body: data['body'] as String? ?? '',
          createdAt:
              (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          isRead: data['read'] as bool? ?? false,
          data: data['payload'] as Map<String, dynamic>?,
        );
      }).toList();
    } catch (error, stackTrace) {
      debugPrint('Failed to get all notifications: $error\n$stackTrace');
      return [];
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
