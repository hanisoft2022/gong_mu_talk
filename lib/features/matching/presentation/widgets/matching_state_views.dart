import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../routing/app_router.dart';

// ==================== Loading View ====================

class MatchingLoadingView extends StatelessWidget {
  const MatchingLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

// ==================== Error View ====================

class MatchingErrorView extends StatelessWidget {
  const MatchingErrorView({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 56),
              const Gap(12),
              Text('매칭 후보를 불러오지 못했어요.', style: Theme.of(context).textTheme.titleMedium),
              const Gap(12),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_outlined),
                label: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ==================== Locked View ====================

class MatchingLockedView extends StatelessWidget {
  const MatchingLockedView({
    super.key,
    required this.reason,
    this.showVerifyShortcut = false,
  });

  final String reason;
  final bool showVerifyShortcut;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 56, color: theme.colorScheme.primary),
            const Gap(12),
            Text(
              '매칭 서비스 잠금',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Gap(8),
            Text(reason, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
            if (showVerifyShortcut) ...[
              const Gap(20),
              OutlinedButton.icon(
                onPressed: () => _goToProfile(context),
                icon: const Icon(Icons.verified_user_outlined),
                label: const Text('공직자 메일 인증하기'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _goToProfile(BuildContext context) {
    final GoRouter router = GoRouter.of(context);
    router.go(ProfileRoute.path);
  }
}

// ==================== Empty State View ====================

class MatchingEmptyView extends StatelessWidget {
  const MatchingEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.hourglass_bottom_outlined, size: 56),
          const Gap(12),
          Text('오늘의 큐레이션이 소진됐어요.', style: theme.textTheme.titleMedium),
          const Gap(8),
          Text(
            '내일 새로운 후보를 준비할게요. 취향 설문을 업데이트하면 추천 폭이 넓어져요.',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
