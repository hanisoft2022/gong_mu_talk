part of 'user_comments_cubit.dart';

class UserCommentsState extends Equatable {
  const UserCommentsState({
    this.comments = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.error,
    this.lastDocument,
  });

  final List<CommentWithPost> comments;
  final bool isLoading;
  final bool hasMore;
  final String? error;
  final QueryDocumentSnapshot<Map<String, Object?>>? lastDocument;

  UserCommentsState copyWith({
    List<CommentWithPost>? comments,
    bool? isLoading,
    bool? hasMore,
    String? error,
    QueryDocumentSnapshot<Map<String, Object?>>? lastDocument,
  }) {
    return UserCommentsState(
      comments: comments ?? this.comments,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error ?? this.error,
      lastDocument: lastDocument ?? this.lastDocument,
    );
  }

  @override
  List<Object?> get props => [comments, isLoading, hasMore, error, lastDocument];
}
