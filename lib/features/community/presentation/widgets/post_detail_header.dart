/// Post Detail Header - Displays post content with action menu
///
/// Responsibilities:
/// - Renders post content using PostCard widget
/// - Provides popup menu for post actions (edit, delete, report, block)
/// - Handles menu action selection and delegates to callbacks

import 'package:flutter/material.dart';
import '../../domain/models/post.dart';
import 'post_card.dart';

class PostDetailHeader extends StatelessWidget {
  const PostDetailHeader({
    super.key,
    required this.post,
    required this.currentUserId,
    required this.onToggleLike,
    required this.onToggleBookmark,
    required this.onMenuAction,
  });

  final Post post;
  final String currentUserId;
  final VoidCallback onToggleLike;
  final VoidCallback onToggleBookmark;
  final void Function(String action) onMenuAction;

  @override
  Widget build(BuildContext context) {
    return PostCard(
      post: post,
      onToggleLike: onToggleLike,
      onToggleBookmark: onToggleBookmark,
      showShare: false,
      showBookmark: false,
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert),
        itemBuilder: (context) => [
          if (post.authorUid == currentUserId) ...[
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit_outlined),
                title: Text('수정'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete_outline),
                title: Text('삭제'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ] else ...[
            const PopupMenuItem(
              value: 'report',
              child: ListTile(
                leading: Icon(Icons.report_outlined),
                title: Text('신고'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'block',
              child: ListTile(
                leading: Icon(Icons.block_outlined),
                title: Text('차단'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ],
        onSelected: onMenuAction,
      ),
    );
  }
}
