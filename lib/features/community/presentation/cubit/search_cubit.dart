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

    final String normalizedQuery = query.trim().toLowerCase();
    emit(state.copyWith(
      isLoading: true,
      query: normalizedQuery,
      results: [],
      hasMore: true,
    ));

    try {
      final results = await _repository.searchPosts(
        prefix: normalizedQuery,
        limit: 20,
        currentUid: _repository.currentUserId,
      );

      emit(state.copyWith(
        isLoading: false,
        results: results,
        hasMore: results.length == 20,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: '검색 중 오류가 발생했습니다.',
      ));
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading) return;

    emit(state.copyWith(isLoading: true));

    try {
      final moreResults = await _repository.searchPosts(
        prefix: state.query,
        limit: 20,
        currentUid: _repository.currentUserId,
      );

      emit(state.copyWith(
        isLoading: false,
        results: [...state.results, ...moreResults],
        hasMore: moreResults.length == 20,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: '추가 검색 결과를 불러오는 중 오류가 발생했습니다.',
      ));
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
}