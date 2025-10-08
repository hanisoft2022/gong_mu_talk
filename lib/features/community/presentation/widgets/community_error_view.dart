import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/utils/performance_optimizations.dart';

class CommunityErrorView extends StatelessWidget {
  const CommunityErrorView({super.key, required this.onRetry, this.message});

  final Future<void> Function() onRetry;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRetry,
      child: OptimizedListView(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: 1,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Gap(12),
                const Icon(Icons.inbox_outlined, size: 72),
                const Gap(16),
                Text(
                  message ?? '피드를 불러오지 못했어요.',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const Gap(12),
                FilledButton.icon(
                  onPressed: () {
                    onRetry();
                  },
                  icon: const Icon(Icons.refresh_outlined),
                  label: const Text('다시 시도'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
