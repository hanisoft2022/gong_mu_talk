import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/community_repository.dart';
import '../../domain/models/post.dart';

part 'scrap_state.dart';

class ScrapCubit extends Cubit<ScrapState> {
  ScrapCubit(this._repository) : super(const ScrapState());

  final CommunityRepository _repository;
  static const int _pageSize = 20;

  Future<void> loadInitial() async {
    emit(state.copyWith(isLoading: true));

    try {
      final result = await _repository.fetchScrappedPosts(
        uid: _repository.currentUserId,
        limit: _pageSize,
      );

      emit(
        state.copyWith(
          isLoading: false,
          scraps: result.items,
          hasMore: result.hasMore,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: '스크랩을 불러오는 중 오류가 발생했습니다.'));
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading) return;

    emit(state.copyWith(isLoading: true));

    try {
      // In a real implementation, you'd use pagination with startAfter
      // For now, we'll just return empty to indicate no more results
      final moreScraps = <Post>[];

      emit(
        state.copyWith(
          isLoading: false,
          scraps: [...state.scraps, ...moreScraps],
          hasMore: moreScraps.length == _pageSize,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(isLoading: false, error: '추가 스크랩을 불러오는 중 오류가 발생했습니다.'),
      );
    }
  }

  Future<void> refresh() async {
    await loadInitial();
  }

  Future<void> toggleLike(Post post) async {
    final scraps = List<Post>.from(state.scraps);
    final index = scraps.indexWhere((p) => p.id == post.id);

    if (index == -1) return;

    final updatedPost = post.copyWith(
      isLiked: !post.isLiked,
      likeCount: post.isLiked ? post.likeCount - 1 : post.likeCount + 1,
    );

    scraps[index] = updatedPost;
    emit(state.copyWith(scraps: scraps));

    try {
      await _repository.toggleLike(post.id);
    } catch (e) {
      // Revert on error
      scraps[index] = post;
      emit(state.copyWith(scraps: scraps));
    }
  }

  Future<void> removeScrap(Post post) async {
    final scraps = List<Post>.from(state.scraps);
    final index = scraps.indexWhere((p) => p.id == post.id);

    if (index == -1) return;

    // Optimistically remove from UI
    scraps.removeAt(index);
    emit(state.copyWith(scraps: scraps));

    try {
      await _repository.togglePostScrap(post.id);
    } catch (e) {
      // Revert on error
      scraps.insert(index, post);
      emit(state.copyWith(scraps: scraps));
    }
  }

  Future<void> clearAll() async {
    final originalScraps = List<Post>.from(state.scraps);

    // Optimistically clear
    emit(state.copyWith(scraps: []));

    try {
      // Clear all scraps for current user
      await Future.wait(
        originalScraps.map(
          (Post post) => _repository.toggleScrap(
            uid: _repository.currentUserId,
            postId: post.id,
          ),
        ),
      );
    } catch (e) {
      // Revert on error
      emit(
        state.copyWith(
          scraps: originalScraps,
          error: '스크랩 삭제 중 오류가 발생했습니다.',
        ),
      );
    }
  }
}
