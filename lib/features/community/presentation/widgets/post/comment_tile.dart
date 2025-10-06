import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../domain/models/comment.dart';
import '../author_display_widget.dart';

class CommentTile extends StatelessWidget {
  const CommentTile({
    super.key,
    required this.comment,
    this.highlight = false,
    required this.onToggleLike,
    this.onReply,
    this.isReply = false,
    required this.onOpenProfile,
    this.authorKey,
  });

  final Comment comment;
  final bool highlight;
  final ValueChanged<Comment> onToggleLike;
  final ValueChanged<Comment>? onReply;
  final bool isReply;
  final VoidCallback onOpenProfile;
  final GlobalKey? authorKey;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String timestamp = _formatTimestamp(comment.createdAt);

    return Align(
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: 1.0,
        child: Container(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.fromLTRB(0, 4, 0, 2),
          decoration: null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Author header
              Stack(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: AuthorDisplayWidget(
                      key: authorKey,
                      nickname: comment.authorNickname.isNotEmpty
                          ? comment.authorNickname
                          : comment.authorUid,
                      track: comment.authorTrack,
                      specificCareer: comment.authorSpecificCareer,
                      serialVisible: comment.authorSerialVisible,
                      onTap: onOpenProfile,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        timestamp,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const Gap(6),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  comment.text,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.3),
                ),
              ),
              const Gap(6),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (highlight) ...[
                    Icon(
                      Icons.local_fire_department,
                      size: 16,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors
                                .orange
                                .shade300 // 다크모드에서 더 밝은 주황색
                          : Colors.deepOrange.shade600, // 라이트모드에서 진한 주황색
                    ),
                    const Gap(6),
                  ],
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => onToggleLike(comment),
                    icon: AnimatedScale(
                      duration: const Duration(milliseconds: 200),
                      scale: comment.isLiked ? 1.3 : 1,
                      curve: Curves.elasticOut,
                      child: Icon(
                        comment.isLiked ? Icons.favorite : Icons.favorite_border,
                        size: 16,
                        color: comment.isLiked
                            ? Colors.pink[400]
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    label: Text(
                      '${comment.likeCount}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: comment.isLiked
                            ? Colors.pink[400]
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (onReply != null)
                    IconButton(
                      tooltip: '답글 달기',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minHeight: 32,
                        minWidth: 32,
                      ),
                      visualDensity: VisualDensity.compact,
                      iconSize: 18,
                      onPressed: () => onReply!(comment),
                      icon: const Icon(Icons.reply_outlined),
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime createdAt) {
    final DateTime now = DateTime.now();
    final Duration difference = now.difference(createdAt);
    if (difference.inMinutes < 1) {
      return '방금 전';
    }
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}분 전';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours}시간 전';
    }
    return '${createdAt.month}월 ${createdAt.day}일';
  }
}
