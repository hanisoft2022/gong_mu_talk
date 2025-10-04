/// Feed Section Widgets - Main feed list and related components
///
/// Responsibilities:
/// - Feed section builder with posts list
/// - Loading more indicator
/// - Empty state handling
/// - Ad insertion logic

library;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../domain/models/feed_filters.dart';
import '../../domain/models/post.dart';
import '../cubit/community_feed_cubit.dart';
import '../../../../core/utils/performance_optimizations.dart';
import 'empty_state_view.dart';
import 'post_card.dart';

/// Builds the main feed section with posts
class FeedSectionBuilder extends StatelessWidget {
  const FeedSectionBuilder({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CommunityFeedCubit, CommunityFeedState>(
      builder: (context, feedState) {
        return BlocSelector<AuthCubit, AuthState, bool>(
          selector: (state) => state.hasSerialTabAccess,
          builder: (context, hasSerialTabAccess) {
            return _buildContent(context, feedState, hasSerialTabAccess);
          },
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, CommunityFeedState feedState, bool hasSerialTabAccess) {
    final CommunityFeedCubit cubit = context.read<CommunityFeedCubit>();
    final bool showSerialGuide = feedState.scope == LoungeScope.serial && !hasSerialTabAccess;
    final bool showEmptyPosts = feedState.posts.isEmpty && !showSerialGuide;

    if (showSerialGuide) {
      return _buildSerialGuideState(cubit);
    }

    if (showEmptyPosts) {
      return _buildEmptyPostsState(cubit);
    }

    // Skeleton UI for sorting and lounging states
    final bool isSorting = feedState.status == CommunityFeedStatus.sorting;
    final bool isLounging = feedState.status == CommunityFeedStatus.lounging;
    
    // Lounging state: Fade out + Skeleton (for lounge transition)
    if (isLounging) {
      return AnimatedOpacity(
        opacity: 0.3,
        duration: const Duration(milliseconds: 200),
        child: Skeletonizer(
          enabled: true,
          enableSwitchAnimation: true,
          child: _buildPostsList(context, cubit, feedState),
        ),
      );
    }
    
    // Sorting state: Simple Skeleton (for sort order change)
    return Skeletonizer(
      enabled: isSorting,
      enableSwitchAnimation: true,
      child: _buildPostsList(context, cubit, feedState),
    );
  }

  Widget _buildSerialGuideState(CommunityFeedCubit cubit) {
    return EmptyStateView(
      icon: Icons.description_outlined,
      title: '급여 명세서를 통해서 본인의 직렬을 인증하세요',
      message: '내 직렬 탭을 이용하려면 급여명세서 인증을 완료해주세요.',
      onRefresh: () => cubit.refresh(),
    );
  }

  Widget _buildEmptyPostsState(CommunityFeedCubit cubit) {
    return Column(
      children: [
        const Gap(60),
        EmptyStateView(
          icon: Icons.chat_bubble_outline,
          title: '아직 게시물이 없습니다.',
          message: '첫 번째 글을 올려 동료 공무원과 이야기를 시작해보세요!',
          onRefresh: () => cubit.refresh(),
        ),
      ],
    );
  }

  Widget _buildPostsList(BuildContext context, CommunityFeedCubit cubit, CommunityFeedState feedState) {
    const int adInterval = 10;
    int renderedCount = 0;
    final int totalPosts = feedState.posts.length;
    final List<Widget> children = <Widget>[];

    for (final Post post in feedState.posts) {
      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: RepaintBoundary(
            child: MemoizedWidget(
              key: ValueKey('post_${post.id}'),
              dependencies: [
                post.id,
                post.isLiked,
                post.likeCount,
                post.isBookmarked,
                post.commentCount,
                feedState.scope,
              ],
              child: PostCard(
                post: post,
                onToggleLike: () {
                  PerformanceProfiler.start('toggle_like_feed');
                  cubit.toggleLike(post);
                  PerformanceProfiler.end('toggle_like_feed');
                },
                onToggleBookmark: () {
                  PerformanceProfiler.start('toggle_bookmark_feed');
                  cubit.toggleBookmark(post);
                  PerformanceProfiler.end('toggle_bookmark_feed');
                },
                displayScope: feedState.scope,
                showShare: false,
                showBookmark: false,
              ),
            ),
          ),
        ),
      );
      renderedCount += 1;

      final bool shouldInsertAd =
          feedState.showAds && renderedCount % adInterval == 0 && renderedCount < totalPosts;

      if (shouldInsertAd) {
        children
          ..add(const SizedBox.shrink())
          ..add(const SizedBox(height: 12));
      }
    }

    if (feedState.isLoadingMore) {
      children.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Column(children: children);
  }
}
