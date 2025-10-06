import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import '../../../../community/domain/models/post.dart';
import '../../../../community/presentation/widgets/post_card.dart';
import '../../cubit/profile_timeline_cubit.dart';

/// The main timeline section showing user's posts.
///
/// Displays loading, error, or success states with infinite scroll support.
class TimelineSection extends StatelessWidget {
  const TimelineSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileTimelineCubit, ProfileTimelineState>(
      builder: (BuildContext context, ProfileTimelineState state) {
        switch (state.status) {
          case ProfileTimelineStatus.initial:
          case ProfileTimelineStatus.loading:
            return const Center(
              child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()),
            );
          case ProfileTimelineStatus.error:
            return Column(
              children: [
                Text(
                  state.errorMessage ?? '타임라인을 불러오지 못했습니다.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const Gap(12),
                OutlinedButton(
                  onPressed: () => context.read<ProfileTimelineCubit>().loadInitial(),
                  child: const Text('다시 시도'),
                ),
              ],
            );
          case ProfileTimelineStatus.refreshing:
          case ProfileTimelineStatus.loaded:
            if (state.posts.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    const Icon(Icons.forum_outlined, size: 40),
                    const Gap(8),
                    Text('아직 작성한 글이 없습니다.', style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              );
            }
            return Column(
              children: [
                ...state.posts.map(
                  (Post post) => PostCard(
                    post: post,
                    onToggleLike: () => context.read<ProfileTimelineCubit>().toggleLike(post),
                    onToggleScrap: () => context.read<ProfileTimelineCubit>().toggleScrap(post),
                  ),
                ),
                if (state.isLoadingMore)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: CircularProgressIndicator(),
                  ),
                if (state.hasMore && !state.isLoadingMore)
                  TextButton(
                    onPressed: () => context.read<ProfileTimelineCubit>().loadMore(),
                    child: const Text('더 보기'),
                  ),
              ],
            );
        }
      },
    );
  }
}
