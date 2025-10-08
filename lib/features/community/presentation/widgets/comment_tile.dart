/// Comment Tile - Displays a single comment with interaction buttons
///
/// Responsibilities:
/// - Renders comment content with author information
/// - Shows like and reply buttons
/// - Formats timestamp and author display names
/// - Supports visual highlighting for featured comments
/// - Handles profile navigation

library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../domain/models/comment.dart';
import '../../../../routing/app_router.dart';
import 'author_display_widget.dart';

class CommentTile extends StatelessWidget {
  const CommentTile({
    super.key,
    required this.comment,
    required this.onToggleLike,
    required this.onReply,
    this.highlight = false,
    this.isReply = false,
  });

  final Comment comment;
  final VoidCallback onToggleLike;
  final void Function(Comment comment) onReply;
  final bool highlight;
  final bool isReply;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String timestamp = _formatTimestamp(comment.createdAt);
    final String displayName = comment.authorNickname.isNotEmpty
        ? comment.authorNickname
        : comment.authorUid;

    final EdgeInsetsGeometry containerPadding = highlight
        ? const EdgeInsets.symmetric(horizontal: 12, vertical: 12)
        : const EdgeInsets.symmetric(vertical: 12);

    return Padding(
      padding: EdgeInsets.only(bottom: isReply ? 12 : 16),
      child: Container(
        decoration: highlight
            ? BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        padding: containerPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, theme, displayName, timestamp),
            const Gap(8),
            Text(comment.text, style: theme.textTheme.bodyMedium),

            // Comment images
            if (comment.imageUrls.isNotEmpty) ...[
              const Gap(8),
              GestureDetector(
                onTap: () => _showCommentImageViewer(
                  context,
                  comment.imageUrls.first,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: comment.imageUrls.first,
                    fit: BoxFit.cover,
                    maxWidthDiskCache: 800,
                    maxHeightDiskCache: 800,
                    placeholder: (context, url) => Container(
                      height: 150,
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 150,
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ],

            const Gap(12),
            _buildActionButtons(theme),
          ],
        ),
      ),
    );
  }

  // ==================== Header ====================

  Widget _buildHeader(BuildContext context, ThemeData theme, String displayName, String timestamp) {
    return InkWell(
      onTap: () => _openProfile(context, comment.authorUid),
      borderRadius: BorderRadius.circular(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: AuthorDisplayWidget(
              nickname: displayName,
              track: comment.authorTrack,
              specificCareer: comment.authorSpecificCareer,
              serialVisible: comment.authorSerialVisible,
            ),
          ),
          const Gap(8),
          Text(
            timestamp,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  // ==================== Action Buttons ====================

  Widget _buildActionButtons(ThemeData theme) {
    return Row(
      children: [
        TextButton.icon(
          onPressed: onToggleLike,
          icon: AnimatedScale(
            duration: const Duration(milliseconds: 200),
            scale: comment.isLiked ? 1.3 : 1,
            curve: Curves.elasticOut,
            child: Icon(
              comment.isLiked ? Icons.favorite : Icons.favorite_border,
              size: 16,
              color: comment.isLiked ? Colors.pink[400] : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          label: Text('${comment.likeCount}', style: theme.textTheme.labelSmall),
          style: TextButton.styleFrom(
            minimumSize: Size.zero,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const Gap(8),
        TextButton.icon(
          onPressed: () => onReply(comment),
          icon: const Icon(Icons.reply_outlined, size: 16),
          label: const Text('답글'),
          style: TextButton.styleFrom(
            minimumSize: Size.zero,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }

  // ==================== Helpers ====================

  static String _formatTimestamp(DateTime createdAt) {
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

  void _openProfile(BuildContext context, String uid) {
    if (uid.isEmpty || uid == 'dummy_user') {
      return;
    }
    context.pushNamed(MemberProfileRoute.name, pathParameters: <String, String>{'uid': uid});
  }
}

/// Show full-screen comment image viewer
void _showCommentImageViewer(BuildContext context, String imageUrl) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (context) => _CommentImageViewerPage(imageUrl: imageUrl),
    ),
  );
}

/// Full-screen image viewer for comment images
class _CommentImageViewerPage extends StatelessWidget {
  const _CommentImageViewerPage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Image with zoom capability
          Center(
            child: InteractiveViewer(
              minScale: 1.0,
              maxScale: 4.0,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) =>
                    const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => const Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    size: 64,
                    color: Colors.white54,
                  ),
                ),
              ),
            ),
          ),

          // Close button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
