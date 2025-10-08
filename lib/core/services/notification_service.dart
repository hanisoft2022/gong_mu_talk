import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';

import '../../routing/app_router.dart';

/// Singleton managed manually via service locator registration.
class NotificationService {
  NotificationService() {
    _initializeLocalNotifications();
    _initializeFirebaseMessaging();
  }

  final Logger _logger = Logger();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );

    // Create notification channels for Android
    if (Platform.isAndroid) {
      await _createNotificationChannels();
    }
  }

  Future<void> _createNotificationChannels() async {
    const AndroidNotificationChannel likesChannel = AndroidNotificationChannel(
      'likes_channel',
      '좋아요 알림',
      description: '내 게시글이나 댓글에 좋아요를 받았을 때 알림',
      importance: Importance.defaultImportance,
    );

    const AndroidNotificationChannel commentsChannel =
        AndroidNotificationChannel(
          'comments_channel',
          '댓글 알림',
          description: '내 게시글에 댓글이 달렸을 때 알림',
          importance: Importance.defaultImportance,
        );

    const AndroidNotificationChannel repliesChannel =
        AndroidNotificationChannel(
          'replies_channel',
          '답글 알림',
          description: '내 댓글에 답글이 달렸을 때 알림',
          importance: Importance.defaultImportance,
        );

    const AndroidNotificationChannel generalChannel =
        AndroidNotificationChannel(
          'general_channel',
          '일반 알림',
          description: '일반적인 앱 알림',
          importance: Importance.defaultImportance,
        );

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    await androidPlugin?.createNotificationChannel(likesChannel);
    await androidPlugin?.createNotificationChannel(commentsChannel);
    await androidPlugin?.createNotificationChannel(repliesChannel);
    await androidPlugin?.createNotificationChannel(generalChannel);
  }

  Future<void> _initializeFirebaseMessaging() async {
    // Request permission for notifications
    final NotificationSettings settings = await _firebaseMessaging
        .requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      _logger.i('User granted notification permission');
    } else {
      _logger.w('User declined or has not accepted notification permission');
    }

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle when app is opened from terminated state
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Get initial message if app was opened from notification
    final RemoteMessage? initialMessage = await _firebaseMessaging
        .getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }
  }

  Future<String?> getToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      _logger.e('Error getting FCM token: $e');
      return null;
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
    } catch (e) {
      _logger.e('Error subscribing to topic $topic: $e');
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
    } catch (e) {
      _logger.e('Error unsubscribing from topic $topic: $e');
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    _logger.i('Received foreground message: ${message.messageId}');

    // Show local notification when app is in foreground
    await showLocalNotification(
      title: message.notification?.title ?? 'New Notification',
      body: message.notification?.body ?? '',
      channelId: _getChannelId(message.data['type']),
      payload: message.data['payload'],
    );
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    _logger.i('Message clicked: ${message.messageId}');
    _navigateBasedOnNotification(message.data);
  }

  void _handleNotificationResponse(NotificationResponse response) {
    _logger.i('Notification clicked: ${response.payload}');
    if (response.payload != null) {
      _navigateBasedOnPayload(response.payload!);
    }
  }

  void _navigateBasedOnNotification(Map<String, dynamic> data) {
    final String? type = data['type'];
    final String? postId = data['postId'];
    final String? commentId = data['commentId'];

    _logger.d('Navigate based on notification type: $type, postId: $postId');

    // Get GoRouter context from global navigator key
    final context = rootNavigatorKey.currentContext;
    if (context == null) {
      _logger.w('Navigation context not available, cannot navigate');
      return;
    }

    switch (type) {
      case 'commentReply':
      case 'postComment':
      case 'scrappedPostComment':
        if (postId != null) {
          _logger.d(
            'Navigate to post detail: $postId'
            '${commentId != null ? ", highlight comment: $commentId" : ""}',
          );
          // Navigate to post detail with optional comment highlight
          final uri = Uri(
            path: '${CommunityRoute.path}/posts/$postId',
            queryParameters: commentId != null ? {'commentId': commentId} : null,
          );
          context.go(uri.toString());
        }
        break;
      case 'postLike':
      case 'commentLike':
        if (postId != null) {
          _logger.d('Navigate to post detail: $postId');
          context.go('${CommunityRoute.path}/posts/$postId');
        }
        break;
      case 'weeklySerialDigest':
        final String? track = data['track'];
        if (track != null) {
          _logger.d('Navigate to community feed with serial filter: $track');
          // Navigate to community feed (serial filtering handled by the feed page itself)
          context.go(CommunityRoute.path);
        }
        break;
      case 'verificationApproved':
      case 'verificationRejected':
        _logger.d('Navigate to profile verification status');
        context.go('${ProfileRoute.path}/verify-paystub');
        break;
      case 'reportProcessed':
        _logger.d('Navigate to notification history');
        context.go(NotificationHistoryRoute.path);
        break;
      default:
        _logger.d('Navigate to notification history (default)');
        context.go(NotificationHistoryRoute.path);
    }
  }

  void _navigateBasedOnPayload(String payload) {
    try {
      final Map<String, dynamic> data =
          jsonDecode(payload) as Map<String, dynamic>;
      _navigateBasedOnNotification(data);
    } catch (error) {
      _logger.e('Failed to parse notification payload: $error');
    }
  }

  String _getChannelId(String? type) {
    switch (type) {
      case 'like':
        return 'likes_channel';
      case 'comment':
        return 'comments_channel';
      case 'reply':
        return 'replies_channel';
      default:
        return 'general_channel';
    }
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
    String channelId = 'general_channel',
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'general_channel',
          '일반 알림',
          channelDescription: '일반적인 앱 알림',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          showWhen: true,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }
}

// Top-level function for background message handling
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  final logger = Logger();
  logger.i('Handling background message: ${message.messageId}');
  // Handle background messages here if needed
}
