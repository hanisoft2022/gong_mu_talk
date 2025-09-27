import 'package:flutter/material.dart';

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
    final Color iconColor = isHighlighted
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;
    final Widget iconWidget = AnimatedScale(
      duration: const Duration(milliseconds: 180),
      scale: isHighlighted ? 1.1 : 1,
      curve: Curves.easeOutBack,
      child: Icon(icon, size: 16, color: iconColor),
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
