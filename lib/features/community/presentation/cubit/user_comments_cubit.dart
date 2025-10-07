import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/community_repository.dart';
import '../../domain/models/comment_with_post.dart';

part 'user_comments_state.dart';

class UserCommentsCubit extends Cubit<UserCommentsState> {
  UserCommentsCubit(this._repository) : super(const UserCommentsState());

  final CommunityRepository _repository;
  static const int _pageSize = 20;

  Future<void> loadInitial(String authorUid) async {
    emit(state.copyWith(isLoading: true));

    try {
      final result = await _repository.fetchUserComments(
        authorUid: authorUid,
        limit: _pageSize,
      );

      emit(
        state.copyWith(
          isLoading: false,
          comments: result.items,
          hasMore: result.hasMore,
          lastDocument: result.lastDocument,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: '댓글을 불러오는 중 오류가 발생했습니다.'));
    }
  }

  Future<void> loadMore(String authorUid) async {
    if (!state.hasMore || state.isLoading || state.lastDocument == null) {
      return;
    }

    emit(state.copyWith(isLoading: true));

    try {
      final result = await _repository.fetchUserComments(
        authorUid: authorUid,
        limit: _pageSize,
        startAfter: state.lastDocument,
      );

      emit(
        state.copyWith(
          isLoading: false,
          comments: [...state.comments, ...result.items],
          hasMore: result.hasMore,
          lastDocument: result.lastDocument,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(isLoading: false, error: '추가 댓글을 불러오는 중 오류가 발생했습니다.'),
      );
    }
  }

  Future<void> refresh(String authorUid) async {
    emit(const UserCommentsState()); // Reset state
    await loadInitial(authorUid);
  }
}
