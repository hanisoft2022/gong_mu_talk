import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:gong_mu_talk/routing/app_router.dart';

import '../../domain/models/comment.dart';
import '../../domain/models/feed_filters.dart';
import '../../domain/models/post.dart';
import '../cubit/post_detail_cubit.dart';
import '../widgets/post_card.dart';
import '../widgets/comment_utils.dart';
import '../../../profile/domain/career_track.dart';

class PostDetailPage extends StatefulWidget {
  const PostDetailPage({super.key, required this.postId, this.initialPost, this.replyCommentId});

  final String postId;
  final Post? initialPost;
  final String? replyCommentId;

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
    final PostDetailCubit cubit = context.read<PostDetailCubit>();
    cubit.loadPost(widget.postId, fallback: widget.initialPost);
    cubit.setPendingReply(widget.replyCommentId);
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
      appBar: AppBar(title: const Text('게시글')),
      body: BlocListener<PostDetailCubit, PostDetailState>(
        listenWhen: (previous, current) => previous.replyingTo != current.replyingTo,
        listener: (context, state) {
          final Comment? target = state.replyingTo;
          if (target != null) {
            _ensureReplyMention(target);
          }
        },
        child: BlocBuilder<PostDetailCubit, PostDetailState>(
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
              return const Center(child: Text('게시글을 찾을 수 없습니다.'));
            }

            final LoungeScope scope = state.post!.audience == PostAudience.serial
                ? LoungeScope.serial
                : LoungeScope.all;

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
                          showShare: false,
                          showBookmark: false,
                          trailing: PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert),
                            itemBuilder: (context) => [
                              if (state.post!.authorUid ==
                                  context.read<PostDetailCubit>().currentUserId) ...[
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
                          scope: scope,
                          onToggleLike: (commentId) =>
                              context.read<PostDetailCubit>().toggleCommentLike(commentId),
                          onReply: _handleReply,
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
                  replyingTo: state.replyingTo,
                  onCancelReply: _cancelReply,
                  scope: scope,
                ),
              ],
            );
          },
        ),
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          FilledButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              if (mounted) navigator.pop();
              await context.read<PostDetailCubit>().reportPost();
              if (mounted) {
                messenger.showSnackBar(const SnackBar(content: Text('신고가 접수되었습니다. 검토 후 조치하겠습니다.')));
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          FilledButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              if (mounted) navigator.pop();
              await context.read<PostDetailCubit>().blockUser();
              if (mounted) {
                messenger.showSnackBar(const SnackBar(content: Text('사용자를 차단했습니다.')));
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

  void _handleReply(Comment comment) {
    context.read<PostDetailCubit>().setReplyTarget(comment);
  }

  void _cancelReply() {
    final PostDetailCubit cubit = context.read<PostDetailCubit>();
    final Comment? replyingTo = cubit.state.replyingTo;
    cubit.clearReplyTarget();

    if (replyingTo == null) {
      return;
    }

    final String mention = '@${replyingTo.authorNickname.trim()} ';
    final String current = _commentController.text;
    if (current.endsWith(mention)) {
      final String updated = current.substring(0, current.length - mention.length).trimRight();
      _commentController
        ..text = updated
        ..selection = TextSelection.collapsed(offset: updated.length);
    }
  }

  void _insertMention(String nickname) {
    final String trimmed = nickname.trim();
    if (trimmed.isEmpty) {
      return;
    }

    final TextEditingValue value = _commentController.value;
    final int start = value.selection.isValid ? value.selection.start : value.text.length;
    final int end = value.selection.isValid ? value.selection.end : value.text.length;
    final bool needsLeadingSpace = start > 0 && !value.text.substring(0, start).endsWith(' ');
    final String mention = '${needsLeadingSpace ? ' ' : ''}@$trimmed ';
    final String newText = value.text.replaceRange(start, end, mention);
    _commentController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + mention.length),
    );
    _commentFocusNode.requestFocus();
  }

  void _ensureReplyMention(Comment comment) {
    final String nickname = comment.authorNickname.trim();
    if (nickname.isEmpty) {
      return;
    }
    final String mentionToken = '@$nickname';
    final TextEditingValue value = _commentController.value;
    if (!value.text.contains(mentionToken)) {
      _insertMention(nickname);
    } else {
      _commentFocusNode.requestFocus();
      _commentController.selection = TextSelection.collapsed(offset: value.text.length);
    }
  }
}

