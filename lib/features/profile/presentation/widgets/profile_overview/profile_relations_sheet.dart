/// Profile Relations Sheet
///
/// Modal bottom sheet displaying followers or following users.
///
/// **Purpose**:
/// - Show list of users who follow the current user
/// - Show list of users the current user is following
/// - Allow navigation to user profiles
/// - Support infinite scroll/pagination
///
/// **Features**:
/// - Draggable bottom sheet with flexible sizing
/// - Loading states (initial, refreshing, loading more)
/// - Error handling with retry option
/// - Empty state messages
/// - Infinite scroll pagination
/// - User profile navigation
///
/// **Usage**:
/// Called from ProfileHeader when user taps on follower/following stats.

library;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import '../../../domain/user_profile.dart';
import '../../cubit/profile_relations_cubit.dart';

/// Shows modal bottom sheet with follower/following list
void showProfileRelationsSheet(
  BuildContext context,
  ProfileRelationType type,
) {
  final ProfileRelationsCubit cubit = context.read<ProfileRelationsCubit>();
  cubit.load(type);

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext context) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (BuildContext context, ScrollController controller) {
          return BlocBuilder<ProfileRelationsCubit, ProfileRelationsState>(
            builder: (BuildContext context, ProfileRelationsState state) {
              return Column(
                children: [
                  // Drag handle
                  Container(
                    width: 48,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          state.type == ProfileRelationType.followers
                              ? '팔로워'
                              : '팔로잉',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Expanded(
                    child: _buildContent(context, state, cubit, controller),
                  ),
                ],
              );
            },
          );
        },
      );
    },
  );
}

/// Builds the content based on the current state
Widget _buildContent(
  BuildContext context,
  ProfileRelationsState state,
  ProfileRelationsCubit cubit,
  ScrollController controller,
) {
  // Loading state
  if (state.status == ProfileRelationsStatus.loading ||
      state.status == ProfileRelationsStatus.refreshing) {
    return const Center(child: CircularProgressIndicator());
  }

  // Error state
  if (state.status == ProfileRelationsStatus.error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(state.errorMessage ?? '목록을 불러오지 못했습니다.'),
          const Gap(12),
          OutlinedButton(
            onPressed: () => cubit.load(state.type),
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  // Empty state
  if (state.users.isEmpty) {
    return Center(
      child: Text(
        state.type == ProfileRelationType.followers
            ? '아직 나를 팔로우한 사용자가 없습니다.'
            : '아직 팔로우 중인 사용자가 없습니다.',
      ),
    );
  }

  // User list
  return NotificationListener<ScrollNotification>(
    onNotification: (ScrollNotification notification) {
      if (notification.metrics.pixels >=
              notification.metrics.maxScrollExtent - 120 &&
          !state.isLoadingMore &&
          state.hasMore) {
        cubit.loadMore();
      }
      return false;
    },
    child: ListView.separated(
      controller: controller,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      itemBuilder: (BuildContext context, int index) {
        final ThemeData theme = Theme.of(context);
        final UserProfile profile = state.users[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            Icons.person_outline,
            color: theme.colorScheme.primary,
          ),
          title: Text(profile.nickname),
          subtitle: profile.bio != null && profile.bio!.isNotEmpty
              ? Text(
                  profile.bio!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              : null,
          onTap: () {
            Navigator.of(context).pop();
            // Navigate to user profile
            // context.push('/profile/${profile.userId}');
          },
        );
      },
      separatorBuilder: (BuildContext context, int index) =>
          const Divider(height: 1),
      itemCount: state.users.length,
    ),
  );
}
