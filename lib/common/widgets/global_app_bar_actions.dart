import 'package:flutter/material.dart';
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          tooltip: '알림',
          onPressed: () => GoRouter.of(context).push('/notifications/history'),
        ),
        IconButton(
          icon: const Icon(Icons.person_outline),
          tooltip: '마이페이지',
          onPressed: onProfileTap,
        ),
      ],
    );
  }
}
