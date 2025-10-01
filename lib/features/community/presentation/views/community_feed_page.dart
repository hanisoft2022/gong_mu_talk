import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../domain/models/feed_filters.dart';
import '../../domain/models/search_result.dart';
import '../cubit/community_feed_cubit.dart';
import '../cubit/search_cubit.dart';
import '../widgets/inline_post_composer.dart';
import '../widgets/community_error_view.dart';
import '../widgets/lounge_floating_menu.dart';
import '../widgets/lounge_fab.dart';
import '../widgets/search_field_widgets.dart';
import '../widgets/search_and_sort_row.dart';
import '../widgets/feed_section_widgets.dart';
import '../widgets/search_results_widgets.dart';
import '../widgets/lounge_app_bar.dart';
import '../../../../di/di.dart';
import '../../../../core/utils/performance_optimizations.dart';
import '../../../../common/widgets/auth_required_view.dart';

class CommunityFeedPage extends StatefulWidget {
  const CommunityFeedPage({super.key});

  @override
  State<CommunityFeedPage> createState() => _CommunityFeedPageState();
}

class _CommunityFeedPageState extends State<CommunityFeedPage> {
  // ==================== State Variables ====================
  late final ScrollController _scrollController;
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;
  bool _isSearchExpanded = false;
  LoungeScope? _lastScope;
  SearchCubit? _searchCubit;
  bool _isAppBarElevated = false;
  bool _isModalOpen = false;
  static final SearchScope _persistentSearchScope = SearchScope.all;

  // ==================== Lifecycle Methods ====================
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

  // ==================== Event Handlers ====================
  void _onScroll() {
    final CommunityFeedCubit cubit = context.read<CommunityFeedCubit>();
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      PerformanceProfiler.start('fetch_more_posts');
      cubit.fetchMore();
      PerformanceProfiler.end('fetch_more_posts');
    }

