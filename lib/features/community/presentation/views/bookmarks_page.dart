import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/post.dart';
import '../cubit/bookmarks_cubit.dart';
import '../widgets/post_card.dart';

class BookmarksPage extends StatefulWidget {
  const BookmarksPage({super.key});

  @override
  State<BookmarksPage> createState() => _BookmarksPageState();
}

class _BookmarksPageState extends State<BookmarksPage> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    context.read<BookmarksCubit>().loadInitial();
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
      context.read<BookmarksCubit>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('북마크'),
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
      body: BlocBuilder<BookmarksCubit, BookmarksState>(
        builder: (context, state) {
          if (state.isLoading && state.bookmarks.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.bookmarks.isEmpty && !state.isLoading) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () => context.read<BookmarksCubit>().refresh(),
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              itemCount: state.bookmarks.length + (state.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= state.bookmarks.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final Post post = state.bookmarks[index];
                return PostCard(
                  post: post,
                  onToggleLike: () =>
                      context.read<BookmarksCubit>().toggleLike(post),
                  onToggleBookmark: () =>
                      context.read<BookmarksCubit>().removeBookmark(post),
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
              '저장된 북마크가 없습니다',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Gap(8),
            Text(
              '관심 있는 게시글에 북마크를 추가해보세요.',
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
        title: const Text('모든 북마크 삭제'),
        content: const Text('모든 북마크를 삭제하시겠습니까?\n삭제된 북마크는 복구할 수 없습니다.'),
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
              await context.read<BookmarksCubit>().clearAll();
              if (mounted) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('모든 북마크를 삭제했습니다.')),
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
