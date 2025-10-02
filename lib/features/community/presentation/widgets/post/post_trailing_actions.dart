/// Trailing actions widget for bookmark and share
///
/// Responsibilities:
/// - Display bookmark and share buttons
/// - Group buttons with visual container
/// - Handle custom trailing actions
///
/// Used by: PostCard

library;
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../domain/models/post.dart';

class PostTrailingActions extends StatelessWidget {
  const PostTrailingActions({
    super.key,
    required this.post,
    required this.onBookmarkTap,
    required this.onShareTap,
    required this.showShare,
    required this.showBookmark,
    this.customTrailing,
  });

  final Post post;
  final VoidCallback onBookmarkTap;
  final VoidCallback onShareTap;
  final bool showShare;
  final bool showBookmark;
  final Widget? customTrailing;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<Widget> grouped = <Widget>[];

    // Share button
    if (showShare) {
      grouped.add(
        IconButton(
          iconSize: 20,
          constraints: const BoxConstraints(minHeight: 36, minWidth: 36),
          padding: const EdgeInsets.all(6),
          icon: const Icon(Icons.share_outlined),
          tooltip: '공유하기',
          color: theme.colorScheme.onSurfaceVariant,
          onPressed: onShareTap,
        ),
      );
    }

    // Bookmark button (if no custom trailing or showBookmark is true)
    if (customTrailing == null && showBookmark) {
      grouped.add(
        IconButton(
          iconSize: 20,
          constraints: const BoxConstraints(minHeight: 36, minWidth: 36),
          padding: const EdgeInsets.all(6),
          icon: Icon(post.isBookmarked ? Icons.bookmark : Icons.bookmark_outline),
          color: post.isBookmarked ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
          onPressed: onBookmarkTap,
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
                  for (int i = 0; i < grouped.length; i++) ...[
                    if (i > 0) const Gap(4),
                    grouped[i],
                  ],
                ],
              ),
            ),
          );

    // Return based on what's available
    final finalCustomTrailing = customTrailing;
    final finalGroupedWidget = groupedWidget;

    if (finalCustomTrailing == null) {
      return finalGroupedWidget ?? const SizedBox.shrink();
    }

    if (finalGroupedWidget == null) {
      return finalCustomTrailing;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [finalGroupedWidget, const Gap(8), finalCustomTrailing],
    );
  }
}
