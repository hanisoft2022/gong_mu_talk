import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../di/di.dart';
import '../../data/community_repository.dart';
import '../../domain/models/comment.dart';
import '../../domain/models/post.dart';
import '../../../profile/domain/career_track.dart';

const List<String> _commentReactionOptions = <String>['👍', '🎉', '😍', '😄'];

class PostCard extends StatefulWidget {
  const PostCard({
    super.key,
    required this.post,
    required this.onToggleLike,
    required this.onToggleBookmark,
    this.trailing,
  });

  final Post post;
  final VoidCallback onToggleLike;
  final VoidCallback onToggleBookmark;
  final Widget? trailing;

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
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
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primary.withValues(
                    alpha: 0.12,
                  ),
                  foregroundColor: theme.colorScheme.primary,
                  child: Text(post.authorNickname.substring(0, 1)),
                ),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.authorNickname,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${post.authorTrack.emoji} ${post.authorTrack.displayName} · $timestamp',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                widget.trailing ??
                    IconButton(
                      icon: Icon(
                        post.isBookmarked
                            ? Icons.bookmark
                            : Icons.bookmark_outline,
                        color: post.isBookmarked
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      onPressed: widget.onToggleBookmark,
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
              ],
            ),
            if (_showComments) ...[
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
                      final Comment featuredComment = _featuredComments.first;
                      return _FeaturedCommentTile(
                        comment: featuredComment,
                        onToggleLike: _handleCommentLike,
                        onReact: (String emoji) =>
                            _handleReaction(featuredComment, emoji),
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
                    onReact: (String emoji) => _handleReaction(comment, emoji),
                  ),
                ),
              ],
            ],
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

  Future<void> _handleReaction(Comment comment, String emoji) async {
    final String? previous = comment.viewerReaction;
    final String? next = previous == emoji ? null : emoji;

    Comment updateComment(Comment current, String? reaction) {
      final Map<String, int> counts = Map<String, int>.from(current.reactionCounts);
      final String? currentReaction = current.viewerReaction;
      if (currentReaction != null) {
        counts[currentReaction] = (counts[currentReaction] ?? 0) - 1;
        if ((counts[currentReaction] ?? 0) <= 0) {
          counts.remove(currentReaction);
        }
      }
      if (reaction != null) {
        counts[reaction] = (counts[reaction] ?? 0) + 1;
      }
      return current.copyWith(
        viewerReaction: reaction,
        reactionCounts: counts,
      );
    }

    void apply(String? reaction) {
      setState(() {
        _timelineComments = _timelineComments
            .map(
              (Comment current) =>
                  current.id == comment.id ? updateComment(current, reaction) : current,
            )
            .toList(growable: false);
        _featuredComments = _featuredComments
            .map(
              (Comment current) =>
                  current.id == comment.id ? updateComment(current, reaction) : current,
            )
            .toList(growable: false);
      });
    }

    apply(next);

    if (_isSynthetic(widget.post)) {
      return;
    }

    try {
      final String? confirmed = await _repository.toggleCommentReaction(
        postId: widget.post.id,
        commentId: comment.id,
        emoji: emoji,
      );
      if (confirmed != next) {
        apply(confirmed);
      }
    } catch (_) {
      apply(previous);
    }
  }

  Comment _fromCached(Post post, CachedComment cached, int index) {
    return Comment(
      id: cached.id,
      postId: post.id,
      authorUid: 'preview',
      authorNickname: cached.authorNickname,
      text: cached.text,
      likeCount: cached.likeCount,
      createdAt: (post.updatedAt ?? post.createdAt).add(
        Duration(minutes: index),
      ),
      reactionCounts: const <String, int>{},
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

class _FeaturedCommentTile extends StatelessWidget {
  const _FeaturedCommentTile({
    required this.comment,
    required this.onToggleLike,
    required this.onReact,
  });

  final Comment comment;
  final ValueChanged<Comment> onToggleLike;
  final void Function(String emoji) onReact;

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
          Text(
            comment.authorNickname,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const Gap(4),
          Text(comment.text, style: theme.textTheme.bodyMedium),
          const Gap(12),
          _CommentReactionBar(
            reactions: comment.reactionCounts,
            viewerReaction: comment.viewerReaction,
            onReact: onReact,
          ),
          const Gap(6),
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
    required this.onReact,
  });

  final Comment comment;
  final bool highlight;
  final ValueChanged<Comment> onToggleLike;
  final void Function(String emoji) onReact;

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
          Row(
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
                    Text(
                      comment.authorNickname,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      timestamp,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
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
            ],
          ),
          const Gap(8),
          Text(comment.text, style: theme.textTheme.bodyMedium),
          const Gap(12),
          _CommentReactionBar(
            reactions: comment.reactionCounts,
            viewerReaction: comment.viewerReaction,
            onReact: onReact,
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
      children: _commentReactionOptions.map((String emoji) {
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
          selectedColor:
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.16),
        );
      }).toList(growable: false),
    );
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
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18, color: iconColor),
      label: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: iconColor,
          fontWeight: FontWeight.w600,
        ),
      ),
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
