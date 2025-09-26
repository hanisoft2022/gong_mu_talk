import 'package:flutter/material.dart';

class GlobalAppBarActions extends StatelessWidget {
  const GlobalAppBarActions({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
    required this.onProfileTap,
    this.compact = false,
    this.opacity = 1,
  });

  final bool isDarkMode;
  final VoidCallback onToggleTheme;
  final VoidCallback onProfileTap;
  final bool compact;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final double buttonIconSize = compact ? 20 : 22;
    final EdgeInsets padding = compact
        ? const EdgeInsets.only(right: 4)
        : const EdgeInsets.only(right: 12);

    final double resolvedOpacity = opacity.clamp(0, 1).toDouble();

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: resolvedOpacity,
      child: Padding(
        padding: padding,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: isDarkMode ? '라이트 모드' : '다크 모드',
              onPressed: onToggleTheme,
              splashRadius: compact ? 20 : 22,
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return RotationTransition(
                    turns: Tween<double>(begin: 0.85, end: 1).animate(animation),
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: Icon(
                  isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                  key: ValueKey<bool>(isDarkMode),
                  size: buttonIconSize,
                ),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              tooltip: '마이페이지',
              onPressed: onProfileTap,
              splashRadius: compact ? 20 : 22,
              icon: Icon(Icons.person_outline, size: buttonIconSize + (compact ? 2 : 4)),
            ),
          ],
        ),
      ),
    );
  }
}
