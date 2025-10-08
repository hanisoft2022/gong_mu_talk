import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import '../../../../community/domain/models/post.dart';
import '../../../../community/presentation/widgets/post_card.dart';
import '../../cubit/profile_timeline_cubit.dart';

/// Tab content for user's authored posts.
///
/// Displays loading, error, or success states with infinite scroll support.
class ProfilePostsTabContent extends StatelessWidget {
  const ProfilePostsTabContent({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileTimelineCubit, ProfileTimelineState>(
      builder: (BuildContext context, ProfileTimelineState state) {
        switch (state.status) {
          case ProfileTimelineStatus.initial:
          case ProfileTimelineStatus.loading:
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            );
          case ProfileTimelineStatus.error:
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  state.errorMessage ?? '작성한 글을 불러오지 못했습니다.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const Gap(12),
                OutlinedButton(
                  onPressed: () =>
                      context.read<ProfileTimelineCubit>().loadInitial(),
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.forum_outlined, size: 40),
                    const Gap(8),
                    Text(
                      '아직 작성한 글이 없습니다.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              );
            }
            return NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollUpdateNotification) {
                  final metrics = notification.metrics;
                  if (metrics.pixels >= metrics.maxScrollExtent - 200) {
                    context.read<ProfileTimelineCubit>().loadMore();
                  }
                }
                return false;
              },
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: state.posts.length + (state.hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= state.posts.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final Post post = state.posts[index];
                  return PostCard(
                    post: post,
                    onToggleLike: () =>
                        context.read<ProfileTimelineCubit>().toggleLike(post),
                    onToggleScrap: () =>
                        context.read<ProfileTimelineCubit>().toggleScrap(post),
                  );
                },
              ),
            );
        }
      },
    );
  }
}
