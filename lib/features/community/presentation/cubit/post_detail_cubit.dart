import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../data/community_repository.dart';
import '../../domain/models/comment.dart';
import '../../domain/models/post.dart';
import '../../../profile/domain/career_track.dart';

part 'post_detail_state.dart';

@injectable
class PostDetailCubit extends Cubit<PostDetailState> {
  PostDetailCubit(this._repository) : super(const PostDetailState());

  final CommunityRepository _repository;

  String get currentUserId => _repository.currentUserId;

  Future<void> loadPost(String postId, {Post? fallback}) async {
    if (fallback != null) {
      emit(
        state.copyWith(
          status: PostDetailStatus.loaded,
          post: fallback,
          featuredComments: _buildFallbackFeaturedComments(fallback),
          comments: _buildFallbackChronologicalComments(fallback),
          isLoadingComments: false,
        ),
      );

      if (_isDummyPost(fallback)) {
        return;
      }
    } else {
      emit(state.copyWith(status: PostDetailStatus.loading));
    }

    try {
      final post = await _repository.getPost(postId);
      if (post == null) {
        if (fallback != null) {
          return;
        }
        emit(
          state.copyWith(
            status: PostDetailStatus.error,
            errorMessage: '게시글을 찾을 수 없습니다.',
          ),
        );
        return;
      }

      emit(state.copyWith(status: PostDetailStatus.loaded, post: post));

      await _loadComments(postId);
    } catch (e) {
      if (fallback != null) {
        return;
      }
      emit(
        state.copyWith(
          status: PostDetailStatus.error,
          errorMessage: '게시글을 불러오는 중 오류가 발생했습니다.',
        ),
      );
    }
  }

