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
import '../../domain/services/career_display_helper.dart';

class AuthorDisplayWidget extends StatelessWidget {
  const AuthorDisplayWidget({
    super.key,
    required this.nickname,
    required this.track,
    this.specificCareer,
    required this.serialVisible,
    this.onTap,
  });

  final String nickname;
  final CareerTrack track;
  final String? specificCareer;
  final bool serialVisible;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName = _buildDisplayName();

    return Material(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: theme.colorScheme.primary.withValues(alpha: 0.1),
        highlightColor: theme.colorScheme.primary.withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            displayName,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  String _buildDisplayName() {
    // Determine track label
    final String trackLabel;
    if (serialVisible && specificCareer != null) {
      // Use specific career if available
      final displayName = CareerDisplayHelper.getCareerDisplayName(specificCareer!);
      final emoji = CareerDisplayHelper.getCareerEmoji(specificCareer!);
      trackLabel = '$displayName $emoji';
    } else if (serialVisible && track != CareerTrack.none) {
      // Fallback to CareerTrack enum
      trackLabel = '${track.displayName} ${track.emoji}';
    } else {
      trackLabel = '공무원';
    }

    // Combine: "[track] [emoji] [nickname]"
    return '$trackLabel $nickname';
  }
}
