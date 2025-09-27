import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../data/community_repository.dart';
import '../../domain/models/post.dart';
import '../../domain/models/search_suggestion.dart';
import '../../domain/models/search_result.dart';

part 'search_state.dart';

@injectable
class SearchCubit extends Cubit<SearchState> {
  SearchCubit(this._repository) : super(const SearchState()) {
  }

  final CommunityRepository _repository;
  Timer? _autocompleteDebounce;

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
      try {
        final List<String> tokens = await _repository.autocompleteSearchTokens(
          prefix: trimmed,
          limit: 6,
        );

        if (state.draftQuery.trim() == trimmed) {
          emit(state.copyWith(autocomplete: tokens));
        }
      } catch (_) {
        // Ignore autocomplete errors to keep typing smooth
      }
    });
  }

  Future<void> loadSuggestions() async {
    try {
      final suggestions = await _repository.topSearchSuggestions(limit: 10);
      emit(state.copyWith(suggestions: suggestions));
    } catch (e) {
      // Silently handle error - suggestions are optional
    }
  }

  Future<void> search(String query) async {
    if (query.trim().isEmpty) return;

    _autocompleteDebounce?.cancel();

    final String trimmedQuery = query.trim();
    final String normalizedQuery = trimmedQuery.toLowerCase();
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
      ),
    );

    try {
      final CommunitySearchResults results = await _repository.searchCommunity(
        query: normalizedQuery,
        scope: state.scope,
        postLimit: state.scope == SearchScope.comments ? 0 : 20,
        commentLimit: state.scope == SearchScope.posts || state.scope == SearchScope.author
            ? 0
            : 20,
        currentUid: _repository.currentUserId,
      );

      emit(
        state.copyWith(
          isLoading: false,
          postResults: results.posts,
          commentResults: results.comments,
          hasMore: false,
          error: null,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: '검색 중 오류가 발생했습니다.'));
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading) return;

    emit(state.copyWith(isLoading: true));

    try {
      emit(state.copyWith(isLoading: false, hasMore: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: '추가 검색 결과를 불러오는 중 오류가 발생했습니다.'));
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

  @override
  Future<void> close() {
    _autocompleteDebounce?.cancel();
    return super.close();
  }
}
