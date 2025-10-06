import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/performance_optimizations.dart';

import '../../domain/models/post.dart';
import '../cubit/scrap_cubit.dart';
import '../widgets/post_card.dart';

class ScrapPage extends StatefulWidget {
  const ScrapPage({super.key});

  @override
  State<ScrapPage> createState() => _ScrapPageState();
}

class _ScrapPageState extends State<ScrapPage> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    context.read<ScrapCubit>().loadInitial();
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
      context.read<ScrapCubit>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('스크랩'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear_all',
                child: ListTile(
                  leading: Icon(Icons.clear_all),
                  title: Text('모두 삭제'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'clear_all') {
                _showClearAllDialog();
              }
            },
          ),
        ],
      ),
      body: BlocBuilder<ScrapCubit, ScrapState>(
        builder: (context, state) {
          if (state.isLoading && state.scraps.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.scraps.isEmpty && !state.isLoading) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () => context.read<ScrapCubit>().refresh(),
            child: OptimizedListView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
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

  Widget _buildEmptyState() {
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

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('모든 스크랩 삭제'),
        content: const Text('모든 스크랩을 삭제하시겠습니까?\n삭제된 스크랩은 복구할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              if (mounted) navigator.pop();
              await context.read<ScrapCubit>().clearAll();
              if (mounted) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('모든 스크랩을 삭제했습니다.')),
                );
              }
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}
