part of 'search_cubit.dart';

class SearchState extends Equatable {
  const SearchState({
    this.query = '',
    this.draftQuery = '',
    this.postResults = const [],
    this.commentResults = const [],
    this.suggestions = const [],
    this.autocomplete = const [],
    this.recentSearches = const [],
    this.isLoading = false,
    this.hasMore = false,
    this.error,
    this.scope = SearchScope.all,
  });

  final String query;
  final String draftQuery;
  final List<Post> postResults;
  final List<CommentSearchResult> commentResults;
  final List<SearchSuggestion> suggestions;
  final List<String> autocomplete;
  final List<String> recentSearches;
  final bool isLoading;
  final bool hasMore;
  final String? error;
  final SearchScope scope;

  SearchState copyWith({
    String? query,
    String? draftQuery,
    List<Post>? postResults,
    List<CommentSearchResult>? commentResults,
    List<SearchSuggestion>? suggestions,
    List<String>? autocomplete,
    List<String>? recentSearches,
    bool? isLoading,
    bool? hasMore,
    String? error,
    SearchScope? scope,
  }) {
    return SearchState(
      query: query ?? this.query,
      draftQuery: draftQuery ?? this.draftQuery,
      postResults: postResults ?? this.postResults,
      commentResults: commentResults ?? this.commentResults,
      suggestions: suggestions ?? this.suggestions,
      autocomplete: autocomplete ?? this.autocomplete,
      recentSearches: recentSearches ?? this.recentSearches,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error ?? this.error,
      scope: scope ?? this.scope,
    );
  }

  @override
  List<Object?> get props => [
    query,
    draftQuery,
    postResults,
    commentResults,
    suggestions,
    autocomplete,
    recentSearches,
    isLoading,
    hasMore,
    error,
    scope,
  ];
}
