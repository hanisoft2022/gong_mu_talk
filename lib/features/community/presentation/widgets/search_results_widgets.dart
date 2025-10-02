/// Search Results Widgets - Components for displaying search results
///
/// Responsibilities:
/// - Search results header with query display
/// - Section headers for posts/comments
/// - Empty results state
/// - Error state for search
/// - Posts and comments results rendering

library;
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../domain/models/post.dart';
import '../../domain/models/search_result.dart';
import '../cubit/search_cubit.dart';
import '../../../../core/utils/performance_optimizations.dart';
import 'post_card.dart';
import 'comment_search_result_card.dart';

/// Header showing search query and scope
class SearchResultsHeader extends StatelessWidget {
  const SearchResultsHeader({
    required this.searchState,
    required this.onClose,
    super.key,
  });

  final SearchState searchState;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                "'${searchState.query}' 검색 결과",
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            TextButton.icon(
              onPressed: onClose,
              icon: const Icon(Icons.close),
              label: const Text('검색 닫기'),
            ),
          ],
        ),
        const Gap(4),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Text(
            '검색 범위 · ${searchState.scope.label}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// Section header for posts or comments results
class SearchSectionHeader extends StatelessWidget {
  const SearchSectionHeader({
    required this.title,
    required this.count,
    super.key,
  });

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const Gap(6),
          Text(
            '$count',
            style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// Empty results message for a section
class NoSectionResults extends StatelessWidget {
  const NoSectionResults({
    required this.target,
    super.key,
  });

  final String target;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        '$target 결과가 없습니다.',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }
}

/// Empty search results card
class SearchEmptyResults extends StatelessWidget {
  const SearchEmptyResults({
    required this.searchState,
    required this.onClear,
    super.key,
  });

  final SearchState searchState;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String target;
    switch (searchState.scope) {
      case SearchScope.all:
        target = '글과 댓글';
        break;
      case SearchScope.posts:
        target = '글';
        break;
      case SearchScope.comments:
        target = '댓글';
        break;
      case SearchScope.author:
        target = '작성자';
        break;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("'${searchState.query}'에 대한 $target 결과가 없습니다.", style: theme.textTheme.titleMedium),
            const Gap(8),
            Text(
              '검색어를 바꾸거나 범위를 조정해보세요.',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const Gap(12),
            TextButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.refresh),
              label: const Text('새로 검색'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Error card for search failures
class SearchErrorCard extends StatelessWidget {
  const SearchErrorCard({
    required this.message,
    required this.onRetry,
    super.key,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red),
                const Gap(8),
                Expanded(
                  child: Text('검색 중 오류가 발생했습니다.', style: Theme.of(context).textTheme.titleMedium),
                ),
              ],
            ),
            const Gap(8),
            Text(message, style: Theme.of(context).textTheme.bodySmall),
            const Gap(12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Builds the complete search results section
class SearchResultsSection extends StatelessWidget {
  const SearchResultsSection({
    required this.searchState,
    required this.searchCubit,
    required this.onClearSearch,
    required this.onCloseSearch,
    super.key,
  });

  final SearchState searchState;
  final SearchCubit searchCubit;
  final VoidCallback onClearSearch;
  final VoidCallback onCloseSearch;

  @override
  Widget build(BuildContext context) {
    if (searchState.error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SearchErrorCard(
          message: searchState.error!,
          onRetry: () => searchCubit.refresh(),
        ),
      );
    }

    final bool showPosts = searchState.scope != SearchScope.comments;
    final bool showComments = searchState.scope == SearchScope.all || searchState.scope == SearchScope.comments;
    final bool noPosts = !showPosts || searchState.postResults.isEmpty;
    final bool noComments = !showComments || searchState.commentResults.isEmpty;

    final List<Widget> widgets = <Widget>[
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SearchResultsHeader(
          searchState: searchState,
          onClose: onCloseSearch,
        ),
      ),
      const Gap(12),
    ];

    if (!searchState.isLoading && noPosts && noComments) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SearchEmptyResults(
            searchState: searchState,
            onClear: onClearSearch,
          ),
        ),
      );
      return Column(children: widgets);
    }

    if (showPosts) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SearchSectionHeader(title: '글 결과', count: searchState.postResults.length),
        ),
      );
      if (searchState.postResults.isEmpty && !searchState.isLoading) {
        widgets.add(
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: NoSectionResults(target: '글'),
          ),
        );
      } else {
        widgets.addAll(
          searchState.postResults.map(
            (Post post) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: MemoizedWidget(
                key: ValueKey('search_post_${post.id}'),
                dependencies: [
                  post.id,
                  post.isLiked,
                  post.likeCount,
                  post.isBookmarked,
                  post.commentCount,
                ],
                child: PostCard(
                  post: post,
                  onToggleLike: () {
                    PerformanceProfiler.start('toggle_like_search');
                    searchCubit.toggleLike(post);
                    PerformanceProfiler.end('toggle_like_search');
                  },
                  onToggleBookmark: () {
                    PerformanceProfiler.start('toggle_bookmark_search');
                    searchCubit.toggleBookmark(post);
                    PerformanceProfiler.end('toggle_bookmark_search');
                  },
                ),
              ),
            ),
          ),
        );
      }
      widgets.add(const Gap(12));
    }

    if (showComments) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SearchSectionHeader(title: '댓글 결과', count: searchState.commentResults.length),
        ),
      );
      if (searchState.commentResults.isEmpty && !searchState.isLoading) {
        widgets.add(
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: NoSectionResults(target: '댓글'),
          ),
        );
      } else {
        widgets.addAll(
          searchState.commentResults.map(
            (CommentSearchResult result) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: CommentSearchResultCard(result: result),
            ),
          ),
        );
      }
    }

    if (searchState.isLoading) {
      widgets.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Column(children: widgets);
  }
}
