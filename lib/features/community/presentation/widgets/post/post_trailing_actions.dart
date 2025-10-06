/// Trailing actions widget for scrap and share
///
/// Responsibilities:
/// - Display scrap and share buttons
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
    required this.onScrapTap,
    required this.onShareTap,
    required this.showShare,
    required this.showScrap,
    this.customTrailing,
    this.onReportTap,
  });

  final Post post;
  final VoidCallback onScrapTap;
  final VoidCallback onShareTap;
  final bool showShare;
  final bool showScrap;
  final Widget? customTrailing;
  final VoidCallback? onReportTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    // Build menu items
    final List<PopupMenuEntry<String>> menuItems = [];

    // Share menu item
    if (showShare) {
      menuItems.add(
        PopupMenuItem(
          value: 'share',
          child: Row(
            children: [
              Icon(Icons.share_outlined, size: 20, color: theme.colorScheme.onSurface),
              const SizedBox(width: 12),
              const Text('공유하기'),
            ],
          ),
        ),
      );
    }

    // Scrap menu item (if no custom trailing or showScrap is true)
    if (customTrailing == null && showScrap) {
      menuItems.add(
        PopupMenuItem(
          value: 'scrap',
          child: Row(
            children: [
              Icon(
                post.isScrapped ? Icons.bookmark : Icons.bookmark_outline,
                size: 20,
                color: post.isScrapped ? theme.colorScheme.primary : theme.colorScheme.onSurface,
              ),
              const SizedBox(width: 12),
              Text(post.isScrapped ? '스크랩 해제' : '스크랩'),
            ],
          ),
        ),
      );
    }

    // Report menu item
    if (onReportTap != null) {
      if (menuItems.isNotEmpty) {
        menuItems.add(const PopupMenuDivider());
      }
      menuItems.add(
        PopupMenuItem(
          value: 'report',
          child: Row(
            children: [
              Icon(Icons.flag_outlined, size: 20, color: theme.colorScheme.error),
              const SizedBox(width: 12),
              Text('신고하기', style: TextStyle(color: theme.colorScheme.error)),
            ],
          ),
        ),
      );
    }

    // If no menu items, return empty
    if (menuItems.isEmpty) {
      return customTrailing ?? const SizedBox.shrink();
    }

    // Build 3-dot menu button
    final Widget menuButton = PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, size: 20, color: theme.colorScheme.onSurfaceVariant),
      iconSize: 20,
      constraints: const BoxConstraints(minHeight: 36, minWidth: 36),
      padding: const EdgeInsets.all(6),
      tooltip: '더보기',
      onSelected: (value) {
        if (value == 'share') {
          onShareTap();
        } else if (value == 'scrap') {
          onScrapTap();
        } else if (value == 'report') {
          onReportTap?.call();
        }
      },
      itemBuilder: (context) => menuItems,
    );

    // Return based on what's available
    if (customTrailing == null) {
      return menuButton;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [menuButton, const Gap(8), customTrailing!],
    );
  }
}
