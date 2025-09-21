part of 'community_search_cubit.dart';

enum CommunitySearchStatus { initial, loading, success, error }

class CommunitySearchState extends Equatable {
  const CommunitySearchState({
    this.status = CommunitySearchStatus.initial,
    this.query = '',
    this.results = const <Post>[],
    this.popularSuggestions = const <String>[],
    this.autocompleteSuggestions = const <String>[],
    this.isFetchingSuggestions = false,
    this.errorMessage,
    this.likedPostIds = const <String>{},
    this.bookmarkedPostIds = const <String>{},
  });

  final CommunitySearchStatus status;
  final String query;
  final List<Post> results;
  final List<String> popularSuggestions;
  final List<String> autocompleteSuggestions;
  final bool isFetchingSuggestions;
  final String? errorMessage;
  final Set<String> likedPostIds;
  final Set<String> bookmarkedPostIds;

  CommunitySearchState copyWith({
    CommunitySearchStatus? status,
    String? query,
    List<Post>? results,
    List<String>? popularSuggestions,
    List<String>? autocompleteSuggestions,
    bool? isFetchingSuggestions,
    String? errorMessage,
    Set<String>? likedPostIds,
    Set<String>? bookmarkedPostIds,
  }) {
    return CommunitySearchState(
      status: status ?? this.status,
      query: query ?? this.query,
      results: results ?? this.results,
      popularSuggestions: popularSuggestions ?? this.popularSuggestions,
      autocompleteSuggestions: autocompleteSuggestions ?? this.autocompleteSuggestions,
      isFetchingSuggestions: isFetchingSuggestions ?? this.isFetchingSuggestions,
      errorMessage: errorMessage,
      likedPostIds: likedPostIds ?? this.likedPostIds,
      bookmarkedPostIds: bookmarkedPostIds ?? this.bookmarkedPostIds,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        status,
        query,
        results,
        popularSuggestions,
        autocompleteSuggestions,
        isFetchingSuggestions,
        errorMessage,
        likedPostIds,
        bookmarkedPostIds,
      ];
}
