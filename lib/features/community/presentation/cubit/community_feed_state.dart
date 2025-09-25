part of 'community_feed_cubit.dart';

enum CommunityFeedStatus { initial, loading, loaded, refreshing, error }

class CommunityFeedState extends Equatable {
  const CommunityFeedState({
    this.status = CommunityFeedStatus.initial,
    this.posts = const <Post>[],
    this.scope = LoungeScope.all,
    this.sort = LoungeSort.latest,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.errorMessage,
    this.careerTrack = CareerTrack.none,
    this.serial = 'unknown',
    this.likedPostIds = const <String>{},
    this.bookmarkedPostIds = const <String>{},
    this.showAds = true,
  });

  final CommunityFeedStatus status;
  final List<Post> posts;
  final LoungeScope scope;
  final LoungeSort sort;
  final bool hasMore;
  final bool isLoadingMore;
  final String? errorMessage;
  final CareerTrack careerTrack;
  final String serial;
  final Set<String> likedPostIds;
  final Set<String> bookmarkedPostIds;
  final bool showAds;

  CommunityFeedState copyWith({
    CommunityFeedStatus? status,
    List<Post>? posts,
    LoungeScope? scope,
    LoungeSort? sort,
    bool? hasMore,
    bool? isLoadingMore,
    String? errorMessage,
    CareerTrack? careerTrack,
    String? serial,
    Set<String>? likedPostIds,
    Set<String>? bookmarkedPostIds,
    bool? showAds,
  }) {
    return CommunityFeedState(
      status: status ?? this.status,
      posts: posts ?? this.posts,
      scope: scope ?? this.scope,
      sort: sort ?? this.sort,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: errorMessage ?? this.errorMessage,
      careerTrack: careerTrack ?? this.careerTrack,
      serial: serial ?? this.serial,
      likedPostIds: likedPostIds ?? this.likedPostIds,
      bookmarkedPostIds: bookmarkedPostIds ?? this.bookmarkedPostIds,
      showAds: showAds ?? this.showAds,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    status,
    posts,
    scope,
    sort,
    hasMore,
    isLoadingMore,
    errorMessage,
    careerTrack,
    serial,
    likedPostIds,
    bookmarkedPostIds,
    showAds,
  ];
}
