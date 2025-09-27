import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/community_repository.dart';
import '../../data/mock_social_graph.dart';
import '../../domain/models/comment.dart';
import '../../domain/models/feed_filters.dart';
import '../../domain/models/post.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../profile/domain/career_track.dart';
import '../../../../routing/app_router.dart';
import 'comment_utils.dart';

enum _AuthorMenuAction { viewProfile, toggleFollow }

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
  bool _isExpanded = false;
  bool _showComments = false;
  bool _isLoadingComments = false;
  bool _commentsLoaded = false;
  List<Comment> _featuredComments = const <Comment>[];
  List<Comment> _timelineComments = const <Comment>[];
  late int _commentCount;
  bool _hasTrackedInteraction = false;
  late final TextEditingController _commentController;
  late final FocusNode _commentFocusNode;
  bool _canSubmitComment = false;
  bool _isSubmittingComment = false;
  List<XFile> _selectedImages = [];
  bool _isUploadingImages = false;
  final ImagePicker _imagePicker = ImagePicker();

  late final CommunityRepository _repository;
  late final MockSocialGraph _socialGraph;
  late final AuthCubit _authCubit;

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

  @override
  Widget build(BuildContext context) {
    final Post post = widget.post;
    final ThemeData theme = Theme.of(context);
    final String timestamp = _formatTimestamp(post.createdAt);
    final bool showMoreButton = !_isExpanded && _shouldShowMore(post.text, context);
    final Widget? trailingActions = _buildTrailingActions(theme, post);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  fit: FlexFit.loose,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _buildAuthorMenu(
                      post: post,
                      timestamp: timestamp,
                      scope: widget.displayScope,
                    ),
                  ),
                ),
              ],
            ),
            const Gap(14),
            if (_isExpanded)
              Text(post.text, style: theme.textTheme.bodyLarge)
            else if (showMoreButton)
              _buildTextWithInlineMore(
                post.text,
                theme.textTheme.bodyLarge!,
                theme.colorScheme.primary,
              )
            else
              Text(
                post.text,
                style: theme.textTheme.bodyLarge,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
            if (post.tags.isNotEmpty) ...[
              const Gap(10),
              Wrap(
                spacing: 6,
                runSpacing: -8,
                children: post.tags
                    .map(
                      (String tag) =>
                          Chip(label: Text('#$tag'), visualDensity: VisualDensity.compact),
                    )
                    .toList(growable: false),
              ),
            ],
            if (post.media.isNotEmpty) ...[const Gap(12), _PostMediaPreview(mediaList: post.media)],
            const Gap(16),
            Row(
              children: [
                _PostActionButton(
                  icon: post.isLiked ? Icons.favorite : Icons.favorite_border,
                  label: '${post.likeCount}',
                  isHighlighted: post.isLiked,
                  onPressed: _handleLikeTap,
                ),
                const Gap(16),
                IconButton(
                  icon: const Icon(Icons.mode_comment_outlined, size: 16),
                  onPressed: _handleCommentButton,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  constraints: const BoxConstraints(minHeight: 32, minWidth: 32),
                  iconSize: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const Gap(16),
                _PostActionButton(
                  icon: Icons.visibility_outlined,
                  label: '${post.viewCount}',
                  onPressed: null,
                ),
                const Spacer(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        post.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                        size: 16,
                      ),
                      onPressed: _handleBookmarkTap,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      constraints: const BoxConstraints(minHeight: 32, minWidth: 32),
                      iconSize: 16,
                      color: post.isBookmarked
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    IconButton(
                      icon: const Icon(Icons.share_outlined, size: 16),
                      onPressed: () => _handleShare(post),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      constraints: const BoxConstraints(minHeight: 32, minWidth: 32),
                      iconSize: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    if (trailingActions != null) trailingActions,
                  ],
                ),
              ],
            ),
            // Comment writing UI positioned directly below action buttons
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: !_showComments
                  ? const SizedBox.shrink()
                  : Builder(
                      builder: (BuildContext context) {
                        final Widget? composer = _buildCommentComposer(context);
                        if (composer != null) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: composer,
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
            ),
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
                      child: Builder(
                        builder: (BuildContext context) {
                          final ThemeData theme = Theme.of(context);
                          final List<Widget> sectionChildren = <Widget>[const Gap(12)];

                          if (_isLoadingComments) {
                            sectionChildren.add(const Center(child: CircularProgressIndicator()));
                          } else if (_timelineComments.isEmpty) {
                            sectionChildren.add(
                              Text('아직 댓글이 없습니다. 첫 댓글을 남겨보세요!', style: theme.textTheme.bodyMedium),
                            );
                          } else {
                            final Map<String, List<Comment>> replies = <String, List<Comment>>{};
                            final List<Comment> roots = <Comment>[];
                            final List<Comment> orphans = <Comment>[];

                            for (final Comment comment in _timelineComments) {
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

                            final List<Widget> threadedComments = roots
                                .map((Comment comment) {
                                  final List<Comment> children =
                                      replies[comment.id] ?? const <Comment>[];
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _CommentTile(
                                        comment: comment,
                                        highlight: _isFeatured(comment),
                                        scope: widget.displayScope,
                                        onToggleLike: _handleCommentLike,
                                        onReply: _handleReplyTap,
                                        onOpenProfile: () => _handleMemberTap(
                                          uid: comment.authorUid,
                                          nickname: comment.authorNickname,
                                        ),
                                      ),
                                      if (children.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(left: 24),
                                          child: Column(
                                            children: children
                                                .map(
                                                  (Comment reply) => _CommentTile(
                                                    comment: reply,
                                                    highlight: _isFeatured(reply),
                                                    scope: widget.displayScope,
                                                    isReply: true,
                                                    onToggleLike: _handleCommentLike,
                                                    onReply: _handleReplyTap,
                                                    onOpenProfile: () => _handleMemberTap(
                                                      uid: reply.authorUid,
                                                      nickname: reply.authorNickname,
                                                    ),
                                                  ),
                                                )
                                                .toList(growable: false),
                                          ),
                                        ),
                                    ],
                                  );
                                })
                                .toList(growable: false);

                            sectionChildren.add(
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: threadedComments,
                              ),
                            );
                          }


                          return Column(
                            key: const ValueKey<String>('comment-section'),
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: sectionChildren,
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  bool _shouldShowMore(String text, BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyLarge!;
    final textSpan = TextSpan(text: text, style: textStyle);
    final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr, maxLines: 5);

    // Get the available width (approximate card content width)
    final screenWidth = MediaQuery.of(context).size.width;
    final cardPadding = 32.0; // Card padding (16 * 2)
    final cardMargin = 24.0; // Card margin
    final availableWidth = screenWidth - cardPadding - cardMargin;

    textPainter.layout(maxWidth: availableWidth);
    return textPainter.didExceedMaxLines;
  }

  Widget _buildTextWithInlineMore(String text, TextStyle textStyle, Color primaryColor) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 간단한 접근: 먼저 기본 5줄 텍스트 표시하고 "더보기" 버튼 추가
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(text, style: textStyle, maxLines: 5, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: _handleExpand,
              child: Text(
                '더보기',
                style: textStyle.copyWith(color: primaryColor, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        );
      },
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

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      // 최대 4개 이미지까지만 허용
      final List<XFile> limitedImages = images.take(4).toList();

      setState(() {
        _selectedImages = limitedImages;
      });

      _handleCommentInputChanged(); // 제출 버튼 상태 업데이트
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('이미지를 선택하는 중 오류가 발생했습니다'),
              duration: Duration(seconds: 2),
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
    });

    try {
      final List<String> imageUrls = [];
      final String userId = _authCubit.state.userId ?? 'anonymous';
      final String postId = widget.post.id;

      for (int i = 0; i < _selectedImages.length; i++) {
        final XFile image = _selectedImages[i];
        final String fileName = 'comments/$postId/${userId}_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';

        final Reference ref = FirebaseStorage.instance.ref().child(fileName);
        final UploadTask uploadTask = ref.putFile(File(image.path));
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
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
      }
      return [];
    } finally {
      setState(() {
        _isUploadingImages = false;
      });
    }
  }

  Widget? _buildCommentComposer(BuildContext context) {
    if (_isSynthetic(widget.post)) {
      return null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _commentController,
          focusNode: _commentFocusNode,
          minLines: 1,
          maxLines: 4,
          textInputAction: TextInputAction.newline,
          decoration: InputDecoration(
            hintText: '댓글을 입력하세요...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            suffixIcon: IconButton(
              icon: const Icon(Icons.image_outlined),
              onPressed: _pickImages,
              tooltip: '이미지 첨부',
            ),
          ),
        ),
        if (_selectedImages.isNotEmpty) ...[
          const Gap(8),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: EdgeInsets.only(right: index < _selectedImages.length - 1 ? 8 : 0),
                  width: 80,
                  height: 80,
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(_selectedImages[index].path),
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
        const Gap(8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (_isUploadingImages)
              const Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  Gap(8),
                  Text('이미지 업로드 중...'),
                ],
              )
            else
              const SizedBox.shrink(),
            FilledButton(
              onPressed: _canSubmitComment && !_isSubmittingComment ? _submitComment : null,
              child: _isSubmittingComment
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('등록'),
            ),
          ],
        ),
      ],
    );
  }

  Widget? _buildTrailingActions(ThemeData theme, Post post) {
    final Widget? customTrailing = widget.trailing;
    final List<Widget> grouped = <Widget>[];

    if (widget.showShare) {
      grouped.add(
        IconButton(
          iconSize: 20,
          constraints: const BoxConstraints(minHeight: 36, minWidth: 36),
          padding: const EdgeInsets.all(6),
          icon: const Icon(Icons.share_outlined),
          tooltip: '공유하기',
          color: theme.colorScheme.onSurfaceVariant,
          onPressed: () => _handleShare(post),
        ),
      );
    }

    if (customTrailing == null && widget.showBookmark) {
      grouped.add(
        IconButton(
          iconSize: 20,
          constraints: const BoxConstraints(minHeight: 36, minWidth: 36),
          padding: const EdgeInsets.all(6),
          icon: Icon(post.isBookmarked ? Icons.bookmark : Icons.bookmark_outline),
          color: post.isBookmarked ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
          onPressed: _handleBookmarkTap,
        ),
      );
    }

    final Widget? groupedWidget = grouped.isEmpty
        ? null
        : DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < grouped.length; i++) ...[if (i > 0) const Gap(4), grouped[i]],
                ],
              ),
            ),
          );

    if (customTrailing == null) {
      return groupedWidget;
    }

    if (groupedWidget == null) {
      return customTrailing;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [groupedWidget, const Gap(8), customTrailing],
    );
  }

  Future<void> _toggleComments() async {
    if (_showComments) {
      setState(() => _showComments = false);
      return;
    }

    setState(() => _showComments = true);
    await _loadComments();
  }

  bool _isSynthetic(Post post) {
    return post.id.startsWith('dummy_') || post.authorUid == 'dummy_user';
  }

  bool _isFeatured(Comment comment) {
    return _featuredComments.any((Comment featured) => featured.id == comment.id);
  }

  List<Comment> _applyRandomLikes(List<Comment> comments) {
    final Random random = Random();
    return comments.map((Comment comment) {
      final int randomLikes = random.nextInt(50) + 1; // 1-50 사이의 무작위 좋아요 수
      return comment.copyWith(likeCount: randomLikes);
    }).toList();
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

      // 가장 많은 좋아요를 받은 댓글을 베스트로 선택
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
                (Comment element) => element.id == comment.id,
                orElse: () => comment,
              );
            }
            return comment;
          })
          .toList(growable: false);

      if (!mounted) {
        return;
      }
      setState(() {
        _featuredComments = _applyRandomLikes(featured);
        _timelineComments = _applyRandomLikes(mergedTimeline);
        _commentsLoaded = true;
        _isLoadingComments = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _isLoadingComments = false);
    }
  }

  void _handleExpand() {
    _registerInteraction();
    setState(() => _isExpanded = true);
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

    // 스낵바 표시
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              isCurrentlyBookmarked ? '북마크가 해제되었습니다' : '북마크에 추가되었습니다',
            ),
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


  Future<void> _submitComment() async {
    final String text = _commentController.text.trim();
    if ((text.isEmpty && _selectedImages.isEmpty) || _isSubmittingComment) {
      return;
    }

    _registerInteraction();
    setState(() => _isSubmittingComment = true);

    try {
      // 이미지 업로드 먼저 처리
      List<String> imageUrls = [];
      if (_selectedImages.isNotEmpty) {
        imageUrls = await _uploadImages();
        if (imageUrls.isEmpty && _selectedImages.isNotEmpty) {
          // 이미지 업로드에 실패했다면 중단
          setState(() => _isSubmittingComment = false);
          return;
        }
      }

      // 댓글 작성 (이미지 URL 포함)
      await _repository.addComment(widget.post.id, text, imageUrls: imageUrls);

      if (!mounted) {
        return;
      }

      // UI 상태 초기화
      _commentController.clear();
      _commentFocusNode.unfocus();
      setState(() {
        _commentCount += 1;
        _canSubmitComment = false;
        _showComments = true;
        _selectedImages.clear(); // 선택된 이미지들 클리어
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

  void _registerInteraction() {
    if (_hasTrackedInteraction || _isSynthetic(widget.post)) {
      return;
    }
    _hasTrackedInteraction = true;
    unawaited(_repository.incrementViewCount(widget.post.id));
  }

  void _handleReplyTap(Comment comment) {
    _registerInteraction();
    if (_isSynthetic(widget.post)) {
      _showSnack(context, '프리뷰 게시물에는 답글을 남길 수 없어요.');
      return;
    }
    unawaited(_showReplySheet(comment));
  }

  Future<void> _showReplySheet(Comment comment) async {
    final bool? added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) => _InlineReplySheet(
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

  Future<void> _handleCommentLike(Comment comment) async {
    _registerInteraction();
    final bool willLike = !comment.isLiked;
    final int nextCount = max(0, comment.likeCount + (willLike ? 1 : -1));

    void updateLists(bool liked, int likeCount) {
      _timelineComments = _timelineComments
          .map(
            (Comment c) =>
                c.id == comment.id ? c.copyWith(isLiked: liked, likeCount: likeCount) : c,
          )
          .toList(growable: false);
      _featuredComments = _featuredComments
          .map(
            (Comment c) =>
                c.id == comment.id ? c.copyWith(isLiked: liked, likeCount: likeCount) : c,
          )
          .toList(growable: false);
    }

    setState(() => updateLists(willLike, nextCount));

    if (_isSynthetic(widget.post)) {
      return;
    }

    try {
      await _repository.toggleCommentLikeById(widget.post.id, comment.id);
    } catch (_) {
      setState(() => updateLists(!willLike, comment.likeCount));
    }
  }

  Future<void> _handleMemberTap({required String uid, required String nickname}) async {
    if (uid.isEmpty) {
      return;
    }

    if (uid == 'preview') {
      if (mounted) {
        _showSnack(context, '프리뷰 데이터라 프로필을 열 수 없어요.');
      }
      return;
    }

    await _showMemberActions(uid: uid, nickname: nickname);
  }

  Widget _buildAuthorMenu({
    required Post post,
    required String timestamp,
    required LoungeScope scope,
  }) {
    final MockSocialGraph socialGraph = _socialGraph;
    final AuthState authState = _authCubit.state;
    final String? currentUid = authState.userId;
    final bool isSelf = currentUid != null && currentUid == post.authorUid;
    final bool canFollow =
        authState.isLoggedIn &&
        currentUid != null &&
        currentUid.isNotEmpty &&
        !isSelf &&
        post.authorUid.isNotEmpty &&
        post.authorUid != 'preview';
    final bool isFollowing = canFollow && socialGraph.isFollowing(post.authorUid);

    final ThemeData theme = Theme.of(context);
    final TextStyle timestampStyle =
        theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant) ??
        TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 11);

    final Widget timestampLabel = Text(timestamp, style: timestampStyle);
    final Widget identityButton = PopupMenuButton<_AuthorMenuAction>(
      tooltip: '작성자 옵션',
      position: PopupMenuPosition.under,
      padding: EdgeInsets.zero,
      itemBuilder: (BuildContext context) {
        return <PopupMenuEntry<_AuthorMenuAction>>[
          const PopupMenuItem<_AuthorMenuAction>(
            value: _AuthorMenuAction.viewProfile,
            child: Row(children: [Icon(Icons.person_outline, size: 18), Gap(8), Text('프로필 보기')]),
          ),
          if (canFollow)
            PopupMenuItem<_AuthorMenuAction>(
              value: _AuthorMenuAction.toggleFollow,
              child: Row(
                children: [
                  Icon(
                    isFollowing
                        ? Icons.person_remove_alt_1_outlined
                        : Icons.person_add_alt_1_outlined,
                    size: 18,
                  ),
                  const Gap(8),
                  Text(isFollowing ? '팔로우 취소하기' : '팔로우하기'),
                ],
              ),
            ),
        ];
      },
      onSelected: (action) async {
        switch (action) {
          case _AuthorMenuAction.viewProfile:
            if (post.authorUid.isEmpty || post.authorUid == 'preview') {
              if (mounted) {
                _showSnack(context, '프리뷰 데이터라 프로필을 열 수 없어요.');
              }
              return;
            }
            _openMockProfile(
              context,
              uid: post.authorUid,
              nickname: post.authorNickname,
              socialGraph: socialGraph,
            );
            break;
          case _AuthorMenuAction.toggleFollow:
            await _toggleFollow(
              socialGraph: socialGraph,
              targetUid: post.authorUid,
              nickname: post.authorNickname,
              isFollowing: isFollowing,
            );
            break;
        }
      },
      child: _AuthorInfoHeader(post: post, scope: scope),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        IntrinsicWidth(child: identityButton),
        const Spacer(),
        timestampLabel,
      ],
    );
  }

  Future<void> _sharePost(Post post) async {
    final String source = post.text.trim();
    final String truncated = source.length > 120 ? '${source.substring(0, 120)}...' : source;
    final String snippet = truncated.replaceAll(RegExp(r'\s+'), ' ').trim();
    final Uri shareUri = Uri.parse(
      'https://gongmutalk.app${CommunityRoute.postDetailPathWithId(post.id)}',
    );

    final String message = snippet.isEmpty
        ? shareUri.toString()
        : '$snippet\n\n${shareUri.toString()}';

    try {
      await Share.share(
        message,
        subject: '공뮤톡 라운지 글 공유',
      );
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

  Future<void> _showMemberActions({required String uid, required String nickname}) async {
    if (!mounted) {
      return;
    }

    final BuildContext hostContext = context;
    final MockSocialGraph socialGraph = _socialGraph;
    final AuthState authState = _authCubit.state;
    final String? currentUid = authState.userId;
    final bool isSelf = currentUid != null && currentUid == uid;
    final bool canFollow =
        authState.isLoggedIn && currentUid != null && currentUid.isNotEmpty && !isSelf;

    if (!mounted) {
      return;
    }

    return showModalBottomSheet<void>(
      context: hostContext,
      useRootNavigator: true,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('프로필 보기'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _openMockProfile(
                    hostContext,
                    uid: uid,
                    nickname: nickname,
                    socialGraph: socialGraph,
                  );
                },
              ),
              if (canFollow)
                ListTile(
                  leading: Icon(
                    socialGraph.isFollowing(uid)
                        ? Icons.person_remove_alt_1_outlined
                        : Icons.person_add_alt_1_outlined,
                  ),
                  title: Text(socialGraph.isFollowing(uid) ? '팔로우 취소하기' : '팔로우하기'),
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    await _toggleFollow(
                      socialGraph: socialGraph,
                      targetUid: uid,
                      nickname: nickname,
                      isFollowing: socialGraph.isFollowing(uid),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _toggleFollow({
    required MockSocialGraph socialGraph,
    required String targetUid,
    required String nickname,
    required bool isFollowing,
  }) async {
    if (!mounted) {
      return;
    }

    final AuthState authState = _authCubit.state;
    final String? currentUid = authState.userId;
    if (currentUid == null || currentUid.isEmpty) {
      _showSnack(context, '로그인이 필요합니다.');
      return;
    }

    try {
      final bool nowFollowing = await socialGraph.toggleFollow(
        targetUid,
        shouldFollow: !isFollowing,
      );
      if (!mounted) {
        return;
      }
      _showSnack(context, nowFollowing ? '$nickname 님을 팔로우했어요.' : '$nickname 님을 팔로우 취소했어요.');
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showSnack(context, '요청을 처리하지 못했어요. 잠시 후 다시 시도해주세요.');
    }
  }

  void _openMockProfile(
    BuildContext context, {
    required String uid,
    required String nickname,
    required MockSocialGraph socialGraph,
  }) {
    final MockMemberProfileData? profile = socialGraph.getProfile(uid);
    if (profile == null) {
      _showSnack(context, '$nickname 님의 정보를 찾을 수 없어요.');
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _MockMemberProfileScreen(profile: profile, socialGraph: socialGraph),
      ),
    );
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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

Widget _buildCommentIdentityRow({
  required ThemeData theme,
  required Comment comment,
  required String timestamp,
  required LoungeScope scope,
  required bool includeAvatar,
  bool showTimestamp = true,
  bool isReply = false,
}) {
  final bool isSerialScope = scope == LoungeScope.serial;

  if (isSerialScope) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (includeAvatar) ...[
          CircleAvatar(
            radius: 16,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
            foregroundColor: theme.colorScheme.primary,
            child: Text(maskNickname(comment.authorNickname).substring(0, 1)),
          ),
          const Gap(12),
        ],
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (comment.authorIsSupporter) ...[
                Icon(Icons.verified, size: 16, color: theme.colorScheme.primary),
                const Gap(4),
              ],
              Expanded(
                child: Text(
                  comment.authorNickname,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isSerialScope && showTimestamp) ...[
                Text(
                  timestamp,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  final bool hasTrack = comment.authorSerialVisible && comment.authorTrack != CareerTrack.none;
  final Color background = hasTrack
      ? theme.colorScheme.primary.withValues(alpha: 0.12)
      : theme.colorScheme.surfaceContainerHighest;
  final Color foreground = hasTrack
      ? theme.colorScheme.primary
      : theme.colorScheme.onSurfaceVariant;
  final String trackLabel = serialLabel(
    comment.authorTrack,
    comment.authorSerialVisible,
    includeEmoji: hasTrack,
  );
  final Widget? supporterIcon = comment.authorIsSupporter
      ? Icon(Icons.verified, size: 16, color: theme.colorScheme.primary)
      : null;
  final String maskedName = maskNickname(
    comment.authorNickname.isNotEmpty ? comment.authorNickname : comment.authorUid,
  );

  return Row(
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
        child: Text(
          trackLabel,
          style: theme.textTheme.labelSmall?.copyWith(
            color: foreground,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      const Gap(8),
      Expanded(
        child: Row(
          children: [
            if (supporterIcon != null) ...[supporterIcon, const Gap(6)],
            Expanded(
              child: Text(
                maskedName,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      if (showTimestamp) ...[
        const Gap(8),
        Text(
          timestamp,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    ],
  );
}

class _AuthorInfoHeader extends StatelessWidget {
  const _AuthorInfoHeader({required this.post, required this.scope});

  final Post post;
  final LoungeScope scope;

  bool get _isSerialScope => scope == LoungeScope.serial;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 12, top: 4, bottom: 4),
      child: _isSerialScope ? _buildSerialHeader(theme) : _buildPublicHeader(theme),
    );
  }

  Widget _buildSerialHeader(ThemeData theme) {
    final Widget? supporter = _buildSupporterBadge(theme);
    final TextStyle nameStyle =
        theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600) ??
        const TextStyle(fontSize: 15, fontWeight: FontWeight.w600);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
          foregroundColor: theme.colorScheme.primary,
          child: Text(_avatarInitial(), style: nameStyle),
        ),
        const Gap(10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (supporter != null) ...[supporter, const Gap(6)],
                  Expanded(
                    child: Text(
                      post.authorNickname,
                      style: nameStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (scope != LoungeScope.serial) ...[
                const Gap(2),
                Text(
                  serialLabel(post.authorTrack, post.authorSerialVisible, includeEmoji: true),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPublicHeader(ThemeData theme) {
    final Widget? supporter = _buildSupporterBadge(theme);
    final TextStyle nameStyle =
        theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600) ??
        const TextStyle(fontSize: 14, fontWeight: FontWeight.w600);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTrackTag(theme),
        const Gap(6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 220),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (supporter != null) ...[supporter, const Gap(6)],
              Flexible(
                child: Text(_maskedUid(), style: nameStyle, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrackTag(ThemeData theme) {
    final bool hasTrack = post.authorSerialVisible && post.authorTrack != CareerTrack.none;
    final Color background = hasTrack
        ? theme.colorScheme.primary.withValues(alpha: 0.12)
        : theme.colorScheme.surfaceContainerHighest;
    final Color foreground = hasTrack
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;
    final String label = serialLabel(
      post.authorTrack,
      post.authorSerialVisible,
      includeEmoji: hasTrack,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(color: foreground, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget? _buildSupporterBadge(ThemeData theme) {
    if (!post.authorIsSupporter) {
      return null;
    }
    final int level = post.authorSupporterLevel;
    return Tooltip(
      message: level > 0 ? '후원자 레벨 $level' : '후원자',
      child: Icon(Icons.verified, size: 18, color: theme.colorScheme.primary),
    );
  }

  String _maskedUid() {
    final String fallback = post.authorNickname.isNotEmpty ? post.authorNickname : post.authorUid;
    return maskNickname(fallback);
  }

  String _avatarInitial() {
    final String normalized = post.authorNickname.trim();
    if (normalized.isEmpty) {
      return '공';
    }
    return String.fromCharCode(normalized.runes.first).toUpperCase();
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.comment,
    this.highlight = false,
    required this.scope,
    required this.onToggleLike,
    this.onReply,
    this.isReply = false,
    required this.onOpenProfile,
  });

  final Comment comment;
  final bool highlight;
  final LoungeScope scope;
  final ValueChanged<Comment> onToggleLike;
  final ValueChanged<Comment>? onReply;
  final bool isReply;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String timestamp = _formatTimestamp(comment.createdAt);

    return Align(
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: isReply ? 0.92 : 0.98,
        child: Container(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.fromLTRB(6, 2, 6, 0),
          decoration: null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              scope == LoungeScope.serial
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: onOpenProfile,
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              child: _buildCommentIdentityRow(
                                theme: theme,
                                comment: comment,
                                timestamp: timestamp,
                                scope: scope,
                                includeAvatar: scope == LoungeScope.serial && !isReply,
                                showTimestamp: false,
                                isReply: isReply,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            timestamp,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    )
                  : InkWell(
                      onTap: onOpenProfile,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: _buildCommentIdentityRow(
                          theme: theme,
                          comment: comment,
                          timestamp: timestamp,
                          scope: scope,
                          includeAvatar: scope == LoungeScope.serial && !isReply,
                          isReply: isReply,
                        ),
                      ),
                    ),
              const Gap(4),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(comment.text, style: theme.textTheme.bodyMedium?.copyWith(height: 1.3)),
              ),
              const Gap(4),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (highlight) ...[
                    Icon(
                      Icons.local_fire_department,
                      size: 16,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors
                                .orange
                                .shade300 // 다크모드에서 더 밝은 주황색
                          : Colors.deepOrange.shade600, // 라이트모드에서 진한 주황색
                    ),
                    const Gap(4),
                  ],
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => onToggleLike(comment),
                    icon: Icon(
                      comment.isLiked ? Icons.favorite : Icons.favorite_border,
                      size: 16,
                      color: comment.isLiked
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    label: Text(
                      '${comment.likeCount}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: comment.isLiked
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (onReply != null)
                    IconButton(
                      tooltip: '답글 달기',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minHeight: 32, minWidth: 32),
                      visualDensity: VisualDensity.compact,
                      iconSize: 18,
                      onPressed: () => onReply!(comment),
                      icon: const Icon(Icons.reply_outlined),
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                ],
              ),
            ],
          ),
        ),
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

class _InlineReplySheet extends StatefulWidget {
  const _InlineReplySheet({
    required this.postId,
    required this.target,
    required this.repository,
    required this.scope,
  });

  final String postId;
  final Comment target;
  final CommunityRepository repository;
  final LoungeScope scope;

  @override
  State<_InlineReplySheet> createState() => _InlineReplySheetState();
}

class _InlineReplySheetState extends State<_InlineReplySheet> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final String rawNickname = widget.target.authorNickname.trim().isNotEmpty
        ? widget.target.authorNickname.trim()
        : widget.target.authorUid;
    final String mention = '@$rawNickname ';
    _controller = TextEditingController(text: mention)
      ..selection = TextSelection.collapsed(offset: mention.length);
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final Comment target = widget.target;
    final bool isSerialScope = widget.scope == LoungeScope.serial;
    final String nicknameSource = target.authorNickname.isNotEmpty
        ? target.authorNickname
        : target.authorUid;
    final String displayName = isSerialScope ? target.authorNickname : maskNickname(nicknameSource);
    final String preview = target.text.trim();

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '답글 작성',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Gap(12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Gap(6),
                    Text(
                      preview.isEmpty ? '내용이 없는 댓글' : preview,
                      style: theme.textTheme.bodySmall,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Gap(12),
              TextField(
                controller: _controller,
                focusNode: _focusNode,
                minLines: 3,
                maxLines: 6,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: '답글을 입력하세요',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const Gap(12),
              Row(
                children: [
                  TextButton(
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
                    child: const Text('취소'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('등록'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final String text = _controller.text.trim();
    if (text.isEmpty || _isSubmitting) {
      return;
    }
    setState(() => _isSubmitting = true);

    try {
      final Comment target = widget.target;
      final String? parentId = target.parentCommentId?.isNotEmpty == true
          ? target.parentCommentId
          : target.id;
      await widget.repository.addComment(widget.postId, text, parentCommentId: parentId);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('답글을 저장하지 못했어요. 잠시 후 다시 시도해주세요.')));
    }
  }
}

class _MockMemberProfileScreen extends StatefulWidget {
  const _MockMemberProfileScreen({required this.profile, required this.socialGraph});

  final MockMemberProfileData profile;
  final MockSocialGraph socialGraph;

  @override
  State<_MockMemberProfileScreen> createState() => _MockMemberProfileScreenState();
}

class _MockMemberProfileScreenState extends State<_MockMemberProfileScreen> {
  bool _isProcessing = false;

  bool get _isFollowing => widget.socialGraph.isFollowing(widget.profile.uid);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.profile.nickname),
        actions: [
          TextButton.icon(
            onPressed: _isProcessing ? null : _handleFollowToggle,
            icon: _isProcessing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    _isFollowing
                        ? Icons.person_remove_alt_1_outlined
                        : Icons.person_add_alt_1_outlined,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
            label: Text(
              _isFollowing ? '팔로잉' : '팔로우',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(radius: 32, child: Text(widget.profile.nickname.substring(0, 1))),
                const Gap(20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.profile.nickname,
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const Gap(8),
                      Text(
                        '${widget.profile.track.emoji} ${widget.profile.track.displayName}',
                        style: theme.textTheme.titleMedium,
                      ),
                      const Gap(4),
                      Text(
                        '${widget.profile.department} · ${widget.profile.region}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Gap(24),
            Text('소개', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const Gap(8),
            Text(widget.profile.bio, style: theme.textTheme.bodyLarge),
            if (widget.profile.tags.isNotEmpty) ...[
              const Gap(16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.profile.tags
                    .map((String tag) => Chip(label: Text('#$tag')))
                    .toList(growable: false),
              ),
            ],
            const Gap(24),
            Text(
              '최근 이야기',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const Gap(12),
            if (widget.profile.recentPosts.isEmpty)
              Text('아직 공유된 글이 없어요.', style: theme.textTheme.bodyMedium)
            else
              ...widget.profile.recentPosts.map(
                (String post) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(post, style: theme.textTheme.bodyLarge),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleFollowToggle() async {
    setState(() => _isProcessing = true);
    try {
      await widget.socialGraph.toggleFollow(widget.profile.uid, shouldFollow: !_isFollowing);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(_isFollowing ? '팔로우를 취소했어요.' : '새로 팔로우하기 시작했어요.')));
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}

class _PostActionButton extends StatelessWidget {
  const _PostActionButton({
    required this.icon,
    required this.label,
    this.onPressed,
    this.isHighlighted = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color iconColor = isHighlighted ? colorScheme.primary : colorScheme.onSurfaceVariant;
    final Widget iconWidget = AnimatedScale(
      duration: const Duration(milliseconds: 180),
      scale: isHighlighted ? 1.1 : 1,
      curve: Curves.easeOutBack,
      child: Icon(icon, size: 16, color: iconColor),
    );

    final TextStyle labelStyle =
        Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(color: iconColor, fontWeight: FontWeight.w600) ??
        TextStyle(color: iconColor, fontWeight: FontWeight.w600);

    final Widget labelWidget = AnimatedSwitcher(
      duration: const Duration(milliseconds: 160),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: Text(label, key: ValueKey<String>(label), style: labelStyle),
    );

    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: Size.zero,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: iconWidget,
      label: labelWidget,
    );
  }
}

class _PostMediaPreview extends StatelessWidget {
  const _PostMediaPreview({required this.mediaList});

  final List<PostMedia> mediaList;

  @override
  Widget build(BuildContext context) {
    if (mediaList.length == 1) {
      final PostMedia media = mediaList.first;
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: media.thumbnailUrl ?? media.url,
          placeholder: (context, url) => Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            height: 180,
            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          errorWidget: (context, url, error) => const Icon(Icons.broken_image_outlined, size: 48),
          fit: BoxFit.cover,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: mediaList.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
        ),
        itemBuilder: (context, index) {
          final PostMedia media = mediaList[index];
          return CachedNetworkImage(
            imageUrl: media.thumbnailUrl ?? media.url,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            errorWidget: (context, url, error) => const Icon(Icons.broken_image_outlined),
          );
        },
      ),
    );
  }
}
