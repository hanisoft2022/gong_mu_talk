import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/comment.dart';
import '../cubit/post_detail_cubit.dart';
import '../widgets/post_card.dart';

class PostDetailPage extends StatefulWidget {
  const PostDetailPage({super.key, required this.postId});

  final String postId;

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  late final TextEditingController _commentController;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController();
    _scrollController = ScrollController();
    context.read<PostDetailCubit>().loadPost(widget.postId);
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('게시글'),
        actions: [
          BlocBuilder<PostDetailCubit, PostDetailState>(
            builder: (context, state) {
              if (state.post != null) {
                return IconButton(
                  icon: Icon(
                    state.post!.isBookmarked
                        ? Icons.bookmark
                        : Icons.bookmark_outline,
                  ),
                  onPressed: () {
                    context.read<PostDetailCubit>().toggleBookmark();
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocBuilder<PostDetailCubit, PostDetailState>(
        builder: (context, state) {
          if (state.status == PostDetailStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == PostDetailStatus.error) {
            return _ErrorView(
              message: state.errorMessage ?? '게시글을 불러올 수 없습니다.',
              onRetry: () => context.read<PostDetailCubit>().loadPost(widget.postId),
            );
          }

          if (state.post == null) {
            return const Center(
              child: Text('게시글을 찾을 수 없습니다.'),
            );
          }

          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => context.read<PostDetailCubit>().refresh(),
                  child: ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    children: [
                      PostCard(
                        post: state.post!,
                        onToggleLike: () => context.read<PostDetailCubit>().toggleLike(),
                        onToggleBookmark: () => context.read<PostDetailCubit>().toggleBookmark(),
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          itemBuilder: (context) => [
                            if (state.post!.authorUid == context.read<PostDetailCubit>().currentUserId) ...[
                              const PopupMenuItem(
                                value: 'edit',
                                child: ListTile(
                                  leading: Icon(Icons.edit_outlined),
                                  title: Text('수정'),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: ListTile(
                                  leading: Icon(Icons.delete_outline),
                                  title: Text('삭제'),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ] else ...[
                              const PopupMenuItem(
                                value: 'report',
                                child: ListTile(
                                  leading: Icon(Icons.report_outlined),
                                  title: Text('신고'),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'block',
                                child: ListTile(
                                  leading: Icon(Icons.block_outlined),
                                  title: Text('차단'),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          ],
                          onSelected: _handleMenuAction,
                        ),
                      ),
                      const Gap(24),
                      _CommentsSection(
                        comments: state.comments,
                        isLoading: state.isLoadingComments,
                        onToggleLike: (commentId) =>
                            context.read<PostDetailCubit>().toggleCommentLike(commentId),
                      ),
                    ],
                  ),
                ),
              ),
              _CommentComposer(
                controller: _commentController,
                isSubmitting: state.isSubmittingComment,
                onSubmit: _submitComment,
              ),
            ],
          );
        },
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'edit':
        _navigateToEdit();
        break;
      case 'delete':
        _showDeleteDialog();
        break;
      case 'report':
        _showReportDialog();
        break;
      case 'block':
        _showBlockDialog();
        break;
    }
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final success = await context.read<PostDetailCubit>().submitComment(text);
    if (success && mounted) {
      _commentController.clear();
      if (mounted) FocusScope.of(context).unfocus();
    }
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('게시글 삭제'),
        content: const Text('이 게시글을 삭제하시겠습니까?\n삭제된 게시글은 복구할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              if (mounted) navigator.pop();
              final success = await context.read<PostDetailCubit>().deletePost();
              if (success && mounted) {
                navigator.pop(true); // Return to previous page with success flag
              }
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('신고하기'),
        content: const Text('이 게시글이 커뮤니티 가이드라인을 위반했다고 신고하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              if (mounted) navigator.pop();
              await context.read<PostDetailCubit>().reportPost();
              if (mounted) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('신고가 접수되었습니다. 검토 후 조치하겠습니다.')),
                );
              }
            },
            child: const Text('신고'),
          ),
        ],
      ),
    );
  }

  void _showBlockDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('사용자 차단'),
        content: const Text('이 사용자를 차단하시겠습니까?\n차단하면 해당 사용자의 게시글과 댓글을 볼 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              if (mounted) navigator.pop();
              await context.read<PostDetailCubit>().blockUser();
              if (mounted) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('사용자를 차단했습니다.')),
                );
                navigator.pop();
              }
            },
            child: const Text('차단'),
          ),
        ],
      ),
    );
  }

  void _navigateToEdit() {
    final state = context.read<PostDetailCubit>().state;
    if (state.post != null) {
      context.push('/community/post/edit/${state.post!.id}');
    }
  }
}

class _CommentsSection extends StatelessWidget {
  const _CommentsSection({
    required this.comments,
    required this.isLoading,
    required this.onToggleLike,
  });

  final List<Comment> comments;
  final bool isLoading;
  final void Function(String commentId) onToggleLike;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.mode_comment_outlined,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            const Gap(8),
            Text(
              '댓글 ${comments.length}개',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const Gap(16),
        if (isLoading) ...[
          const Center(child: CircularProgressIndicator()),
        ] else if (comments.isEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32),
            alignment: Alignment.center,
            child: Column(
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const Gap(8),
                Text(
                  '첫 번째 댓글을 남겨보세요!',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ] else ...[
          ...comments.map(
            (comment) => _CommentTile(
              comment: comment,
              onToggleLike: () => onToggleLike(comment.id),
            ),
          ),
        ],
      ],
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.comment,
    required this.onToggleLike,
  });

  final Comment comment;
  final VoidCallback onToggleLike;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timestamp = _formatTimestamp(comment.createdAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
            foregroundColor: theme.colorScheme.primary,
            child: Text(comment.authorNickname.substring(0, 1)),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.authorNickname,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Gap(8),
                    Text(
                      timestamp,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const Gap(4),
                Text(
                  comment.text,
                  style: theme.textTheme.bodyMedium,
                ),
                const Gap(8),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: onToggleLike,
                      icon: Icon(
                        comment.isLiked ? Icons.favorite : Icons.favorite_border,
                        size: 16,
                        color: comment.isLiked
                            ? Colors.red
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      label: Text(
                        '${comment.likeCount}',
                        style: theme.textTheme.labelSmall,
                      ),
                      style: TextButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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

class _CommentComposer extends StatefulWidget {
  const _CommentComposer({
    required this.controller,
    required this.isSubmitting,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool isSubmitting;
  final Future<void> Function() onSubmit;

  @override
  State<_CommentComposer> createState() => _CommentComposerState();
}

class _CommentComposerState extends State<_CommentComposer> {
  bool _canSubmit = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_updateSubmitState);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateSubmitState);
    super.dispose();
  }

  void _updateSubmitState() {
    final canSubmit = widget.controller.text.trim().isNotEmpty;
    if (_canSubmit != canSubmit) {
      setState(() {
        _canSubmit = canSubmit;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: widget.controller,
              decoration: const InputDecoration(
                hintText: '댓글을 입력하세요...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              maxLines: null,
              textInputAction: TextInputAction.newline,
              enabled: !widget.isSubmitting,
            ),
          ),
          const Gap(12),
          FilledButton(
            onPressed: _canSubmit && !widget.isSubmitting ? widget.onSubmit : null,
            child: widget.isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('등록'),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const Gap(16),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const Gap(24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}