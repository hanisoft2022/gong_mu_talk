/// Main PostCard widget - displays a single post with interactions
///
/// Refactored from 2,190 lines to ~650 lines by extracting:
/// - PostHeader: Author info and menu
/// - PostContent: Text, tags, and media
/// - PostActionsBar: Like, comment, view buttons
/// - PostTrailingActions: Scrap and share
/// - CommentComposer: Comment input and image upload
/// - PostCommentsSection: Comments display
/// - AuthorMenuOverlay: Author action menu
/// - InlineReplySheet: Reply composition
///
/// Responsibilities:
/// - Main post card layout and state management
/// - Coordinate between child widgets
/// - Handle user interactions (like, scrap, share)
/// - Manage comments state (loading, display, submission)
/// - Track view interactions
/// - Handle image uploads for comments
/// - Manage author menu overlay

library;

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:gong_mu_talk/di/di.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/ui_helpers.dart';
import '../../../../core/utils/date_time_helpers.dart';
import '../../../../core/utils/snackbar_helpers.dart';
import '../../../../routing/app_router.dart';

import '../../data/community_repository.dart';
import '../../domain/models/comment.dart';
import '../../domain/models/feed_filters.dart';
import '../../domain/models/post.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../profile/data/follow_repository.dart';
import '../cubit/community_feed_cubit.dart';
import '../cubit/post_card_cubit.dart';
import '../cubit/post_card_state.dart';

// Import new widget components
import 'post/post_header.dart';
import 'post/post_content.dart' as content;
import 'post/post_actions_bar.dart';
import 'post/post_trailing_actions.dart';
import 'post/comment_composer_widget.dart';
import 'post/post_comments_section.dart';
import 'post/author_menu_overlay.dart';
import 'post/reply_sheet.dart';
import 'post/comment_image_uploader.dart';
import 'post/post_share_handler.dart';
import 'report_dialog.dart';
import 'block_user_dialog.dart';

class PostCard extends StatefulWidget {
  const PostCard({
    super.key,
    required this.post,
    required this.onToggleLike,
    required this.onToggleScrap,
    this.displayScope = LoungeScope.all,
    this.trailing,
    this.showShare = true,
    this.showScrap = true,
    this.highlightCommentId,
    this.onUnblockUser,
  });

