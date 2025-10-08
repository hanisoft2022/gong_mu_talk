import 'package:equatable/equatable.dart';

enum NotificationKind {
  // Comment notifications
  commentReply,
  postComment,
  scrappedPostComment,

  // Like notifications
  postLike,
  commentLike,

  // System notifications
  weeklySerialDigest,
  verificationApproved,
  verificationRejected,
  reportProcessed,

  // Future: mention notifications
  mentionInComment,
}

extension NotificationKindX on NotificationKind {
  String get id => name;

  String get channelId {
    switch (this) {
      case NotificationKind.commentReply:
      case NotificationKind.postComment:
      case NotificationKind.scrappedPostComment:
      case NotificationKind.mentionInComment:
        return 'comments_channel';
      case NotificationKind.postLike:
      case NotificationKind.commentLike:
        return 'likes_channel';
      case NotificationKind.weeklySerialDigest:
      case NotificationKind.verificationApproved:
      case NotificationKind.verificationRejected:
      case NotificationKind.reportProcessed:
        return 'general_channel';
    }
  }

  String get displayName {
    switch (this) {
      case NotificationKind.commentReply:
        return '내 댓글에 답글';
      case NotificationKind.postComment:
        return '내 게시글에 댓글';
      case NotificationKind.scrappedPostComment:
        return '스크랩한 글에 댓글';
      case NotificationKind.postLike:
        return '게시글 좋아요';
      case NotificationKind.commentLike:
        return '댓글 좋아요';
      case NotificationKind.weeklySerialDigest:
        return '주간 인기글 요약';
      case NotificationKind.verificationApproved:
        return '인증 승인';
      case NotificationKind.verificationRejected:
        return '인증 거부';
      case NotificationKind.reportProcessed:
        return '신고 처리 완료';
      case NotificationKind.mentionInComment:
        return '댓글 멘션';
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
