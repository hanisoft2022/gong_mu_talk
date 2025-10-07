import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/performance_optimizations.dart';
import '../../../../routing/app_router.dart';
import '../../../profile/domain/user_profile.dart';
import '../../../profile/domain/career_track.dart';
import '../../domain/models/post.dart';
import '../../domain/models/search_suggestion.dart';
import '../../domain/models/search_result.dart';
import '../cubit/search_cubit.dart';
import '../widgets/comment_search_result_card.dart';
import '../widgets/post_card.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key, this.initialQuery});

  final String? initialQuery;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late final TextEditingController _searchController;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery ?? '');
    _scrollController = ScrollController()..addListener(_onScroll);

    if (widget.initialQuery?.isNotEmpty == true) {
      context.read<SearchCubit>().search(widget.initialQuery!);
    } else {
      context.read<SearchCubit>().loadSuggestions();
    }

    context.read<SearchCubit>().onQueryChanged(_searchController.text);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<SearchCubit>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<SearchCubit, SearchState>(
          builder: (context, state) {
            String hintText;
            switch (state.scope) {
              case SearchScope.all:
                hintText = '글+댓글 검색';
                break;
              case SearchScope.posts:
                hintText = '글 검색';
                break;
              case SearchScope.comments:
                hintText = '댓글 검색';
                break;
              case SearchScope.author:
                hintText = '글 작성자 검색';
                break;
            }

            return TextField(
              controller: _searchController,
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintText: hintText,
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (query) => _performSearch(query.trim()),
              onChanged: (value) =>
                  context.read<SearchCubit>().onQueryChanged(value),
              autofocus: widget.initialQuery?.isEmpty ?? true,
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _performSearch(_searchController.text.trim()),
          ),
          IconButton(icon: const Icon(Icons.clear), onPressed: _clearSearch),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: BlocBuilder<SearchCubit, SearchState>(
            builder: (context, state) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: SegmentedButton<SearchScope>(
                  segments: const <ButtonSegment<SearchScope>>[
                    ButtonSegment<SearchScope>(
                      value: SearchScope.all,
                      label: Text('글+댓글'),
                      icon: Icon(Icons.all_inbox_outlined),
                    ),
                    ButtonSegment<SearchScope>(
                      value: SearchScope.posts,
                      label: Text('글'),
                      icon: Icon(Icons.article_outlined),
                    ),
                    ButtonSegment<SearchScope>(
                      value: SearchScope.comments,
                      label: Text('댓글'),
                      icon: Icon(Icons.mode_comment_outlined),
                    ),
                    ButtonSegment<SearchScope>(
                      value: SearchScope.author,
                      label: Text('글 작성자'),
                      icon: Icon(Icons.person_search_outlined),
                    ),
                  ],
                  selected: <SearchScope>{state.scope},
                  onSelectionChanged: (selection) {
                    context.read<SearchCubit>().changeScope(selection.first);
                  },
                ),
              );
            },
          ),
        ),
      ),
      body: BlocBuilder<SearchCubit, SearchState>(
        builder: (context, state) {
          final Widget content = _buildBody(state);
          final Widget overlay = _buildAutocompleteOverlay(state);
          if (overlay is SizedBox) {
            return content;
          }
          return Stack(children: [content, overlay]);
        },
      ),
    );
  }

  Widget _buildBody(SearchState state) {
    final bool showPosts =
        state.scope != SearchScope.comments &&
        state.scope != SearchScope.author;
    final bool showComments =
        state.scope == SearchScope.all || state.scope == SearchScope.comments;
    final bool showUsers = state.scope == SearchScope.author;

    if (state.isLoading &&
        state.postResults.isEmpty &&
        state.commentResults.isEmpty &&
        state.userResults.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.query.isEmpty) {
      return _buildSuggestions(state.suggestions);
    }

    final bool noPosts = !showPosts || state.postResults.isEmpty;
    final bool noComments = !showComments || state.commentResults.isEmpty;
    final bool noUsers = !showUsers || state.userResults.isEmpty;
    if (noPosts && noComments && noUsers && !state.isLoading) {
      return _buildEmptyResults(state);
    }

    return RefreshIndicator(
      onRefresh: () => context.read<SearchCubit>().refresh(),
      child: OptimizedListView(
        controller: _scrollController,
        itemCount: 1,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildResultsHeader(state),
              if (showUsers) ...[
                _buildSectionHeader('사용자', state.userResults.length),
                if (state.userResults.isEmpty && !state.isLoading)
                  _buildNoSectionResults('사용자')
                else
                  ...state.userResults.map(
                    (UserProfile user) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildUserResultCard(user),
                    ),
                  ),
                const Gap(8),
              ],
              if (showPosts) ...[
                _buildSectionHeader('글 결과', state.postResults.length),
                if (state.postResults.isEmpty && !state.isLoading)
                  _buildNoSectionResults('글')
                else
                  ...state.postResults.map(
                    (Post post) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: PostCard(
                        post: post,
                        onToggleLike: () =>
                            context.read<SearchCubit>().toggleLike(post),
                        onToggleScrap: () =>
                            context.read<SearchCubit>().toggleScrap(post),
                      ),
                    ),
                  ),
                const Gap(8),
              ],
              if (showComments) ...[
                _buildSectionHeader('댓글 결과', state.commentResults.length),
                if (state.commentResults.isEmpty && !state.isLoading)
                  _buildNoSectionResults('댓글')
                else
                  ...state.commentResults.map(
                    (CommentSearchResult result) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: CommentSearchResultCard(result: result),
                    ),
                  ),
              ],
              if (state.isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestions(List<SearchSuggestion> suggestions) {
    if (suggestions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_outlined, size: 64),
            Gap(16),
            Text('검색어를 입력하세요'),
          ],
        ),
      );
    }

    return OptimizedListView(
      itemCount: 1,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.trending_up_outlined),
                const Gap(8),
                Text(
                  '인기 검색어',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Gap(16),
            ...suggestions.map(
              (suggestion) => ListTile(
                leading: const Icon(Icons.search_outlined),
                title: Text(suggestion.token),
                subtitle: Text('${suggestion.count}회 검색'),
                onTap: () => _performSearch(suggestion.token),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyResults(SearchState state) {
    final String target;
    switch (state.scope) {
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

    final String query = state.query;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_outlined, size: 64),
            const Gap(16),
            Text(
              "'$query'에 대한 $target 검색 결과가 없습니다.",
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const Gap(8),
            const Text('다른 검색어로 시도해보세요.', textAlign: TextAlign.center),
            const Gap(24),
            FilledButton.icon(
              onPressed: _clearSearch,
              icon: const Icon(Icons.refresh),
              label: const Text('새로 검색'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutocompleteOverlay(SearchState state) {
    final List<String> suggestions = state.autocomplete;
    final String draft = state.draftQuery.trim();
    if (suggestions.isEmpty || draft.isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 12,
      left: 16,
      right: 16,
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 240),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: suggestions.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final String token = suggestions[index];
              return ListTile(
                leading: const Icon(Icons.search),
                title: Text(token),
                onTap: () {
                  _searchController
                    ..text = token
                    ..selection = TextSelection.fromPosition(
                      TextPosition(offset: token.length),
                    );
                  context.read<SearchCubit>().onQueryChanged(token);
                  _performSearch(token);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildResultsHeader(SearchState state) {
    final ThemeData theme = Theme.of(context);
    final bool showPosts = state.scope != SearchScope.comments;
    final bool showComments =
        state.scope == SearchScope.all || state.scope == SearchScope.comments;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: RichText(
              text: TextSpan(
                style: theme.textTheme.titleMedium,
                children: [
                  const TextSpan(text: "'"),
                  TextSpan(
                    text: state.query,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const TextSpan(text: "' 검색 결과 "),
                  if (showPosts)
                    TextSpan(
                      text: '글 ${state.postResults.length}개',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  if (showPosts && showComments)
                    TextSpan(text: ' · ', style: theme.textTheme.titleMedium),
                  if (showComments)
                    TextSpan(
                      text: '댓글 ${state.commentResults.length}개',
                      style: TextStyle(
                        color: theme.colorScheme.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _performSearch(String query) {
    if (query.isEmpty) return;

    _searchController.text = query;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: _searchController.text.length),
    );
    context.read<SearchCubit>().search(query);
    FocusScope.of(context).unfocus();
  }

  Widget _buildSectionHeader(String title, int count) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const Gap(6),
          Text(
            '$count개',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSectionResults(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      alignment: Alignment.center,
      child: Text(
        '$label 검색 결과가 없습니다.',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }

  Widget _buildUserResultCard(UserProfile user) {
    final ThemeData theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () {
          context.push('${ProfileRoute.path}/user/${user.uid}');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Career Emoji (large)
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(
                    alpha: 0.3,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: Text(
                    user.careerTrack.emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const Gap(16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.nickname,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Gap(4),
                    Text(
                      '팔로워 ${user.followerCount}명',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<SearchCubit>().clearSearch();
  }
}
