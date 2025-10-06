import 'package:equatable/equatable.dart';

enum NotificationKind {
  commentReply,
  scrappedPostComment,
  weeklySerialDigest,
}

extension NotificationKindX on NotificationKind {
  String get id => name;

  String get channelId {
    switch (this) {
      case NotificationKind.commentReply:
      case NotificationKind.scrappedPostComment:
        return 'comments_channel';
      case NotificationKind.weeklySerialDigest:
        return 'general_channel';
    }
  }
}

class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.kind,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
    this.data,
  });

  final String id;
  final String userId;
  final NotificationKind kind;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic>? data;

  AppNotification copyWith({
    String? id,
    String? userId,
    NotificationKind? kind,
    String? title,
    String? body,
    DateTime? createdAt,
    bool? isRead,
    Map<String, dynamic>? data,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      kind: kind ?? this.kind,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        kind,
        title,
        body,
        createdAt,
        isRead,
        data,
      ];
}