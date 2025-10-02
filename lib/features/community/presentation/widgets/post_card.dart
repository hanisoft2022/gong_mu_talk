/// Main PostCard widget - displays a single post with interactions
///
/// Refactored from 2,190 lines to ~650 lines by extracting:
/// - PostHeader: Author info and menu
/// - PostContent: Text, tags, and media
/// - PostActionsBar: Like, comment, view buttons
/// - PostTrailingActions: Bookmark and share
/// - CommentComposer: Comment input and image upload
/// - PostCommentsSection: Comments display
/// - AuthorMenuOverlay: Author action menu
/// - InlineReplySheet: Reply composition
/// - MockMemberProfileScreen: Profile screen
///
/// Responsibilities:
/// - Main post card layout and state management
/// - Coordinate between child widgets
/// - Handle user interactions (like, bookmark, share)
/// - Manage comments state (loading, display, submission)
/// - Track view interactions
/// - Handle image uploads for comments
/// - Manage author menu overlay

library;
import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/utils/ui_helpers.dart';
import '../../../../core/utils/date_time_helpers.dart';
import '../../../../routing/app_router.dart';

import '../../data/community_repository.dart';
import '../../data/mock_social_graph.dart';
import '../../domain/models/comment.dart';
import '../../domain/models/feed_filters.dart';
import '../../domain/models/post.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';

// Import new widget components
import 'post/post_header.dart';
import 'post/post_content.dart' as content;
import 'post/post_actions_bar.dart';
import 'post/post_trailing_actions.dart';
import 'post/comment_composer_widget.dart';
import 'post/post_comments_section.dart';
import 'post/author_menu_overlay.dart';
import 'post/reply_sheet.dart';
import 'post/profile_screen.dart';
import 'post/comment_image_uploader.dart';
import 'post/post_share_handler.dart';

class PostCard extends StatefulWidget {
  const PostCard({
    super.key,
    required this.post,
    required this.onToggleLike,
    required this.onToggleBookmark,
    this.displayScope = LoungeScope.all,
    this.trailing,
    this.showShare = true,
    this.showBookmark = true,
  });

