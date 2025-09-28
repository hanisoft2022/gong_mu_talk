import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../domain/models/comment.dart';
import '../../../domain/models/feed_filters.dart';
import '../../../../profile/domain/career_track.dart';
import '../comment_utils.dart';

class CommentTile extends StatelessWidget {
  const CommentTile({
    super.key,
    required this.comment,
    this.highlight = false,
    required this.scope,
    required this.onToggleLike,
    this.onReply,
    this.isReply = false,
    required this.onOpenProfile,
  });

  final Comment comment;
  final bool highlight;
  final LoungeScope scope;
  final ValueChanged<Comment> onToggleLike;
  final ValueChanged<Comment>? onReply;
  final bool isReply;
  final VoidCallback onOpenProfile;

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
              scope == LoungeScope.serial
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        IntrinsicWidth(
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            child: InkWell(
                              onTap: onOpenProfile,
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                child: _buildCommentIdentityRow(
                                  theme: theme,
                                  comment: comment,
                                  timestamp: timestamp,
                                  scope: scope,
                                  includeAvatar:
                                      scope == LoungeScope.serial && !isReply,
                                  showTimestamp: false,
                                  isReply: isReply,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            timestamp,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        IntrinsicWidth(
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            child: InkWell(
                              onTap: onOpenProfile,
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 4,
                                ),
                                child: _buildCommentIdentityRow(
                                  theme: theme,
                                  comment: comment,
                                  timestamp: timestamp,
                                  scope: scope,
                                  includeAvatar:
                                      scope == LoungeScope.serial && !isReply,
                                  showTimestamp: false, // 타임스탬프는 InkWell 밖에서 표시
                                  isReply: isReply,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            timestamp,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
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
                    icon: Icon(
                      comment.isLiked ? Icons.favorite : Icons.favorite_border,
                      size: 16,
                      color: comment.isLiked
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    label: Text(
                      '${comment.likeCount}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: comment.isLiked
                            ? theme.colorScheme.primary
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

Widget _buildCommentIdentityRow({
  required ThemeData theme,
  required Comment comment,
  required String timestamp,
  required LoungeScope scope,
  required bool includeAvatar,
  bool showTimestamp = true,
  bool isReply = false,
}) {
  final bool isSerialScope = scope == LoungeScope.serial;

  if (isSerialScope) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (includeAvatar) ...[
          CircleAvatar(
            radius: 16,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
            foregroundColor: theme.colorScheme.primary,
            child: Text(maskNickname(comment.authorNickname).substring(0, 1)),
          ),
          const Gap(12),
        ],
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (comment.authorIsSupporter) ...[
                Icon(
                  Icons.verified,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const Gap(4),
              ],
              Flexible(
                child: Text(
                  comment.authorNickname,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isSerialScope && showTimestamp) ...[
                Text(
                  timestamp,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  final bool hasTrack =
      comment.authorSerialVisible && comment.authorTrack != CareerTrack.none;
  final Color background = hasTrack
      ? theme.colorScheme.primary.withValues(alpha: 0.12)
      : theme.colorScheme.surfaceContainerHighest;
  final Color foreground = hasTrack
      ? theme.colorScheme.primary
      : theme.colorScheme.onSurfaceVariant;
  final String trackLabel = serialLabel(
    comment.authorTrack,
    comment.authorSerialVisible,
    includeEmoji: hasTrack,
  );
  final Widget? supporterIcon = comment.authorIsSupporter
      ? Icon(Icons.verified, size: 16, color: theme.colorScheme.primary)
      : null;
  final String maskedName = maskNickname(
    comment.authorNickname.isNotEmpty
        ? comment.authorNickname
        : comment.authorUid,
  );

  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          trackLabel,
          style: theme.textTheme.labelSmall?.copyWith(
            color: foreground,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      const Gap(8),
      IntrinsicWidth(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (supporterIcon != null) ...[supporterIcon, const Gap(6)],
            Flexible(
              child: Text(
                maskedName,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      if (showTimestamp) ...[
        const Gap(8),
        Text(
          timestamp,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ],
  );
}
