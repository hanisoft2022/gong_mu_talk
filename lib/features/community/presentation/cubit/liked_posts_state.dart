part of 'liked_posts_cubit.dart';

class LikedPostsState extends Equatable {
  const LikedPostsState({
    this.likedPosts = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.error,
  });

  final List<Post> likedPosts;
  final bool isLoading;
  final bool hasMore;
  final String? error;

  LikedPostsState copyWith({
    List<Post>? likedPosts,
    bool? isLoading,
    bool? hasMore,
    String? error,
  }) {
    return LikedPostsState(
      likedPosts: likedPosts ?? this.likedPosts,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [likedPosts, isLoading, hasMore, error];
}
