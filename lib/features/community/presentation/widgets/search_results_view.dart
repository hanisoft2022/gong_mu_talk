import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import '../../domain/models/post.dart';
import '../../domain/models/search_result.dart';
import '../cubit/search_cubit.dart';
import '../widgets/post_card.dart';
import '../widgets/comment_search_result_card.dart';
import '../../../../core/utils/performance_optimizations.dart';

class SearchResultsView extends StatelessWidget {
  const SearchResultsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SearchCubit, SearchState>(
      builder: (context, state) {
        if (state.error != null) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildSearchErrorCard(context, state.error!),
          );
        }

        final SearchCubit searchCubit = context.read<SearchCubit>();
        final bool showPosts = state.scope != SearchScope.comments;
        final bool showComments =
            state.scope == SearchScope.all || state.scope == SearchScope.comments;
        final bool noPosts = !showPosts || state.postResults.isEmpty;
        final bool noComments = !showComments || state.commentResults.isEmpty;

        final List<Widget> widgets = <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildSearchResultsHeader(context, state),
          ),
          const Gap(12),
        ];

        if (!state.isLoading && noPosts && noComments) {
          widgets.add(
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildSearchEmptyResults(context, state),
            ),
          );
          return Column(children: widgets);
        }

        if (showPosts) {
          widgets.add(
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildSearchSectionHeader(
                context,
                '글 결과',
                state.postResults.length,
              ),
            ),
          );
          if (state.postResults.isEmpty && !state.isLoading) {
            widgets.add(
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildNoSectionResults(context, '글'),
              ),
            );
          } else {
            widgets.addAll(
              state.postResults.map(
                (Post post) => Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: MemoizedWidget(
                    key: ValueKey('search_post_${post.id}'),
                    dependencies: [
                      post.id,
                      post.isLiked,
                      post.likeCount,
                      post.isScrapped,
                      post.commentCount,
                    ],
                    child: PostCard(
                      post: post,
                      onToggleLike: () {
                        PerformanceProfiler.start('toggle_like_search');
                        searchCubit.toggleLike(post);
                        PerformanceProfiler.end('toggle_like_search');
                      },
                      onToggleScrap: () {
                        PerformanceProfiler.start('toggle_scrap_search');
                        searchCubit.toggleScrap(post);
                        PerformanceProfiler.end('toggle_scrap_search');
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
              child: _buildSearchSectionHeader(
                context,
                '댓글 결과',
                state.commentResults.length,
              ),
            ),
          );
          if (state.commentResults.isEmpty && !state.isLoading) {
            widgets.add(
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildNoSectionResults(context, '댓글'),
              ),
            );
          } else {
            widgets.addAll(
              state.commentResults.map(
                (CommentSearchResult result) => Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: CommentSearchResultCard(result: result),
                ),
              ),
            );
          }
        }

        if (state.isLoading) {
          widgets.add(
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        return Column(children: widgets);
      },
    );
  }

  Widget _buildSearchErrorCard(BuildContext context, String error) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const Gap(8),
            Text(
              '검색 중 오류가 발생했습니다',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const Gap(4),
            Text(
              error,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResultsHeader(BuildContext context, SearchState state) {
    final int totalResults = state.postResults.length + state.commentResults.length;
    return Text(
      '검색 결과 $totalResults개',
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildSearchEmptyResults(BuildContext context, SearchState state) {
    return Column(
      children: [
        const Icon(Icons.search_off, size: 48, color: Colors.grey),
        const Gap(16),
        Text(
          '검색 결과가 없습니다',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const Gap(8),
        Text(
          '다른 키워드로 검색해보세요',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchSectionHeader(BuildContext context, String title, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        '\$title (\$count)',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildNoSectionResults(BuildContext context, String section) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        '\$section 결과가 없습니다',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Colors.grey,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}