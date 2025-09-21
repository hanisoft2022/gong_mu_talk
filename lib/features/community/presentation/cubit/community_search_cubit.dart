import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../data/community_repository.dart';
import '../../domain/models/post.dart';
import '../../domain/models/search_suggestion.dart';

part 'community_search_state.dart';

class CommunitySearchCubit extends Cubit<CommunitySearchState> {
  CommunitySearchCubit({
    required CommunityRepository repository,
    required AuthCubit authCubit,
  })  : _repository = repository,
        _authCubit = authCubit,
        super(const CommunitySearchState());

  final CommunityRepository _repository;
  final AuthCubit _authCubit;
  Timer? _debounce;

  Future<void> initialize() async {
    try {
      final List<SearchSuggestion> suggestions =
          await _repository.topSearchSuggestions(limit: 20);
      emit(
        state.copyWith(
          popularSuggestions:
              suggestions.map((SearchSuggestion suggestion) => suggestion.token).toList(growable: false),
        ),
      );
    } catch (_) {
      emit(state.copyWith(popularSuggestions: const <String>[]));
    }
  }

  void updateQuery(String value) {
    emit(state.copyWith(query: value, errorMessage: null));
    _debounce?.cancel();

    final String trimmed = value.trim();
    if (trimmed.isEmpty) {
      emit(
        state.copyWith(
          autocompleteSuggestions: const <String>[],
          isFetchingSuggestions: false,
        ),
      );
      return;
    }

    emit(state.copyWith(isFetchingSuggestions: true));
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        final List<String> tokens = await _repository.fetchAutocompleteTokens(
          prefix: trimmed,
          limit: 10,
        );
        emit(
          state.copyWith(
            autocompleteSuggestions: tokens,
            isFetchingSuggestions: false,
          ),
        );
      } catch (_) {
        emit(state.copyWith(isFetchingSuggestions: false));
      }
    });
  }

  Future<void> search([String? rawQuery]) async {
    final String target = (rawQuery ?? state.query).trim();
    if (target.isEmpty) {
      emit(state.copyWith(status: CommunitySearchStatus.initial, results: const <Post>[]));
      return;
    }

    emit(
      state.copyWith(
        status: CommunitySearchStatus.loading,
        query: target,
        errorMessage: null,
        autocompleteSuggestions: const <String>[],
      ),
    );

    try {
      final List<Post> results = await _repository.searchPosts(
        prefix: target,
        currentUid: _authCubit.state.userId,
      );
      final Set<String> liked = results
          .where((Post post) => post.isLiked)
          .map((Post post) => post.id)
          .toSet();
      final Set<String> bookmarked = results
          .where((Post post) => post.isBookmarked)
          .map((Post post) => post.id)
          .toSet();

      emit(
        state.copyWith(
          status: CommunitySearchStatus.success,
          results: results,
          likedPostIds: liked,
          bookmarkedPostIds: bookmarked,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: CommunitySearchStatus.error,
          errorMessage: '검색 중 오류가 발생했습니다. 잠시 후 다시 시도해주세요.',
        ),
      );
    }
  }

  Future<void> selectSuggestion(String suggestion) async {
    updateQuery(suggestion);
    await search(suggestion);
  }

  Future<void> toggleLike(Post post) async {
    final String? uid = _authCubit.state.userId;
    if (uid == null) {
      return;
    }

    try {
      final bool nowLiked = await _repository.togglePostLike(postId: post.id, uid: uid);
      final List<Post> updated = state.results.map((Post existing) {
        if (existing.id != post.id) {
          return existing;
        }
        final int nextCount =
            (existing.likeCount + (nowLiked ? 1 : -1)).clamp(0, 1 << 31).toInt();
        return existing.copyWith(likeCount: nextCount, isLiked: nowLiked);
      }).toList(growable: false);
      final Set<String> liked = Set<String>.from(state.likedPostIds);
      if (nowLiked) {
        liked.add(post.id);
      } else {
        liked.remove(post.id);
      }
      emit(state.copyWith(results: updated, likedPostIds: liked));
    } catch (_) {
      emit(state.copyWith(errorMessage: '좋아요 처리 중 오류가 발생했습니다.'));
    }
  }

  Future<void> toggleBookmark(Post post) async {
    final String? uid = _authCubit.state.userId;
    if (uid == null) {
      return;
    }

    try {
      await _repository.toggleBookmark(uid: uid, postId: post.id);
      final bool nowBookmarked = !state.bookmarkedPostIds.contains(post.id);
      final List<Post> updated = state.results.map((Post existing) {
        if (existing.id != post.id) {
          return existing;
        }
        return existing.copyWith(isBookmarked: nowBookmarked);
      }).toList(growable: false);
      final Set<String> bookmarked = Set<String>.from(state.bookmarkedPostIds);
      if (nowBookmarked) {
        bookmarked.add(post.id);
      } else {
        bookmarked.remove(post.id);
      }
      emit(state.copyWith(results: updated, bookmarkedPostIds: bookmarked));
    } catch (_) {
      emit(state.copyWith(errorMessage: '스크랩 처리 중 오류가 발생했습니다.'));
    }
  }

  void recordView(String postId) {
    unawaited(_repository.incrementViewCount(postId));
  }

  void clear() {
    emit(
      state.copyWith(
        query: '',
        results: const <Post>[],
        status: CommunitySearchStatus.initial,
        autocompleteSuggestions: const <String>[],
        likedPostIds: const <String>{},
        bookmarkedPostIds: const <String>{},
      ),
    );
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
