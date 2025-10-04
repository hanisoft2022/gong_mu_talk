import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/usecases/search_community.dart';
import '../../domain/repositories/i_community_repository.dart';
import '../../domain/models/post.dart';
import '../../domain/models/search_suggestion.dart';
import '../../domain/models/search_result.dart';

part 'search_state.dart';

class SearchCubit extends Cubit<SearchState> {
  SearchCubit(
    this._repository,
    this._searchCommunity,
    this._preferences,
  ) : super(const SearchState());

  final ICommunityRepository _repository;
  final SearchCommunity _searchCommunity;
  final SharedPreferences _preferences;
  Timer? _autocompleteDebounce;

  static const String _recentSearchesKey = 'recent_searches';
  static const int _maxRecentSearches = 10;

  void onQueryChanged(String value) {
    emit(state.copyWith(draftQuery: value));
    _autocompleteDebounce?.cancel();

    final String trimmed = value.trim();
    if (trimmed.isEmpty) {
      emit(state.copyWith(autocomplete: const <String>[]));
      return;
    }

    if (trimmed == state.query.trim()) {
      emit(state.copyWith(autocomplete: const <String>[]));
      return;
    }

    _autocompleteDebounce = Timer(const Duration(milliseconds: 250), () async {
      final result = await _repository.autocompleteSearchTokens(
        prefix: trimmed,
        limit: 6,
      );

      result.fold(
        (error) {
          // Ignore autocomplete errors to keep typing smooth
        },
        (tokens) {
          if (state.draftQuery.trim() == trimmed) {
            emit(state.copyWith(autocomplete: tokens));
          }
        },
      );
    });
  }

  Future<void> loadSuggestions() async {
    final result = await _repository.topSearchSuggestions(limit: 10);
    result.fold(
      (error) {
        // Silently handle error - suggestions are optional
      },
      (suggestions) => emit(state.copyWith(suggestions: suggestions)),
    );
  }

  Future<void> search(String query) async {
    if (query.trim().isEmpty) return;

    _autocompleteDebounce?.cancel();

    final String trimmedQuery = query.trim();

    // 최근 검색어에 추가
    await _addRecentSearch(trimmedQuery);

    emit(
      state.copyWith(
        isLoading: true,
        query: trimmedQuery,
        draftQuery: trimmedQuery,
        postResults: const <Post>[],
        commentResults: const <CommentSearchResult>[],
        hasMore: false,
        autocomplete: const <String>[],
        error: null,
        recentSearches: await _getRecentSearches(),
      ),
    );

    final result = await _searchCommunity(
      query: trimmedQuery,
      scope: state.scope,
      postLimit: state.scope == SearchScope.comments ? 0 : 20,
      commentLimit:
          state.scope == SearchScope.posts ||
              state.scope == SearchScope.author
          ? 0
          : 20,
      currentUid: _repository.currentUserId,
    );

    result.fold(
      (error) => emit(state.copyWith(isLoading: false, error: error.message)),
      (results) => emit(
        state.copyWith(
          isLoading: false,
          postResults: results.posts,
          commentResults: results.comments,
          hasMore: false,
          error: null,
        ),
      ),
    );
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading) return;

    emit(state.copyWith(isLoading: true));

    try {
      emit(state.copyWith(isLoading: false, hasMore: false));
    } catch (e) {
      emit(
        state.copyWith(isLoading: false, error: '추가 검색 결과를 불러오는 중 오류가 발생했습니다.'),
      );
    }
  }

  Future<void> refresh() async {
    if (state.query.isEmpty) {
      await loadSuggestions();
    } else {
      await search(state.query);
    }
  }

  void clearSearch() {
    _autocompleteDebounce?.cancel();
    emit(SearchState(scope: state.scope)); // Keep the current scope
    loadSuggestions();
  }

  void changeScope(SearchScope scope) {
    if (state.scope == scope) {
      return;
    }
    emit(state.copyWith(scope: scope));
    if (state.query.trim().isNotEmpty) {
      search(state.query);
    }
  }

  Future<void> toggleLike(Post post) async {
    final List<Post> results = List<Post>.from(state.postResults);
    final index = results.indexWhere((p) => p.id == post.id);

    if (index == -1) return;

    final updatedPost = post.copyWith(
      isLiked: !post.isLiked,
      likeCount: post.isLiked ? post.likeCount - 1 : post.likeCount + 1,
    );

    results[index] = updatedPost;
    emit(state.copyWith(postResults: results));

    try {
      await _repository.toggleLike(post.id);
    } catch (e) {
      // Revert on error
      results[index] = post;
      emit(state.copyWith(postResults: results));
    }
  }

  Future<void> toggleBookmark(Post post) async {
    final List<Post> results = List<Post>.from(state.postResults);
    final index = results.indexWhere((p) => p.id == post.id);

    if (index == -1) return;

    final updatedPost = post.copyWith(isBookmarked: !post.isBookmarked);
    results[index] = updatedPost;
    emit(state.copyWith(postResults: results));

    try {
      await _repository.togglePostBookmark(post.id);
    } catch (e) {
      // Revert on error
      results[index] = post;
      emit(state.copyWith(postResults: results));
    }
  }

  // 최근 검색어 로드
  Future<void> loadRecentSearches() async {
    final recentSearches = await _getRecentSearches();
    emit(state.copyWith(recentSearches: recentSearches));
  }

  // 최근 검색어 추가
  Future<void> _addRecentSearch(String query) async {
    final recentSearches = await _getRecentSearches();

    // 이미 존재하는 검색어는 제거 (맨 앞으로 이동시키기 위해)
    recentSearches.remove(query);

    // 맨 앞에 추가
    recentSearches.insert(0, query);

    // 최대 개수 제한
    if (recentSearches.length > _maxRecentSearches) {
      recentSearches.removeRange(_maxRecentSearches, recentSearches.length);
    }

    // 저장
    await _preferences.setStringList(_recentSearchesKey, recentSearches);
  }

  // 최근 검색어 가져오기
  Future<List<String>> _getRecentSearches() async {
    return _preferences.getStringList(_recentSearchesKey) ?? <String>[];
  }

  // 최근 검색어 개별 삭제
  Future<void> removeRecentSearch(String query) async {
    final recentSearches = await _getRecentSearches();
    recentSearches.remove(query);
    await _preferences.setStringList(_recentSearchesKey, recentSearches);
    emit(state.copyWith(recentSearches: recentSearches));
  }

  // 최근 검색어 전체 삭제
  Future<void> clearRecentSearches() async {
    await _preferences.remove(_recentSearchesKey);
    emit(state.copyWith(recentSearches: const <String>[]));
  }

  @override
  Future<void> close() {
    _autocompleteDebounce?.cancel();
    return super.close();
  }
}
