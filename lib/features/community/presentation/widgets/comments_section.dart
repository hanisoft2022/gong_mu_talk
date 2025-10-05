/// Comments Section - Displays all comments with featured/timeline organization
///
/// Responsibilities:
/// - Organizes comments into featured and timeline sections
/// - Manages comment threading (parent-reply relationships)
/// - Handles orphaned replies
/// - Displays empty state when no comments exist
/// - Shows loading state while comments are being fetched

library;
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../domain/models/comment.dart';

import 'comment_tile.dart';

class CommentsSection extends StatelessWidget {
  const CommentsSection({
    super.key,
    required this.featuredComments,
    required this.timelineComments,
    required this.isLoading,
    required this.onToggleLike,
    required this.onReply,
  });

  final List<Comment> featuredComments;
  final List<Comment> timelineComments;
  final bool isLoading;
  final void Function(String commentId) onToggleLike;
  final void Function(Comment comment) onReply;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Set<String> featuredIds = featuredComments
        .map((Comment c) => c.id)
        .toSet();

    final Map<String, List<Comment>> replies = <String, List<Comment>>{};
    final List<Comment> roots = <Comment>[];
    final List<Comment> orphans = <Comment>[];

    for (final Comment comment in timelineComments) {
      final String? parentId = comment.parentCommentId;
      if (comment.isReply && parentId != null && parentId.isNotEmpty) {
        replies.putIfAbsent(parentId, () => <Comment>[]).add(comment);
      } else if (!comment.isReply) {
        roots.add(comment);
      } else {
        orphans.add(comment);
      }
    }

    if (orphans.isNotEmpty) {
      roots.addAll(orphans);
    }

    final List<Widget> threads = roots
        .map(
          (Comment parent) => _CommentThread(
            parent: parent,
            replies: replies[parent.id] ?? const <Comment>[],
            featuredIds: featuredIds,
            onToggleLike: onToggleLike,
            onReply: onReply,
          ),
        )
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(theme),
        const Gap(16),
        if (isLoading)
          const Center(child: CircularProgressIndicator())
        else if (timelineComments.isEmpty)
          _buildEmptyState(theme)
        else ...[
          if (featuredComments.isNotEmpty) ...[
            _FeaturedCommentsSection(
              comments: featuredComments,
              onToggleLike: onToggleLike,
              onReply: onReply,
            ),
            const Gap(16),
          ],
          ...threads,
        ],
      ],
    );
  }

  // ==================== Section Header ====================

  Widget _buildSectionHeader(ThemeData theme) {
    return Row(
      children: [
        Icon(
          Icons.mode_comment_outlined,
          size: 20,
          color: theme.colorScheme.primary,
        ),
        const Gap(8),
        Text(
          '댓글 ${timelineComments.length}',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ==================== Empty State ====================

  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const Gap(8),
          Text('첫 번째 댓글을 남겨보세요!', style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}

// ==================== Comment Thread ====================

class _CommentThread extends StatelessWidget {
  const _CommentThread({
    required this.parent,
    required this.replies,
    required this.featuredIds,
    required this.onToggleLike,
    required this.onReply,
  });

  final Comment parent;
  final List<Comment> replies;
  final Set<String> featuredIds;
  final void Function(String commentId) onToggleLike;
  final void Function(Comment comment) onReply;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CommentTile(
          comment: parent,
          highlight: featuredIds.contains(parent.id),
          onToggleLike: () => onToggleLike(parent.id),
          onReply: onReply,
        ),
        if (replies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 40),
            child: Column(
              children: replies
                  .map(
                    (Comment reply) => CommentTile(
                      comment: reply,
                      isReply: true,
                      highlight: featuredIds.contains(reply.id),
                      onToggleLike: () => onToggleLike(reply.id),
                      onReply: onReply,
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
      ],
    );
  }
}

// ==================== Featured Comments Section ====================

class _FeaturedCommentsSection extends StatelessWidget {
  const _FeaturedCommentsSection({
    required this.comments,
    required this.onToggleLike,
    required this.onReply,
  });

  final List<Comment> comments;
  final void Function(String commentId) onToggleLike;
  final void Function(Comment comment) onReply;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Set<String> rendered = <String>{};
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '베스트 댓글',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Gap(12),
          ...comments
              .where((Comment comment) {
                if (rendered.contains(comment.id)) {
                  return false;
                }
                rendered.add(comment.id);
                return true;
              })
              .map(
                (Comment comment) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CommentTile(
                    comment: comment,
                    highlight: true,
                    onToggleLike: () => onToggleLike(comment.id),
                    onReply: onReply,
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
