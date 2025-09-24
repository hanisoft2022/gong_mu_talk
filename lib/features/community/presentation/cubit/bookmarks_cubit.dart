import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../data/community_repository.dart';
import '../../domain/models/post.dart';

part 'bookmarks_state.dart';

@injectable
class BookmarksCubit extends Cubit<BookmarksState> {
  BookmarksCubit(this._repository) : super(const BookmarksState());

  final CommunityRepository _repository;
  static const int _pageSize = 20;

  Future<void> loadInitial() async {
    emit(state.copyWith(isLoading: true));

    try {
      final result = await _repository.fetchBookmarkedPosts(
        uid: _repository.currentUserId,
        limit: _pageSize,
      );

      emit(state.copyWith(
        isLoading: false,
        bookmarks: result.items,
        hasMore: result.hasMore,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: '북마크를 불러오는 중 오류가 발생했습니다.',
      ));
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading) return;

    emit(state.copyWith(isLoading: true));

    try {
      // In a real implementation, you'd use pagination with startAfter
      // For now, we'll just return empty to indicate no more results
      final moreBookmarks = <Post>[];

      emit(state.copyWith(
        isLoading: false,
        bookmarks: [...state.bookmarks, ...moreBookmarks],
        hasMore: moreBookmarks.length == _pageSize,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: '추가 북마크를 불러오는 중 오류가 발생했습니다.',
      ));
    }
  }

  Future<void> refresh() async {
    await loadInitial();
  }

  Future<void> toggleLike(Post post) async {
    final bookmarks = List<Post>.from(state.bookmarks);
    final index = bookmarks.indexWhere((p) => p.id == post.id);

    if (index == -1) return;

    final updatedPost = post.copyWith(
      isLiked: !post.isLiked,
      likeCount: post.isLiked ? post.likeCount - 1 : post.likeCount + 1,
    );

    bookmarks[index] = updatedPost;
    emit(state.copyWith(bookmarks: bookmarks));

    try {
      await _repository.toggleLike(post.id);
    } catch (e) {
      // Revert on error
      bookmarks[index] = post;
      emit(state.copyWith(bookmarks: bookmarks));
    }
  }

  Future<void> removeBookmark(Post post) async {
    final bookmarks = List<Post>.from(state.bookmarks);
    final index = bookmarks.indexWhere((p) => p.id == post.id);

    if (index == -1) return;

    // Optimistically remove from UI
    bookmarks.removeAt(index);
    emit(state.copyWith(bookmarks: bookmarks));

    try {
      await _repository.togglePostBookmark(post.id);
    } catch (e) {
      // Revert on error
      bookmarks.insert(index, post);
      emit(state.copyWith(bookmarks: bookmarks));
    }
  }

  Future<void> clearAll() async {
    final originalBookmarks = List<Post>.from(state.bookmarks);

    // Optimistically clear
    emit(state.copyWith(bookmarks: []));

    try {
      // Clear all bookmarks for current user
      await Future.wait(
        originalBookmarks.map(
          (Post post) => _repository.toggleBookmark(
            uid: _repository.currentUserId,
            postId: post.id,
          ),
        ),
      );
    } catch (e) {
      // Revert on error
      emit(state.copyWith(
        bookmarks: originalBookmarks,
        error: '북마크 삭제 중 오류가 발생했습니다.',
      ));
    }
  }
}
