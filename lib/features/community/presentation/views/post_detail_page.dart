import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:gong_mu_talk/routing/app_router.dart';

import '../../domain/models/comment.dart';
import '../../domain/models/post.dart';
import '../cubit/post_detail_cubit.dart';
import '../widgets/post_card.dart';
import '../../../profile/domain/career_track.dart';

class PostDetailPage extends StatefulWidget {
  const PostDetailPage({super.key, required this.postId, this.initialPost});

  final String postId;
  final Post? initialPost;

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  late final TextEditingController _commentController;
  late final FocusNode _commentFocusNode;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController();
    _commentFocusNode = FocusNode();
    _scrollController = ScrollController();
    context.read<PostDetailCubit>().loadPost(
      widget.postId,
      fallback: widget.initialPost,
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
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
              onRetry: () =>
                  context.read<PostDetailCubit>().loadPost(widget.postId),
            );
          }

          if (state.post == null) {
            return const Center(child: Text('게시글을 찾을 수 없습니다.'));
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
                        onToggleLike: () =>
                            context.read<PostDetailCubit>().toggleLike(),
                        onToggleBookmark: () =>
                            context.read<PostDetailCubit>().toggleBookmark(),
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          itemBuilder: (context) => [
                            if (state.post!.authorUid ==
                                context
                                    .read<PostDetailCubit>()
                                    .currentUserId) ...[
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
                        featuredComments: state.featuredComments,
                        timelineComments: state.comments,
                        isLoading: state.isLoadingComments,
                        onToggleLike: (commentId) => context
                            .read<PostDetailCubit>()
                            .toggleCommentLike(commentId),
                        onReact: (commentId, emoji) => context
                            .read<PostDetailCubit>()
                            .toggleCommentReaction(commentId, emoji),
                        onReply: _insertMention,
                      ),
                    ],
                  ),
                ),
              ),
              _CommentComposer(
                controller: _commentController,
                isSubmitting: state.isSubmittingComment,
                onSubmit: _submitComment,
                focusNode: _commentFocusNode,
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
              final success = await context
                  .read<PostDetailCubit>()
                  .deletePost();
              if (success && mounted) {
                navigator.pop(
                  true,
                ); // Return to previous page with success flag
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
        content: const Text(
          '이 사용자를 차단하시겠습니까?\n차단하면 해당 사용자의 게시글과 댓글을 볼 수 없습니다.',
        ),
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
      context.push('${CommunityRoute.editPath}/${state.post!.id}');
    }
  }

  void _insertMention(String nickname) {
    final String trimmed = nickname.trim();
    if (trimmed.isEmpty) {
      return;
    }

    final TextEditingValue value = _commentController.value;
    final int start = value.selection.isValid
        ? value.selection.start
        : value.text.length;
    final int end = value.selection.isValid
        ? value.selection.end
        : value.text.length;
    final bool needsLeadingSpace =
        start > 0 && !value.text.substring(0, start).endsWith(' ');
    final String mention = '${needsLeadingSpace ? ' ' : ''}@$trimmed ';
    final String newText = value.text.replaceRange(start, end, mention);
    _commentController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + mention.length),
    );
    _commentFocusNode.requestFocus();
  }
}

class _CommentsSection extends StatelessWidget {
  const _CommentsSection({
    required this.featuredComments,
    required this.timelineComments,
    required this.isLoading,
    required this.onToggleLike,
    required this.onReact,
    required this.onReply,
  });

  final List<Comment> featuredComments;
  final List<Comment> timelineComments;
  final bool isLoading;
  final void Function(String commentId) onToggleLike;
  final void Function(String commentId, String emoji) onReact;
  final void Function(String nickname) onReply;

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
              '댓글 ${timelineComments.length}',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const Gap(16),
        if (isLoading) ...[
          const Center(child: CircularProgressIndicator()),
        ] else if (timelineComments.isEmpty) ...[
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
          if (featuredComments.isNotEmpty) ...[
            _FeaturedCommentsSection(
              comments: featuredComments,
              onToggleLike: onToggleLike,
              onReact: onReact,
              onReply: onReply,
            ),
            const Gap(16),
          ],
          ...timelineComments.map(
            (Comment comment) => _CommentTile(
              comment: comment,
              onToggleLike: () => onToggleLike(comment.id),
              onReact: (String emoji) => onReact(comment.id, emoji),
              onReply: () => onReply(comment.authorNickname),
            ),
          ),
        ],
      ],
    );
  }
}

