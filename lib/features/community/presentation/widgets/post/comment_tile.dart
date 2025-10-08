import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../domain/models/comment.dart';
import '../author_display_widget.dart';

class CommentTile extends StatefulWidget {
  const CommentTile({
    super.key,
    required this.comment,
    this.highlight = false,
    this.isHighlighted = false,
    required this.onToggleLike,
    this.onReply,
    this.onDelete,
    this.isReply = false,
    required this.onOpenProfile,
    this.authorKey,
    this.currentUserId,
  });

  final Comment comment;
  final bool highlight;
  final bool isHighlighted;
  final ValueChanged<Comment> onToggleLike;
  final ValueChanged<Comment>? onReply;
  final ValueChanged<Comment>? onDelete;
  final bool isReply;
  final VoidCallback onOpenProfile;
  final GlobalKey? authorKey;
  final String? currentUserId;

  @override
  State<CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<CommentTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _highlightController;
  late Animation<double> _highlightAnimation;

  @override
  void initState() {
    super.initState();
    _highlightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _highlightAnimation = Tween<double>(begin: 0.35, end: 0.0).animate(
      CurvedAnimation(
        parent: _highlightController,
        curve: Curves.easeOut,
      ),
    );

    if (widget.isHighlighted) {
      _highlightController.forward();
    }
  }

  @override
  void didUpdateWidget(CommentTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isHighlighted && !oldWidget.isHighlighted) {
      _highlightController.forward();
    } else if (!widget.isHighlighted && oldWidget.isHighlighted) {
      _highlightController.reset();
    }
  }

  @override
  void dispose() {
    _highlightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String timestamp = _formatTimestamp(widget.comment.createdAt);
    final bool isDeleted = widget.comment.deleted;

    return Align(
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: 1.0,
        child: AnimatedBuilder(
          animation: _highlightAnimation,
          builder: (context, child) {
            return Container(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
              decoration: widget.isHighlighted
                  ? BoxDecoration(
                      color: (Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFFFFC107) // Amber for dark mode
                              : const Color(0xFFFFF9C4)) // Light yellow for light mode
                          .withValues(
                        alpha: _highlightAnimation.value,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    )
                  : null,
              child: child,
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Author header (hidden for deleted comments)
              if (!isDeleted)
                Stack(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: AuthorDisplayWidget(
                        key: widget.authorKey,
                        nickname: widget.comment.authorNickname.isNotEmpty
                            ? widget.comment.authorNickname
                            : widget.comment.authorUid,
                        track: widget.comment.authorTrack,
                        specificCareer: widget.comment.authorSpecificCareer,
                        serialVisible: widget.comment.authorSerialVisible,
                        onTap: widget.onOpenProfile,
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
              if (!isDeleted) const Gap(6),

              // Comment text
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  isDeleted ? '작성자에 의해 삭제된 댓글입니다' : widget.comment.text,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.3,
                    color: isDeleted
                      ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6)
                      : null,
                    fontStyle: isDeleted ? FontStyle.italic : null,
                  ),
                ),
              ),

              // Add spacing after deleted comment
              if (isDeleted) const Gap(16),

              // Action buttons (hidden for deleted comments)
              if (!isDeleted) ...[
                const Gap(6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (widget.highlight) ...[
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
                      onPressed: () => widget.onToggleLike(widget.comment),
                      icon: AnimatedScale(
                        duration: const Duration(milliseconds: 200),
                        scale: widget.comment.isLiked ? 1.3 : 1,
                        curve: Curves.elasticOut,
                        child: Icon(
                          widget.comment.isLiked
                              ? Icons.favorite
                              : Icons.favorite_border,
                          size: 16,
                          color: widget.comment.isLiked
                              ? Colors.pink[400]
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      label: Text(
                        '${widget.comment.likeCount}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: widget.comment.isLiked
                              ? Colors.pink[400]
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    if (widget.onReply != null)
                      IconButton(
                        tooltip: '답글 달기',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minHeight: 32,
                          minWidth: 32,
                        ),
                        visualDensity: VisualDensity.compact,
                        iconSize: 18,
                        onPressed: () => widget.onReply!(widget.comment),
                        icon: const Icon(Icons.reply_outlined),
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    // 3-dot menu (only for comment author)
                    if (widget.onDelete != null &&
                        widget.currentUserId != null &&
                        widget.currentUserId == widget.comment.authorUid)
                      PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          Icons.more_vert,
                          size: 18,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        itemBuilder: (BuildContext context) => [
                          PopupMenuItem<String>(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                  color: theme.colorScheme.error,
                                ),
                                const Gap(8),
                                Text(
                                  '삭제하기',
                                  style: TextStyle(
                                    color: theme.colorScheme.error,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (String value) {
                          if (value == 'delete') {
                            widget.onDelete!(widget.comment);
                          }
                        },
                      ),
                  ],
                ),
              ],
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
