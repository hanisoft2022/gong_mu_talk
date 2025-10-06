import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/community_repository.dart';
import '../../domain/models/post.dart';

part 'liked_posts_state.dart';

class LikedPostsCubit extends Cubit<LikedPostsState> {
  LikedPostsCubit(this._repository) : super(const LikedPostsState());

  final CommunityRepository _repository;
  static const int _pageSize = 20;

  Future<void> loadInitial() async {
    emit(state.copyWith(isLoading: true));

    try {
      final result = await _repository.fetchLikedPosts(
        uid: _repository.currentUserId,
        limit: _pageSize,
      );

      emit(
        state.copyWith(
          isLoading: false,
          likedPosts: result.items,
          hasMore: result.hasMore,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: '좋아요한 글을 불러오는 중 오류가 발생했습니다.'));
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading) return;

    emit(state.copyWith(isLoading: true));

    try {
      // TODO: Implement pagination with startAfter
      final morePosts = <Post>[];

      emit(
        state.copyWith(
          isLoading: false,
          likedPosts: [...state.likedPosts, ...morePosts],
          hasMore: morePosts.length == _pageSize,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(isLoading: false, error: '추가 글을 불러오는 중 오류가 발생했습니다.'),
      );
    }
  }

  Future<void> refresh() async {
    await loadInitial();
  }

  Future<void> toggleLike(Post post) async {
    final likedPosts = List<Post>.from(state.likedPosts);
    final index = likedPosts.indexWhere((p) => p.id == post.id);

    if (index == -1) return;

    // Optimistically remove from UI (unlike = remove from liked list)
    likedPosts.removeAt(index);
    emit(state.copyWith(likedPosts: likedPosts));

    try {
      await _repository.toggleLike(post.id);
    } catch (e) {
      // Revert on error
      likedPosts.insert(index, post);
      emit(state.copyWith(likedPosts: likedPosts));
    }
  }

  Future<void> toggleScrap(Post post) async {
    final likedPosts = List<Post>.from(state.likedPosts);
    final index = likedPosts.indexWhere((p) => p.id == post.id);

    if (index == -1) return;

    final updatedPost = post.copyWith(
      isScrapped: !post.isScrapped,
    );

    likedPosts[index] = updatedPost;
    emit(state.copyWith(likedPosts: likedPosts));

    try {
      await _repository.togglePostScrap(post.id);
    } catch (e) {
      // Revert on error
      likedPosts[index] = post;
      emit(state.copyWith(likedPosts: likedPosts));
    }
  }
}
