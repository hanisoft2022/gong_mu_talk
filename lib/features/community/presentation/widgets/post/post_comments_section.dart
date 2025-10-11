/// Post comments section displaying comment list
///
/// Responsibilities:
/// - Display comments in threaded structure (parent + replies)
/// - Show loading indicator
/// - Show empty state message
/// - Handle comment highlighting (featured comments)
/// - Organize comments and replies hierarchically
///
/// Used by: PostCard

library;

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../domain/models/comment.dart';

import 'comment_tile.dart';

class PostCommentsSection extends StatelessWidget {
  const PostCommentsSection({
    super.key,
    required this.isLoading,
    required this.timelineComments,
    required this.featuredComments,
    required this.onToggleCommentLike,
    required this.onReplyTap,
    required this.onOpenCommentAuthorProfile,
    this.onDeleteComment,
    this.currentUserId,
    this.highlightedCommentId,
    this.commentKeys,
    this.canLike = true,
    this.onDisabledLikeTap,
  });

  final bool isLoading;
  final List<Comment> timelineComments;
  final List<Comment> featuredComments;
  final void Function(Comment) onToggleCommentLike;
  final void Function(Comment) onReplyTap;
  final void Function(Comment, GlobalKey) onOpenCommentAuthorProfile;
  final void Function(Comment)? onDeleteComment;
  final String? currentUserId;
  final String? highlightedCommentId;
  final Map<String, GlobalKey>? commentKeys;
  final bool canLike;
  final VoidCallback? onDisabledLikeTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<Widget> sectionChildren = <Widget>[const Gap(12)];

    if (isLoading) {
      sectionChildren.add(const Center(child: CircularProgressIndicator()));
    } else if (timelineComments.isEmpty) {
      sectionChildren.add(
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.comment_outlined,
                  size: 32,
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.5,
                  ),
                ),
                const Gap(8),
                Text(
                  '아직 댓글이 없습니다. 첫 댓글을 남겨보세요!',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      // Organize comments into threads
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

      // Add orphaned comments to roots
      if (orphans.isNotEmpty) {
        roots.addAll(orphans);
      }

      // Build threaded comment list
      final List<Widget> threadedComments = roots
          .map((Comment comment) {
            final List<Comment> children =
                replies[comment.id] ?? const <Comment>[];
            final GlobalKey commentAuthorKey = GlobalKey();

            // Create or retrieve comment key for scrolling
            final commentKey = commentKeys != null
                ? (commentKeys![comment.id] ??= GlobalKey())
                : null;
            final isHighlighted = highlightedCommentId == comment.id;

            return Column(
              key: commentKey,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Parent comment
                CommentTile(
                  comment: comment,
                  highlight: _isFeatured(comment),
                  isHighlighted: isHighlighted,
                  onToggleLike: onToggleCommentLike,
                  onReply: onReplyTap,
                  onDelete: onDeleteComment,
                  currentUserId: currentUserId,
                  authorKey: commentAuthorKey,
                  onOpenProfile: () =>
                      onOpenCommentAuthorProfile(comment, commentAuthorKey),
                  canLike: canLike,
                  onDisabledLikeTap: onDisabledLikeTap,
                ),

                // Reply comments (indented)
                if (children.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 24),
                    child: Column(
                      children: children
                          .map((Comment reply) {
                            final GlobalKey replyAuthorKey = GlobalKey();
                            final replyKey = commentKeys != null
                                ? (commentKeys![reply.id] ??= GlobalKey())
                                : null;
                            final isReplyHighlighted =
                                highlightedCommentId == reply.id;

                            return Column(
                              key: replyKey,
                              children: [
                                CommentTile(
                                  comment: reply,
                                  highlight: _isFeatured(reply),
                                  isHighlighted: isReplyHighlighted,
                                  isReply: true,
                                  onToggleLike: onToggleCommentLike,
                                  onReply: onReplyTap,
                                  onDelete: onDeleteComment,
                                  currentUserId: currentUserId,
                                  authorKey: replyAuthorKey,
                                  onOpenProfile: () => onOpenCommentAuthorProfile(
                                    reply,
                                    replyAuthorKey,
                                  ),
                                  canLike: canLike,
                                  onDisabledLikeTap: onDisabledLikeTap,
                                ),
                              ],
                            );
                          })
                          .toList(growable: false),
                    ),
                  ),
              ],
            );
          })
          .toList(growable: false);

      sectionChildren.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: threadedComments,
        ),
      );
      sectionChildren.add(const Gap(12));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        key: const ValueKey<String>('comment-section'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: sectionChildren,
      ),
    );
  }

  bool _isFeatured(Comment comment) {
    return featuredComments.any(
      (Comment featured) => featured.id == comment.id,
    );
  }
}
