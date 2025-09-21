import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../core/firebase/paginated_query.dart';
import '../../data/community_repository.dart';
import '../../domain/models/board.dart';
import '../../domain/models/post.dart';

part 'board_feed_state.dart';

class BoardFeedCubit extends Cubit<BoardFeedState> {
  BoardFeedCubit({
    required CommunityRepository repository,
    required AuthCubit authCubit,
  }) : _repository = repository,
       _authCubit = authCubit,
       super(const BoardFeedState());

  final CommunityRepository _repository;
  final AuthCubit _authCubit;

  QueryDocumentSnapshotJson? _cursor;
  bool _isFetching = false;

  Future<void> loadBoard(Board board) async {
    if (_isFetching) {
      return;
    }
    _isFetching = true;
    emit(state.copyWith(status: BoardFeedStatus.loading, board: board, errorMessage: null));
    _cursor = null;
    try {
      final PaginatedQueryResult<Post> result = await _repository.fetchBoardPosts(
        boardId: board.id,
        limit: _pageSize,
        currentUid: _authCubit.state.userId,
      );
      emit(
        state.copyWith(
          status: BoardFeedStatus.loaded,
          posts: result.items,
          hasMore: result.hasMore,
          likedPostIds: result.items
              .where((Post post) => post.isLiked)
              .map((Post post) => post.id)
              .toSet(),
          bookmarkedPostIds: result.items
              .where((Post post) => post.isBookmarked)
              .map((Post post) => post.id)
              .toSet(),
        ),
      );
      _cursor = result.lastDocument;
    } catch (_) {
      emit(state.copyWith(status: BoardFeedStatus.error, errorMessage: '게시판 글을 불러오지 못했습니다.'));
    } finally {
      _isFetching = false;
    }
  }

  Future<void> refresh() async {
    final Board? board = state.board;
    if (board == null) {
      return;
    }
    await loadBoard(board);
  }

  Future<void> fetchMore() async {
    if (_isFetching || !state.hasMore || state.board == null) {
      return;
    }
    _isFetching = true;
    emit(state.copyWith(isLoadingMore: true));
    try {
      final PaginatedQueryResult<Post> result = await _repository.fetchBoardPosts(
        boardId: state.board!.id,
        limit: _pageSize,
        startAfter: _cursor,
        currentUid: _authCubit.state.userId,
      );
      final List<Post> combined = List<Post>.from(state.posts)..addAll(result.items);
      final Set<String> liked = Set<String>.from(state.likedPostIds)
        ..addAll(result.items.where((Post post) => post.isLiked).map((Post post) => post.id));
      final Set<String> bookmarked = Set<String>.from(state.bookmarkedPostIds)
        ..addAll(result.items.where((Post post) => post.isBookmarked).map((Post post) => post.id));
      emit(
        state.copyWith(
          posts: combined,
          hasMore: result.hasMore,
          isLoadingMore: false,
          likedPostIds: liked,
          bookmarkedPostIds: bookmarked,
        ),
      );
      _cursor = result.lastDocument ?? _cursor;
    } catch (_) {
      emit(state.copyWith(isLoadingMore: false, errorMessage: '다음 글을 불러오지 못했습니다.'));
    } finally {
      _isFetching = false;
    }
  }

  Future<void> toggleLike(Post post) async {
    final String? uid = _authCubit.state.userId;
    if (uid == null) {
      return;
    }

    try {
      final bool nowLiked = await _repository.togglePostLike(postId: post.id, uid: uid);
      final List<Post> updated = state.posts.map((Post existing) {
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
      emit(state.copyWith(posts: updated, likedPostIds: liked));
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
      final List<Post> updated = state.posts.map((Post existing) {
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
      emit(state.copyWith(posts: updated, bookmarkedPostIds: bookmarked));
    } catch (_) {
      emit(state.copyWith(errorMessage: '스크랩 처리 중 오류가 발생했습니다.'));
    }
  }

  static const int _pageSize = 20;
}
