import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import '../../data/community_repository.dart';
import '../../domain/models/comment.dart';
import 'post_card_state.dart';

/// Cubit for PostCard widget
///
/// Responsibilities:
/// - Load comments (featured + timeline)
/// - Submit comments
/// - Toggle comment likes (with optimistic updates)
/// - Report posts
/// - Block users
/// - Track view interactions
///
/// This cubit replaces direct Repository calls from PostCard StatefulWidget,
/// following CLAUDE.md principle: "Repository 호출 → Cubit 필수"
class PostCardCubit extends Cubit<PostCardState> {
  PostCardCubit({
    required CommunityRepository repository,
    required String postId,
    required int initialCommentCount,
  }) : _repository = repository,
       _postId = postId,
       super(PostCardState.initial(commentCount: initialCommentCount));

  final CommunityRepository _repository;
  final String _postId;

  /// Load comments for the post
  ///
  /// Loads both featured (top) and timeline comments.
  /// Featured comment criteria:
  /// - Total comments >= 3
  /// - Top comment likeCount >= 3
  ///
  /// [force] - Force reload even if already loaded
  Future<void> loadComments({bool force = false}) async {
    // Skip if already loaded and not forcing
    if (state.commentsLoaded && !force) {
      return;
    }

    emit(state.copyWith(isLoadingComments: true, clearError: true));

    try {
      // Fetch featured (top) and timeline comments in parallel
      final results = await Future.wait([
        _repository.getTopComments(_postId, limit: 1),
        _repository.getComments(_postId),
      ]);

      final List<Comment> featured = results[0];
      final List<Comment> timeline = results[1];

      // Merge featured comments into timeline to ensure consistency
      final Set<String> featuredIds = featured.map((c) => c.id).toSet();
      final List<Comment> mergedTimeline = timeline.map((comment) {
        if (featuredIds.contains(comment.id)) {
          return featured.firstWhere(
            (featuredComment) => featuredComment.id == comment.id,
            orElse: () => comment,
          );
        }
        return comment;
      }).toList();

      // Apply featured comment criteria
      final bool canShowFeatured =
          timeline.length >= 3 &&
          featured.isNotEmpty &&
          featured.first.likeCount >= 3;

      emit(
        state.copyWith(
          isLoadingComments: false,
          commentsLoaded: true,
          featuredComments: canShowFeatured ? featured : [],
          timelineComments: mergedTimeline,
          clearError: true,
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading comments for post $_postId: $e');
      debugPrint('Stack trace: $stackTrace');

      emit(
        state.copyWith(
          isLoadingComments: false,
          error: '댓글을 불러오지 못했어요. 잠시 후 다시 시도해주세요.',
        ),
      );
    }
  }

  /// Submit a new comment
  ///
  /// [text] - Comment text (whitespace will be trimmed)
  /// [imageUrls] - Optional image URLs for the comment
  ///
  /// After successful submission:
  /// - Increments comment count
  /// - Reloads comments automatically
  Future<void> submitComment(
    String text, {
    List<String> imageUrls = const [],
  }) async {
    final String trimmedText = text.trim();

    // Validate comment content
    if (trimmedText.isEmpty && imageUrls.isEmpty) {
      return; // Silent fail for empty comments
    }

    emit(state.copyWith(isSubmittingComment: true, clearError: true));

    try {
      await _repository.addComment(_postId, trimmedText, imageUrls: imageUrls);

      // Increment count
      emit(
        state.copyWith(
          isSubmittingComment: false,
          commentCount: state.commentCount + 1,
          clearError: true,
        ),
      );

      // Reload comments to show the new one
      await loadComments(force: true);
    } catch (e) {
      debugPrint('❌ Error submitting comment for post $_postId: $e');

      // Don't reload comments on error
      emit(
        state.copyWith(
          isSubmittingComment: false,
          error: '댓글을 저장하지 못했어요. 잠시 후 다시 시도해주세요.',
        ),
      );
    }
  }

  /// Toggle like on a comment with optimistic update
  ///
  /// Uses optimistic update pattern:
  /// 1. Immediately update UI
  /// 2. Call repository
  /// 3. Rollback if API call fails
  Future<void> toggleCommentLike(Comment comment) async {
    final bool willLike = !comment.isLiked;
    final int nextCount = max(0, comment.likeCount + (willLike ? 1 : -1));

    // Optimistic update - immediately reflect in UI
    _updateCommentInLists(
      comment.id,
      comment.copyWith(isLiked: willLike, likeCount: nextCount),
    );

    try {
      await _repository.toggleCommentLikeById(_postId, comment.id);
    } catch (e) {
      debugPrint('❌ Error toggling comment like: $e');

      // Rollback on failure (no error emit - silent fail for better UX)
      _updateCommentInLists(
        comment.id,
        comment, // Revert to original
      );
    }
  }

  /// Report the post
  Future<void> reportPost(String reason) async {
    try {
      await _repository.reportPost(_postId, reason);
    } catch (e) {
      debugPrint('❌ Error reporting post $_postId: $e');

      emit(state.copyWith(error: '신고를 처리하지 못했어요. 잠시 후 다시 시도해주세요.'));
    }
  }

  /// Block a user
  Future<void> blockUser(String uid) async {
    try {
      await _repository.blockUser(uid);
    } catch (e) {
      debugPrint('❌ Error blocking user $uid: $e');

      emit(state.copyWith(error: '차단에 실패했습니다. 잠시 후 다시 시도해주세요.'));
    }
  }

  /// Delete a comment (soft delete)
  ///
  /// Marks the comment as deleted. Firebase Functions will handle commentCount decrement.
  /// Returns the original comment text for potential undo operation.
  Future<String?> deleteComment(Comment comment, String requesterUid) async {
    try {
      // Store original text for potential undo
      final String originalText = comment.text;

      // Optimistic UI update - mark as deleted immediately
      _updateCommentInLists(
        comment.id,
        comment.copyWith(deleted: true, text: '[삭제된 댓글]'),
      );

      // Call repository to soft delete
      await _repository.deleteComment(
        postId: _postId,
        commentId: comment.id,
        requesterUid: requesterUid,
      );

      // Optimistic commentCount decrement (will be corrected by Functions)
      emit(state.copyWith(commentCount: max(0, state.commentCount - 1)));

      return originalText; // Return for undo functionality
    } catch (e) {
      debugPrint('❌ Error deleting comment ${comment.id}: $e');

      // Rollback optimistic update on error
      _updateCommentInLists(comment.id, comment);
      emit(state.copyWith(
        error: '댓글 삭제에 실패했습니다. 잠시 후 다시 시도해주세요.',
      ));

      return null;
    }
  }

  /// Undo comment deletion (restore)
  ///
  /// Restores a deleted comment. Firebase Functions will handle commentCount increment.
  Future<void> undoDeleteComment(
    String commentId,
    String requesterUid,
    String originalText,
  ) async {
    try {
      // Find the deleted comment
      Comment? deletedComment;
      try {
        deletedComment = state.timelineComments.firstWhere(
          (c) => c.id == commentId,
        );
      } catch (e) {
        deletedComment = null;
      }

      if (deletedComment == null) {
        debugPrint('❌ Cannot find deleted comment $commentId for undo');
        return;
      }

      // Optimistic UI update - restore immediately
      _updateCommentInLists(
        commentId,
        deletedComment.copyWith(deleted: false, text: originalText),
      );

      // Call repository to restore
      await _repository.undoDeleteComment(
        postId: _postId,
        commentId: commentId,
        requesterUid: requesterUid,
        originalText: originalText,
      );

      // Optimistic commentCount increment (will be corrected by Functions)
      emit(state.copyWith(commentCount: state.commentCount + 1));
    } catch (e) {
      debugPrint('❌ Error undoing comment deletion $commentId: $e');

      // Rollback - mark as deleted again
      Comment? comment;
      try {
        comment = state.timelineComments.firstWhere(
          (c) => c.id == commentId,
        );
        _updateCommentInLists(
          commentId,
          comment.copyWith(deleted: true, text: '[삭제된 댓글]'),
        );
      } catch (e) {
        // Comment not found in list, ignore rollback
      }

      emit(state.copyWith(
        error: '댓글 복구에 실패했습니다.',
      ));
    }
  }

  /// Clear error state
  void clearError() {
    emit(state.copyWith(clearError: true));
  }

  /// Helper: Update a comment in both featured and timeline lists
  void _updateCommentInLists(String commentId, Comment updatedComment) {
    final List<Comment> updatedTimeline = state.timelineComments
        .map((c) => c.id == commentId ? updatedComment : c)
        .toList();

    final List<Comment> updatedFeatured = state.featuredComments
        .map((c) => c.id == commentId ? updatedComment : c)
        .toList();

    emit(
      state.copyWith(
        timelineComments: updatedTimeline,
        featuredComments: updatedFeatured,
      ),
    );
  }
}
