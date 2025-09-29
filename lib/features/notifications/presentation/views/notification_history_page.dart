import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../domain/entities/notification.dart';

class NotificationHistoryPage extends StatefulWidget {
  const NotificationHistoryPage({super.key});

  @override
  State<NotificationHistoryPage> createState() => _NotificationHistoryPageState();
}

class _NotificationHistoryPageState extends State<NotificationHistoryPage> {
  List<AppNotification> _notifications = [];
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      // TODO: NotificationRepository에 getAllNotifications 메서드 추가 필요
      // 현재는 빈 리스트로 대체
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        setState(() {
          _notifications = _generateMockNotifications();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  // TODO: 실제 알림 데이터로 대체 필요
  List<AppNotification> _generateMockNotifications() {
    final now = DateTime.now();
    return [
      AppNotification(
        id: '1',
        userId: 'current_user',
        kind: NotificationKind.commentReply,
        title: '새 댓글 알림',
        body: '김공무원님이 회식 관련 질문글에 댓글을 남겼습니다.',
        data: const {'type': 'comment', 'postId': 'post1'},
        isRead: false,
        createdAt: now.subtract(const Duration(minutes: 30)),
      ),
      AppNotification(
        id: '2',
        userId: 'current_user',
        kind: NotificationKind.commentReply,
        title: '좋아요 알림',
        body: '이공직님이 급여 관련 질문에 좋아요를 눌렀습니다.',
        data: const {'type': 'like', 'postId': 'post2'},
        isRead: true,
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      AppNotification(
        id: '3',
        userId: 'current_user',
        kind: NotificationKind.weeklySerialDigest,
        title: '주간 요약',
        body: '이번 주 인기 글과 활동 요약을 확인해보세요.',
        data: const {'type': 'weekly_digest'},
        isRead: true,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      AppNotification(
        id: '4',
        userId: 'current_user',
        kind: NotificationKind.commentReply,
        title: '새 글 알림',
        body: '교육행정직 커뮤니티에 새로운 글이 올라왔습니다.',
        data: const {'type': 'new_post', 'postId': 'post3'},
        isRead: true,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
    ];
  }

  Future<void> _markAsRead(AppNotification notification) async {
    if (notification.isRead) return;

    try {
      // TODO: 실제 mark as read 구현
      if (mounted) {
        setState(() {
          final index = _notifications.indexWhere((n) => n.id == notification.id);
          if (index != -1) {
            _notifications[index] = notification.copyWith(isRead: true);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('알림 읽기 처리에 실패했습니다: $e')),
        );
      }
    }
  }

  Future<void> _deleteNotification(AppNotification notification) async {
    try {
      // TODO: 실제 delete 구현
      if (mounted) {
        setState(() {
          _notifications.removeWhere((n) => n.id == notification.id);
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('알림이 삭제되었습니다')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('알림 삭제에 실패했습니다: $e')),
        );
      }
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      // TODO: 실제 mark all as read 구현
      if (mounted) {
        setState(() {
          _notifications = _notifications
              .map((n) => n.copyWith(isRead: true))
              .toList();
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('모든 알림을 읽음으로 처리했습니다')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('일괄 읽기 처리에 실패했습니다: $e')),
        );
      }
    }
  }

  IconData _getNotificationIcon(NotificationKind kind) {
    switch (kind) {
      case NotificationKind.commentReply:
        return Icons.comment_outlined;
      case NotificationKind.bookmarkedPostComment:
        return Icons.bookmark_outlined;
      case NotificationKind.weeklySerialDigest:
        return Icons.summarize_outlined;
    }
  }

  Color _getNotificationColor(BuildContext context, NotificationKind kind) {
    final theme = Theme.of(context);
    switch (kind) {
      case NotificationKind.commentReply:
        return theme.colorScheme.primary;
      case NotificationKind.bookmarkedPostComment:
        return theme.colorScheme.tertiary;
      case NotificationKind.weeklySerialDigest:
        return theme.colorScheme.secondary;
    }
  }

  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return '방금 전';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}시간 전';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return '${dateTime.year}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.day.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('알림'),
            if (unreadCount > 0)
              Text(
                '읽지 않은 알림 $unreadCount개',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        backgroundColor: theme.colorScheme.surface,
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text('모두 읽음'),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotifications,
            tooltip: '새로고침',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            Gap(16),
            Text('알림을 불러오고 있습니다...'),
          ],
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const Gap(16),
            Text(
              '알림을 불러오는데 실패했습니다',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Gap(8),
            Text(
              _errorMessage ?? '알 수 없는 오류가 발생했습니다',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const Gap(24),
            FilledButton.icon(
              onPressed: _loadNotifications,
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    if (_notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const Gap(16),
            Text(
              '알림이 없습니다',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Gap(8),
            Text(
              '새로운 알림이 도착하면 여기에 표시됩니다',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _notifications.length,
        separatorBuilder: (context, index) => const Gap(8),
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          return _buildNotificationCard(notification);
        },
      ),
    );
  }

  Widget _buildNotificationCard(AppNotification notification) {
    final ThemeData theme = Theme.of(context);
    final iconColor = _getNotificationColor(context, notification.kind);

    return Card(
      color: notification.isRead
          ? null
          : theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
      child: Dismissible(
        key: Key(notification.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.error,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.delete,
            color: theme.colorScheme.onError,
          ),
        ),
        onDismissed: (_) => _deleteNotification(notification),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: iconColor.withValues(alpha: 0.1),
            child: Icon(
              _getNotificationIcon(notification.kind),
              color: iconColor,
              size: 20,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  notification.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: notification.isRead ? FontWeight.normal : FontWeight.w600,
                  ),
                ),
              ),
              if (!notification.isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Gap(4),
              Text(
                notification.body,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Gap(8),
              Text(
                _formatRelativeTime(notification.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          onTap: () => _markAsRead(notification),
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }
}