part of 'search_cubit.dart';

class SearchState extends Equatable {
  const SearchState({
    this.query = '',
    this.results = const [],
    this.suggestions = const [],
    this.isLoading = false,
    this.hasMore = false,
    this.error,
  });

  final String query;
  final List<Post> results;
  final List<SearchSuggestion> suggestions;
  final bool isLoading;
  final bool hasMore;
  final String? error;

  SearchState copyWith({
    String? query,
    List<Post>? results,
    List<SearchSuggestion>? suggestions,
    bool? isLoading,
    bool? hasMore,
    String? error,
  }) {
    return SearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      suggestions: suggestions ?? this.suggestions,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
        query,
        results,
        suggestions,
        isLoading,
        hasMore,
        error,
      ];
}