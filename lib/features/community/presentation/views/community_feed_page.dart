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
import '../../../../common/widgets/scrap_undo_snackbar.dart';

class CommunityFeedPage extends StatefulWidget {
  const CommunityFeedPage({super.key});

  @override
  State<CommunityFeedPage> createState() => _CommunityFeedPageState();
}

class _CommunityFeedPageState extends State<CommunityFeedPage>
    with WidgetsBindingObserver {
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
    WidgetsBinding.instance.addObserver(this);
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
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh from cache when app resumes (e.g., returning from ScrapPage)
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<CommunityFeedCubit>().refreshFromCache();
    }
  }

  // ==================== Event Handlers ====================
  void _onScroll() {
    final CommunityFeedCubit cubit = context.read<CommunityFeedCubit>();
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      PerformanceProfiler.start('fetch_more_posts');
      cubit.fetchMore();
      PerformanceProfiler.end('fetch_more_posts');
    }

    final bool shouldElevate =
        _scrollController.hasClients && _scrollController.offset > 4;
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
      ..selection = TextSelection.fromPosition(
        TextPosition(offset: token.length),
      );
    _onSearchSubmitted(token);
  }

  void _showSearchOptions() {
    final SearchCubit searchCubit = _searchCubit ?? context.read<SearchCubit>();
    final CommunityFeedState feedState = context
        .read<CommunityFeedCubit>()
        .state;

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
      child: BlocListener<CommunityFeedCubit, CommunityFeedState>(
        listenWhen: (previous, current) {
          final shouldShow = previous.lastScrapUndoNotificationTime != current.lastScrapUndoNotificationTime &&
              current.lastScrapUndoNotificationTime != null;
          if (shouldShow) {
            debugPrint('✅ CommunityFeedPage: listenWhen triggered at ${current.lastScrapUndoNotificationTime}, showing SnackBar');
          }
          return shouldShow;
        },
        listener: (context, state) {
          debugPrint('📢 CommunityFeedPage: Showing scrap undo SnackBar');
          if (state.lastScrapWasAdded != null) {
            showScrapUndoSnackBar(
              context: context,
              wasAdded: state.lastScrapWasAdded!,
              onUndo: () {
                debugPrint('↩️ CommunityFeedPage: Undo button pressed');
                context.read<CommunityFeedCubit>().undoScrapToggle();
              },
            );
          }
        },
        child: BlocSelector<AuthCubit, AuthState, bool>(
          selector: (state) => state.hasLoungeReadAccess,
          builder: (context, hasLoungeReadAccess) {
            return BlocBuilder<CommunityFeedCubit, CommunityFeedState>(
              builder: (context, feedState) {
              return BlocSelector<
                SearchCubit,
                SearchState,
                ({String query, bool isLoading})
              >(
                selector: (state) =>
                    (query: state.query, isLoading: state.isLoading),
                builder: (context, searchData) {
                  // Check lounge read access (로그인 필요)
                  if (!hasLoungeReadAccess) {
                    return _buildNoAccessScaffold(feedState);
                  }

                  _searchCubit ??= context.read<SearchCubit>();
                  _handleScopeChange(feedState);

                  final bool showSearchResults =
                      _isSearchExpanded &&
                      (searchData.query.isNotEmpty || searchData.isLoading);

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
                    showSearchResults: showSearchResults,
                  );
                },
              );
            },
          );
        },
      ),
      ),
    );
  }

  bool _isInitialLoading(CommunityFeedState feedState) {
    return (feedState.status == CommunityFeedStatus.initial ||
            feedState.status == CommunityFeedStatus.loading) &&
        feedState.posts.isEmpty;
  }

  bool _isErrorState(CommunityFeedState feedState) {
    return feedState.status == CommunityFeedStatus.error &&
        feedState.posts.isEmpty;
  }

  void _handleScopeChange(CommunityFeedState feedState) {
    if (_lastScope != feedState.scope) {
      _lastScope = feedState.scope;
      // 부드럽게 상단으로 스크롤
      // AnimatedSwitcher와 조화롭게 동작하도록 짧은 애니메이션 추가
      if (_scrollController.hasClients && _scrollController.offset > 0) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
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
        body: const AuthRequiredView(message: '라운지를 이용하려면\n로그인이 필요합니다.'),
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
    required bool showSearchResults,
  }) {
    final Future<void> Function() onRefresh = showSearchResults
        ? () => (_searchCubit ?? context.read<SearchCubit>()).refresh()
        : () => context.read<CommunityFeedCubit>().refresh();

    final List<Widget> children = _buildContentChildren(
      feedState: feedState,
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
                duration: const Duration(milliseconds: 250),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: OptimizedListView(
                  key: ValueKey<String>(
                    'feed_${feedState.scope.loungeId}_${feedState.sort}_${showSearchResults ? 'search' : 'feed'}',
                  ),
                  itemCount: children.length,
                  itemBuilder: (context, index) => children[index],
                ),
              ),
            ),
          ),

          // Menu overlay
          if (feedState.isLoungeMenuOpen) _buildMenuOverlay(),

          // FAB + Lounge menu
          _buildFloatingActions(feedState),
        ],
      ),
    );
  }

  List<Widget> _buildContentChildren({
    required CommunityFeedState feedState,
    required bool showSearchResults,
  }) {
    final List<Widget> children = <Widget>[
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: InlinePostComposer(
          scope: feedState.scope,
          selectedLoungeInfo: feedState.selectedLoungeInfo,
        ),
      ),
      const Gap(12),
      BlocBuilder<SearchCubit, SearchState>(
        builder: (context, searchState) {
          return Padding(
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
          );
        },
      ),
      const Gap(16),
    ];

    if (_isSearchExpanded && !showSearchResults) {
      final searchCubit = _searchCubit ?? context.read<SearchCubit>();
      children.add(
        BlocBuilder<SearchCubit, SearchState>(
          builder: (context, searchState) {
            final bool hasContent =
                searchState.suggestions.isNotEmpty ||
                searchState.recentSearches.isNotEmpty;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasContent) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SearchSuggestionsCard(
                      searchState: searchState,
                      onSuggestionTap: _useSuggestion,
                      onClearRecentSearches: () =>
                          searchCubit.clearRecentSearches(),
                      onRemoveRecentSearch: (search) =>
                          searchCubit.removeRecentSearch(search),
                    ),
                  ),
                  const Gap(12),
                ],
                const FeedSectionBuilder(),
              ],
            );
          },
        ),
      );
    } else if (showSearchResults) {
      children.add(
        BlocBuilder<SearchCubit, SearchState>(
          builder: (context, searchState) {
            return SearchResultsSection(
              searchState: searchState,
              searchCubit: _searchCubit ?? context.read<SearchCubit>(),
              onClearSearch: _clearSearchQuery,
              onCloseSearch: _collapseSearchField,
            );
          },
        ),
      );
    } else {
      children.add(const FeedSectionBuilder());
    }

    return children;
  }

  Widget _buildMenuOverlay() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () => context.read<CommunityFeedCubit>().closeLoungeMenu(),
        child: Container(color: Colors.black.withValues(alpha: 0.3)),
      ),
    );
  }

  Widget _buildFloatingActions(CommunityFeedState feedState) {
    return Positioned(
      right: 16,
      bottom: 24,
      child: BlocSelector<AuthCubit, AuthState, bool>(
        selector: (state) => state.careerHierarchy != null,
        builder: (context, hasCareerVerification) {
          return Column(
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
                hasCareerVerification: hasCareerVerification,
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
          );
        },
      ),
    );
  }
}