  Future<void> _loadComments(String postId) async {
    emit(state.copyWith(isLoadingComments: true));

    try {
      final List<Comment> featured = await _repository.getTopComments(postId);
      final List<Comment> timeline = await _repository.getComments(postId);

      final Set<String> featuredIds = featured
          .map((comment) => comment.id)
          .toSet();
      final List<Comment> mergedTimeline = timeline
          .map((comment) {
            if (featuredIds.contains(comment.id)) {
              final Comment featuredMatch = featured.firstWhere(
                (featuredComment) => featuredComment.id == comment.id,
              );
              return featuredMatch;
            }
            return comment;
          })
          .toList(growable: false);

      emit(
        state.copyWith(
          featuredComments: featured,
          comments: mergedTimeline,
          isLoadingComments: false,
        ),
      );
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
      emit(state.copyWith(post: updatedPost, isSubmittingComment: false));

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
      likeCount: comment.isLiked
          ? comment.likeCount - 1
          : comment.likeCount + 1,
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

  Future<void> toggleCommentReaction(String commentId, String emoji) async {
    final Post? post = state.post;
    if (post == null) {
      return;
    }

    final String? current = state.comments
        .firstWhere(
          (Comment comment) => comment.id == commentId,
          orElse: () => state.featuredComments.firstWhere(
            (Comment comment) => comment.id == commentId,
            orElse: () => Comment(
              id: commentId,
              postId: post.id,
              authorUid: '',
              authorNickname: '',
              text: '',
              likeCount: 0,
              createdAt: DateTime.now(),
              authorTrack: CareerTrack.none,
              authorSupporterLevel: 0,
              authorIsSupporter: false,
            ),
          ),
        )
        .viewerReaction;

    final String? previous = current;
    final String? next = previous == emoji ? null : emoji;

    void emitWith(String? reaction) {
      emit(
        state.copyWith(
          comments: _updateCommentReactions(
            state.comments,
            commentId,
            reaction,
          ),
          featuredComments: _updateCommentReactions(
            state.featuredComments,
            commentId,
            reaction,
          ),
        ),
      );
    }

    emitWith(next);

    try {
      final String? confirmed = await _repository.toggleCommentReaction(
        postId: post.id,
        commentId: commentId,
        emoji: emoji,
      );
      if (confirmed != next) {
        emitWith(confirmed);
      }
    } catch (_) {
      emitWith(previous);
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

  bool _isDummyPost(Post post) {
    return post.id.startsWith('dummy_') || post.authorUid == 'dummy_user';
  }

  List<Comment> _buildFallbackFeaturedComments(Post post) {
    if (post.previewComments.isNotEmpty) {
      return post.previewComments
          .take(3)
          .map(
            (CachedComment comment) => Comment(
              id: comment.id,
              postId: post.id,
              authorUid: 'preview',
              authorNickname: comment.authorNickname,
              authorTrack: comment.authorTrack,
              text: comment.text,
              likeCount: comment.likeCount,
              createdAt: post.updatedAt ?? post.createdAt,
              reactionCounts: const <String, int>{},
              authorSupporterLevel: comment.authorSupporterLevel,
              authorIsSupporter: comment.authorIsSupporter,
            ),
          )
          .toList(growable: false);
    }

    if (post.topComment != null) {
      return <Comment>[
        Comment(
          id: post.topComment!.id,
          postId: post.id,
          authorUid: 'preview',
          authorNickname: post.topComment!.authorNickname,
          text: post.topComment!.text,
          likeCount: post.topComment!.likeCount,
          createdAt: post.updatedAt ?? post.createdAt,
          reactionCounts: const <String, int>{},
          authorTrack: post.topComment!.authorTrack,
          authorSupporterLevel: post.topComment!.authorSupporterLevel,
          authorIsSupporter: post.topComment!.authorIsSupporter,
        ),
      ];
    }

    return const <Comment>[];
  }

  List<Comment> _buildFallbackChronologicalComments(Post post) {
    if (post.previewComments.isNotEmpty) {
      return post.previewComments
          .map(
            (CachedComment comment) => Comment(
              id: comment.id,
              postId: post.id,
              authorUid: 'preview',
              authorNickname: comment.authorNickname,
              text: comment.text,
              likeCount: comment.likeCount,
              createdAt: post.updatedAt ?? post.createdAt,
              reactionCounts: const <String, int>{},
              authorTrack: comment.authorTrack,
              authorSupporterLevel: comment.authorSupporterLevel,
              authorIsSupporter: comment.authorIsSupporter,
            ),
          )
          .toList(growable: false);
    }

    if (post.topComment != null) {
      return <Comment>[
        Comment(
          id: post.topComment!.id,
          postId: post.id,
          authorUid: 'preview',
          authorNickname: post.topComment!.authorNickname,
          text: post.topComment!.text,
          likeCount: post.topComment!.likeCount,
          createdAt: post.updatedAt ?? post.createdAt,
          reactionCounts: const <String, int>{},
          authorTrack: post.topComment!.authorTrack,
          authorSupporterLevel: post.topComment!.authorSupporterLevel,
          authorIsSupporter: post.topComment!.authorIsSupporter,
        ),
      ];
    }

    return const <Comment>[];
  }

  List<Comment> _updateCommentReactions(
    List<Comment> source,
    String commentId,
    String? reaction,
  ) {
    return source
        .map(
          (Comment comment) => comment.id == commentId
              ? _adjustCommentReaction(comment, reaction)
              : comment,
        )
        .toList(growable: false);
  }

  Comment _adjustCommentReaction(Comment comment, String? reaction) {
    final Map<String, int> counts = Map<String, int>.from(
      comment.reactionCounts,
    );
    final String? current = comment.viewerReaction;
    if (current != null) {
      counts[current] = (counts[current] ?? 0) - 1;
      if ((counts[current] ?? 0) <= 0) {
        counts.remove(current);
      }
    }
    if (reaction != null) {
      counts[reaction] = (counts[reaction] ?? 0) + 1;
    }
    return comment.copyWith(viewerReaction: reaction, reactionCounts: counts);
  }
}
