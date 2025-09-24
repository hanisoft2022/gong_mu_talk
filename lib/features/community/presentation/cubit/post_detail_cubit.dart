import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../data/community_repository.dart';
import '../../domain/models/comment.dart';
import '../../domain/models/post.dart';

part 'post_detail_state.dart';

@injectable
class PostDetailCubit extends Cubit<PostDetailState> {
  PostDetailCubit(this._repository) : super(const PostDetailState());

  final CommunityRepository _repository;

  String get currentUserId => _repository.currentUserId;

  Future<void> loadPost(String postId) async {
    emit(state.copyWith(status: PostDetailStatus.loading));

    try {
      final post = await _repository.getPost(postId);
      if (post == null) {
        emit(state.copyWith(
          status: PostDetailStatus.error,
          errorMessage: '게시글을 찾을 수 없습니다.',
        ));
        return;
      }

      emit(state.copyWith(
        status: PostDetailStatus.loaded,
        post: post,
      ));

      await _loadComments(postId);
    } catch (e) {
      emit(state.copyWith(
        status: PostDetailStatus.error,
        errorMessage: '게시글을 불러오는 중 오류가 발생했습니다.',
      ));
    }
  }

  Future<void> _loadComments(String postId) async {
    emit(state.copyWith(isLoadingComments: true));

    try {
      final comments = await _repository.getComments(postId);
      emit(state.copyWith(
        comments: comments,
        isLoadingComments: false,
      ));
    } catch (e) {
      emit(state.copyWith(isLoadingComments: false));
    }
  }

  Future<void> refresh() async {
    if (state.post?.id != null) {
      await loadPost(state.post!.id);
    }
  }

  Future<void> toggleLike() async {
    final post = state.post;
    if (post == null) return;

    try {
      final updatedPost = post.copyWith(
        isLiked: !post.isLiked,
        likeCount: post.isLiked ? post.likeCount - 1 : post.likeCount + 1,
      );
      emit(state.copyWith(post: updatedPost));

      await _repository.toggleLike(post.id);
    } catch (e) {
      // Revert on error
      emit(state.copyWith(post: post));
    }
  }

  Future<void> toggleBookmark() async {
    final post = state.post;
    if (post == null) return;

    try {
      final updatedPost = post.copyWith(isBookmarked: !post.isBookmarked);
      emit(state.copyWith(post: updatedPost));

      await _repository.togglePostBookmark(post.id);
    } catch (e) {
      // Revert on error
      emit(state.copyWith(post: post));
    }
  }

  Future<bool> submitComment(String text) async {
    final post = state.post;
    if (post == null || text.trim().isEmpty) return false;

    emit(state.copyWith(isSubmittingComment: true));

    try {
      await _repository.addComment(post.id, text.trim());

      // Refresh comments
      await _loadComments(post.id);

      // Update post comment count
      final updatedPost = post.copyWith(commentCount: post.commentCount + 1);
      emit(state.copyWith(
        post: updatedPost,
        isSubmittingComment: false,
      ));

      return true;
    } catch (e) {
      emit(state.copyWith(isSubmittingComment: false));
      return false;
    }
  }

  Future<void> toggleCommentLike(String commentId) async {
    final comments = List<Comment>.from(state.comments);
    final index = comments.indexWhere((c) => c.id == commentId);

    if (index == -1) return;

    final comment = comments[index];
    final updatedComment = comment.copyWith(
      isLiked: !comment.isLiked,
      likeCount: comment.isLiked ? comment.likeCount - 1 : comment.likeCount + 1,
    );

    comments[index] = updatedComment;
    emit(state.copyWith(comments: comments));

    try {
      await _repository.toggleCommentLikeById(state.post!.id, commentId);
    } catch (e) {
      // Revert on error
      comments[index] = comment;
      emit(state.copyWith(comments: comments));
    }
  }

  Future<bool> deletePost() async {
    final post = state.post;
    if (post == null) return false;

    try {
      await _repository.deletePostById(post.id);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> reportPost() async {
    final post = state.post;
    if (post == null) return;

    try {
      await _repository.reportPost(post.id, 'inappropriate_content');
    } catch (e) {
      // Handle error silently for now
    }
  }

  Future<void> blockUser() async {
    final post = state.post;
    if (post == null) return;

    try {
      await _repository.blockUser(post.authorUid);
    } catch (e) {
      // Handle error silently for now
    }
  }
}