class _CommentsSection extends StatelessWidget {
  const _CommentsSection({
    required this.featuredComments,
    required this.timelineComments,
    required this.isLoading,
    required this.scope,
    required this.onToggleLike,
    required this.onReply,
  });

  final List<Comment> featuredComments;
  final List<Comment> timelineComments;
  final bool isLoading;
  final LoungeScope scope;
  final void Function(String commentId) onToggleLike;
  final void Function(Comment comment) onReply;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Set<String> featuredIds = featuredComments.map((Comment c) => c.id).toSet();

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
            scope: scope,
            featuredIds: featuredIds,
            onToggleLike: onToggleLike,
            onReply: onReply,
          ),
        )
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.mode_comment_outlined, size: 20, color: theme.colorScheme.primary),
            const Gap(8),
            Text(
              '댓글 ${timelineComments.length}',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const Gap(16),
        if (isLoading)
          const Center(child: CircularProgressIndicator())
        else if (timelineComments.isEmpty)
          Container(
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
          )
        else ...[
          if (featuredComments.isNotEmpty) ...[
            _FeaturedCommentsSection(
              comments: featuredComments,
              scope: scope,
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
}

class _CommentThread extends StatelessWidget {
  const _CommentThread({
    required this.parent,
    required this.replies,
    required this.scope,
    required this.featuredIds,
    required this.onToggleLike,
    required this.onReply,
  });

  final Comment parent;
  final List<Comment> replies;
  final LoungeScope scope;
  final Set<String> featuredIds;
  final void Function(String commentId) onToggleLike;
  final void Function(Comment comment) onReply;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _CommentTile(
          comment: parent,
          scope: scope,
          highlight: featuredIds.contains(parent.id),
          onToggleLike: () => onToggleLike(parent.id),
          onReply: onReply,
          onOpenProfile: () => _openMemberProfile(context, parent.authorUid),
        ),
        if (replies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 40),
            child: Column(
              children: replies
                  .map(
                    (Comment reply) => _CommentTile(
                      comment: reply,
                      scope: scope,
                      isReply: true,
                      highlight: featuredIds.contains(reply.id),
                      onToggleLike: () => onToggleLike(reply.id),
                      onReply: onReply,
                      onOpenProfile: () => _openMemberProfile(context, reply.authorUid),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
      ],
    );
  }
}

class _FeaturedCommentsSection extends StatelessWidget {
  const _FeaturedCommentsSection({
    required this.comments,
    required this.scope,
    required this.onToggleLike,
    required this.onReply,
  });

  final List<Comment> comments;
  final LoungeScope scope;
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
                  child: _CommentTile(
                    comment: comment,
                    scope: scope,
                    highlight: true,
                    onToggleLike: () => onToggleLike(comment.id),
                    onReply: onReply,
                    onOpenProfile: () => _openMemberProfile(context, comment.authorUid),
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
    required this.scope,
    required this.onToggleLike,
    required this.onReply,
    required this.onOpenProfile,
    this.highlight = false,
    this.isReply = false,
  });

  final Comment comment;
  final LoungeScope scope;
  final VoidCallback onToggleLike;
  final void Function(Comment comment) onReply;
  final VoidCallback onOpenProfile;
  final bool highlight;
  final bool isReply;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isSerialScope = scope == LoungeScope.serial;
    final bool hasTrack = comment.authorSerialVisible && comment.authorTrack != CareerTrack.none;
    final String trackLabel = serialLabel(
      comment.authorTrack,
      comment.authorSerialVisible,
      includeEmoji: isSerialScope ? true : hasTrack,
    );
    final String timestamp = _formatTimestamp(comment.createdAt);
    final String nicknameSource = comment.authorNickname.isNotEmpty
        ? comment.authorNickname
        : comment.authorUid;
    final String maskedNickname = maskNickname(nicknameSource);
    final String displayName = isSerialScope ? comment.authorNickname : maskedNickname;
    final String displayInitial = displayName.trim().isEmpty
        ? '공'
        : String.fromCharCode(displayName.trim().runes.first).toUpperCase();

    final Widget header = isSerialScope
        ? InkWell(
            onTap: onOpenProfile,
            borderRadius: BorderRadius.circular(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isReply) ...[
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                    foregroundColor: theme.colorScheme.primary,
                    child: Text(displayInitial),
                  ),
                  const Gap(12),
                ],
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
                              displayName,
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
                        timestamp,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        : InkWell(
            onTap: onOpenProfile,
            borderRadius: BorderRadius.circular(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: hasTrack
                        ? theme.colorScheme.primary.withValues(alpha: 0.12)
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    trackLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: hasTrack
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Gap(8),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          displayName,
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (comment.authorIsSupporter) ...[
                        const Gap(6),
                        Icon(Icons.workspace_premium, size: 16, color: theme.colorScheme.primary),
                      ],
                    ],
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
          );

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
            header,
            const Gap(8),
            Text(comment.text, style: theme.textTheme.bodyMedium),
            const Gap(12),
            Row(
              children: [
                TextButton.icon(
                  onPressed: onToggleLike,
                  icon: Icon(
                    comment.isLiked ? Icons.favorite : Icons.favorite_border,
                    size: 16,
                    color: comment.isLiked
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
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
            ),
          ],
        ),
      ),
    );
  }

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
}

