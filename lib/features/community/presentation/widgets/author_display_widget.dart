/// Author display widget - Shows career track icon, name, and nickname
///
/// Format: [track name] [emoji] [nickname]
/// Example: "초등교사 📚 김선생" or "공무원 김선생" (if track hidden)
///
/// Responsibilities:
/// - Display author identity in consistent format across posts and comments
/// - Include career track emoji when visible
/// - Use consistent typography (titleSmall + fontWeight.w600)

library;

import 'package:flutter/material.dart';
import '../../../profile/domain/career_track.dart';

class AuthorDisplayWidget extends StatelessWidget {
  const AuthorDisplayWidget({
    super.key,
    required this.nickname,
    required this.track,
    required this.serialVisible,
  });

  final String nickname;
  final CareerTrack track;
  final bool serialVisible;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName = _buildDisplayName();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        displayName,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  String _buildDisplayName() {
    // Determine track label
    final String trackLabel;
    if (serialVisible && track != CareerTrack.none) {
      trackLabel = '${track.displayName} ${track.emoji}';
    } else {
      trackLabel = '공무원';
    }

    // Combine: "[track] [emoji] [nickname]"
    return '$trackLabel $nickname';
  }
}
