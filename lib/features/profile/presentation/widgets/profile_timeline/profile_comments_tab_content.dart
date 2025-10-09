import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../community/domain/models/comment_with_post.dart';
import '../../../../community/presentation/cubit/user_comments_cubit.dart';

/// Tab content for user's authored comments.
///
/// Displays loading, error, or success states with infinite scroll support.
/// Uses NotificationListener for scroll detection (NestedScrollView compatible).
class ProfileCommentsTabContent extends StatelessWidget {
  const ProfileCommentsTabContent({super.key, required this.authorUid});

  final String authorUid;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserCommentsCubit, UserCommentsState>(
      builder: (context, state) {
        // Show error state
        if (state.error != null && state.comments.isEmpty) {
          return _buildErrorState(context, state.error!);
        }

        if (state.isLoading && state.comments.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.comments.isEmpty && !state.isLoading) {
          return _buildEmptyState(context);
        }

        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollUpdateNotification) {
              final metrics = notification.metrics;
              if (metrics.pixels >= metrics.maxScrollExtent - 200) {
                context.read<UserCommentsCubit>().loadMore(authorUid);
              }
            }
            return false;
          },
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: state.comments.length + (state.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= state.comments.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final CommentWithPost commentWithPost = state.comments[index];
              return _CommentCard(commentWithPost: commentWithPost);
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.comment_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const Gap(16),
            Text(
              '작성한 댓글이 없습니다',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Gap(8),
            Text(
              '커뮤니티 게시글에 댓글을 남겨보세요.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const Gap(16),
            Text(
              '오류가 발생했습니다',
              style: theme.textTheme.titleMedium,
            ),
            const Gap(8),
            Text(
              error,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const Gap(16),
            FilledButton.tonal(
              onPressed: () {
                context.read<UserCommentsCubit>().refresh(authorUid);
              },
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentCard extends StatelessWidget {
  const _CommentCard({required this.commentWithPost});

  final CommentWithPost commentWithPost;

  @override
  Widget build(BuildContext context) {
    final comment = commentWithPost.comment;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0.5,
      color: colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          // Navigate to post detail with commentId to auto-scroll and highlight
          context.push(
            '/community/posts/${commentWithPost.postId}?commentId=${comment.id}',
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Original post reference
              Row(
                children: [
                  Icon(
                    Icons.subdirectory_arrow_right,
                    size: 14,
                    color: colorScheme.primary.withValues(alpha: 0.7),
                  ),
                  const Gap(6),
                  Expanded(
                    child: Text(
                      commentWithPost.postText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const Gap(12),

              // Comment content
              Text(
                comment.text,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                ),
              ),

              // Comment image preview
              if (comment.imageUrls.isNotEmpty) ...[
                const Gap(12),
                Center(
                  child: GestureDetector(
                    onTap: () => _showCommentImageViewer(
                      context,
                      comment.imageUrls.first,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 250),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: comment.imageUrls.first,
                          fit: BoxFit.contain,
                          maxWidthDiskCache: 800,
                          maxHeightDiskCache: 800,
                          placeholder: (context, url) => Container(
                            height: 150,
                            color: colorScheme.surfaceContainerHighest,
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            height: 150,
                            color: colorScheme.surfaceContainerHighest,
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              const Gap(16),

              // Metadata row
              Row(
                children: [
                  Text(
                    '좋아요 ${comment.likeCount}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Gap(8),
                  Container(
                    width: 3,
                    height: 3,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.4,
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const Gap(8),
                  Text(
                    _formatDate(comment.createdAt),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.year}.${date.month}.${date.day}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
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
