import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/performance_optimizations.dart';

import '../../domain/models/post.dart';
import '../cubit/liked_posts_cubit.dart';
import '../widgets/post_card.dart';

class LikedPostsPage extends StatefulWidget {
  const LikedPostsPage({super.key});

  @override
  State<LikedPostsPage> createState() => _LikedPostsPageState();
}

class _LikedPostsPageState extends State<LikedPostsPage> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    context.read<LikedPostsCubit>().loadInitial();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<LikedPostsCubit>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('좋아요한 글'),
      ),
      body: BlocBuilder<LikedPostsCubit, LikedPostsState>(
        builder: (context, state) {
          if (state.isLoading && state.likedPosts.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.likedPosts.isEmpty && !state.isLoading) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () => context.read<LikedPostsCubit>().refresh(),
            child: OptimizedListView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              itemCount: state.likedPosts.length + (state.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= state.likedPosts.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final Post post = state.likedPosts[index];
                return PostCard(
                  post: post,
                  onToggleLike: () =>
                      context.read<LikedPostsCubit>().toggleLike(post),
                  onToggleScrap: () =>
                      context.read<LikedPostsCubit>().toggleScrap(post),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.favorite_outline,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const Gap(16),
            Text(
              '좋아요한 글이 없습니다',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Gap(8),
            Text(
              '마음에 드는 게시글에 좋아요를 눌러보세요.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const Gap(24),
            FilledButton.icon(
              onPressed: () => context.go('/community'),
              icon: const Icon(Icons.explore_outlined),
              label: const Text('커뮤니티 둘러보기'),
            ),
          ],
        ),
      ),
    );
  }
}
