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

enum _AuthorMenuAction { viewProfile, toggleFollow }

class PostCard extends StatefulWidget {
  const PostCard({
    super.key,
    required this.post,
    required this.onToggleLike,
    required this.onToggleBookmark,
    this.displayScope = LoungeScope.all,
    this.trailing,
  });

  final Post post;
  final VoidCallback onToggleLike;
  final VoidCallback onToggleBookmark;
  final LoungeScope displayScope;
  final Widget? trailing;

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

  CommunityRepository get _repository => getIt<CommunityRepository>();

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
                  onPressed: () => setState(() => _isExpanded = true),
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
                  onPressed: widget.onToggleLike,
                ),
                const Gap(16),
                _PostActionButton(
                  icon: Icons.mode_comment_outlined,
                  label: '${post.commentCount}',
                  onPressed: post.commentCount == 0
                      ? null
                      : () => _toggleComments(),
                ),
                const Gap(16),
                _PostActionButton(
                  icon: Icons.visibility_outlined,
                  label: '${post.viewCount}',
                  onPressed: null,
                ),
                const Spacer(),
                IconButton(
                  iconSize: 20,
                  constraints: const BoxConstraints(
                    minHeight: 36,
                    minWidth: 36,
                  ),
                  padding: const EdgeInsets.all(6),
                  icon: const Icon(Icons.share_outlined),
                  tooltip: '공유하기',
                  color: theme.colorScheme.onSurfaceVariant,
                  onPressed: () => _sharePost(post),
                ),
                widget.trailing ??
                    IconButton(
                      iconSize: 20,
                      constraints: const BoxConstraints(
                        minHeight: 36,
                        minWidth: 36,
                      ),
                      padding: const EdgeInsets.all(6),
                      icon: Icon(
                        post.isBookmarked
                            ? Icons.bookmark
                            : Icons.bookmark_outline,
                      ),
                      color: post.isBookmarked
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                      onPressed: widget.onToggleBookmark,
                    ),
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
                                    onToggleLike: _handleCommentLike,
                                    onOpenProfile: () => _handleMemberTap(
                                      uid: featuredComment.authorUid,
                                      nickname: featuredComment.authorNickname,
                                    ),
                                  );
                                },
                              ),
                              const Gap(12),
                            ],
                            ..._timelineComments.map(
                              (Comment comment) => _CommentTile(
                                comment: comment,
                                highlight: _isFeatured(comment),
                                onToggleLike: _handleCommentLike,
                                onOpenProfile: () => _handleMemberTap(
                                  uid: comment.authorUid,
                                  nickname: comment.authorNickname,
                                ),
                              ),
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

  Future<void> _toggleComments() async {
    if (_showComments) {
      setState(() => _showComments = false);
      return;
    }

    setState(() => _showComments = true);

    if (_commentsLoaded || widget.post.commentCount == 0) {
      return;
    }

    setState(() {
      _isLoadingComments = true;
    });

    try {
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
              );
            }
            return comment;
          })
          .toList(growable: false);

      setState(() {
        _featuredComments = featured;
        _timelineComments = mergedTimeline;
        _commentsLoaded = true;
        _isLoadingComments = false;
      });
    } catch (_) {
      setState(() => _isLoadingComments = false);
    }
  }

  bool _isSynthetic(Post post) {
    return post.id.startsWith('dummy_') || post.authorUid == 'dummy_user';
  }

  bool _isFeatured(Comment comment) {
    return _featuredComments.any(
      (Comment featured) => featured.id == comment.id,
    );
  }

  Future<void> _handleCommentLike(Comment comment) async {
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
      reactionCounts: const <String, int>{},
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

String _serialLabel(
  CareerTrack track,
  bool serialVisible, {
  bool includeEmoji = true,
}) {
  if (!serialVisible) {
    return '공무원';
  }
  if (track == CareerTrack.none) {
    return '직렬 비공개';
  }
  if (!includeEmoji) {
    return track.displayName;
  }
  return '${track.emoji} ${track.displayName}';
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
              const Gap(4),
              Text(
                _serialLabel(
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
    final String label = _serialLabel(
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
    final String raw = post.authorUid.trim();
    if (raw.isEmpty) {
      return 'USER***';
    }
    final String sanitized = raw.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    final String source = sanitized.isEmpty ? raw : sanitized;
    final String upper = source.toUpperCase();
    final String leading = upper.length <= 3 ? upper : upper.substring(0, 3);
    return '$leading***';
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
    required this.onToggleLike,
    required this.onOpenProfile,
  });

  final Comment comment;
  final ValueChanged<Comment> onToggleLike;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String timestamp = _formatTimestamp(comment.createdAt);
    final String trackLabel = _serialLabel(
      comment.authorTrack,
      comment.authorSerialVisible,
    );
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
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                comment.authorNickname,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const Gap(2),
          Row(
            children: [
              Text(
                trackLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (comment.authorIsSupporter) ...[
                const Gap(4),
                Icon(
                  Icons.workspace_premium,
                  size: 14,
                  color: theme.colorScheme.primary,
                ),
              ],
            ],
          ),
          const Gap(4),
          Text(comment.text, style: theme.textTheme.bodyMedium),
          const Gap(12),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              style: TextButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
    required this.onToggleLike,
    required this.onOpenProfile,
  });

  final Comment comment;
  final bool highlight;
  final ValueChanged<Comment> onToggleLike;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String timestamp = _formatTimestamp(comment.createdAt);
    final String trackLabel = _serialLabel(
      comment.authorTrack,
      comment.authorSerialVisible,
    );

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
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: theme.colorScheme.primary.withValues(
                    alpha: 0.12,
                  ),
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
                      Text(
                        '$trackLabel · $timestamp',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Gap(12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(comment.text, style: theme.textTheme.bodyMedium),
          ),
          const Gap(12),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              style: TextButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
