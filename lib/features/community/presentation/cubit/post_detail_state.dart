part of 'post_detail_cubit.dart';

enum PostDetailStatus { initial, loading, loaded, error }

class PostDetailState extends Equatable {
  const PostDetailState({
    this.status = PostDetailStatus.initial,
    this.post,
    this.comments = const [],
    this.isLoadingComments = false,
    this.isSubmittingComment = false,
    this.errorMessage,
  });

  final PostDetailStatus status;
  final Post? post;
  final List<Comment> comments;
  final bool isLoadingComments;
  final bool isSubmittingComment;
  final String? errorMessage;

  PostDetailState copyWith({
    PostDetailStatus? status,
    Post? post,
    List<Comment>? comments,
    bool? isLoadingComments,
    bool? isSubmittingComment,
    String? errorMessage,
  }) {
    return PostDetailState(
      status: status ?? this.status,
      post: post ?? this.post,
      comments: comments ?? this.comments,
      isLoadingComments: isLoadingComments ?? this.isLoadingComments,
      isSubmittingComment: isSubmittingComment ?? this.isSubmittingComment,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        post,
        comments,
        isLoadingComments,
        isSubmittingComment,
        errorMessage,
      ];
}