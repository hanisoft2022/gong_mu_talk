import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../profile/domain/career_track.dart';
import '../../../profile/domain/lounge_info.dart';
import '../../domain/models/feed_filters.dart';
import '../../domain/models/post.dart';
import '../../domain/models/search_result.dart';
import '../../domain/models/search_suggestion.dart';
import '../cubit/community_feed_cubit.dart';
import '../cubit/search_cubit.dart';
import '../widgets/inline_post_composer.dart';
import '../widgets/post_card.dart';
import '../widgets/comment_search_result_card.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/community_error_view.dart';
import '../widgets/sort_button.dart';
import '../widgets/search_icon_button.dart';
import '../../../../di/di.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/utils/performance_optimizations.dart';
import '../../../../routing/app_router.dart';
import '../../../../common/widgets/global_app_bar_actions.dart';
import '../../../../common/widgets/app_logo_button.dart';
import '../../../../common/widgets/auth_required_view.dart';

class CommunityFeedPage extends StatefulWidget {
  const CommunityFeedPage({super.key});

  @override
  State<CommunityFeedPage> createState() => _CommunityFeedPageState();
}

class _CommunityFeedPageState extends State<CommunityFeedPage> {
  late final ScrollController _scrollController;
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;
  bool _isSearchExpanded = false;
  LoungeScope? _lastScope;
  SearchCubit? _searchCubit;
  bool _isAppBarElevated = false;
  bool _isModalOpen = false;
  static final SearchScope _persistentSearchScope = SearchScope.all;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode()
      ..addListener(() {
        if (!_searchFocusNode.hasFocus &&
            mounted &&
            _searchController.text.trim().isEmpty &&
            !_isModalOpen) {
          setState(() {
            _isSearchExpanded = false;
          });
        }
      });
    context.read<CommunityFeedCubit>().loadInitial();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final CommunityFeedCubit cubit = context.read<CommunityFeedCubit>();
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      PerformanceProfiler.start('fetch_more_posts');
      cubit.fetchMore();
      PerformanceProfiler.end('fetch_more_posts');
    }

    final bool shouldElevate = _scrollController.hasClients && _scrollController.offset > 4;
    if (shouldElevate != _isAppBarElevated && mounted) {
      // Defer setState to avoid conflicts with semantic tree updates
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && shouldElevate != _isAppBarElevated) {
          setState(() => _isAppBarElevated = shouldElevate);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SearchCubit>(
      create: (_) {
        final cubit = getIt<SearchCubit>();
        cubit.loadSuggestions();
        // Apply persistent scope after the initial state is set
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_persistentSearchScope != SearchScope.all) {
            cubit.changeScope(_persistentSearchScope);
          }
        });
        return cubit;
      },
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          return BlocBuilder<CommunityFeedCubit, CommunityFeedState>(
            builder: (context, feedState) {
              return BlocBuilder<SearchCubit, SearchState>(
                builder: (context, searchState) {
                  // 라운지 접근 권한 확인 - 로그인만으로는 전체 탭도 볼 수 없음
                  if (!authState.hasLoungeAccess) {
                    return Scaffold(
                      body: NestedScrollView(
                        controller: _scrollController,
                        headerSliverBuilder: (context, _) => <Widget>[
                          _buildLoungeSliverAppBar(context, feedState),
                        ],
                        body: const AuthRequiredView(message: '라운지 기능을 이용하려면\n공직자 메일 인증을 완료해주세요.'),
                      ),
                    );
                  }

                  _searchCubit ??= context.read<SearchCubit>();
                  if (_lastScope != feedState.scope) {
                    _lastScope = feedState.scope;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) {
                        return;
                      }
                      if (_scrollController.hasClients) {
                        _scrollController.animateTo(
                          0,
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOut,
                        );
                      }
                    });
                  }

                  final bool showSearchResults =
                      _isSearchExpanded && (searchState.query.isNotEmpty || searchState.isLoading);

                  if (!showSearchResults &&
                      (feedState.status == CommunityFeedStatus.initial ||
                          feedState.status == CommunityFeedStatus.loading) &&
                      feedState.posts.isEmpty) {
                    return Scaffold(
                      body: NestedScrollView(
                        controller: _scrollController,
                        headerSliverBuilder: (context, _) => <Widget>[
                          _buildLoungeSliverAppBar(context, feedState),
                        ],
                        body: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const Gap(16),
                              Text(
                                '라운지 게시물을 불러오고 있습니다...',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  if (!showSearchResults &&
                      feedState.status == CommunityFeedStatus.error &&
                      feedState.posts.isEmpty) {
                    return Scaffold(
                      body: CommunityErrorView(
                        message: feedState.errorMessage,
                        onRetry: () => context.read<CommunityFeedCubit>().loadInitial(),
                      ),
                    );
                  }

                  final Future<void> Function() onRefresh = showSearchResults
                      ? () => (_searchCubit ?? context.read<SearchCubit>()).refresh()
                      : () => context.read<CommunityFeedCubit>().refresh();

                  final List<Widget> children = <Widget>[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: InlinePostComposer(scope: feedState.scope),
                    ),
                    const Gap(12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildSearchAndSortRow(context, feedState, searchState),
                    ),
                    const Gap(16),
                  ];

                  if (_isSearchExpanded && !showSearchResults) {
                    final Widget? suggestionsCard = _buildSearchSuggestionsCard(
                      context,
                      searchState,
                    );
                    if (suggestionsCard != null) {
                      children
                        ..add(
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: suggestionsCard,
                          ),
                        )
                        ..add(const Gap(12));
                    }
                    children.addAll(_buildFeedSection(context, feedState, authState));
                  } else if (showSearchResults) {
                    children.addAll(_buildSearchResultsSection(context, searchState));
                  } else {
                    children.addAll(_buildFeedSection(context, feedState, authState));
                  }

                  return Scaffold(
                    body: NestedScrollView(
                      controller: _scrollController,
                      headerSliverBuilder: (context, _) => <Widget>[
                        _buildLoungeSliverAppBar(context, feedState),
                      ],
                      body: RefreshIndicator(
                        onRefresh: onRefresh,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          switchInCurve: Curves.easeOutQuart,
                          switchOutCurve: Curves.easeInQuart,
                          transitionBuilder: (Widget child, Animation<double> animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position:
                                    Tween<Offset>(
                                      begin: const Offset(0.0, 0.03),
                                      end: Offset.zero,
                                    ).animate(
                                      CurvedAnimation(
                                        parent: animation,
                                        curve: Curves.easeOutQuart,
                                      ),
                                    ),
                                child: child,
                              ),
                            );
                          },
                          child: OptimizedListView(
                            key: ValueKey<String>(
                              'feed_${feedState.scope.name}_${feedState.sort.name}_${showSearchResults ? 'search' : 'feed'}_${searchState.scope.name}_${searchState.query}',
                            ),
                            itemCount: children.length,
                            itemBuilder: (context, index) => children[index],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSearchAndSortRow(
    BuildContext context,
    CommunityFeedState feedState,
    SearchState searchState,
  ) {
    final ThemeData theme = Theme.of(context);
    final CommunityFeedCubit feedCubit = context.read<CommunityFeedCubit>();

    return SizedBox(
      height: 44,
      child: Row(
        children: [
          if (!_isSearchExpanded) _buildCollapsedSearchTrigger(theme, searchState),
          if (_isSearchExpanded) Expanded(child: _buildExpandedSearchField(context, searchState)),
          if (!_isSearchExpanded) ...[
            const Spacer(),
            _buildSortButtons(feedState.sort, feedCubit.changeSort),
          ],
        ],
      ),
    );
  }

  Widget _buildCollapsedSearchTrigger(ThemeData theme, SearchState searchState) {
    final String placeholder = _searchController.text.trim();

    // If there's search text, show it in a compact form
    if (placeholder.isNotEmpty) {
      return SizedBox(
        height: 44,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: DecoratedBox(
            decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _expandSearchField,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Icon(Icons.search, size: 18, color: theme.colorScheme.onSurfaceVariant),
                      const Gap(8),
                      Expanded(
                        child: Text(
                          placeholder,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Otherwise, show just a search icon
    return SearchIconButton(
      icon: Icons.search,
      tooltip: '검색',
      onPressed: _expandSearchField,
      color: theme.colorScheme.onSurfaceVariant,
    );
  }

  Widget _buildExpandedSearchField(BuildContext context, SearchState searchState) {
    final ThemeData theme = Theme.of(context);
    final BorderRadius radius = BorderRadius.circular(12);
    final bool hasText = _searchController.text.trim().isNotEmpty;

    // Get current hint text based on search scope
    String getHintText(SearchScope scope) {
      String hintText;
      switch (scope) {
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
      return hintText;
    }

    return SizedBox(
      height: 44,
      child: ClipRRect(
        key: ValueKey<String>('expanded_${searchState.scope.name}_${hasText ? 'filled' : 'empty'}'),
        borderRadius: radius,
        child: DecoratedBox(
          decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest),
          child: Row(
            children: [
              SearchIconButton(
                icon: Icons.arrow_back,
                tooltip: '검색 닫기',
                onPressed: _collapseSearchField,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              Expanded(
                child: TextField(
                  key: ValueKey('search_field_${searchState.scope.name}'),
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  textInputAction: TextInputAction.search,
                  onSubmitted: _onSearchSubmitted,
                  onChanged: _onQueryChanged,
                  style: theme.textTheme.bodyMedium,
                  decoration: InputDecoration(
                    hintText: () {
                      final hint = getHintText(searchState.scope);
                      return hint;
                    }(),
                    hintStyle: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    filled: true,
                    fillColor: Colors.transparent,
                  ),
                  cursorColor: theme.colorScheme.primary,
                ),
              ),
              if (searchState.isLoading && searchState.query.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              if (hasText)
                SearchIconButton(
                  icon: Icons.close,
                  tooltip: '검색어 지우기',
                  onPressed: _clearSearchQuery,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              SearchIconButton(
                icon: Icons.tune,
                tooltip: '검색 옵션',
                onPressed: () {
                  _showSearchOptionsBottomSheet(context, searchState);
                },
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFeedSection(
    BuildContext context,
    CommunityFeedState state,
    AuthState authState,
  ) {
    final CommunityFeedCubit cubit = context.read<CommunityFeedCubit>();
    final bool showSerialGuide = state.scope == LoungeScope.serial && !authState.hasSerialTabAccess;
    final bool showEmptyPosts = state.posts.isEmpty && !showSerialGuide;

    if (showSerialGuide) {
      return <Widget>[
        EmptyStateView(
          icon: Icons.description_outlined,
          title: '급여 명세서를 통해서 본인의 직렬을 인증하세요',
          message: '내 직렬 탭을 이용하려면 급여명세서 인증을 완료해주세요.',
          onRefresh: () => cubit.refresh(),
        ),
      ];
    }

    if (showEmptyPosts) {
      return <Widget>[
        EmptyStateView(
          icon: Icons.chat_bubble_outline,
          title: '아직 게시물이 없습니다.',
          message: '첫 번째 글을 올려 동료 공무원과 이야기를 시작해보세요!',
          onRefresh: () => cubit.refresh(),
        ),
      ];
    }

    const int adInterval = 10;
    int renderedCount = 0;
    final int totalPosts = state.posts.length;
    final List<Widget> children = <Widget>[];

    for (final Post post in state.posts) {
      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: MemoizedWidget(
            key: ValueKey('post_${post.id}'),
            dependencies: [
              post.id,
              post.isLiked,
              post.likeCount,
              post.isBookmarked,
              post.commentCount,
              state.scope,
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
              displayScope: state.scope,
              showShare: false,
              showBookmark: false,
            ),
          ),
        ),
      );
      renderedCount += 1;

      final bool shouldInsertAd =
          state.showAds && renderedCount % adInterval == 0 && renderedCount < totalPosts;

      if (shouldInsertAd) {
        children
          ..add(const SizedBox.shrink())
          ..add(const SizedBox(height: 12));
      }
    }

    if (state.isLoadingMore) {
      children.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return children;
  }

  Widget? _buildSearchSuggestionsCard(BuildContext context, SearchState searchState) {
    final ThemeData theme = Theme.of(context);
    final List<SearchSuggestion> suggestions = searchState.suggestions;
    final List<String> recentSearches = searchState.recentSearches;

    if (suggestions.isEmpty && recentSearches.isEmpty) {
      return null;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 최근 검색어 섹션
            if (recentSearches.isNotEmpty) ...[
              Row(
                children: [
                  Icon(Icons.history, size: 18, color: theme.colorScheme.onSurfaceVariant),
                  const Gap(8),
                  Text(
                    '최근 검색어',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      (_searchCubit ?? context.read<SearchCubit>()).clearRecentSearches();
                    },
                    icon: Icon(
                      Icons.clear_all,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    tooltip: '전체 삭제',
                  ),
                ],
              ),
              const Gap(12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: recentSearches
                    .map(
                      (String search) => InputChip(
                        label: Text(search),
                        onPressed: () => _useSuggestion(search),
                        onDeleted: () {
                          (_searchCubit ?? context.read<SearchCubit>()).removeRecentSearch(search);
                        },
                        deleteIcon: Icon(
                          Icons.close,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    )
                    .toList(growable: false),
              ),
              if (suggestions.isNotEmpty) const Gap(20),
            ],
            // 인기 검색어 섹션
            if (suggestions.isNotEmpty) ...[
              Row(
                children: [
                  Icon(
                    Icons.local_fire_department_outlined,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const Gap(8),
                  Text(
                    '인기 검색어',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const Gap(12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: suggestions
                    .map(
                      (SearchSuggestion suggestion) => ActionChip(
                        label: Text(suggestion.token),
                        onPressed: () => _useSuggestion(suggestion.token),
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSearchResultsSection(BuildContext context, SearchState state) {
    if (state.error != null) {
      return <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildSearchErrorCard(context, state.error!),
        ),
      ];
    }

    final SearchCubit searchCubit = _searchCubit ?? context.read<SearchCubit>();
    final bool showPosts = state.scope != SearchScope.comments;
    final bool showComments = state.scope == SearchScope.all || state.scope == SearchScope.comments;
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
      return widgets;
    }

    if (showPosts) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildSearchSectionHeader(context, '글 결과', state.postResults.length),
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
          child: _buildSearchSectionHeader(context, '댓글 결과', state.commentResults.length),
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
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return widgets;
  }

  Widget _buildSearchResultsHeader(BuildContext context, SearchState state) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                "'${state.query}' 검색 결과",
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            TextButton.icon(
              onPressed: _collapseSearchField,
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
            '검색 범위 · ${state.scope.label}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchSectionHeader(BuildContext context, String title, int count) {
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

  Widget _buildNoSectionResults(BuildContext context, String target) {
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

  Widget _buildSearchEmptyResults(BuildContext context, SearchState state) {
    final ThemeData theme = Theme.of(context);
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("'${state.query}'에 대한 $target 결과가 없습니다.", style: theme.textTheme.titleMedium),
            const Gap(8),
            Text(
              '검색어를 바꾸거나 범위를 조정해보세요.',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const Gap(12),
            TextButton.icon(
              onPressed: _clearSearchQuery,
              icon: const Icon(Icons.refresh),
              label: const Text('새로 검색'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchErrorCard(BuildContext context, String message) {
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
              onPressed: () => (_searchCubit ?? context.read<SearchCubit>()).refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }

  void _expandSearchField() {
    if (_isSearchExpanded) {
      return;
    }
    setState(() {
      _isSearchExpanded = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _searchFocusNode.requestFocus();
    });

    final SearchCubit searchCubit = _searchCubit ?? context.read<SearchCubit>();
    if (searchCubit.state.suggestions.isEmpty) {
      searchCubit.loadSuggestions();
    }
    // 최근 검색어 로드
    if (searchCubit.state.recentSearches.isEmpty) {
      searchCubit.loadRecentSearches();
    }
  }

  void _collapseSearchField() {
    if (!_isSearchExpanded) {
      return;
    }
    setState(() {
      _isSearchExpanded = false;
    });
    _searchFocusNode.unfocus();
    _searchController.clear();
    (_searchCubit ?? context.read<SearchCubit>()).clearSearch();
  }

  Widget _buildSortButtons(LoungeSort currentSort, ValueChanged<LoungeSort> onSelect) {
    final ThemeData theme = Theme.of(context);

    return Row(
      children: [
        SortButton(
          sortType: LoungeSort.latest,
          isSelected: currentSort == LoungeSort.latest,
          onPressed: () {
            PerformanceProfiler.start('change_sort');
            onSelect(LoungeSort.latest);
            PerformanceProfiler.end('change_sort');
          },
          theme: theme,
        ),
        const Gap(8),
        SortButton(
          sortType: LoungeSort.popular,
          isSelected: currentSort == LoungeSort.popular,
          onPressed: () {
            PerformanceProfiler.start('change_sort');
            onSelect(LoungeSort.popular);
            PerformanceProfiler.end('change_sort');
          },
          theme: theme,
        ),
        const Gap(8),
        SortButton(
          sortType: LoungeSort.likes,
          isSelected: currentSort == LoungeSort.likes,
          onPressed: () {
            PerformanceProfiler.start('change_sort');
            onSelect(LoungeSort.likes);
            PerformanceProfiler.end('change_sort');
          },
          theme: theme,
        ),
      ],
    );
  }

  void _clearSearchQuery() {
    _searchController.clear();
    (_searchCubit ?? context.read<SearchCubit>()).clearSearch();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _searchFocusNode.requestFocus();
    });
  }

  void _onQueryChanged(String value) {
    (_searchCubit ?? context.read<SearchCubit>()).onQueryChanged(value);
  }

  void _onSearchSubmitted(String value) {
    final String trimmed = value.trim();
    if (trimmed.isEmpty) {
      return;
    }
    PerformanceProfiler.start('search_execution');
    (_searchCubit ?? context.read<SearchCubit>()).search(trimmed);
    PerformanceProfiler.end('search_execution');
  }

  void _showSearchOptionsBottomSheet(BuildContext context, SearchState searchState) {
    setState(() {
      _isModalOpen = true;
    });

    final CommunityFeedState feedState = context.read<CommunityFeedCubit>().state;

    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext bottomSheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '검색 옵션',
                  style: Theme.of(
                    bottomSheetContext,
                  ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const Divider(height: 1),
              ...SearchScope.values
                  .where((SearchScope scope) {
                    // 전체 탭에서는 글 작성자 검색 옵션 제외
                    if (feedState.scope == LoungeScope.all && scope == SearchScope.author) {
                      return false;
                    }
                    return true;
                  })
                  .map((SearchScope scope) {
                    final bool isSelected = scope == searchState.scope;
                    return ListTile(
                      leading: isSelected
                          ? Icon(
                              Icons.check,
                              color: Theme.of(bottomSheetContext).colorScheme.primary,
                            )
                          : const SizedBox(width: 24),
                      title: Text(scope.label),
                      onTap: () {
                        Navigator.of(bottomSheetContext).pop();
                        // Use the original context that has access to SearchCubit
                        (_searchCubit ?? context.read<SearchCubit>()).changeScope(scope);
                      },
                    );
                  }),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    ).then((_) {
      // Modal closed - reset the flag and refocus on search field
      setState(() {
        _isModalOpen = false;
      });
      if (_isSearchExpanded) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _searchFocusNode.requestFocus();
          }
        });
      }
    });
  }

  SliverAppBar _buildLoungeSliverAppBar(BuildContext context, CommunityFeedState state) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color background = Color.lerp(
      colorScheme.surface.withValues(alpha: 0.9),
      colorScheme.surface,
      _isAppBarElevated ? 1 : 0,
    )!;
    final double radius = _isAppBarElevated ? 12 : 18;
    const double toolbarHeight = 64;
    return SliverAppBar(
      floating: true,
      snap: true,
      stretch: true,
      forceElevated: _isAppBarElevated,
      elevation: _isAppBarElevated ? 3 : 0,
      scrolledUnderElevation: 6,
      titleSpacing: 12,
      toolbarHeight: toolbarHeight,
      leadingWidth: toolbarHeight,
      backgroundColor: background,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withValues(alpha: _isAppBarElevated ? 0.08 : 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(radius)),
      ),
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: AppLogoButton(compact: true, onTap: _scrollToTop),
      ),
      title: _buildScopeSelector(context, state),
      actions: [
        BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, themeMode) {
            return GlobalAppBarActions(
              compact: true,
              opacity: _isAppBarElevated ? 1 : 0.92,
              onProfileTap: () => GoRouter.of(context).push(ProfileRoute.path),
            );
          },
        ),
      ],
    );
  }

  void _scrollToTop() {
    if (!_scrollController.hasClients) {
      return;
    }

    // 스크롤 시작 시 햅틱 피드백
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {
      // 햅틱 피드백이 지원되지 않는 경우 무시
    }

    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }

  double _calculateFontSize(String text) {
    final int length = text.length;
    if (length <= 4) {
      return 13.0; // 기본 크기
    } else if (length <= 6) {
      return 11.0; // 약간 축소
    } else {
      return 9.0; // 더 축소
    }
  }

  Widget _buildScopeSelector(BuildContext context, CommunityFeedState state) {
    final ThemeData theme = Theme.of(context);

    // 접근 가능한 라운지가 없으면 기본 상태 표시
    if (state.accessibleLounges.isEmpty || state.selectedLoungeInfo == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.public_outlined,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const Gap(8),
            Text(
              '전체',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    // 접근 가능한 라운지가 1개면 드롭다운 없이 단순 표시
    if (state.accessibleLounges.length == 1) {
      final LoungeInfo lounge = state.accessibleLounges.first;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withAlpha(40),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.primary.withAlpha(153)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              lounge.emoji,
              style: const TextStyle(fontSize: 16),
            ),
            const Gap(8),
            Text(
              lounge.shortName,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      );
    }

    // 여러 라운지가 있는 경우 드롭다운 버튼
    return PopupMenuButton<LoungeInfo>(
      initialValue: state.selectedLoungeInfo,
      onSelected: (LoungeInfo loungeInfo) {
        if (loungeInfo != state.selectedLoungeInfo) {
          PerformanceProfiler.start('change_lounge');
          context.read<CommunityFeedCubit>().changeLounge(loungeInfo);
          PerformanceProfiler.end('change_lounge');
        }
      },
      itemBuilder: (BuildContext context) {
        return state.accessibleLounges.map<PopupMenuEntry<LoungeInfo>>(
          (LoungeInfo lounge) {
            final bool isSelected = lounge.id == state.selectedLoungeInfo?.id;
            return PopupMenuItem<LoungeInfo>(
              value: lounge,
              child: Row(
                children: [
                  Text(
                    lounge.emoji,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lounge.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected ? theme.colorScheme.primary : null,
                          ),
                        ),
                        if (lounge.memberCount > 0) ...[
                          const Gap(2),
                          Text(
                            '${lounge.memberCount}명',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (isSelected) ...[
                    const Gap(8),
                    Icon(
                      Icons.check,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ],
              ),
            );
          },
        ).toList();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withAlpha(40),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.primary.withAlpha(153)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              state.selectedLoungeInfo!.emoji,
              style: const TextStyle(fontSize: 16),
            ),
            const Gap(8),
            Text(
              state.selectedLoungeInfo!.shortName,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
            const Gap(4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  void _useSuggestion(String token) {
    _searchController
      ..text = token
      ..selection = TextSelection.fromPosition(TextPosition(offset: token.length));
    _onSearchSubmitted(token);
  }
}
