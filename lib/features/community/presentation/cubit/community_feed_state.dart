part of 'community_feed_cubit.dart';

enum CommunityFeedStatus { initial, loading, loaded, error }
enum CommunityFeedScope { all, myTrack }

class CommunityFeedState extends Equatable {
  const CommunityFeedState({
    this.status = CommunityFeedStatus.initial,
    this.posts = const <CommunityPost>[],
    this.scope = CommunityFeedScope.all,
    this.currentTrack = CareerTrack.none,
  });

  final CommunityFeedStatus status;
  final List<CommunityPost> posts;
  final CommunityFeedScope scope;
  final CareerTrack currentTrack;

  CommunityFeedState copyWith({
    CommunityFeedStatus? status,
    List<CommunityPost>? posts,
    CommunityFeedScope? scope,
    CareerTrack? currentTrack,
  }) {
    return CommunityFeedState(
      status: status ?? this.status,
      posts: posts ?? this.posts,
      scope: scope ?? this.scope,
      currentTrack: currentTrack ?? this.currentTrack,
    );
  }

  @override
  List<Object?> get props => [status, posts, scope, currentTrack];
}
