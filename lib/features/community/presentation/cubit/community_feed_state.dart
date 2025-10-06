part of 'community_feed_cubit.dart';

enum CommunityFeedStatus { initial, loading, loaded, refreshing, sorting, lounging, error }

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
    this.scrappedPostIds = const <String>{},
    this.pendingLikePostIds = const <String>{},
    this.showAds = true,
    this.accessibleLounges = const <LoungeInfo>[],
    this.selectedLoungeInfo,
    this.isLoungeMenuOpen = false,
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
  final Set<String> scrappedPostIds;
  final Set<String> pendingLikePostIds;
  final bool showAds;
  final List<LoungeInfo> accessibleLounges;
  final LoungeInfo? selectedLoungeInfo;
  final bool isLoungeMenuOpen;

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
    Set<String>? scrappedPostIds,
    Set<String>? pendingLikePostIds,
    bool? showAds,
    List<LoungeInfo>? accessibleLounges,
    LoungeInfo? selectedLoungeInfo,
    bool? isLoungeMenuOpen,
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
      scrappedPostIds: scrappedPostIds ?? this.scrappedPostIds,
      pendingLikePostIds: pendingLikePostIds ?? this.pendingLikePostIds,
      showAds: showAds ?? this.showAds,
      accessibleLounges: accessibleLounges ?? this.accessibleLounges,
      selectedLoungeInfo: selectedLoungeInfo ?? this.selectedLoungeInfo,
      isLoungeMenuOpen: isLoungeMenuOpen ?? this.isLoungeMenuOpen,
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
    scrappedPostIds,
    pendingLikePostIds,
    showAds,
    accessibleLounges,
    selectedLoungeInfo,
    isLoungeMenuOpen,
  ];
}