  final Post post;
  final VoidCallback onToggleLike;
  final VoidCallback onToggleScrap;
  final LoungeScope displayScope;
  final Widget? trailing;
  final bool showShare;
  final bool showScrap;
  final String? highlightCommentId;
  final VoidCallback? onUnblockUser;

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> with TickerProviderStateMixin {
  // ==================== State Variables ====================

  // UI State
  final GlobalKey _authorButtonKey = GlobalKey();
  OverlayEntry? _menuOverlayEntry;
  late final ValueNotifier<bool> _isExpandedNotifier;
  late final ValueNotifier<bool> _showCommentsNotifier;

  // Comments State
  bool _isLoadingComments = false;
  bool _commentsLoaded = false;
  List<Comment> _featuredComments = const <Comment>[];
  List<Comment> _timelineComments = const <Comment>[];
  late int _commentCount;

  /// Filter out deleted comments without replies
  /// - Show deleted comments only if they have replies (to maintain thread structure)
  /// - Hide deleted comments without replies completely
  List<Comment> get _visibleTimelineComments {
    final Set<String> parentIdsWithReplies = _timelineComments
        .where((c) => c.parentCommentId != null)
        .map((c) => c.parentCommentId!)
        .toSet();

    return _timelineComments.where((comment) {
      if (!comment.deleted) return true; // Always show active comments

      // For deleted comments, only show if they have replies
      return parentIdsWithReplies.contains(comment.id);
    }).toList();
  }

  // Comment Input State
  late final TextEditingController _commentController;
  late final FocusNode _commentFocusNode;
  bool _canSubmitComment = false;
  bool _isSubmittingComment = false;

  // Image Upload State
  List<XFile> _selectedImages = [];
  bool _isUploadingImages = false;
  double _uploadProgress = 0.0;
  final CommentImageUploader _imageUploader = CommentImageUploader();

  // Delete Undo State
  Timer? _deleteUndoTimer;
  String? _deletedCommentId;
  String? _deletedCommentText;

  // Block Undo State
  Timer? _blockUndoTimer;
  String? _blockedUserId;
  String? _blockedUserNickname;

  // Follow Undo State
  Timer? _followUndoTimer;
  String? _followTargetUid;
  String? _followTargetNickname;
  bool? _wasFollowing;

  // Highlight State (Phase 3)
  String? _highlightedCommentId;
  Timer? _highlightTimer;
  final Map<String, GlobalKey> _commentKeys = {};

  // Dependencies
  late final CommunityRepository _repository;
  late final AuthCubit _authCubit;
  late final PostCardCubit _postCardCubit;
  late final FollowRepository _followRepository;

  // ==================== Lifecycle Methods ====================

  @override
  void initState() {
    super.initState();
    _repository = context.read<CommunityRepository>();
    _authCubit = context.read<AuthCubit>();
    _followRepository = getIt<FollowRepository>();

    // Initialize PostCardCubit
    _postCardCubit = PostCardCubit(
      repository: _repository,
      postId: widget.post.id,
      initialCommentCount: widget.post.commentCount,
      currentUid: _authCubit.state.userId,
    );

    _commentCount = widget.post.commentCount;
    _commentController = TextEditingController()..addListener(_handleCommentInputChanged);
    _commentFocusNode = FocusNode();
    _isExpandedNotifier = ValueNotifier<bool>(false);
    _showCommentsNotifier = ValueNotifier<bool>(false);

    // Phase 3: Auto-expand comments if highlightCommentId is provided
    if (widget.highlightCommentId != null) {
      _showCommentsNotifier.value = true;
      _highlightedCommentId = widget.highlightCommentId;
      // Load comments immediately
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadComments();
      });
    }
  }

  @override
  void dispose() {
    if (_menuOverlayEntry != null) {
      try {
        _menuOverlayEntry!.remove();
      } catch (e) {
        // Silently handle overlay removal errors
      } finally {
        _menuOverlayEntry = null;
      }
    }
    _deleteUndoTimer?.cancel();
    _blockUndoTimer?.cancel();
    _followUndoTimer?.cancel();
    _highlightTimer?.cancel();
    _commentController
      ..removeListener(_handleCommentInputChanged)
      ..dispose();
    _commentFocusNode.dispose();
    _isExpandedNotifier.dispose();
    _showCommentsNotifier.dispose();
    _postCardCubit.close(); // Close cubit
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.post.id != oldWidget.post.id) {
      _commentFocusNode.unfocus();
      setState(() {
        _commentCount = widget.post.commentCount;
        _isExpandedNotifier.value = false;
        _showCommentsNotifier.value = false;
        _isLoadingComments = false;
        _commentsLoaded = false;
        _featuredComments = const <Comment>[];
        _timelineComments = const <Comment>[];
        _commentController.clear();
        _canSubmitComment = false;
        _isSubmittingComment = false;
      });
    } else if (widget.post.commentCount != oldWidget.post.commentCount) {
      setState(() {
        _commentCount = widget.post.commentCount;
        if (widget.post.commentCount > oldWidget.post.commentCount) {
          _commentsLoaded = false;
        }
      });
    }
  }

  // ==================== Build Methods ====================

  @override
  Widget build(BuildContext context) {
    final Post post = widget.post;
    final String timestamp = _formatTimestamp(post.createdAt);
    final ThemeData theme = Theme.of(context);

    return BlocListener<PostCardCubit, PostCardState>(
      bloc: _postCardCubit,
      listener: (context, state) {
        // Sync Cubit state to local state for synthetic post handling
        if (!_isSynthetic(post) && mounted) {
          final wasLoading = _isLoadingComments;

          setState(() {
            _isLoadingComments = state.isLoadingComments;
            _featuredComments = state.featuredComments;
            _timelineComments = state.timelineComments;
            _commentCount = state.commentCount;
            _isSubmittingComment = state.isSubmittingComment;
          });

          // Phase 3: Scroll to highlighted comment when loading completes
          if (wasLoading && !state.isLoadingComments && _highlightedCommentId != null) {
            _scrollToHighlightedComment();
          }

          // Show error if any
          if (state.error != null) {
            SnackbarHelpers.showError(context, state.error!);
            _postCardCubit.clearError();
          }
        }
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 0.5,
        color: theme.colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Post header, content, and actions
            Padding(
              padding: UiHelpers.standardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PostHeader(
                    post: post,
                    timestamp: timestamp,
                    authorButtonKey: _authorButtonKey,
                    onAuthorMenuTap: _handleAuthorMenuTap,
                  ),
                  const Gap(12),
                  RepaintBoundary(
                    child: ValueListenableBuilder<bool>(
                      valueListenable: _isExpandedNotifier,
                      builder: (context, isExpanded, _) {
                        final bool showMoreButton =
                            !isExpanded && content.shouldShowMore(post.text, context);
                        return content.PostContent(
                          post: post,
                          isExpanded: isExpanded,
                          showMoreButton: showMoreButton,
                          onExpand: _handleExpand,
                        );
                      },
                    ),
                  ),
                  const Gap(16),
                  BlocBuilder<AuthCubit, AuthState>(
                    builder: (context, authState) {
                      final bool canLike = authState.hasLoungeWriteAccess;
                      return PostActionsBar(
                        post: post,
                        onLikeTap: _handleLikeTap,
                        onCommentTap: _handleCommentButton,
                        canLike: canLike,
                        onDisabledLikeTap: () =>
                            _showVerificationRequiredDialog(context, authState, actionType: 'like'),
                        trailingActions: PostTrailingActions(
                          post: post,
                          onScrapTap: _handleScrapTap,
                          onShareTap: () => _handleShare(post),
                          showShare: widget.showShare,
                          showScrap: widget.showScrap,
                          customTrailing: widget.trailing,
                          onReportTap: _handleReport,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Comment composer (shown when comments are visible)
            ValueListenableBuilder<bool>(
              valueListenable: _showCommentsNotifier,
              builder: (context, showComments, _) {
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: !showComments
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              BlocBuilder<AuthCubit, AuthState>(
                                builder: (context, authState) {
                                  final bool canWrite = authState.hasLoungeWriteAccess;
                                  return CommentComposer(
                                    controller: _commentController,
                                    focusNode: _commentFocusNode,
                                    selectedImages: _selectedImages,
                                    isSubmitting: _isSubmittingComment,
                                    isUploadingImages: _isUploadingImages,
                                    uploadProgress: _uploadProgress,
                                    canSubmit: _canSubmitComment,
                                    onPickImages: _pickImages,
                                    onRemoveImage: _removeImage,
                                    onSubmit: _submitComment,
                                    enabled: canWrite,
                                    onDisabledTap: () =>
                                        _showVerificationRequiredDialog(context, authState),
                                    hintText: canWrite ? '댓글을 입력하세요.' : '댓글 작성은 공직자 메일 인증 후 가능합니다.',
                                  );
                                },
                              ),
                              const Gap(16),
                            ],
                          ),
                        ),
                );
              },
            ),

            // Comments section
            ValueListenableBuilder<bool>(
              valueListenable: _showCommentsNotifier,
              builder: (context, showComments, _) {
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: !showComments
                      ? const SizedBox.shrink()
                      : AnimatedSize(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOutCubic,
                          alignment: Alignment.topCenter,
                          child: RepaintBoundary(
                            child: BlocBuilder<AuthCubit, AuthState>(
                              builder: (context, authState) {
                                final bool canLike = authState.hasLoungeWriteAccess;
                                return PostCommentsSection(
                                  isLoading: _isLoadingComments,
                                  timelineComments: _visibleTimelineComments,
                                  featuredComments: _featuredComments,
                                  onToggleCommentLike: _handleCommentLike,
                                  onReplyTap: _handleReplyTap,
                                  onOpenCommentAuthorProfile: _showCommentAuthorMenu,
                                  onDeleteComment: _handleDeleteComment,
                                  currentUserId: _authCubit.state.userId,
                                  highlightedCommentId: _highlightedCommentId,
                                  commentKeys: _commentKeys,
                                  canLike: canLike,
                                  onDisabledLikeTap: () => _showVerificationRequiredDialog(
                                    context,
                                    authState,
                                    actionType: 'like',
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ==================== Event Handlers ====================

  void _handleExpand() {
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _isExpandedNotifier.value = true;
      });
    }
  }

  void _handleLikeTap() {
    widget.onToggleLike();
  }

  void _handleCommentButton() {
    unawaited(_toggleComments());
  }

  void _handleScrapTap() {
    widget.onToggleScrap();
  }

  void _handleShare(Post post) {
    PostShareHandler.showShareOptions(context, post);
  }

  Future<void> _handleReport() async {
    if (_isSynthetic(widget.post)) {
      _showSnack('프리뷰 게시물은 신고할 수 없어요.');
      return;
    }

    final String? reason = await ReportDialog.show(context);
    if (reason == null || !mounted) return;

    // Use Cubit for reporting
    await _postCardCubit.reportPost(reason);

    if (!mounted) return;

    SnackbarHelpers.showInfo(context, '신고가 접수되었습니다. 검토 후 조치하겠습니다.');
  }

  void _handleAuthorMenuTap() {
    if (!mounted) return;

    final AuthState authState = _authCubit.state;
    final String? currentUid = authState.userId;
    final bool isSelf = currentUid != null && currentUid == widget.post.authorUid;
    final bool canFollow = _canFollowUser(authState, currentUid, isSelf, widget.post.authorUid);
    const bool isFollowing = false; // Social graph feature not yet implemented

    _showAuthorMenuAtPosition(canFollow: canFollow, isFollowing: isFollowing);
  }

  void _handleCommentInputChanged() {
    final bool canSubmit = _commentController.text.trim().isNotEmpty || _selectedImages.isNotEmpty;
    if (canSubmit != _canSubmitComment) {
      setState(() {
        _canSubmitComment = canSubmit;
      });
    }
  }

  // ==================== Author Menu ====================

  void _showAuthorMenuAtPosition({required bool canFollow, required bool isFollowing}) {
    if (_menuOverlayEntry != null) {
      _closeAuthorMenu();
      return;
    }

    final overlayEntry = AuthorMenuOverlay.show(
      context: context,
      authorButtonKey: _authorButtonKey,
      canFollow: canFollow,
      isFollowing: isFollowing,
      onViewProfile: () =>
          _handleAuthorAction(AuthorMenuAction.viewProfile, isFollowing: isFollowing),
      onToggleFollow: () =>
          _handleAuthorAction(AuthorMenuAction.toggleFollow, isFollowing: isFollowing),
      onBlockUser: () => _handleAuthorAction(AuthorMenuAction.blockUser, isFollowing: isFollowing),
      onClose: _closeAuthorMenu,
    );

    if (overlayEntry != null && mounted) {
      try {
        _menuOverlayEntry = overlayEntry;
        Overlay.of(context).insert(_menuOverlayEntry!);
      } catch (e) {
        _menuOverlayEntry = null;
      }
    }
  }

  void _showCommentAuthorMenu(Comment comment, GlobalKey authorKey) {
    if (!mounted) return;

    final AuthState authState = _authCubit.state;
    final String? currentUid = authState.userId;
    final bool isSelf = currentUid != null && currentUid == comment.authorUid;
    final bool canFollow =
        authState.isLoggedIn &&
        currentUid != null &&
        currentUid.isNotEmpty &&
        !isSelf &&
        comment.authorUid.isNotEmpty;

    if (_menuOverlayEntry != null) {
      _closeAuthorMenu();
      return;
    }

    const bool isFollowing = false; // Social graph feature not yet implemented
    final overlayEntry = AuthorMenuOverlay.show(
      context: context,
      authorButtonKey: authorKey,
      canFollow: canFollow,
      isFollowing: isFollowing,
      onViewProfile: () => _handleCommentAuthorAction(
        comment,
        AuthorMenuAction.viewProfile,
        isFollowing: isFollowing,
      ),
      onToggleFollow: () => _handleCommentAuthorAction(
        comment,
        AuthorMenuAction.toggleFollow,
        isFollowing: isFollowing,
      ),
      onBlockUser: () =>
          _handleCommentAuthorAction(comment, AuthorMenuAction.blockUser, isFollowing: isFollowing),
      onClose: _closeAuthorMenu,
    );

    if (overlayEntry != null && mounted) {
      try {
        _menuOverlayEntry = overlayEntry;
        Overlay.of(context).insert(_menuOverlayEntry!);
      } catch (e) {
        _menuOverlayEntry = null;
      }
    }
  }

  void _closeAuthorMenu() {
    if (_menuOverlayEntry != null && mounted) {
      try {
        _menuOverlayEntry!.remove();
      } catch (e) {
        // Silently handle errors
      } finally {
        _menuOverlayEntry = null;
      }
    }
  }

  Future<void> _handleAuthorAction(AuthorMenuAction action, {required bool isFollowing}) async {
    _closeAuthorMenu();
    if (!mounted) return;

    switch (action) {
      case AuthorMenuAction.viewProfile:
        if (widget.post.authorUid.isEmpty || widget.post.authorUid == 'preview') {
          _showSnack('프리뷰 데이터라 프로필을 열 수 없어요.');
          return;
        }
        _openMockProfile(uid: widget.post.authorUid, nickname: widget.post.authorNickname);
        break;
      case AuthorMenuAction.toggleFollow:
        await _toggleFollow(
          targetUid: widget.post.authorUid,
          nickname: widget.post.authorNickname,
          isFollowing: isFollowing,
        );
        break;
      case AuthorMenuAction.blockUser:
        await _handleBlockUser(
          targetUid: widget.post.authorUid,
          nickname: widget.post.authorNickname,
        );
        break;
    }
  }

  Future<void> _handleCommentAuthorAction(
    Comment comment,
    AuthorMenuAction action, {
    required bool isFollowing,
  }) async {
    _closeAuthorMenu();
    if (!mounted) return;

    switch (action) {
      case AuthorMenuAction.viewProfile:
        if (comment.authorUid.isEmpty || comment.authorUid == 'preview') {
          _showSnack('프리뷰 데이터라 프로필을 열 수 없어요.');
          return;
        }
        _openMockProfile(uid: comment.authorUid, nickname: comment.authorNickname);
        break;
      case AuthorMenuAction.toggleFollow:
        await _toggleFollow(
          targetUid: comment.authorUid,
          nickname: comment.authorNickname,
          isFollowing: isFollowing,
        );
        break;
      case AuthorMenuAction.blockUser:
        await _handleBlockUser(targetUid: comment.authorUid, nickname: comment.authorNickname);
        break;
    }
  }

  Future<void> _handleDeleteComment(Comment comment) async {
    if (_isSynthetic(widget.post)) {
      _showSnack('프리뷰 게시물의 댓글은 삭제할 수 없어요.');
      return;
    }

    final String? currentUid = _authCubit.state.userId;
    if (currentUid == null) {
      _showSnack('로그인이 필요합니다.');
      return;
    }

    // Cancel any existing undo timer
    _deleteUndoTimer?.cancel();

    // Delete comment via Cubit
    final String? originalText = await _postCardCubit.deleteComment(comment, currentUid);

    if (originalText == null || !mounted) {
      return; // Failed to delete
    }

    // Store for undo
    _deletedCommentId = comment.id;
    _deletedCommentText = originalText;

    // Show SnackBar with undo option
    SnackbarHelpers.showUndo(
      context,
      message: '댓글이 삭제되었습니다',
      onUndo: () {
        _deleteUndoTimer?.cancel();
        _handleUndoDelete();
      },
    );

    // Set timer to clear undo data after 5 seconds
    _deleteUndoTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        _deletedCommentId = null;
        _deletedCommentText = null;
      }
    });
  }

  Future<void> _handleUndoDelete() async {
    if (_deletedCommentId == null || _deletedCommentText == null) {
      return;
    }

    final String? currentUid = _authCubit.state.userId;
    if (currentUid == null) {
      return;
    }

    final String commentId = _deletedCommentId!;
    final String originalText = _deletedCommentText!;

    // Clear undo data
    _deletedCommentId = null;
    _deletedCommentText = null;

    // Restore comment via Cubit
    await _postCardCubit.undoDeleteComment(commentId, currentUid, originalText);

    if (!mounted) return;

    SnackbarHelpers.showSuccess(context, '댓글이 복구되었습니다');
  }

  // ==================== Comments ====================

  Future<void> _toggleComments() async {
    if (_showCommentsNotifier.value) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showCommentsNotifier.value = false;
        });
      }
      return;
    }

    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showCommentsNotifier.value = true;
      });
    }
    await _loadComments();
  }

  Future<void> _loadComments({bool force = false}) async {
    // Skip if already loaded (unless forcing)
    if (!force && (_commentsLoaded || _commentCount == 0)) {
      return;
    }

    final Post post = widget.post;

    // Handle synthetic (preview) posts locally
    if (_isSynthetic(post)) {
      final List<Comment> syntheticTimeline = _applyRandomLikes(
        List<Comment>.generate(
          post.previewComments.length,
          (int index) => _fromCached(post, post.previewComments[index], index),
        ),
      );

      final List<Comment> sortedByLikes = List<Comment>.from(syntheticTimeline)
        ..sort((a, b) => b.likeCount.compareTo(a.likeCount));

      // 베스트 댓글 조건: 최소 좋아요 3개 이상, 전체 댓글 3개 이상
      final bool canSelectFeatured =
          syntheticTimeline.length >= 3 &&
          sortedByLikes.isNotEmpty &&
          sortedByLikes.first.likeCount >= 3;

      setState(() {
        _featuredComments = canSelectFeatured
            ? sortedByLikes.take(1).toList(growable: false)
            : <Comment>[];
        _timelineComments = syntheticTimeline;
        _commentsLoaded = true;
        _isLoadingComments = false;
      });
      return;
    }

    // For real posts, use Cubit
    await _postCardCubit.loadComments(force: force);

    // Mark as loaded locally (for synthetic check)
    if (mounted) {
      setState(() {
        _commentsLoaded = true;
      });
    }
  }

  Future<void> _submitComment() async {
    final String text = _commentController.text.trim();
    if (!_hasCommentContent(text) || _isSubmittingComment) {
      return;
    }

    if (_isSynthetic(widget.post)) {
      if (mounted) {
        SnackbarHelpers.showWarning(context, '프리뷰 게시물에는 댓글을 작성할 수 없습니다.');
      }
      return;
    }

    setState(() => _isSubmittingComment = true);

    try {
      // Upload images if any
      List<String> imageUrls = [];
      if (_selectedImages.isNotEmpty) {
        imageUrls = await _uploadImages();
        if (imageUrls.isEmpty && _selectedImages.isNotEmpty) {
          setState(() => _isSubmittingComment = false);
          return;
        }
      }

      // Submit comment via Cubit
      await _postCardCubit.submitComment(text, imageUrls: imageUrls);

      if (!mounted) return;

      // Clear local UI state
      _commentController.clear();
      _commentFocusNode.unfocus();
      setState(() {
        _canSubmitComment = false;
        _selectedImages.clear();
        _isSubmittingComment = false;
      });
      _showCommentsNotifier.value = true;
    } catch (_) {
      if (mounted) {
        SnackbarHelpers.showError(context, '댓글을 저장하지 못했어요. 잠시 후 다시 시도해주세요.');
        setState(() => _isSubmittingComment = false);
      }
    }
  }

  Future<void> _handleCommentLike(Comment comment) async {
    // Skip for synthetic posts
    if (_isSynthetic(widget.post)) return;

    // Use Cubit for optimistic update
    await _postCardCubit.toggleCommentLike(comment);
  }

  void _handleReplyTap(Comment comment) {
    if (_isSynthetic(widget.post)) {
      _showSnack('프리뷰 게시물에는 답글을 남길 수 없어요.');
      return;
    }
    unawaited(_showReplySheet(comment));
  }

  Future<void> _showReplySheet(Comment comment) async {
    final bool? added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) => InlineReplySheet(
        postId: widget.post.id,
        target: comment,
        scope: widget.displayScope,
        repository: _repository,
      ),
    );

    if (added == true && mounted) {
      setState(() {
        _commentCount += 1;
      });
      _showCommentsNotifier.value = true;
      await _loadComments(force: true);
    }
  }

  // ==================== Image Upload ====================

  Future<void> _pickImages() async {
    final result = await _imageUploader.pickAndCompressImage(
      context,
      currentImages: _selectedImages,
      onStart: () {
        if (mounted) {
          setState(() {
            _isUploadingImages = true;
          });
        }
      },
      onComplete: () {
        if (mounted) {
          setState(() {
            _isUploadingImages = false;
          });
        }
      },
    );

    if (result != null && mounted) {
      setState(() {
        _selectedImages = [result];
      });
      _handleCommentInputChanged();
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
    _handleCommentInputChanged();
  }

  Future<List<String>> _uploadImages() async {
    if (_selectedImages.isEmpty) return [];

    return await _imageUploader.uploadImages(
      images: _selectedImages,
      userId: _authCubit.state.userId ?? 'anonymous',
      postId: widget.post.id,
      onProgress: (progress) {
        if (mounted) {
          setState(() {
            _uploadProgress = progress;
          });
        }
      },
      context: context,
    );
  }

  // Share methods moved to PostShareHandler

  // ==================== Profile ====================

  Future<void> _toggleFollow({
    required String targetUid,
    required String nickname,
    required bool isFollowing,
  }) async {
    if (!mounted) return;

    final AuthState authState = _authCubit.state;
    final String? currentUid = authState.userId;

    if (currentUid == null || currentUid.isEmpty) {
      _showSnack('로그인이 필요합니다.');
      return;
    }

    // Check verification status
    if (!authState.hasLoungeWriteAccess) {
      _showVerificationRequiredDialog(context, authState, actionType: 'follow');
      return;
    }

    // Cancel any existing undo timer
    _followUndoTimer?.cancel();

    // Store for undo
    _followTargetUid = targetUid;
    _followTargetNickname = nickname;
    _wasFollowing = isFollowing;

    try {
      // Toggle follow state
      if (isFollowing) {
        await _followRepository.unfollow(followerUid: currentUid, targetUid: targetUid);
      } else {
        await _followRepository.follow(followerUid: currentUid, targetUid: targetUid);
      }

      if (!mounted) return;

      // Show undo snackbar
      SnackbarHelpers.showUndo(
        context,
        message: isFollowing ? '팔로우를 취소했어요.' : '새로운 동료를 팔로우했어요.',
        onUndo: () {
          _followUndoTimer?.cancel();
          _handleUndoFollow();
        },
      );

      // Set timer to clear undo data after 5 seconds
      _followUndoTimer = Timer(const Duration(seconds: 5), () {
        if (mounted) {
          _followTargetUid = null;
          _followTargetNickname = null;
          _wasFollowing = null;
        }
      });
    } catch (e, stackTrace) {
      if (!mounted) return;
      debugPrint('❌ Follow toggle failed: $e');
      debugPrint('Stack trace: $stackTrace');
      _showSnack('팔로우 상태를 변경하지 못했습니다. 잠시 후 다시 시도해주세요.');
    }
  }

  Future<void> _handleUndoFollow() async {
    if (_followTargetUid == null || _wasFollowing == null) {
      return;
    }

    final String? currentUid = _authCubit.state.userId;
    if (currentUid == null) {
      return;
    }

    final String targetUid = _followTargetUid!;
    final String nickname = _followTargetNickname ?? '사용자';
    final bool wasFollowing = _wasFollowing!;

    // Clear undo data
    _followTargetUid = null;
    _followTargetNickname = null;
    _wasFollowing = null;

    try {
      // Restore previous follow state
      if (wasFollowing) {
        await _followRepository.follow(followerUid: currentUid, targetUid: targetUid);
      } else {
        await _followRepository.unfollow(followerUid: currentUid, targetUid: targetUid);
      }

      if (!mounted) return;

      SnackbarHelpers.showSuccess(context, '$nickname님에 대한 팔로우 상태를 복구했습니다');
    } catch (e) {
      if (!mounted) return;

      SnackbarHelpers.showError(context, '팔로우 상태 복구에 실패했습니다');
    }
  }

  Future<void> _handleBlockUser({required String targetUid, required String nickname}) async {
    if (!mounted) return;

    // Show confirmation dialog
    final bool? confirmed = await BlockUserDialog.show(context, nickname: nickname);

    if (confirmed != true || !mounted) return;

    // Cancel any existing block undo timer
    _blockUndoTimer?.cancel();

    // Store for undo
    _blockedUserId = targetUid;
    _blockedUserNickname = nickname;

    // Block user via Cubit
    await _postCardCubit.blockUser(targetUid);

    if (!mounted) return;

    // 즉시 피드에서 제거 (클라이언트 필터링)
    try {
      context.read<CommunityFeedCubit>().hideBlockedUserPosts(targetUid);
    } catch (e) {
      debugPrint('CommunityFeedCubit not found: $e');
    }

    // Show SnackBar with undo option
    SnackbarHelpers.showUndo(
      context,
      message: '$nickname님을 차단했습니다',
      onUndo: () {
        _blockUndoTimer?.cancel();
        _handleUndoBlock();
      },
    );

    // Set timer to clear undo data after 5 seconds
    _blockUndoTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        _blockedUserId = null;
        _blockedUserNickname = null;
      }
    });
  }

  Future<void> _handleUndoBlock() async {
    if (_blockedUserId == null || _blockedUserNickname == null) {
      return;
    }

    final String userId = _blockedUserId!;
    final String nickname = _blockedUserNickname!;

    // Clear undo data
    _blockedUserId = null;
    _blockedUserNickname = null;

    // Unblock user via repository
    try {
      await _repository.unblockUser(userId);

      // IMPORTANT: Call refresh callback BEFORE mounted check
      // The callback operates on feed-level cubit, so it's safe even if PostCard is unmounted
      // This ensures the feed refreshes even if this PostCard was removed from tree during blocking
      widget.onUnblockUser?.call();

      // Only show SnackBar if widget is still mounted (requires valid context)
      if (!mounted) return;

      SnackbarHelpers.showSuccess(context, '$nickname님에 대한 차단을 해제했습니다');
    } catch (e) {
      debugPrint('❌ Error unblocking user: $e');
      if (!mounted) return;

      SnackbarHelpers.showError(context, '차단 해제에 실패했습니다');
    }
  }

  void _openMockProfile({required String uid, required String nickname}) {
    if (uid.isEmpty || uid == 'dummy_user') {
      return;
    }
    context.pushNamed(MemberProfileRoute.name, pathParameters: <String, String>{'uid': uid});
  }

  // ==================== Helper Methods ====================

  /// Phase 3: Scroll to highlighted comment and remove highlight after delay
  void _scrollToHighlightedComment() {
    if (_highlightedCommentId == null) return;

    // Wait for build to complete AND images to load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _highlightedCommentId == null) return;

      // Add additional delay for images to load
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted || _highlightedCommentId == null) return;

        final commentKey = _commentKeys[_highlightedCommentId!];
        if (commentKey?.currentContext != null) {
          // Scroll to the comment with animation
          Scrollable.ensureVisible(
            commentKey!.currentContext!,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            alignment: 0.2, // Position comment at 20% from top of viewport
          );

          // Remove highlight after 3 seconds
          _highlightTimer?.cancel();
          _highlightTimer = Timer(const Duration(seconds: 3), () {
            if (mounted) {
              setState(() {
                _highlightedCommentId = null;
              });
            }
          });
        }
      });
    });
  }

  bool _isSynthetic(Post post) {
    return post.id.startsWith('dummy_') || post.authorUid == 'dummy_user';
  }

  List<Comment> _applyRandomLikes(List<Comment> comments) {
    final Random random = Random();
    return comments.map((Comment comment) {
      final int randomLikes = random.nextInt(50) + 1;
      return comment.copyWith(likeCount: randomLikes);
    }).toList();
  }

  Comment _fromCached(Post post, CachedComment cached, int index) {
    return Comment(
      id: cached.id,
      postId: post.id,
      authorUid: 'preview',
      authorNickname: cached.authorNickname,
      authorTrack: cached.authorTrack,
      authorSerialVisible: cached.authorSerialVisible,
      text: cached.text,
      likeCount: cached.likeCount,
      createdAt: (post.updatedAt ?? post.createdAt).add(Duration(minutes: index)),
    );
  }

  String _formatTimestamp(DateTime createdAt) {
    return createdAt.relativeTime;
  }

  bool _canFollowUser(AuthState authState, String? currentUid, bool isSelf, String targetUid) {
    return authState.isLoggedIn &&
        currentUid != null &&
        currentUid.isNotEmpty &&
        !isSelf &&
        targetUid.isNotEmpty &&
        targetUid != 'preview';
  }

  bool _hasCommentContent(String text) {
    return text.isNotEmpty || _selectedImages.isNotEmpty;
  }

  void _showSnack(String message) {
    SnackbarHelpers.showInfo(context, message);
  }

  /// Show verification required dialog when user tries to interact without verification
  void _showVerificationRequiredDialog(
    BuildContext context,
    AuthState authState, {
    String? actionType,
  }) {
    final String action;
    switch (actionType) {
      case 'like':
        action = '좋아요를 누르려면';
        break;
      case 'follow':
        action = '팔로우하려면';
        break;
      default:  // 'comment' or null
        action = '댓글을 작성하려면';
        break;
    }
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [Icon(Icons.lock_outline, size: 24), SizedBox(width: 8), Text('인증 필요')],
        ),
        content: Text(
          '$action 공직자 메일 인증이 필요합니다.\n\n💡 직렬 인증(급여명세서)을 완료하시면 메일 인증 없이도 바로 이용 가능합니다.',
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('취소')),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.push('/profile');
            },
            child: const Text('지금 인증하기'),
          ),
        ],
      ),
    );
  }
}
