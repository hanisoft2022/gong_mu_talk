/// Search and Sort Row - Combined search trigger and sort buttons
///
/// Responsibilities:
/// - Display search trigger (collapsed/expanded)
/// - Display sort buttons
/// - Coordinate layout between search and sort controls

library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import '../../domain/models/feed_filters.dart';
import '../cubit/community_feed_cubit.dart';
import '../cubit/search_cubit.dart';
import '../../../../core/utils/performance_optimizations.dart';
import 'sort_button.dart';
import 'search_field_widgets.dart';

/// Row containing search field and sort buttons
class SearchAndSortRow extends StatelessWidget {
  const SearchAndSortRow({
    required this.feedState,
    required this.searchState,
    required this.isSearchExpanded,
    required this.searchController,
    required this.searchFocusNode,
    required this.onExpandSearch,
    required this.onCollapseSearch,
    required this.onSearchSubmitted,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onShowSearchOptions,
    super.key,
  });

  final CommunityFeedState feedState;
  final SearchState searchState;
  final bool isSearchExpanded;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final VoidCallback onExpandSearch;
  final VoidCallback onCollapseSearch;
  final ValueChanged<String> onSearchSubmitted;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final VoidCallback onShowSearchOptions;

  @override
  Widget build(BuildContext context) {
    final CommunityFeedCubit feedCubit = context.read<CommunityFeedCubit>();

    return SizedBox(
      height: 44,
      child: Row(
        children: [
          if (!isSearchExpanded)
            CollapsedSearchTrigger(
              searchController: searchController,
              onExpand: onExpandSearch,
            ),
          if (isSearchExpanded)
            Expanded(
              child: ExpandedSearchField(
                searchController: searchController,
                searchFocusNode: searchFocusNode,
                searchState: searchState,
                onCollapse: onCollapseSearch,
                onSubmitted: onSearchSubmitted,
                onChanged: onSearchChanged,
                onClear: onClearSearch,
                onShowOptions: onShowSearchOptions,
              ),
            ),
          if (!isSearchExpanded) ...[
            const Spacer(),
            _SortButtonsRow(
              currentSort: feedState.sort,
              onSelect: feedCubit.changeSort,
            ),
          ],
        ],
      ),
    );
  }
}

/// Row of sort buttons
class _SortButtonsRow extends StatelessWidget {
  const _SortButtonsRow({required this.currentSort, required this.onSelect});

  final LoungeSort currentSort;
  final ValueChanged<LoungeSort> onSelect;

  @override
  Widget build(BuildContext context) {
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
        const Gap(6),
        SortButton(
          sortType: LoungeSort.dailyPopular,
          isSelected: currentSort == LoungeSort.dailyPopular,
          onPressed: () {
            PerformanceProfiler.start('change_sort');
            onSelect(LoungeSort.dailyPopular);
            PerformanceProfiler.end('change_sort');
          },
          theme: theme,
        ),
        const Gap(6),
        SortButton(
          sortType: LoungeSort.weeklyPopular,
          isSelected: currentSort == LoungeSort.weeklyPopular,
          onPressed: () {
            PerformanceProfiler.start('change_sort');
            onSelect(LoungeSort.weeklyPopular);
            PerformanceProfiler.end('change_sort');
          },
          theme: theme,
        ),
      ],
    );
  }
}
