part of 'board_feed_cubit.dart';

enum BoardFeedStatus { initial, loading, loaded, error }

class BoardFeedState extends Equatable {
  const BoardFeedState({
    this.status = BoardFeedStatus.initial,
    this.posts = const <Post>[],
    this.board,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.errorMessage,
    this.likedPostIds = const <String>{},
    this.bookmarkedPostIds = const <String>{},
  });

  final BoardFeedStatus status;
  final List<Post> posts;
  final Board? board;
  final bool hasMore;
  final bool isLoadingMore;
  final String? errorMessage;
  final Set<String> likedPostIds;
  final Set<String> bookmarkedPostIds;

  BoardFeedState copyWith({
    BoardFeedStatus? status,
    List<Post>? posts,
    Board? board,
    bool? hasMore,
    bool? isLoadingMore,
    String? errorMessage,
    Set<String>? likedPostIds,
    Set<String>? bookmarkedPostIds,
  }) {
    return BoardFeedState(
      status: status ?? this.status,
      posts: posts ?? this.posts,
      board: board ?? this.board,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: errorMessage,
      likedPostIds: likedPostIds ?? this.likedPostIds,
      bookmarkedPostIds: bookmarkedPostIds ?? this.bookmarkedPostIds,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    status,
    posts,
    board,
    hasMore,
    isLoadingMore,
    errorMessage,
    likedPostIds,
    bookmarkedPostIds,
  ];
}
