import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

class GlobalAppBarActions extends StatelessWidget {
  const GlobalAppBarActions({
    super.key,
    required this.onProfileTap,
    this.compact = false,
    this.opacity = 1,
  });

  final VoidCallback onProfileTap;
  final bool compact;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final double buttonIconSize = compact ? 25 : 30;
    final EdgeInsets padding = compact
        ? const EdgeInsets.only(right: 12)
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
            _CompactButton(
              icon: Icons.notifications_outlined,
              size: buttonIconSize,
              compact: compact,
              tooltip: '알림',
              onTap: () => GoRouter.of(context).push('/notifications/history'),
            ),
            const Gap(8),
            _CompactButton(
              icon: Icons.person_outline,
              size: buttonIconSize,
              compact: compact,
              tooltip: '마이페이지',
              onTap: onProfileTap,
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactButton extends StatelessWidget {
  const _CompactButton({
    required this.icon,
    required this.size,
    required this.compact,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final double size;
  final bool compact;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(compact ? 16 : 18),
        child: Container(
          width: compact ? 28 : 32,
          height: compact ? 28 : 32,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(compact ? 18 : 20)),
          child: Icon(icon, size: size, color: theme.colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}
