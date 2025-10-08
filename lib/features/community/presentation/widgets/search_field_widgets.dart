/// Search Field Widgets - Search UI components for community feed
///
/// Responsibilities:
/// - Collapsed search trigger (icon/chip display)
/// - Expanded search field with controls
/// - Search options bottom sheet
/// - Search suggestions card display

library;

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../domain/models/feed_filters.dart';
import '../../domain/models/search_result.dart';
import '../../domain/models/search_suggestion.dart';
import '../cubit/search_cubit.dart';
import 'search_icon_button.dart';

/// Collapsed search trigger - shows search icon or search query chip
class CollapsedSearchTrigger extends StatelessWidget {
  const CollapsedSearchTrigger({
    required this.searchController,
    required this.onExpand,
    super.key,
  });

  final TextEditingController searchController;
  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String placeholder = searchController.text.trim();

    // If there's search text, show it in a compact form
    if (placeholder.isNotEmpty) {
      return SizedBox(
        height: 44,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
            ),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onExpand,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search,
                        size: 18,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
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
      onPressed: onExpand,
      color: theme.colorScheme.onSurfaceVariant,
    );
  }
}

/// Expanded search field with search bar and controls
class ExpandedSearchField extends StatelessWidget {
  const ExpandedSearchField({
    required this.searchController,
    required this.searchFocusNode,
    required this.searchState,
    required this.onCollapse,
    required this.onSubmitted,
    required this.onChanged,
    required this.onClear,
    required this.onShowOptions,
    super.key,
  });

  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final SearchState searchState;
  final VoidCallback onCollapse;
  final ValueChanged<String> onSubmitted;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onShowOptions;

  String _getHintText(SearchScope scope) {
    switch (scope) {
      case SearchScope.all:
        return '글+댓글 검색';
      case SearchScope.posts:
        return '글 검색';
      case SearchScope.comments:
        return '댓글 검색';
      case SearchScope.author:
        return '글 작성자 검색';
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final BorderRadius radius = BorderRadius.circular(12);
    final bool hasText = searchController.text.trim().isNotEmpty;

    return SizedBox(
      height: 44,
      child: ClipRRect(
        key: ValueKey<String>(
          'expanded_${searchState.scope.name}_${hasText ? 'filled' : 'empty'}',
        ),
        borderRadius: radius,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
          ),
          child: Row(
            children: [
              SearchIconButton(
                icon: Icons.arrow_back,
                tooltip: '검색 닫기',
                onPressed: onCollapse,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              Expanded(
                child: TextField(
                  key: ValueKey('search_field_${searchState.scope.name}'),
                  controller: searchController,
                  focusNode: searchFocusNode,
                  textInputAction: TextInputAction.search,
                  onSubmitted: onSubmitted,
                  onChanged: onChanged,
                  style: theme.textTheme.bodyMedium,
                  decoration: InputDecoration(
                    hintText: _getHintText(searchState.scope),
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
                  onPressed: onClear,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              SearchIconButton(
                icon: Icons.tune,
                tooltip: '검색 옵션',
                onPressed: onShowOptions,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Search suggestions card with recent searches and popular searches
class SearchSuggestionsCard extends StatelessWidget {
  const SearchSuggestionsCard({
    required this.searchState,
    required this.onSuggestionTap,
    required this.onClearRecentSearches,
    required this.onRemoveRecentSearch,
    super.key,
  });

  final SearchState searchState;
  final ValueChanged<String> onSuggestionTap;
  final VoidCallback onClearRecentSearches;
  final ValueChanged<String> onRemoveRecentSearch;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<SearchSuggestion> suggestions = searchState.suggestions;
    final List<String> recentSearches = searchState.recentSearches;

    if (suggestions.isEmpty && recentSearches.isEmpty) {
      return const SizedBox.shrink();
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
                  Icon(
                    Icons.history,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const Gap(8),
                  Text(
                    '최근 검색어',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: onClearRecentSearches,
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
                        onPressed: () => onSuggestionTap(search),
                        onDeleted: () => onRemoveRecentSearch(search),
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
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
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
                        onPressed: () => onSuggestionTap(suggestion.token),
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
}

/// Shows search options bottom sheet
void showSearchOptionsBottomSheet({
  required BuildContext context,
  required SearchState searchState,
  required LoungeScope feedScope,
  required SearchCubit searchCubit,
  required VoidCallback onModalOpen,
  required VoidCallback onModalClose,
}) {
  onModalOpen();

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
                  if (feedScope == LoungeScope.all &&
                      scope == SearchScope.author) {
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
                            color: Theme.of(
                              bottomSheetContext,
                            ).colorScheme.primary,
                          )
                        : const SizedBox(width: 24),
                    title: Text(scope.label),
                    onTap: () {
                      Navigator.of(bottomSheetContext).pop();
                      searchCubit.changeScope(scope);
                    },
                  );
                }),
            const Gap(16),
          ],
        ),
      );
    },
  ).then((_) {
    onModalClose();
  });
}
