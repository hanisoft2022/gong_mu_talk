import 'dart:async';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../di/di.dart';
import '../../data/community_repository.dart';
import '../../data/mock_social_graph.dart';
import '../../domain/models/comment.dart';
import '../../domain/models/feed_filters.dart';
import '../../domain/models/post.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../profile/domain/career_track.dart';
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

  CommunityRepository get _repository => getIt<CommunityRepository>();

  @override
  void initState() {
    super.initState();
    _commentCount = widget.post.commentCount;
  }

  @override
  void didUpdateWidget(covariant PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.post.id != oldWidget.post.id) {
      setState(() {
        _commentCount = widget.post.commentCount;
        _isExpanded = false;
        _showComments = false;
        _isLoadingComments = false;
        _commentsLoaded = false;
        _featuredComments = const <Comment>[];
        _timelineComments = const <Comment>[];
        _hasTrackedInteraction = false;
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
    final bool showMoreButton = !_isExpanded && _shouldShowMore(post.text);

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
            Text(
              post.text,
              style: theme.textTheme.bodyLarge,
              maxLines: _isExpanded ? null : 3,
              overflow: _isExpanded ? null : TextOverflow.ellipsis,
            ),
            if (showMoreButton)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _handleExpand,
                  child: const Text('더보기'),
                ),
              ),
            if (post.tags.isNotEmpty) ...[
              const Gap(10),
              Wrap(
                spacing: 6,
                runSpacing: -8,
                children: post.tags
                    .map(
                      (String tag) => Chip(
                        label: Text('#$tag'),
                        visualDensity: VisualDensity.compact,
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
            if (post.media.isNotEmpty) ...[
              const Gap(12),
              _PostMediaPreview(mediaList: post.media),
            ],
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
                _PostActionButton(
                  icon: Icons.mode_comment_outlined,
                  label: '$_commentCount',
                  onPressed: _commentCount == 0 ? null : _handleCommentButton,
                ),
                const Gap(16),
                _PostActionButton(
                  icon: Icons.visibility_outlined,
                  label: '${post.viewCount}',
                  onPressed: null,
                ),
                const Spacer(),
                ..._buildTrailingActions(theme, post),
              ],
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
                      child: Column(
                        key: const ValueKey<String>('comment-section'),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Gap(12),
                          if (_isLoadingComments)
                            const Center(child: CircularProgressIndicator())
                          else if (_timelineComments.isEmpty)
                            Text(
                              '아직 댓글이 없습니다. 첫 댓글을 남겨보세요!',
                              style: theme.textTheme.bodyMedium,
                            )
                          else ...[
                            if (_featuredComments.isNotEmpty) ...[
                              Builder(
                                builder: (BuildContext context) {
                                  final Comment featuredComment =
                                      _featuredComments.first;
                                  return _FeaturedCommentTile(
                                    comment: featuredComment,
                                    scope: widget.displayScope,
                                    onToggleLike: _handleCommentLike,
                                    onReply: _handleReplyTap,
                                    onOpenProfile: () => _handleMemberTap(
                                      uid: featuredComment.authorUid,
                                      nickname: featuredComment.authorNickname,
                                    ),
                                  );
                                },
                              ),
                              const Gap(12),
                            ],
                            Builder(
                              builder: (BuildContext context) {
                                final Map<String, List<Comment>> replies =
                                    <String, List<Comment>>{};
                                final List<Comment> roots = <Comment>[];
                                final List<Comment> orphans = <Comment>[];

                                for (final Comment comment
                                    in _timelineComments) {
                                  final String? parentId =
                                      comment.parentCommentId;
                                  if (comment.isReply &&
                                      parentId != null &&
                                      parentId.isNotEmpty) {
                                    replies
                                        .putIfAbsent(
                                          parentId,
                                          () => <Comment>[],
                                        )
                                        .add(comment);
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
                                          replies[comment.id] ??
                                          const <Comment>[];
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _CommentTile(
                                            comment: comment,
                                            highlight: _isFeatured(comment),
                                            scope: widget.displayScope,
                                            onToggleLike: _handleCommentLike,
                                            onReply: _handleReplyTap,
                                            onOpenProfile: () =>
                                                _handleMemberTap(
                                                  uid: comment.authorUid,
                                                  nickname:
                                                      comment.authorNickname,
                                                ),
                                          ),
                                          if (children.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                left: 32,
                                              ),
                                              child: Column(
                                                children: children
                                                    .map(
                                                      (
                                                        Comment reply,
                                                      ) => _CommentTile(
                                                        comment: reply,
                                                        highlight: _isFeatured(
                                                          reply,
                                                        ),
                                                        scope:
                                                            widget.displayScope,
                                                        isReply: true,
                                                        onToggleLike:
                                                            _handleCommentLike,
                                                        onReply:
                                                            _handleReplyTap,
                                                        onOpenProfile: () =>
                                                            _handleMemberTap(
                                                              uid: reply
                                                                  .authorUid,
                                                              nickname: reply
                                                                  .authorNickname,
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

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: threadedComments,
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  bool _shouldShowMore(String text) {
    if (text.trim().split('\n').length > 3) {
      return true;
    }
    return text.trim().length > 120;
  }

  List<Widget> _buildTrailingActions(ThemeData theme, Post post) {
    final List<Widget> actions = <Widget>[];

    if (widget.showShare) {
      actions.add(
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

    if (widget.trailing != null) {
      actions.add(widget.trailing!);
    } else if (widget.showBookmark) {
      actions.add(
        IconButton(
          iconSize: 20,
          constraints: const BoxConstraints(minHeight: 36, minWidth: 36),
          padding: const EdgeInsets.all(6),
          icon: Icon(
            post.isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
          ),
          color: post.isBookmarked
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant,
          onPressed: _handleBookmarkTap,
        ),
      );
    }

    return actions;
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
    return _featuredComments.any(
      (Comment featured) => featured.id == comment.id,
    );
  }

  Future<void> _loadComments({bool force = false}) async {
    if (force) {
      _commentsLoaded = false;
    } else if (_commentsLoaded || _commentCount == 0) {
      return;
    }

    final Post post = widget.post;
    if (_isSynthetic(post)) {
      final List<Comment> syntheticTimeline = List<Comment>.generate(
        post.previewComments.length,
        (int index) => _fromCached(post, post.previewComments[index], index),
      );
      setState(() {
        _featuredComments = syntheticTimeline.take(1).toList(growable: false);
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
      final List<Comment> featured = await _repository.getTopComments(
        widget.post.id,
        limit: 1,
      );
      final List<Comment> timeline = await _repository.getComments(
        widget.post.id,
      );

      final Set<String> featuredIds = featured
          .map((Comment comment) => comment.id)
          .toSet();
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
        _featuredComments = featured;
        _timelineComments = mergedTimeline;
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
    widget.onToggleBookmark();
  }

  void _handleShare(Post post) {
    _registerInteraction();
    _sharePost(post);
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
            (Comment c) => c.id == comment.id
                ? c.copyWith(isLiked: liked, likeCount: likeCount)
                : c,
          )
          .toList(growable: false);
      _featuredComments = _featuredComments
          .map(
            (Comment c) => c.id == comment.id
                ? c.copyWith(isLiked: liked, likeCount: likeCount)
                : c,
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

  Future<void> _handleMemberTap({
    required String uid,
    required String nickname,
  }) async {
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
    final MockSocialGraph socialGraph = getIt<MockSocialGraph>();
    final AuthState authState = getIt<AuthCubit>().state;
    final String? currentUid = authState.userId;
    final bool isSelf = currentUid != null && currentUid == post.authorUid;
    final bool canFollow =
        authState.isLoggedIn &&
        currentUid != null &&
        currentUid.isNotEmpty &&
        !isSelf &&
        post.authorUid.isNotEmpty &&
        post.authorUid != 'preview';
    final bool isFollowing =
        canFollow && socialGraph.isFollowing(post.authorUid);

    return PopupMenuButton<_AuthorMenuAction>(
      tooltip: '작성자 옵션',
      position: PopupMenuPosition.under,
      padding: EdgeInsets.zero,
      itemBuilder: (BuildContext context) {
        return <PopupMenuEntry<_AuthorMenuAction>>[
          const PopupMenuItem<_AuthorMenuAction>(
            value: _AuthorMenuAction.viewProfile,
            child: Row(
              children: [
                Icon(Icons.person_outline, size: 18),
                Gap(8),
                Text('프로필 보기'),
              ],
            ),
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
      child: _AuthorInfoHeader(post: post, timestamp: timestamp, scope: scope),
    );
  }

  void _sharePost(Post post) {
    if (!mounted) {
      return;
    }
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('공유 기능을 준비 중이에요.')));
  }

  Future<void> _showMemberActions({
    required String uid,
    required String nickname,
  }) async {
    if (!mounted) {
      return;
    }

    final BuildContext hostContext = context;
    final MockSocialGraph socialGraph = getIt<MockSocialGraph>();
    final AuthState authState = getIt<AuthCubit>().state;
    final String? currentUid = authState.userId;
    final bool isSelf = currentUid != null && currentUid == uid;
    final bool canFollow =
        authState.isLoggedIn &&
        currentUid != null &&
        currentUid.isNotEmpty &&
        !isSelf;

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
                  title: Text(
                    socialGraph.isFollowing(uid) ? '팔로우 취소하기' : '팔로우하기',
                  ),
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

    final AuthState authState = getIt<AuthCubit>().state;
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
      _showSnack(
        context,
        nowFollowing ? '$nickname 님을 팔로우했어요.' : '$nickname 님을 팔로우 취소했어요.',
      );
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
        builder: (_) => _MockMemberProfileScreen(
          profile: profile,
          socialGraph: socialGraph,
        ),
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
      createdAt: (post.updatedAt ?? post.createdAt).add(
        Duration(minutes: index),
      ),
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
    final String trackLabel = serialLabel(
      comment.authorTrack,
      comment.authorSerialVisible,
      includeEmoji: true,
    );

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
              Text(
                showTimestamp ? '$trackLabel · $timestamp' : trackLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  final bool hasTrack =
      comment.authorSerialVisible && comment.authorTrack != CareerTrack.none;
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
      ? Icon(
          Icons.workspace_premium,
          size: 16,
          color: theme.colorScheme.primary,
        )
      : null;
  final String maskedName = maskNickname(
    comment.authorNickname.isNotEmpty
        ? comment.authorNickname
        : comment.authorUid,
  );

  return Row(
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
        ),
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
            Expanded(
              child: Text(
                maskedName,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (supporterIcon != null) ...[const Gap(6), supporterIcon],
          ],
        ),
      ),
      if (showTimestamp) ...[
        const Gap(8),
        Text(
          timestamp,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ],
  );
}

class _AuthorInfoHeader extends StatelessWidget {
  const _AuthorInfoHeader({
    required this.post,
    required this.timestamp,
    required this.scope,
  });

  final Post post;
  final String timestamp;
  final LoungeScope scope;

  bool get _isSerialScope => scope == LoungeScope.serial;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 12, top: 4, bottom: 4),
      child: _isSerialScope
          ? _buildSerialHeader(theme)
          : _buildPublicHeader(theme),
    );
  }

  Widget _buildSerialHeader(ThemeData theme) {
    final Widget? supporter = _buildSupporterBadge(theme);
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
          foregroundColor: theme.colorScheme.primary,
          child: Text(
            _avatarInitial(),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Gap(12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      post.authorNickname,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (supporter != null) ...[const Gap(6), supporter],
                ],
              ),
              if (!_isSerialScope) ...[
                const Gap(4),
                Text(
                  serialLabel(
                    post.authorTrack,
                    post.authorSerialVisible,
                    includeEmoji: true,
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        const Gap(12),
        Text(
          timestamp,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildPublicHeader(ThemeData theme) {
    final Widget? supporter = _buildSupporterBadge(theme);
    return Row(
      children: [
        _buildTrackTag(theme),
        const Gap(8),
        Text(
          _maskedUid(),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        if (supporter != null) ...[const Gap(6), supporter],
        const Spacer(),
        Text(
          timestamp,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildTrackTag(ThemeData theme) {
    final bool hasTrack =
        post.authorSerialVisible && post.authorTrack != CareerTrack.none;
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w600,
        ),
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
      child: Icon(
        Icons.workspace_premium,
        size: 18,
        color: theme.colorScheme.primary,
      ),
    );
  }

  String _maskedUid() {
    final String fallback = post.authorNickname.isNotEmpty
        ? post.authorNickname
        : post.authorUid;
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

class _FeaturedCommentTile extends StatelessWidget {
  const _FeaturedCommentTile({
    required this.comment,
    required this.scope,
    required this.onToggleLike,
    required this.onOpenProfile,
    this.onReply,
  });

  final Comment comment;
  final LoungeScope scope;
  final ValueChanged<Comment> onToggleLike;
  final VoidCallback onOpenProfile;
  final ValueChanged<Comment>? onReply;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String timestamp = _formatTimestamp(comment.createdAt);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_fire_department_outlined,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const Gap(6),
              Text(
                '베스트 댓글',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(timestamp, style: theme.textTheme.bodySmall),
            ],
          ),
          const Gap(10),
          InkWell(
            onTap: onOpenProfile,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: _buildCommentIdentityRow(
                theme: theme,
                comment: comment,
                timestamp: timestamp,
                scope: scope,
                includeAvatar: scope == LoungeScope.serial,
                showTimestamp: false,
              ),
            ),
          ),
          const Gap(12),
          Text(comment.text, style: theme.textTheme.bodyMedium),
          const Gap(12),
          Row(
            children: [
              TextButton.icon(
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
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
              if (onReply != null) ...[
                const Gap(8),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => onReply!(comment),
                  icon: const Icon(Icons.reply_outlined, size: 16),
                  label: const Text('답글'),
                ),
              ],
            ],
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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: highlight
          ? BoxDecoration(
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
              ),
              borderRadius: BorderRadius.circular(12),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
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
          const Gap(12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(comment.text, style: theme.textTheme.bodyMedium),
          ),
          const Gap(12),
          Row(
            children: [
              TextButton.icon(
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
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
              if (onReply != null) ...[
                const Gap(8),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => onReply!(comment),
                  icon: const Icon(Icons.reply_outlined, size: 16),
                  label: const Text('답글'),
                ),
              ],
            ],
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
    final String displayName = isSerialScope
        ? target.authorNickname
        : maskNickname(nicknameSource);
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
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
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
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
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
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const Gap(12),
              Row(
                children: [
                  TextButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(false),
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
      await widget.repository.addComment(
        widget.postId,
        text,
        parentCommentId: parentId,
      );
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
        ..showSnackBar(
          const SnackBar(content: Text('답글을 저장하지 못했어요. 잠시 후 다시 시도해주세요.')),
        );
    }
  }
}

class _MockMemberProfileScreen extends StatefulWidget {
  const _MockMemberProfileScreen({
    required this.profile,
    required this.socialGraph,
  });

  final MockMemberProfileData profile;
  final MockSocialGraph socialGraph;

  @override
  State<_MockMemberProfileScreen> createState() =>
      _MockMemberProfileScreenState();
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
                CircleAvatar(
                  radius: 32,
                  child: Text(widget.profile.nickname.substring(0, 1)),
                ),
                const Gap(20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.profile.nickname,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
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
            Text(
              '소개',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
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
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
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
      await widget.socialGraph.toggleFollow(
        widget.profile.uid,
        shouldFollow: !_isFollowing,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(_isFollowing ? '팔로우를 취소했어요.' : '새로 팔로우하기 시작했어요.'),
          ),
        );
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
    final Color iconColor = isHighlighted
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;
    final Widget iconWidget = AnimatedScale(
      duration: const Duration(milliseconds: 180),
      scale: isHighlighted ? 1.1 : 1,
      curve: Curves.easeOutBack,
      child: Icon(icon, size: 16, color: iconColor),
    );

    final TextStyle labelStyle =
        Theme.of(context).textTheme.labelMedium?.copyWith(
          color: iconColor,
          fontWeight: FontWeight.w600,
        ) ??
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
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          errorWidget: (context, url, error) =>
              const Icon(Icons.broken_image_outlined, size: 48),
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
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            errorWidget: (context, url, error) =>
                const Icon(Icons.broken_image_outlined),
          );
        },
      ),
    );
  }
}
