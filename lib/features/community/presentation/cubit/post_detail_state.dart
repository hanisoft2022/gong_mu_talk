part of 'post_detail_cubit.dart';

enum PostDetailStatus { initial, loading, loaded, error }

class PostDetailState extends Equatable {
  static const Object _replyingToUnset = Object();

  const PostDetailState({
    this.status = PostDetailStatus.initial,
    this.post,
    this.comments = const [],
    this.featuredComments = const [],
    this.isLoadingComments = false,
    this.isSubmittingComment = false,
    this.errorMessage,
    this.replyingTo,
  });

  final PostDetailStatus status;
  final Post? post;
  final List<Comment> comments;
  final List<Comment> featuredComments;
  final bool isLoadingComments;
  final bool isSubmittingComment;
  final String? errorMessage;
  final Comment? replyingTo;

  PostDetailState copyWith({
    PostDetailStatus? status,
    Post? post,
    List<Comment>? comments,
    List<Comment>? featuredComments,
    bool? isLoadingComments,
    bool? isSubmittingComment,
    String? errorMessage,
    Object? replyingTo = _replyingToUnset,
  }) {
    return PostDetailState(
      status: status ?? this.status,
      post: post ?? this.post,
      comments: comments ?? this.comments,
      featuredComments: featuredComments ?? this.featuredComments,
      isLoadingComments: isLoadingComments ?? this.isLoadingComments,
      isSubmittingComment: isSubmittingComment ?? this.isSubmittingComment,
      errorMessage: errorMessage ?? this.errorMessage,
      replyingTo: replyingTo == _replyingToUnset
          ? this.replyingTo
          : replyingTo as Comment?,
    );
  }

  @override
  List<Object?> get props => [
    status,
    post,
    comments,
    featuredComments,
    isLoadingComments,
    isSubmittingComment,
    errorMessage,
    replyingTo,
  ];
}