    final bool shouldElevate = _scrollController.hasClients && _scrollController.offset > 4;
    if (shouldElevate != _isAppBarElevated && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && shouldElevate != _isAppBarElevated) {
          setState(() => _isAppBarElevated = shouldElevate);
        }
      });
    }
  }

  void _expandSearchField() {
    if (_isSearchExpanded) return;
    setState(() => _isSearchExpanded = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _searchFocusNode.requestFocus();
    });

    final SearchCubit searchCubit = _searchCubit ?? context.read<SearchCubit>();
    if (searchCubit.state.suggestions.isEmpty) {
      searchCubit.loadSuggestions();
    }
    if (searchCubit.state.recentSearches.isEmpty) {
      searchCubit.loadRecentSearches();
    }
  }

  void _collapseSearchField() {
    if (!_isSearchExpanded) return;
    setState(() => _isSearchExpanded = false);
    _searchFocusNode.unfocus();
    _searchController.clear();
    (_searchCubit ?? context.read<SearchCubit>()).clearSearch();
  }

  void _clearSearchQuery() {
    _searchController.clear();
    (_searchCubit ?? context.read<SearchCubit>()).clearSearch();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _searchFocusNode.requestFocus();
    });
  }

  void _onQueryChanged(String value) {
    (_searchCubit ?? context.read<SearchCubit>()).onQueryChanged(value);
  }

  void _onSearchSubmitted(String value) {
    final String trimmed = value.trim();
    if (trimmed.isEmpty) return;
    PerformanceProfiler.start('search_execution');
    (_searchCubit ?? context.read<SearchCubit>()).search(trimmed);
    PerformanceProfiler.end('search_execution');
  }

  void _scrollToTop() {
    if (!_scrollController.hasClients) return;

    try {
      HapticFeedback.mediumImpact();
    } catch (_) {
      // Ignore if haptic feedback not supported
    }

    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }

  void _useSuggestion(String token) {
    _searchController
      ..text = token
      ..selection = TextSelection.fromPosition(TextPosition(offset: token.length));
    _onSearchSubmitted(token);
  }

  void _showSearchOptions() {
    final SearchCubit searchCubit = _searchCubit ?? context.read<SearchCubit>();
    final CommunityFeedState feedState = context.read<CommunityFeedCubit>().state;

    showSearchOptionsBottomSheet(
      context: context,
      searchState: searchCubit.state,
      feedScope: feedState.scope,
      searchCubit: searchCubit,
      onModalOpen: () => setState(() => _isModalOpen = true),
      onModalClose: () {
        setState(() => _isModalOpen = false);
        if (_isSearchExpanded) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _searchFocusNode.requestFocus();
          });
        }
      },
    );
  }

  // ==================== Build Methods ====================
  @override
  Widget build(BuildContext context) {
    return BlocProvider<SearchCubit>(
      create: (_) {
        final cubit = getIt<SearchCubit>();
        cubit.loadSuggestions();
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
                  // Check lounge access
                  if (!authState.hasLoungeAccess) {
                    return _buildNoAccessScaffold(feedState);
                  }

                  _searchCubit ??= context.read<SearchCubit>();
                  _handleScopeChange(feedState);

                  final bool showSearchResults =
                      _isSearchExpanded && (searchState.query.isNotEmpty || searchState.isLoading);

                  // Initial loading state
                  if (!showSearchResults && _isInitialLoading(feedState)) {
                    return _buildLoadingScaffold(feedState);
                  }

                  // Error state
                  if (!showSearchResults && _isErrorState(feedState)) {
                    return _buildErrorScaffold(feedState);
                  }

                  return _buildMainScaffold(
                    feedState: feedState,
                    searchState: searchState,
                    authState: authState,
                    showSearchResults: showSearchResults,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  bool _isInitialLoading(CommunityFeedState feedState) {
    return (feedState.status == CommunityFeedStatus.initial ||
            feedState.status == CommunityFeedStatus.loading) &&
        feedState.posts.isEmpty;
  }

  bool _isErrorState(CommunityFeedState feedState) {
    return feedState.status == CommunityFeedStatus.error && feedState.posts.isEmpty;
  }

  void _handleScopeChange(CommunityFeedState feedState) {
    if (_lastScope != feedState.scope) {
      _lastScope = feedState.scope;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  // ==================== Scaffold Builders ====================
  Widget _buildNoAccessScaffold(CommunityFeedState feedState) {
    return Scaffold(
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, _) => <Widget>[
          LoungeSliverAppBar(
            feedState: feedState,
            isElevated: _isAppBarElevated,
            onLogoTap: _scrollToTop,
          ),
        ],
        body: const AuthRequiredView(message: '라운지 기능을 이용하려면\n공직자 메일 인증을 완료해주세요.'),
      ),
    );
  }

  Widget _buildLoadingScaffold(CommunityFeedState feedState) {
    return Scaffold(
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, _) => <Widget>[
          LoungeSliverAppBar(
            feedState: feedState,
            isElevated: _isAppBarElevated,
            onLogoTap: _scrollToTop,
          ),
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

  Widget _buildErrorScaffold(CommunityFeedState feedState) {
    return Scaffold(
      body: CommunityErrorView(
        message: feedState.errorMessage,
        onRetry: () => context.read<CommunityFeedCubit>().loadInitial(),
      ),
    );
  }

  Widget _buildMainScaffold({
    required CommunityFeedState feedState,
    required SearchState searchState,
    required AuthState authState,
    required bool showSearchResults,
  }) {
    final Future<void> Function() onRefresh = showSearchResults
        ? () => (_searchCubit ?? context.read<SearchCubit>()).refresh()
        : () => context.read<CommunityFeedCubit>().refresh();

    final List<Widget> children = _buildContentChildren(
      feedState: feedState,
      searchState: searchState,
      authState: authState,
      showSearchResults: showSearchResults,
    );

    return Scaffold(
      body: Stack(
        children: [
          // Main content
          NestedScrollView(
            controller: _scrollController,
            headerSliverBuilder: (context, _) => <Widget>[
              LoungeSliverAppBar(
                feedState: feedState,
                isElevated: _isAppBarElevated,
                onLogoTap: _scrollToTop,
              ),
            ],
            body: RefreshIndicator(
              onRefresh: onRefresh,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                switchInCurve: Curves.easeOutQuart,
                switchOutCurve: Curves.easeOut,
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.0, 0.015),
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
                    'feed_${feedState.scope.name}_${showSearchResults ? 'search' : 'feed'}_${searchState.scope.name}_${searchState.query}',
                  ),
                  itemCount: children.length,
                  itemBuilder: (context, index) => children[index],
                ),
              ),
            ),
          ),

          // Sorting overlay
          if (feedState.status == CommunityFeedStatus.sorting) _buildSortingOverlay(),

          // Menu overlay
          if (feedState.isLoungeMenuOpen) _buildMenuOverlay(),

          // FAB + Lounge menu
          _buildFloatingActions(feedState, authState),
        ],
      ),
    );
  }

  List<Widget> _buildContentChildren({
    required CommunityFeedState feedState,
    required SearchState searchState,
    required AuthState authState,
    required bool showSearchResults,
  }) {
    final List<Widget> children = <Widget>[
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: InlinePostComposer(scope: feedState.scope),
      ),
      const Gap(12),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SearchAndSortRow(
          feedState: feedState,
          searchState: searchState,
          isSearchExpanded: _isSearchExpanded,
          searchController: _searchController,
          searchFocusNode: _searchFocusNode,
          onExpandSearch: _expandSearchField,
          onCollapseSearch: _collapseSearchField,
          onSearchSubmitted: _onSearchSubmitted,
          onSearchChanged: _onQueryChanged,
          onClearSearch: _clearSearchQuery,
          onShowSearchOptions: _showSearchOptions,
        ),
      ),
      const Gap(16),
    ];

    if (_isSearchExpanded && !showSearchResults) {
      final searchCubit = _searchCubit ?? context.read<SearchCubit>();
      children
        ..add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SearchSuggestionsCard(
              searchState: searchState,
              onSuggestionTap: _useSuggestion,
              onClearRecentSearches: () => searchCubit.clearRecentSearches(),
              onRemoveRecentSearch: (search) => searchCubit.removeRecentSearch(search),
            ),
          ),
        )
        ..add(const Gap(12))
        ..add(FeedSectionBuilder(feedState: feedState, authState: authState));
    } else if (showSearchResults) {
      children.add(
        SearchResultsSection(
          searchState: searchState,
          searchCubit: _searchCubit ?? context.read<SearchCubit>(),
          onClearSearch: _clearSearchQuery,
          onCloseSearch: _collapseSearchField,
        ),
      );
    } else {
      children.add(FeedSectionBuilder(feedState: feedState, authState: authState));
    }

    return children;
  }

  Widget _buildSortingOverlay() {
    return Positioned.fill(
      top: kToolbarHeight + MediaQuery.of(context).padding.top,
      child: IgnorePointer(
        child: Container(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuOverlay() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () => context.read<CommunityFeedCubit>().closeLoungeMenu(),
        child: Container(color: Colors.black.withValues(alpha: 0.3)),
      ),
    );
  }

  Widget _buildFloatingActions(CommunityFeedState feedState, AuthState authState) {
    return Positioned(
      right: 16,
      bottom: 24,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Lounge selection menu
          LoungeFloatingMenu(
            lounges: feedState.accessibleLounges,
            selectedLounge: feedState.selectedLoungeInfo,
            onLoungeSelected: (lounge) {
              context.read<CommunityFeedCubit>().changeLounge(lounge);
            },
            isVisible: feedState.isLoungeMenuOpen,
            hasCareerVerification: authState.careerHierarchy != null,
            onVerifyCareer: () {
              context.read<CommunityFeedCubit>().toggleLoungeMenu();
              context.push('/profile/verify-paystub');
            },
          ),

          // FAB
          LoungeFAB(
            selectedLounge: feedState.selectedLoungeInfo,
            onTap: () {
              context.read<CommunityFeedCubit>().toggleLoungeMenu();
            },
            isMenuOpen: feedState.isLoungeMenuOpen,
          ),
        ],
      ),
    );
  }
}
