/// Post actions bar with like, comment, view buttons
///
/// Responsibilities:
/// - Display like, comment, and view count buttons
/// - Handle button taps and visual feedback
/// - Animated highlighting for liked state
///
/// Used by: PostCard

library;
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../domain/models/post.dart';

class PostActionsBar extends StatelessWidget {
  const PostActionsBar({
    super.key,
    required this.post,
    required this.onLikeTap,
    required this.onCommentTap,
    required this.trailingActions,
  });

  final Post post;
  final VoidCallback onLikeTap;
  final VoidCallback onCommentTap;
  final Widget? trailingActions;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Like button
        PostActionButton(
          icon: post.isLiked ? Icons.favorite : Icons.favorite_border,
          label: '${post.likeCount}',
          isHighlighted: post.isLiked,
          onPressed: onLikeTap,
        ),
        const Gap(16),

        // Comment button
        PostActionButton(
          icon: Icons.mode_comment_outlined,
          label: '${post.commentCount}',
          onPressed: onCommentTap,
        ),
        const Gap(16),

        // View count (read-only)
        PostActionButton(
          icon: Icons.visibility_outlined,
          label: '${post.viewCount}',
          onPressed: null,
        ),

        const Spacer(),

        // Trailing actions (bookmark, share, etc.)
        if (trailingActions != null) trailingActions!,
      ],
    );
  }
}

/// Individual action button widget
class PostActionButton extends StatelessWidget {
  const PostActionButton({
    super.key,
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
    final Color iconColor = isHighlighted ? colorScheme.primary : colorScheme.onSurfaceVariant;

    final Widget iconWidget = AnimatedScale(
      duration: const Duration(milliseconds: 180),
      scale: isHighlighted ? 1.1 : 1,
      curve: Curves.easeOutBack,
      child: Icon(icon, size: 16, color: iconColor),
    );

    final TextStyle labelStyle =
        Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(color: iconColor, fontWeight: FontWeight.w600) ??
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
