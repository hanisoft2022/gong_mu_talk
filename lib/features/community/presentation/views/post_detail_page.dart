/// Post Detail Page - Main coordinator for post detail view
///
/// Responsibilities:
/// - Manages page state and lifecycle
/// - Coordinates between cubit and UI widgets
/// - Handles navigation to edit page
/// - Manages comment input state and focus
/// - Delegates actions to appropriate handlers
/// - Orchestrates dialogs and snackbar messages

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:gong_mu_talk/routing/app_router.dart';

import '../../domain/models/comment.dart';
import '../../domain/models/feed_filters.dart';
import '../../domain/models/post.dart';
import '../cubit/post_detail_cubit.dart';
import '../widgets/post_detail_header.dart';
import '../widgets/comments_section.dart';
import '../widgets/comment_composer.dart';
import '../widgets/post_detail_error_view.dart';
import '../widgets/post_detail_dialogs.dart';

class PostDetailPage extends StatefulWidget {
  const PostDetailPage({
    super.key,
    required this.postId,
    this.initialPost,
    this.replyCommentId,
  });

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

  // ==================== Lifecycle ====================

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

  // ==================== Build ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('게시글')),
      body: BlocListener<PostDetailCubit, PostDetailState>(
        listenWhen: (previous, current) =>
            previous.replyingTo != current.replyingTo,
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
              return PostDetailErrorView(
                message: state.errorMessage ?? '게시글을 불러올 수 없습니다.',
                onRetry: () =>
                    context.read<PostDetailCubit>().loadPost(widget.postId),
              );
            }

            if (state.post == null) {
              return const Center(child: Text('게시글을 찾을 수 없습니다.'));
            }

            final LoungeScope scope =
                state.post!.audience == PostAudience.serial
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
                        PostDetailHeader(
                          post: state.post!,
                          currentUserId: context
                              .read<PostDetailCubit>()
                              .currentUserId,
                          onToggleLike: () =>
                              context.read<PostDetailCubit>().toggleLike(),
                          onToggleBookmark: () =>
                              context.read<PostDetailCubit>().toggleBookmark(),
                          onMenuAction: _handleMenuAction,
                        ),
                        const Gap(24),
                        CommentsSection(
                          featuredComments: state.featuredComments,
                          timelineComments: state.comments,
                          isLoading: state.isLoadingComments,
                          scope: scope,
                          onToggleLike: (commentId) => context
                              .read<PostDetailCubit>()
                              .toggleCommentLike(commentId),
                          onReply: _handleReply,
                        ),
                      ],
                    ),
                  ),
                ),
                CommentComposer(
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

  // ==================== Menu Actions ====================

  void _handleMenuAction(String action) {
    switch (action) {
      case 'edit':
        _navigateToEdit();
        break;
      case 'delete':
        _handleDelete();
        break;
      case 'report':
        _handleReport();
        break;
      case 'block':
        _handleBlock();
        break;
    }
  }

  void _navigateToEdit() {
    final state = context.read<PostDetailCubit>().state;
    if (state.post != null) {
      context.push('${CommunityRoute.editPath}/${state.post!.id}');
    }
  }

  Future<void> _handleDelete() async {
    final bool? confirmed = await PostDetailDialogs.showDeleteDialog(context);
    if (confirmed == true && mounted) {
      final success = await context.read<PostDetailCubit>().deletePost();
      if (success && mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  Future<void> _handleReport() async {
    final bool? confirmed = await PostDetailDialogs.showReportDialog(context);
    if (confirmed == true && mounted) {
      await context.read<PostDetailCubit>().reportPost();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('신고가 접수되었습니다. 검토 후 조치하겠습니다.')),
        );
      }
    }
  }

  Future<void> _handleBlock() async {
    final bool? confirmed = await PostDetailDialogs.showBlockDialog(context);
    if (confirmed == true && mounted) {
      await context.read<PostDetailCubit>().blockUser();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('사용자를 차단했습니다.')),
        );
        Navigator.pop(context);
      }
    }
  }

  // ==================== Comment Actions ====================

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final success = await context.read<PostDetailCubit>().submitComment(text);
    if (success && mounted) {
      _commentController.clear();
      if (mounted) FocusScope.of(context).unfocus();
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
      final String updated = current
          .substring(0, current.length - mention.length)
          .trimRight();
      _commentController
        ..text = updated
        ..selection = TextSelection.collapsed(offset: updated.length);
    }
  }

  // ==================== Mention Helpers ====================

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
      _commentController.selection = TextSelection.collapsed(
        offset: value.text.length,
      );
    }
  }
}
