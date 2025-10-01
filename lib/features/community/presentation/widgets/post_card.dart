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

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/utils/image_compression_util.dart';
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
  final ImagePicker _imagePicker = ImagePicker();

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
    _showShareOptions(post);
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
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) return;

      if (_selectedImages.isNotEmpty) {
        if (mounted) {
          final bool? replace = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('이미지 교체'),
              content: const Text('댓글에는 이미지를 1장만 첨부할 수 있습니다. 기존 이미지를 교체하시겠습니까?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('취소'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('교체'),
                ),
              ],
            ),
          );

          if (replace != true) return;
        }
      }

      setState(() {
        _isUploadingImages = true;
      });

      try {
        final XFile? compressedImage = await ImageCompressionUtil.compressImage(
          image,
          ImageCompressionType.comment,
        );

        if (compressedImage != null) {
          setState(() {
            _selectedImages = [compressedImage];
            _isUploadingImages = false;
          });
          _handleCommentInputChanged();
        } else {
          throw const ImageCompressionException('이미지 압축에 실패했습니다.');
        }
      } on ImageCompressionException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(e.message),
                duration: const Duration(seconds: 3),
                behavior: SnackBarBehavior.floating,
              ),
            );
        }
        setState(() {
          _isUploadingImages = false;
          _uploadProgress = 0.0;
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(
                content: Text('이미지 처리 중 오류가 발생했습니다.'),
                duration: Duration(seconds: 3),
                behavior: SnackBarBehavior.floating,
              ),
            );
        }
        setState(() {
          _isUploadingImages = false;
          _uploadProgress = 0.0;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('이미지를 선택하는 중 오류가 발생했습니다'),
              behavior: SnackBarBehavior.floating,
            ),
          );
      }
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

    setState(() {
      _isUploadingImages = true;
      _uploadProgress = 0.0;
    });

    try {
      final List<String> imageUrls = [];
      final String userId = _authCubit.state.userId ?? 'anonymous';
      final String postId = widget.post.id;

      for (int i = 0; i < _selectedImages.length; i++) {
        final XFile image = _selectedImages[i];
        final DateTime now = DateTime.now();
        final String year = now.year.toString();
        final String month = now.month.toString().padLeft(2, '0');
        final String fileName =
            'comments/$year/$month/$postId/${userId}_${now.millisecondsSinceEpoch}.jpg';

        final Reference ref = FirebaseStorage.instance.ref().child(fileName);
        final UploadTask uploadTask = ref.putFile(File(image.path));

        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final double progress = snapshot.bytesTransferred / snapshot.totalBytes;
          final double totalProgress = (i + progress) / _selectedImages.length;
          setState(() {
            _uploadProgress = totalProgress;
          });
        });

        final TaskSnapshot snapshot = await uploadTask;
        final String downloadUrl = await snapshot.ref.getDownloadURL();

        imageUrls.add(downloadUrl);
      }

      return imageUrls;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('이미지 업로드 중 오류가 발생했습니다'),
              behavior: SnackBarBehavior.floating,
            ),
          );
      }
      return [];
    } finally {
      setState(() {
        _isUploadingImages = false;
        _uploadProgress = 0.0;
      });
    }
  }

  // ==================== Share ====================

  void _showShareOptions(Post post) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        final ThemeData theme = Theme.of(context);
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '공유하기',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.link),
                title: const Text('링크 복사'),
                onTap: () {
                  _copyLinkToClipboard(post);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('다른 앱으로 공유'),
                onTap: () {
                  _sharePost(post);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _copyLinkToClipboard(Post post) {
    final Uri shareUri = Uri.parse(
      'https://gongmutalk.app${CommunityRoute.postDetailPathWithId(post.id)}',
    );

    Clipboard.setData(ClipboardData(text: shareUri.toString()));

    if (mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('링크가 클립보드에 복사되었습니다'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  Future<void> _sharePost(Post post) async {
    final String source = post.text.trim();
    final String truncated = source.length > 120 ? '${source.substring(0, 120)}...' : source;
    final String snippet = truncated.replaceAll(RegExp(r'\s+'), ' ').trim();
    final Uri shareUri = Uri.parse(
      'https://gongmutalk.app${CommunityRoute.postDetailPathWithId(post.id)}',
    );

    final String message = snippet.isEmpty ? shareUri.toString() : '$snippet\n\n${shareUri.toString()}';

    try {
      await Share.share(message, subject: '공뮤톡 라운지 글 공유');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('공유하기를 실행할 수 없습니다'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
      }
    }
  }

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
