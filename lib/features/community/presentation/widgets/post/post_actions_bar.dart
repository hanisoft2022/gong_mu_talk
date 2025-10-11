/// Post actions bar with like and comment buttons
///
/// Responsibilities:
/// - Display like and comment count buttons
/// - Handle button taps and visual feedback
/// - Animated highlighting for liked state
///
/// Used by: PostCard

library;

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../../core/utils/number_formatter.dart';
import '../../../domain/models/post.dart';

class PostActionsBar extends StatelessWidget {
  const PostActionsBar({
    super.key,
    required this.post,
    required this.onLikeTap,
    required this.onCommentTap,
    required this.trailingActions,
    this.canLike = true,
    this.onDisabledLikeTap,
  });

  final Post post;
  final VoidCallback onLikeTap;
  final VoidCallback onCommentTap;
  final Widget? trailingActions;
  final bool canLike;
  final VoidCallback? onDisabledLikeTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Like button
        PostActionButton(
          icon: post.isLiked ? Icons.favorite : Icons.favorite_border,
          label: formatCompactNumber(post.likeCount),
          isHighlighted: post.isLiked,
          onPressed: canLike ? onLikeTap : onDisabledLikeTap,
          highlightColor: Colors.pink[400],
          isDisabled: !canLike,
        ),
        const Gap(12),

        // Comment button
        PostActionButton(
          icon: Icons.mode_comment_outlined,
          label: formatCompactNumber(post.commentCount),
          onPressed: onCommentTap,
        ),

        const Spacer(),

        // Trailing actions (scrap, share, etc.)
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
    this.highlightColor,
    this.alwaysGray = false,
    this.isDisabled = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool isHighlighted;
  final Color? highlightColor;
  final bool alwaysGray;
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    // Determine color based on state and value
    final Color iconColor;
    if (isDisabled) {
      iconColor = colorScheme.onSurfaceVariant.withValues(alpha: 0.4);
    } else if (alwaysGray) {
      iconColor = colorScheme.onSurfaceVariant;
    } else if (isHighlighted) {
      iconColor = highlightColor ?? colorScheme.primary;
    } else if (label == '0') {
      iconColor = colorScheme.onSurfaceVariant;
    } else {
      iconColor = colorScheme.onSurface;
    }

    final Widget iconWidget = AnimatedScale(
      duration: const Duration(milliseconds: 200),
      scale: isHighlighted ? 1.2 : 1.0,
      curve: Curves.easeOutBack,
      child: Icon(icon, size: 22, color: iconColor),
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
