import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../data/community_repository.dart';
import '../../domain/models/post.dart';
import '../../domain/models/search_suggestion.dart';

part 'search_state.dart';

@injectable
class SearchCubit extends Cubit<SearchState> {
  SearchCubit(this._repository) : super(const SearchState());

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
        results: const <Post>[],
        hasMore: true,
        autocomplete: const <String>[],
        error: null,
      ),
    );

    try {
      final results = await _repository.searchPosts(
        prefix: normalizedQuery,
        limit: 20,
        currentUid: _repository.currentUserId,
      );

      emit(
        state.copyWith(
          isLoading: false,
          results: results,
          hasMore: results.length == 20,
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
      final moreResults = await _repository.searchPosts(
        prefix: state.query.toLowerCase(),
        limit: 20,
        currentUid: _repository.currentUserId,
      );

      emit(
        state.copyWith(
          isLoading: false,
          results: [...state.results, ...moreResults],
          hasMore: moreResults.length == 20,
        ),
      );
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
    emit(const SearchState());
    loadSuggestions();
  }

  Future<void> toggleLike(Post post) async {
    final results = List<Post>.from(state.results);
    final index = results.indexWhere((p) => p.id == post.id);

    if (index == -1) return;

    final updatedPost = post.copyWith(
      isLiked: !post.isLiked,
      likeCount: post.isLiked ? post.likeCount - 1 : post.likeCount + 1,
    );

    results[index] = updatedPost;
    emit(state.copyWith(results: results));

    try {
      await _repository.toggleLike(post.id);
    } catch (e) {
      // Revert on error
      results[index] = post;
      emit(state.copyWith(results: results));
    }
  }

  Future<void> toggleBookmark(Post post) async {
    final results = List<Post>.from(state.results);
    final index = results.indexWhere((p) => p.id == post.id);

    if (index == -1) return;

    final updatedPost = post.copyWith(isBookmarked: !post.isBookmarked);
    results[index] = updatedPost;
    emit(state.copyWith(results: results));

    try {
      await _repository.togglePostBookmark(post.id);
    } catch (e) {
      // Revert on error
      results[index] = post;
      emit(state.copyWith(results: results));
    }
  }

  @override
  Future<void> close() {
    _autocompleteDebounce?.cancel();
    return super.close();
  }
}
