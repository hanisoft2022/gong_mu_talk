import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import '../../../../community/domain/models/post.dart';
import '../../../../community/presentation/cubit/scrap_cubit.dart';
import '../../../../community/presentation/widgets/post_card.dart';
import '../../../../../common/widgets/scrap_undo_snackbar.dart';

/// Tab content for user's scrapped posts.
///
/// Displays loading, error, or success states with infinite scroll support.
/// Uses NotificationListener for scroll detection (NestedScrollView compatible).
class ProfileScrapsTabContent extends StatelessWidget {
  const ProfileScrapsTabContent({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<ScrapCubit, ScrapState>(
      listenWhen: (previous, current) {
        return previous.lastUndoNotificationTime != current.lastUndoNotificationTime &&
            current.lastUndoNotificationTime != null;
      },
      listener: (context, state) {
        // 마이페이지 스크랩 리스트에서는 항상 스크랩 해제
        showScrapUndoSnackBar(
          context: context,
          wasAdded: false,
          onUndo: () {
            context.read<ScrapCubit>().undoRemoveScrap();
          },
        );
      },
      child: BlocBuilder<ScrapCubit, ScrapState>(
        builder: (context, state) {
        if (state.isLoading && state.scraps.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.scraps.isEmpty && !state.isLoading) {
          return _buildEmptyState(context);
        }

        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollUpdateNotification) {
              final metrics = notification.metrics;
              if (metrics.pixels >= metrics.maxScrollExtent - 200) {
                context.read<ScrapCubit>().loadMore();
              }
            }
            return false;
          },
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: state.scraps.length + (state.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= state.scraps.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final Post post = state.scraps[index];
              return PostCard(
                post: post,
                onToggleLike: () =>
                    context.read<ScrapCubit>().toggleLike(post),
                onToggleScrap: () =>
                    context.read<ScrapCubit>().removeScrap(post),
              );
            },
          ),
        );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bookmark_outline,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const Gap(16),
            Text(
              '저장된 스크랩이 없습니다',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Gap(8),
            Text(
              '관심 있는 게시글을 스크랩해보세요.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
