import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../../routing/app_router.dart';
import '../../../../community/domain/models/post.dart';
import '../../utils/profile_helpers.dart';
import 'timeline_stat.dart';

/// A timeline post tile displaying a post summary.
///
/// Shows the post's audience/serial, creation date, text preview,
/// and engagement stats (likes, comments, views).
class TimelinePostTile extends StatelessWidget {
  const TimelinePostTile({super.key, required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return InkWell(
      onTap: () => context.pushNamed(
        CommunityPostDetailRoute.name,
        pathParameters: {'postId': post.id},
        extra: post,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  post.audience == PostAudience.serial ? post.serial.toUpperCase() : '전체 공개',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  formatDateRelative(post.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const Gap(8),
            Text(
              post.text,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const Gap(8),
            Row(
              children: [
                TimelineStat(icon: Icons.favorite_border, value: post.likeCount),
                const Gap(12),
                TimelineStat(icon: Icons.mode_comment_outlined, value: post.commentCount),
                const Gap(12),
                TimelineStat(icon: Icons.visibility_outlined, value: post.viewCount),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
