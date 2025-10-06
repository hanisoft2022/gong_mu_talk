import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/post.dart';
import '../../domain/models/feed_filters.dart';
import '../cubit/community_feed_cubit.dart';
import 'post_card.dart';
import '../../../../core/utils/performance_optimizations.dart';
import '../../../../core/utils/image_cache_manager.dart';

/// 성능 최적화된 PostCard 리스트
class OptimizedPostList extends StatefulWidget {
  const OptimizedPostList({
    super.key,
    required this.posts,
    required this.hasReachedMax,
    required this.onRefresh,
    required this.displayScope,
  });

  final List<Post> posts;
  final bool hasReachedMax;
  final Future<void> Function() onRefresh;
  final LoungeScope displayScope;

  @override
  State<OptimizedPostList> createState() => _OptimizedPostListState();
}

class _OptimizedPostListState extends State<OptimizedPostList>
    with PerformanceProfileMixin {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);

    // 첫 번째 화면의 이미지들을 프리로드
    _preloadInitialImages();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _preloadInitialImages() {
    final imageUrls = widget.posts
        .take(3) // 처음 3개 포스트의 이미지만
        .expand((post) => post.media)
        .map((media) => media.thumbnailUrl ?? media.url)
        .toList();

    if (imageUrls.isNotEmpty) {
      ImageCacheManager.preloadImages(imageUrls);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<CommunityFeedCubit>().fetchMore();

      // 다음 페이지 이미지들을 프리로드
      _preloadNextPageImages();
    }
  }

  void _preloadNextPageImages() {
    final currentIndex = widget.posts.length;
    if (currentIndex > 10) {
      // 충분한 포스트가 있을 때만
      final nextPageUrls = widget.posts
          .skip(currentIndex - 5)
          .take(3)
          .expand((post) => post.media)
          .map((media) => media.thumbnailUrl ?? media.url)
          .toList();

      if (nextPageUrls.isNotEmpty) {
        ImageCacheManager.preloadImages(nextPageUrls);
      }
    }
  }

  @override
  Widget buildProfiled(BuildContext context) {
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: OptimizedListView(
        controller: _scrollController,
        itemCount: widget.posts.length + (widget.hasReachedMax ? 0 : 1),
        itemBuilder: (context, index) {
          if (index >= widget.posts.length) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }

          final post = widget.posts[index];

          // 성능 최적화: 중요한 속성들만 의존성으로 사용
          return MemoizedWidget(
            dependencies: [
              post.id,
              post.isLiked,
              post.likeCount,
              post.isScrapped,
              post.commentCount,
              widget.displayScope,
            ],
            child: OptimizedPostCard(
              key: ValueKey(post.id),
              post: post,
              displayScope: widget.displayScope,
            ),
          );
        },
      ),
    );
  }
}

/// 성능 최적화된 PostCard 래퍼
class OptimizedPostCard extends StatelessWidget {
  const OptimizedPostCard({
    super.key,
    required this.post,
    required this.displayScope,
  });

  final Post post;
  final LoungeScope displayScope;

  @override
  Widget build(BuildContext context) {
    // BlocSelector를 사용하여 필요한 상태 변화에만 반응
    return BlocSelector<CommunityFeedCubit, CommunityFeedState, bool>(
      selector: (state) => state.status == CommunityFeedStatus.loading,
      builder: (context, isLoading) {
        return PostCard(
          post: post,
          displayScope: displayScope,
          onToggleLike: () {
            PerformanceProfiler.start('toggle_like');
            context.read<CommunityFeedCubit>().toggleLike(post);
            PerformanceProfiler.end('toggle_like');
          },
          onToggleScrap: () {
            PerformanceProfiler.start('toggle_scrap');
            context.read<CommunityFeedCubit>().toggleScrap(post);
            PerformanceProfiler.end('toggle_scrap');
          },
        );
      },
    );
  }
}

/// 성능 모니터링을 포함한 리스트 관리자
class PostListPerformanceManager {
  static final Map<String, int> _renderCounts = {};
  static final Map<String, DateTime> _lastRenderTimes = {};

  /// 렌더링 횟수 추적
  static void trackRender(String postId) {
    _renderCounts[postId] = (_renderCounts[postId] ?? 0) + 1;
    _lastRenderTimes[postId] = DateTime.now();

    // 과도한 렌더링 감지
    if (_renderCounts[postId]! > 10) {
      debugPrint(
        '⚠️ Post $postId has been rendered ${_renderCounts[postId]} times',
      );
    }
  }

  /// 성능 통계 출력
  static void printStats() {
    debugPrint('\n📊 Post Rendering Statistics:');
    _renderCounts.entries.where((entry) => entry.value > 5).forEach((entry) {
      debugPrint('Post ${entry.key}: ${entry.value} renders');
    });
  }

  /// 통계 초기화
  static void clearStats() {
    _renderCounts.clear();
    _lastRenderTimes.clear();
  }
}
