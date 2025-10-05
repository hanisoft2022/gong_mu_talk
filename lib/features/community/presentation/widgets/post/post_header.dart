/// Post header widget displaying author information and menu
///
/// Responsibilities:
/// - Display author name with career track icon
/// - Show timestamp
/// - Handle author menu tap
///
/// Used by: PostCard

library;
import 'package:flutter/material.dart';

import '../../../domain/models/post.dart';
import '../author_display_widget.dart';

class PostHeader extends StatelessWidget {
  const PostHeader({
    super.key,
    required this.post,
    required this.timestamp,
    required this.authorButtonKey,
    required this.onAuthorMenuTap,
  });

  final Post post;
  final String timestamp;
  final GlobalKey authorButtonKey;
  final VoidCallback onAuthorMenuTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          fit: FlexFit.loose,
          child: Align(
            alignment: Alignment.centerLeft,
            child: _buildAuthorMenu(context),
          ),
        ),
      ],
    );
  }

  Widget _buildAuthorMenu(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle timestampStyle =
        theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant) ??
        TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 11);

    final Widget timestampLabel = Text(timestamp, style: timestampStyle);
    final Widget identityButton = AuthorDisplayWidget(
      key: authorButtonKey,
      nickname: post.authorNickname.isNotEmpty ? post.authorNickname : post.authorUid,
      track: post.authorTrack,
      serialVisible: post.authorSerialVisible,
      onTap: onAuthorMenuTap,
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
}
