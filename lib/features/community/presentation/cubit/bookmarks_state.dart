part of 'bookmarks_cubit.dart';

class BookmarksState extends Equatable {
  const BookmarksState({
    this.bookmarks = const [],
    this.isLoading = false,
    this.hasMore = false,
    this.error,
  });

  final List<Post> bookmarks;
  final bool isLoading;
  final bool hasMore;
  final String? error;

  BookmarksState copyWith({
    List<Post>? bookmarks,
    bool? isLoading,
    bool? hasMore,
    String? error,
  }) {
    return BookmarksState(
      bookmarks: bookmarks ?? this.bookmarks,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [bookmarks, isLoading, hasMore, error];
}
