import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../domain/usecases/search_community.dart';
import '../../domain/repositories/i_community_repository.dart';
import '../../domain/models/post.dart';
import '../../domain/models/search_suggestion.dart';
import '../../domain/models/search_result.dart';

part 'search_state.dart';

@injectable
class SearchCubit extends Cubit<SearchState> {
  SearchCubit(
    this._repository,
    this._searchCommunity,
  ) : super(const SearchState());

  final ICommunityRepository _repository;
  final SearchCommunity _searchCommunity;
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

  @override
  Future<void> close() {
    _autocompleteDebounce?.cancel();
    return super.close();
  }
}