class _FeaturedCommentsSection extends StatelessWidget {
  const _FeaturedCommentsSection({
    required this.comments,
    required this.onToggleLike,
    required this.onReact,
    required this.onReply,
  });

  final List<Comment> comments;
  final void Function(String commentId) onToggleLike;
  final void Function(String commentId, String emoji) onReact;
  final void Function(String nickname) onReply;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                  child: _CommentTile(
                    comment: comment,
                    onToggleLike: () => onToggleLike(comment.id),
                    onReact: (String emoji) => onReact(comment.id, emoji),
                    onReply: () => onReply(comment.authorNickname),
                    highlight: true,
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.comment,
    required this.onToggleLike,
    required this.onReact,
    required this.onReply,
    this.highlight = false,
  });

  final Comment comment;
  final VoidCallback onToggleLike;
  final void Function(String emoji) onReact;
  final VoidCallback onReply;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timestamp = _formatTimestamp(comment.createdAt);

    return Container(
      padding: const EdgeInsets.only(bottom: 16),
      margin: highlight ? const EdgeInsets.only(bottom: 4) : EdgeInsets.zero,
      decoration: highlight
          ? BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
            )
          : null,
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
                    if (comment.authorIsSupporter) ...[
                      Icon(
                        Icons.workspace_premium,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const Gap(4),
                    ],
                    Expanded(
                      child: Text(
                        comment.authorNickname,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const Gap(2),
                Text(
                  '${comment.authorTrack.emoji} ${comment.authorTrack.displayName} · $timestamp',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Gap(6),
                Text(comment.text, style: theme.textTheme.bodyMedium),
                const Gap(12),
                _CommentReactionBar(
                  reactions: comment.reactionCounts,
                  viewerReaction: comment.viewerReaction,
                  onReact: onReact,
                ),
                const Gap(8),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: onToggleLike,
                      icon: Icon(
                        comment.isLiked
                            ? Icons.favorite
                            : Icons.favorite_border,
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    const Gap(8),
                    TextButton.icon(
                      onPressed: onReply,
                      icon: const Icon(Icons.reply_outlined, size: 16),
                      label: const Text('답글'),
                      style: TextButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
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
    required this.focusNode,
  });

  final TextEditingController controller;
  final bool isSubmitting;
  final Future<void> Function() onSubmit;
  final FocusNode focusNode;

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
              focusNode: widget.focusNode,
              decoration: const InputDecoration(
                hintText: '댓글을 입력하세요...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.newline,
              enabled: !widget.isSubmitting,
            ),
          ),
          const Gap(12),
          FilledButton(
            onPressed: _canSubmit && !widget.isSubmitting
                ? widget.onSubmit
                : null,
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

const List<String> _commentReactionOptions = <String>['👍', '🎉', '😍', '😄'];

class _CommentReactionBar extends StatelessWidget {
  const _CommentReactionBar({
    required this.reactions,
    required this.viewerReaction,
    required this.onReact,
  });

  final Map<String, int> reactions;
  final String? viewerReaction;
  final void Function(String emoji) onReact;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      children: _commentReactionOptions
          .map((String emoji) {
            final int count = reactions[emoji] ?? 0;
            final bool selected = viewerReaction == emoji;
            return ChoiceChip(
              label: Text(
                count > 0 ? '$emoji $count' : emoji,
                style: TextStyle(fontWeight: selected ? FontWeight.w600 : null),
              ),
              selected: selected,
              showCheckmark: false,
              onSelected: (_) => onReact(emoji),
              selectedColor: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.16),
            );
          })
          .toList(growable: false),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

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
