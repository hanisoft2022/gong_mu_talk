part of 'scrap_cubit.dart';

class ScrapState extends Equatable {
  const ScrapState({
    this.scraps = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.error,
  });

  final List<Post> scraps;
  final bool isLoading;
  final bool hasMore;
  final String? error;

  ScrapState copyWith({
    List<Post>? scraps,
    bool? isLoading,
    bool? hasMore,
    String? error,
  }) {
    return ScrapState(
      scraps: scraps ?? this.scraps,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [scraps, isLoading, hasMore, error];
}
