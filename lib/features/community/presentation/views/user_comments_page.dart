import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/performance_optimizations.dart';
import '../../domain/models/comment_with_post.dart';
import '../cubit/user_comments_cubit.dart';

class UserCommentsPage extends StatefulWidget {
  const UserCommentsPage({
    super.key,
    required this.authorUid,
  });

  final String authorUid;

  @override
  State<UserCommentsPage> createState() => _UserCommentsPageState();
}

class _UserCommentsPageState extends State<UserCommentsPage> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    context.read<UserCommentsCubit>().loadInitial(widget.authorUid);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<UserCommentsCubit>().loadMore(widget.authorUid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('작성한 댓글'),
      ),
      body: BlocBuilder<UserCommentsCubit, UserCommentsState>(
        builder: (context, state) {
          if (state.isLoading && state.comments.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.comments.isEmpty && !state.isLoading) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () =>
                context.read<UserCommentsCubit>().refresh(widget.authorUid),
            child: OptimizedListView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              itemCount: state.comments.length + (state.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= state.comments.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final CommentWithPost commentWithPost = state.comments[index];
                return _CommentCard(
                  commentWithPost: commentWithPost,
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
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
            const Gap(24),
            FilledButton.icon(
              onPressed: () => context.go('/community'),
              icon: const Icon(Icons.explore_outlined),
              label: const Text('커뮤니티 둘러보기'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentCard extends StatelessWidget {
  const _CommentCard({
    required this.commentWithPost,
  });

  final CommentWithPost commentWithPost;

  @override
  Widget build(BuildContext context) {
    final comment = commentWithPost.comment;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // Navigate to post detail
          context.push('/community/post/${commentWithPost.postId}');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Post context
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.article_outlined,
                          size: 16,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const Gap(4),
                        Text(
                          '원글',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const Gap(8),
                        Text(
                          commentWithPost.postAuthorNickname,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const Gap(4),
                    Text(
                      commentWithPost.postText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(12),

              // Comment content
              Text(
                comment.text,
                style: theme.textTheme.bodyMedium,
              ),
              const Gap(12),

              // Comment metadata
              Row(
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const Gap(4),
                  Text(
                    comment.likeCount.toString(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Gap(16),
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const Gap(4),
                  Text(
                    _formatDate(comment.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
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
