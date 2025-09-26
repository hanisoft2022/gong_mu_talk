import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../profile/domain/career_track.dart';
import '../../domain/models/feed_filters.dart';
import '../../domain/models/post.dart';
import '../../domain/models/search_result.dart';
import '../../domain/models/search_suggestion.dart';
import '../cubit/community_feed_cubit.dart';
import '../cubit/search_cubit.dart';
import '../widgets/inline_post_composer.dart';
import '../widgets/post_card.dart';
import '../widgets/lounge_ad_banner.dart';
import '../widgets/comment_search_result_card.dart';
import '../../../../di/di.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../routing/app_router.dart';
import '../../../../common/widgets/global_app_bar_actions.dart';
import '../../../../common/widgets/app_logo_button.dart';

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

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode()
      ..addListener(() {
        if (!_searchFocusNode.hasFocus && mounted && _searchController.text.trim().isEmpty) {
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
      cubit.fetchMore();
    }

    final bool shouldElevate =
        _scrollController.hasClients && _scrollController.offset > 4;
    if (shouldElevate != _isAppBarElevated && mounted) {
      setState(() => _isAppBarElevated = shouldElevate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SearchCubit>(
      create: (_) => getIt<SearchCubit>()..loadSuggestions(),
      child: BlocBuilder<CommunityFeedCubit, CommunityFeedState>(
        builder: (context, feedState) {
          return BlocBuilder<SearchCubit, SearchState>(
            builder: (context, searchState) {
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
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }

              if (!showSearchResults &&
                  feedState.status == CommunityFeedStatus.error &&
                  feedState.posts.isEmpty) {
                return Scaffold(
                  body: _CommunityErrorView(
                    message: feedState.errorMessage,
                    onRetry: () => context.read<CommunityFeedCubit>().loadInitial(),
                  ),
                );
              }

              final Future<void> Function() onRefresh = showSearchResults
                  ? () => (_searchCubit ?? context.read<SearchCubit>()).refresh()
                  : () => context.read<CommunityFeedCubit>().refresh();

              final List<Widget> children = <Widget>[
                InlinePostComposer(scope: feedState.scope),
                const Gap(12),
                _buildSearchAndSortRow(context, feedState, searchState),
                const Gap(16),
              ];

              if (_isSearchExpanded && !showSearchResults) {
                final Widget? suggestionsCard = _buildSearchSuggestionsCard(context, searchState);
                if (suggestionsCard != null) {
                  children
                    ..add(suggestionsCard)
                    ..add(const Gap(16));
                }
                children.addAll(_buildFeedSection(context, feedState));
              } else if (showSearchResults) {
                children.addAll(_buildSearchResultsSection(context, searchState));
              } else {
                children.addAll(_buildFeedSection(context, feedState));
              }

              return Scaffold(
                body: NestedScrollView(
                  controller: _scrollController,
                  headerSliverBuilder: (context, _) => <Widget>[
                    _buildLoungeSliverAppBar(context, feedState),
                  ],
                  body: RefreshIndicator(
                    onRefresh: onRefresh,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: children,
                    ),
                  ),
                ),
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

    return Row(
      children: [
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: _isSearchExpanded
                ? _buildExpandedSearchField(context, searchState)
                : _buildCollapsedSearchTrigger(theme, searchState),
          ),
        ),
        const Gap(12),
        SizedBox(
          height: 44,
          child: _SortMenu(currentSort: feedState.sort, onSelect: feedCubit.changeSort),
        ),
      ],
    );
  }

  Widget _buildCollapsedSearchTrigger(ThemeData theme, SearchState searchState) {
    final BorderRadius radius = BorderRadius.circular(12);
    final TextStyle labelStyle =
        theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ) ??
        TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant);
    final String placeholder = _searchController.text.trim();
    final bool showPlaceholder = placeholder.isNotEmpty;

    return SizedBox(
      height: 44,
      child: ClipRRect(
        key: ValueKey<String>('collapsed_${searchState.scope.name}'),
        borderRadius: radius,
        child: DecoratedBox(
          decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: radius,
              onTap: _expandSearchField,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Icon(Icons.search, size: 18, color: theme.colorScheme.onSurfaceVariant),
                    if (showPlaceholder) ...[
                      const Gap(8),
                      Flexible(child: Text(placeholder, style: labelStyle)),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedSearchField(BuildContext context, SearchState searchState) {
    final ThemeData theme = Theme.of(context);
    final BorderRadius radius = BorderRadius.circular(12);
    final bool hasText = _searchController.text.trim().isNotEmpty;

    return SizedBox(
      height: 44,
      child: ClipRRect(
        key: ValueKey<String>('expanded_${searchState.scope.name}_${hasText ? 'filled' : 'empty'}'),
        borderRadius: radius,
        child: DecoratedBox(
          decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest),
          child: Row(
            children: [
              _SearchIconButton(
                icon: Icons.arrow_back,
                tooltip: '검색 닫기',
                onPressed: _collapseSearchField,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  textInputAction: TextInputAction.search,
                  onSubmitted: _onSearchSubmitted,
                  onChanged: _onQueryChanged,
                  style: theme.textTheme.bodyMedium,
                  decoration: InputDecoration(
                    hintText: '${searchState.scope.label} 검색',
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
                _SearchIconButton(
                  icon: Icons.close,
                  tooltip: '검색어 지우기',
                  onPressed: _clearSearchQuery,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              PopupMenuButton<SearchScope>(
                tooltip: '검색 범위 설정',
                initialValue: searchState.scope,
                onSelected: (SearchScope scope) {
                  if (scope != searchState.scope) {
                    (_searchCubit ?? context.read<SearchCubit>()).changeScope(scope);
                  }
                },
                itemBuilder: (BuildContext context) {
                  return SearchScope.values
                      .map(
                        (SearchScope scope) => PopupMenuItem<SearchScope>(
                          value: scope,
                          child: Row(
                            children: [
                              if (scope == searchState.scope)
                                Icon(Icons.check, size: 16, color: theme.colorScheme.primary)
                              else
                                const SizedBox(width: 16),
                              const Gap(8),
                              Text(scope.label),
                            ],
                          ),
                        ),
                      )
                      .toList(growable: false);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.tune, size: 18, color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFeedSection(BuildContext context, CommunityFeedState state) {
    final CommunityFeedCubit cubit = context.read<CommunityFeedCubit>();
    final bool hasSerialAccess = state.careerTrack != CareerTrack.none && state.serial != 'unknown';
    final bool showSerialGuide = state.scope == LoungeScope.serial && !hasSerialAccess;
    final bool showEmptyPosts = state.posts.isEmpty && !showSerialGuide;

    if (showSerialGuide) {
      return <Widget>[
        _EmptyStateView(
          icon: Icons.group_add_outlined,
          title: '직렬 정보를 등록하면 전용 피드를 볼 수 있어요.',
          message: '마이페이지에서 직렬과 소속 정보를 설정해주세요.',
          onRefresh: () => cubit.refresh(),
        ),
      ];
    }

    if (showEmptyPosts) {
      return <Widget>[
        _EmptyStateView(
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
        PostCard(
          post: post,
          onToggleLike: () => cubit.toggleLike(post),
          onToggleBookmark: () => cubit.toggleBookmark(post),
          displayScope: state.scope,
        ),
      );
      renderedCount += 1;

      final bool shouldInsertAd =
          state.showAds && renderedCount % adInterval == 0 && renderedCount < totalPosts;

      if (shouldInsertAd) {
        children
          ..add(const LoungeAdBanner())
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

    if (suggestions.isEmpty) {
      return null;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
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
        ),
      ),
    );
  }

  List<Widget> _buildSearchResultsSection(BuildContext context, SearchState state) {
    if (state.error != null) {
      return <Widget>[_buildSearchErrorCard(context, state.error!)];
    }

    final SearchCubit searchCubit = _searchCubit ?? context.read<SearchCubit>();
    final bool showPosts = state.scope != SearchScope.comments;
    final bool showComments = state.scope == SearchScope.all || state.scope == SearchScope.comments;
    final bool noPosts = !showPosts || state.postResults.isEmpty;
    final bool noComments = !showComments || state.commentResults.isEmpty;

    final List<Widget> widgets = <Widget>[_buildSearchResultsHeader(context, state), const Gap(12)];

    if (!state.isLoading && noPosts && noComments) {
      widgets.add(_buildSearchEmptyResults(context, state));
      return widgets;
    }

    if (showPosts) {
      widgets.add(_buildSearchSectionHeader(context, '글 결과', state.postResults.length));
      if (state.postResults.isEmpty && !state.isLoading) {
        widgets.add(_buildNoSectionResults(context, '글'));
      } else {
        widgets.addAll(
          state.postResults.map(
            (Post post) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PostCard(
                post: post,
                onToggleLike: () => searchCubit.toggleLike(post),
                onToggleBookmark: () => searchCubit.toggleBookmark(post),
              ),
            ),
          ),
        );
      }
      widgets.add(const Gap(12));
    }

    if (showComments) {
      widgets.add(_buildSearchSectionHeader(context, '댓글 결과', state.commentResults.length));
      if (state.commentResults.isEmpty && !state.isLoading) {
        widgets.add(_buildNoSectionResults(context, '댓글'));
      } else {
        widgets.addAll(
          state.commentResults.map(
            (CommentSearchResult result) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
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
    (_searchCubit ?? context.read<SearchCubit>()).search(trimmed);
  }

  SliverAppBar _buildLoungeSliverAppBar(BuildContext context, CommunityFeedState state) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color background = Color.lerp(
      colorScheme.surface.withValues(alpha: 0.9),
      colorScheme.surface,
      _isAppBarElevated ? 1 : 0,
    )!;
    final double radius = _isAppBarElevated ? 12 : 18;
    return SliverAppBar(
      floating: true,
      snap: true,
      stretch: true,
      forceElevated: _isAppBarElevated,
      elevation: _isAppBarElevated ? 3 : 0,
      scrolledUnderElevation: 6,
      titleSpacing: 12,
      toolbarHeight: 64,
      leadingWidth: 56,
      backgroundColor: background,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withValues(alpha: _isAppBarElevated ? 0.08 : 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(radius),
        ),
      ),
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: AppLogoButton(
          compact: true,
          onTap: _scrollToTop,
        ),
      ),
      title: _buildScopeSelector(context, state),
      actions: [
        GlobalAppBarActions(
          compact: true,
          opacity: _isAppBarElevated ? 1 : 0.92,
          isDarkMode: isDark,
          onToggleTheme: () => context.read<ThemeCubit>().toggle(),
          onProfileTap: () => GoRouter.of(context).push(ProfileRoute.path),
        ),
      ],
    );
  }

  void _scrollToTop() {
    if (!_scrollController.hasClients) {
      return;
    }
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }

  Widget _buildScopeSelector(BuildContext context, CommunityFeedState state) {
    final ThemeData theme = Theme.of(context);
    final bool hasSerialAccess = state.careerTrack != CareerTrack.none && state.serial != 'unknown';
    final String serialLabel = hasSerialAccess
        ? state.careerTrack.displayName
        : '내 직렬';

    final TextStyle labelStyle =
        theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600) ??
        const TextStyle(fontSize: 13, fontWeight: FontWeight.w600);

    final ButtonStyle style = ButtonStyle(
      visualDensity: VisualDensity.compact,
      padding: WidgetStateProperty.resolveWith(
        (states) => const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      textStyle: WidgetStatePropertyAll<TextStyle>(labelStyle),
      shape: WidgetStateProperty.resolveWith(
        (states) =>
            const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
      ),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return theme.colorScheme.primary.withAlpha(40);
        }
        return theme.colorScheme.surfaceContainerHighest;
      }),
      foregroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant,
      ),
      side: WidgetStateProperty.resolveWith(
        (states) => BorderSide(
          color: states.contains(WidgetState.selected)
              ? theme.colorScheme.primary.withAlpha(153)
              : theme.dividerColor,
        ),
      ),
    );

    return SegmentedButton<LoungeScope>(
      style: style,
      segments: [
        const ButtonSegment<LoungeScope>(
          value: LoungeScope.all,
          label: Text('전체'),
          icon: Icon(Icons.public_outlined),
        ),
        ButtonSegment<LoungeScope>(
          value: LoungeScope.serial,
          label: Text(serialLabel),
          icon: const Icon(Icons.group_outlined),
          enabled: hasSerialAccess,
        ),
      ],
      selected: <LoungeScope>{state.scope},
      onSelectionChanged: (selection) {
        final LoungeScope nextScope = selection.first;
        if (nextScope != state.scope) {
          context.read<CommunityFeedCubit>().changeScope(nextScope);
        }
      },
    );
  }

  void _useSuggestion(String token) {
    _searchController
      ..text = token
      ..selection = TextSelection.fromPosition(TextPosition(offset: token.length));
    _onSearchSubmitted(token);
  }
}

class _SearchIconButton extends StatelessWidget {
  const _SearchIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    required this.color,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      tooltip: tooltip,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
      splashRadius: 22,
      style: IconButton.styleFrom(splashFactory: NoSplash.splashFactory, foregroundColor: color),
    );
  }
}

class _CommunityErrorView extends StatelessWidget {
  const _CommunityErrorView({required this.onRetry, this.message});

  final Future<void> Function() onRetry;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRetry,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                const Icon(Icons.inbox_outlined, size: 72),
                const Gap(16),
                Text(
                  message ?? '피드를 불러오지 못했어요.',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const Gap(12),
                FilledButton.icon(
                  onPressed: () {
                    onRetry();
                  },
                  icon: const Icon(Icons.refresh_outlined),
                  label: const Text('다시 시도'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SortMenu extends StatelessWidget {
  const _SortMenu({required this.currentSort, required this.onSelect});

  final LoungeSort currentSort;
  final ValueChanged<LoungeSort> onSelect;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return PopupMenuButton<LoungeSort>(
      tooltip: '정렬 방법',
      initialValue: currentSort,
      onSelected: onSelect,
      itemBuilder: (context) {
        return LoungeSort.values
            .map((LoungeSort option) {
              final bool isSelected = option == currentSort;
              return PopupMenuItem<LoungeSort>(
                value: option,
                height: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    if (isSelected)
                      Icon(Icons.check, size: 18, color: theme.colorScheme.primary)
                    else
                      const SizedBox(width: 18),
                    const Gap(8),
                    Text(option.label),
                  ],
                ),
              );
            })
            .toList(growable: false);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.tune, size: 16),
            const Gap(4),
            Text(
              currentSort.label,
              style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Gap(2),
            const Icon(Icons.arrow_drop_down, size: 18),
          ],
        ),
      ),
    );
  }
}

class _EmptyStateView extends StatelessWidget {
  const _EmptyStateView({
    required this.icon,
    required this.title,
    required this.message,
    required this.onRefresh,
  });

  final IconData icon;
  final String title;
  final String message;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, size: 56, color: theme.colorScheme.primary),
              const Gap(12),
              Text(title, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
              const Gap(8),
              Text(message, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
              const Gap(16),
              FilledButton.icon(
                onPressed: () => context.read<CommunityFeedCubit>().seedDummyChirps(),
                icon: const Icon(Icons.auto_awesome),
                label: const Text('더미 데이터 채우기'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
