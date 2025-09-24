part of 'search_cubit.dart';

class SearchState extends Equatable {
  const SearchState({
    this.query = '',
    this.draftQuery = '',
    this.results = const [],
    this.suggestions = const [],
    this.autocomplete = const [],
    this.isLoading = false,
    this.hasMore = false,
    this.error,
  });

  final String query;
  final String draftQuery;
  final List<Post> results;
  final List<SearchSuggestion> suggestions;
  final List<String> autocomplete;
  final bool isLoading;
  final bool hasMore;
  final String? error;

  SearchState copyWith({
    String? query,
    String? draftQuery,
    List<Post>? results,
    List<SearchSuggestion>? suggestions,
    List<String>? autocomplete,
    bool? isLoading,
    bool? hasMore,
    String? error,
  }) {
    return SearchState(
      query: query ?? this.query,
      draftQuery: draftQuery ?? this.draftQuery,
      results: results ?? this.results,
      suggestions: suggestions ?? this.suggestions,
      autocomplete: autocomplete ?? this.autocomplete,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
    query,
    draftQuery,
    results,
    suggestions,
    autocomplete,
    isLoading,
    hasMore,
    error,
  ];
}