class _CommentComposer extends StatefulWidget {
  const _CommentComposer({
    required this.controller,
    required this.isSubmitting,
    required this.onSubmit,
    required this.focusNode,
    required this.replyingTo,
    required this.onCancelReply,
    required this.scope,
  });

  final TextEditingController controller;
  final bool isSubmitting;
  final Future<void> Function() onSubmit;
  final FocusNode focusNode;
  final Comment? replyingTo;
  final VoidCallback onCancelReply;
  final LoungeScope scope;

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
    final bool canSubmit = widget.controller.text.trim().isNotEmpty;
    if (_canSubmit != canSubmit) {
      setState(() {
        _canSubmit = canSubmit;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Comment? replyingTo = widget.replyingTo;
    final bool isSerialScope = widget.scope == LoungeScope.serial;

    final List<Widget> children = <Widget>[];

    if (replyingTo != null) {
      final String nicknameSource = replyingTo.authorNickname.isNotEmpty
          ? replyingTo.authorNickname
          : replyingTo.authorUid;
      final String displayName = isSerialScope
          ? replyingTo.authorNickname
          : maskNickname(nicknameSource);
      final String preview = replyingTo.text.trim();
      children.add(
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$displayName 님에게 답글 작성 중',
                      style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (preview.isNotEmpty)
                      Text(
                        preview,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              TextButton(onPressed: widget.onCancelReply, child: const Text('취소')),
            ],
          ),
        ),
      );
    }

    children.add(
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              decoration: const InputDecoration(
                hintText: '댓글을 입력하세요...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              maxLines: null,
              textInputAction: TextInputAction.newline,
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

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.2))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

void _openMemberProfile(BuildContext context, String uid) {
  if (uid.isEmpty || uid == 'dummy_user') {
    return;
  }
  context.pushNamed(MemberProfileRoute.name, pathParameters: <String, String>{'uid': uid});
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