  final Post post;
  final VoidCallback onToggleLike;
  final VoidCallback onToggleBookmark;
  final LoungeScope displayScope;
  final Widget? trailing;
  final bool showShare;
  final bool showBookmark;

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> with TickerProviderStateMixin {
  // ==================== State Variables ====================

  // UI State
  final GlobalKey _authorButtonKey = GlobalKey();
  OverlayEntry? _menuOverlayEntry;
  bool _isExpanded = false;
  bool _showComments = false;
  bool _hasTrackedInteraction = false;

  // Comments State
  bool _isLoadingComments = false;
  bool _commentsLoaded = false;
  List<Comment> _featuredComments = const <Comment>[];
  List<Comment> _timelineComments = const <Comment>[];
  late int _commentCount;

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

  // Dependencies
  late final CommunityRepository _repository;
  late final MockSocialGraph _socialGraph;
  late final AuthCubit _authCubit;

  // ==================== Lifecycle Methods ====================

  @override
  void initState() {
    super.initState();
    _repository = context.read<CommunityRepository>();
    _socialGraph = context.read<MockSocialGraph>();
    _authCubit = context.read<AuthCubit>();
    _commentCount = widget.post.commentCount;
    _commentController = TextEditingController()..addListener(_handleCommentInputChanged);
    _commentFocusNode = FocusNode();
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
    _commentController
      ..removeListener(_handleCommentInputChanged)
      ..dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.post.id != oldWidget.post.id) {
      _commentFocusNode.unfocus();
      setState(() {
        _commentCount = widget.post.commentCount;
        _isExpanded = false;
        _showComments = false;
        _isLoadingComments = false;
        _commentsLoaded = false;
        _featuredComments = const <Comment>[];
        _timelineComments = const <Comment>[];
        _hasTrackedInteraction = false;
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
    final bool showMoreButton = !_isExpanded && content.shouldShowMore(post.text, context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                  scope: widget.displayScope,
                  authorButtonKey: _authorButtonKey,
                  onAuthorMenuTap: _handleAuthorMenuTap,
                ),
                const Gap(14),
                content.PostContent(
                  post: post,
                  isExpanded: _isExpanded,
                  showMoreButton: showMoreButton,
                  onExpand: _handleExpand,
                ),
                const Gap(16),
                PostActionsBar(
                  post: post,
                  onLikeTap: _handleLikeTap,
                  onCommentTap: _handleCommentButton,
                  trailingActions: PostTrailingActions(
                    post: post,
                    onBookmarkTap: _handleBookmarkTap,
                    onShareTap: () => _handleShare(post),
                    showShare: widget.showShare,
                    showBookmark: widget.showBookmark,
                    customTrailing: widget.trailing,
                  ),
                ),
              ],
            ),
          ),

          // Comment composer (shown when comments are visible)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: !_showComments
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CommentComposer(
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
                        ),
                        const Gap(16),
                      ],
                    ),
                  ),
          ),

          // Comments section
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: !_showComments
                ? const SizedBox.shrink()
                : AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: PostCommentsSection(
                      isLoading: _isLoadingComments,
                      timelineComments: _timelineComments,
                      featuredComments: _featuredComments,
                      scope: widget.displayScope,
                      onToggleCommentLike: _handleCommentLike,
                      onReplyTap: _handleReplyTap,
                      onOpenCommentAuthorProfile: _showCommentAuthorMenu,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ==================== Event Handlers ====================

  void _handleExpand() {
    _registerInteraction();
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _isExpanded = true);
      });
    }
  }

  void _handleLikeTap() {
    _registerInteraction();
    widget.onToggleLike();
  }

  void _handleCommentButton() {
    _registerInteraction();
    unawaited(_toggleComments());
  }

  void _handleBookmarkTap() {
    _registerInteraction();
    final bool isCurrentlyBookmarked = widget.post.isBookmarked;
    widget.onToggleBookmark();

    if (mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(isCurrentlyBookmarked ? '북마크가 해제되었습니다' : '북마크에 추가되었습니다'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  void _handleShare(Post post) {
    _registerInteraction();
    PostShareHandler.showShareOptions(context, post);
  }

  void _handleAuthorMenuTap() {
    if (!mounted) return;

    final AuthState authState = _authCubit.state;
    final String? currentUid = authState.userId;
    final bool isSelf = currentUid != null && currentUid == widget.post.authorUid;
    final bool canFollow = _canFollowUser(authState, currentUid, isSelf, widget.post.authorUid);
    final bool isFollowing = canFollow && _socialGraph.isFollowing(widget.post.authorUid);

    _showAuthorMenuAtPosition(
      canFollow: canFollow,
      isFollowing: isFollowing,
    );
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

  void _showAuthorMenuAtPosition({
    required bool canFollow,
    required bool isFollowing,
  }) {
    if (_menuOverlayEntry != null) {
      _closeAuthorMenu();
      return;
    }

    final overlayEntry = AuthorMenuOverlay.show(
      context: context,
      authorButtonKey: _authorButtonKey,
      canFollow: canFollow,
      isFollowing: isFollowing,
      onViewProfile: () => _handleAuthorAction(
        AuthorMenuAction.viewProfile,
        isFollowing: isFollowing,
      ),
      onToggleFollow: () => _handleAuthorAction(
        AuthorMenuAction.toggleFollow,
        isFollowing: isFollowing,
      ),
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
    final bool canFollow = authState.isLoggedIn &&
        currentUid != null &&
        currentUid.isNotEmpty &&
        !isSelf &&
        comment.authorUid.isNotEmpty;

    if (_menuOverlayEntry != null) {
      _closeAuthorMenu();
      return;
    }

    final bool isFollowing = canFollow && _socialGraph.isFollowing(comment.authorUid);
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

  Future<void> _handleAuthorAction(
    AuthorMenuAction action, {
    required bool isFollowing,
  }) async {
    _closeAuthorMenu();
    if (!mounted) return;

    switch (action) {
      case AuthorMenuAction.viewProfile:
        if (widget.post.authorUid.isEmpty || widget.post.authorUid == 'preview') {
          _showSnack('프리뷰 데이터라 프로필을 열 수 없어요.');
          return;
        }
        _openMockProfile(
          uid: widget.post.authorUid,
          nickname: widget.post.authorNickname,
        );
        break;
      case AuthorMenuAction.toggleFollow:
        await _toggleFollow(
          targetUid: widget.post.authorUid,
          nickname: widget.post.authorNickname,
          isFollowing: isFollowing,
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
        _openMockProfile(
          uid: comment.authorUid,
          nickname: comment.authorNickname,
        );
        break;
      case AuthorMenuAction.toggleFollow:
        await _toggleFollow(
          targetUid: comment.authorUid,
          nickname: comment.authorNickname,
          isFollowing: isFollowing,
        );
        break;
    }
  }

  // ==================== Comments ====================

  Future<void> _toggleComments() async {
    if (_showComments) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _showComments = false);
        });
      }
      return;
    }

    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _showComments = true);
      });
    }
    await _loadComments();
  }

  Future<void> _loadComments({bool force = false}) async {
    if (force) {
      _commentsLoaded = false;
    } else if (_commentsLoaded || _commentCount == 0) {
      return;
    }

    final Post post = widget.post;
    if (_isSynthetic(post)) {
      final List<Comment> syntheticTimeline = _applyRandomLikes(
        List<Comment>.generate(
          post.previewComments.length,
          (int index) => _fromCached(post, post.previewComments[index], index),
        ),
      );

      final List<Comment> sortedByLikes = List<Comment>.from(syntheticTimeline)
        ..sort((a, b) => b.likeCount.compareTo(a.likeCount));

      setState(() {
        _featuredComments = sortedByLikes.take(1).toList(growable: false);
        _timelineComments = syntheticTimeline;
        _commentsLoaded = true;
        _isLoadingComments = false;
      });
      return;
    }

    setState(() {
      _isLoadingComments = true;
    });

    try {
      final List<Comment> featured = await _repository.getTopComments(widget.post.id, limit: 1);
      final List<Comment> timeline = await _repository.getComments(widget.post.id);

      final Set<String> featuredIds = featured.map((Comment comment) => comment.id).toSet();
      final List<Comment> mergedTimeline = timeline
          .map((Comment comment) {
            if (featuredIds.contains(comment.id)) {
              return featured.firstWhere(
                (Comment featuredComment) => featuredComment.id == comment.id,
                orElse: () => comment,
              );
            }
            return comment;
          })
          .toList(growable: false);

      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _featuredComments = _applyRandomLikes(featured);
            _timelineComments = _applyRandomLikes(mergedTimeline);
            _commentsLoaded = true;
            _isLoadingComments = false;
          });
        }
      });
    } catch (_) {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _isLoadingComments = false);
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
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('프리뷰 게시물에는 댓글을 작성할 수 없습니다.'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
      }
      return;
    }

    _registerInteraction();
    setState(() => _isSubmittingComment = true);

    try {
      List<String> imageUrls = [];
      if (_selectedImages.isNotEmpty) {
        imageUrls = await _uploadImages();
        if (imageUrls.isEmpty && _selectedImages.isNotEmpty) {
          setState(() => _isSubmittingComment = false);
          return;
        }
      }

      await _repository.addComment(widget.post.id, text, imageUrls: imageUrls);

      if (!mounted) return;

      _commentController.clear();
      _commentFocusNode.unfocus();
      setState(() {
        _commentCount += 1;
        _canSubmitComment = false;
        _showComments = true;
        _selectedImages.clear();
      });
      await _loadComments(force: true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('댓글을 저장하지 못했어요. 잠시 후 다시 시도해주세요.')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmittingComment = false);
      }
    }
  }

  Future<void> _handleCommentLike(Comment comment) async {
    _registerInteraction();
    final bool willLike = !comment.isLiked;
    final int nextCount = max(0, comment.likeCount + (willLike ? 1 : -1));

    void updateLists(bool liked, int likeCount) {
      _timelineComments = _timelineComments
          .map(
            (Comment timelineComment) => timelineComment.id == comment.id
                ? timelineComment.copyWith(isLiked: liked, likeCount: likeCount)
                : timelineComment,
          )
          .toList(growable: false);
      _featuredComments = _featuredComments
          .map(
            (Comment featuredComment) => featuredComment.id == comment.id
                ? featuredComment.copyWith(isLiked: liked, likeCount: likeCount)
                : featuredComment,
          )
          .toList(growable: false);
    }

    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => updateLists(willLike, nextCount));
      });
    }

    if (_isSynthetic(widget.post)) return;

    try {
      await _repository.toggleCommentLikeById(widget.post.id, comment.id);
    } catch (_) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => updateLists(!willLike, comment.likeCount));
        });
      }
    }
  }

  void _handleReplyTap(Comment comment) {
    _registerInteraction();
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
        _showComments = true;
      });
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

    try {
      final bool nowFollowing = await _socialGraph.toggleFollow(
        targetUid,
        shouldFollow: !isFollowing,
      );
      if (!mounted) return;
      setState(() {});
      _showSnack(nowFollowing ? '$nickname 님을 팔로우했어요.' : '$nickname 님을 팔로우 취소했어요.');
    } catch (_) {
      if (!mounted) return;
      _showSnack('요청을 처리하지 못했어요. 잠시 후 다시 시도해주세요.');
    }
  }

  void _openMockProfile({
    required String uid,
    required String nickname,
  }) {
    final MockMemberProfileData? profile = _socialGraph.getProfile(uid);
    if (profile == null) {
      _showSnack('$nickname 님의 정보를 찾을 수 없어요.');
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MockMemberProfileScreen(profile: profile, socialGraph: _socialGraph),
      ),
    );
  }

  // ==================== Helper Methods ====================

  void _registerInteraction() {
    if (_hasTrackedInteraction || _isSynthetic(widget.post)) {
      return;
    }
    _hasTrackedInteraction = true;
    unawaited(_repository.incrementViewCount(widget.post.id));
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
      authorSupporterLevel: cached.authorSupporterLevel,
      authorIsSupporter: cached.authorIsSupporter,
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
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
