import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../profile/domain/career_track.dart';
import '../../../profile/domain/user_profile.dart';
import '../../../../core/firebase/paginated_query.dart';
import '../../data/community_repository.dart';
import '../../domain/models/feed_filters.dart';
import '../../domain/models/post.dart';
import '../../../notifications/data/notification_repository.dart';

part 'community_feed_state.dart';

class CommunityFeedCubit extends Cubit<CommunityFeedState> {
  CommunityFeedCubit({
    required CommunityRepository repository,
    required AuthCubit authCubit,
    required NotificationRepository notificationRepository,
  }) : _repository = repository,
       _authCubit = authCubit,
       _notificationRepository = notificationRepository,
       super(const CommunityFeedState()) {
    _authSubscription = _authCubit.stream.listen(_handleAuthChanged);
    emit(
      state.copyWith(
        careerTrack: _authCubit.state.careerTrack,
        serial: _authCubit.state.serial,
      ),
    );
  }

  final CommunityRepository _repository;
  final AuthCubit _authCubit;
  final NotificationRepository _notificationRepository;
  late final StreamSubscription<AuthState> _authSubscription;

  final Map<String, QueryDocumentSnapshotJson?> _cursors =
      <String, QueryDocumentSnapshotJson?>{};
  bool _isFetching = false;

  static const int _pageSize = 20;

  String _cursorKey(LoungeScope scope, LoungeSort sort) =>
      '${scope.name}_${sort.name}';

  bool get _shouldShowAds {
    final AuthState authState = _authCubit.state;
    final bool isSupporter =
        authState.supporterLevel > 0 ||
        authState.premiumTier != PremiumTier.none;
    return !isSupporter;
  }

  Future<void> loadInitial({LoungeScope? scope, LoungeSort? sort}) async {
    if (_isFetching) {
      return;
    }

    _isFetching = true;
    final LoungeScope targetScope = scope ?? state.scope;
    final LoungeSort targetSort = sort ?? state.sort;
    emit(
      state.copyWith(
        status: CommunityFeedStatus.loading,
        scope: targetScope,
        sort: targetSort,
        errorMessage: null,
        careerTrack: _authCubit.state.careerTrack,
        serial: _authCubit.state.serial,
      ),
    );

    _cursors[_cursorKey(targetScope, targetSort)] = null;

    try {
      final PaginatedQueryResult<Post> result = await _fetchPosts(
        targetScope,
        targetSort,
        reset: true,
      );
      final Set<String> liked = result.items
          .where((Post post) => post.isLiked)
          .map((Post post) => post.id)
          .toSet();
      final Set<String> bookmarked = result.items
          .where((Post post) => post.isBookmarked)
          .map((Post post) => post.id)
          .toSet();

      emit(
        state.copyWith(
          status: CommunityFeedStatus.loaded,
          posts: result.items,
          scope: targetScope,
          sort: targetSort,
          hasMore: result.hasMore,
          isLoadingMore: false,
          likedPostIds: liked,
          bookmarkedPostIds: bookmarked,
          errorMessage: null,
          careerTrack: _authCubit.state.careerTrack,
          serial: _authCubit.state.serial,
          showAds: _shouldShowAds,
        ),
      );

      _cursors[_cursorKey(targetScope, targetSort)] = result.lastDocument;
      unawaited(
        _notificationRepository.maybeShowWeeklySerialDigest(
          track: _authCubit.state.careerTrack,
          posts: result.items,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: CommunityFeedStatus.error,
          errorMessage: '피드를 불러오지 못했습니다. 잠시 후 다시 시도해주세요.',
          posts: const <Post>[],
          hasMore: false,
          isLoadingMore: false,
        ),
      );
    } finally {
      _isFetching = false;
    }
  }

  Future<void> refresh() async {
    if (_isFetching) {
      return;
    }
    _isFetching = true;
    emit(
      state.copyWith(
        status: CommunityFeedStatus.refreshing,
        errorMessage: null,
      ),
    );
    try {
      final PaginatedQueryResult<Post> result = await _fetchPosts(
        state.scope,
        state.sort,
        reset: true,
      );
      final Set<String> liked = result.items
          .where((Post post) => post.isLiked)
          .map((Post post) => post.id)
          .toSet();
      final Set<String> bookmarked = result.items
          .where((Post post) => post.isBookmarked)
          .map((Post post) => post.id)
          .toSet();
      emit(
        state.copyWith(
          status: CommunityFeedStatus.loaded,
          posts: result.items,
          hasMore: result.hasMore,
          isLoadingMore: false,
          likedPostIds: liked,
          bookmarkedPostIds: bookmarked,
          errorMessage: null,
          showAds: _shouldShowAds,
        ),
      );
      _cursors[_cursorKey(state.scope, state.sort)] = result.lastDocument;
      unawaited(
        _notificationRepository.maybeShowWeeklySerialDigest(
          track: _authCubit.state.careerTrack,
          posts: result.items,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: CommunityFeedStatus.error,
          errorMessage: '새로고침 중 오류가 발생했습니다.',
        ),
      );
    } finally {
      _isFetching = false;
    }
  }

  Future<void> fetchMore() async {
    if (_isFetching || !state.hasMore || state.isLoadingMore) {
      return;
    }

    _isFetching = true;
    emit(state.copyWith(isLoadingMore: true));

    try {
      final PaginatedQueryResult<Post> result = await _fetchPosts(
        state.scope,
        state.sort,
        reset: false,
      );
      final List<Post> combined = List<Post>.from(state.posts)
        ..addAll(result.items);
      final Set<String> liked = Set<String>.from(state.likedPostIds)
        ..addAll(
          result.items
              .where((Post post) => post.isLiked)
              .map((Post post) => post.id),
        );
      final Set<String> bookmarked = Set<String>.from(state.bookmarkedPostIds)
        ..addAll(
          result.items
              .where((Post post) => post.isBookmarked)
              .map((Post post) => post.id),
        );

      emit(
        state.copyWith(
          posts: combined,
          hasMore: result.hasMore,
          isLoadingMore: false,
          likedPostIds: liked,
          bookmarkedPostIds: bookmarked,
          errorMessage: null,
        ),
      );

      final String key = _cursorKey(state.scope, state.sort);
      _cursors[key] = result.lastDocument ?? _cursors[key];
    } catch (_) {
      emit(
        state.copyWith(
          isLoadingMore: false,
          errorMessage: '다음 글을 불러오는 중 문제가 발생했습니다.',
        ),
      );
    } finally {
      _isFetching = false;
    }
  }

  Future<void> changeScope(LoungeScope scope) async {
    if (state.scope == scope && state.status == CommunityFeedStatus.loaded) {
      return;
    }
    await loadInitial(scope: scope);
  }

  Future<void> changeSort(LoungeSort sort) async {
    if (state.sort == sort && state.status == CommunityFeedStatus.loaded) {
      return;
    }
    await loadInitial(sort: sort);
  }

  Future<void> toggleLike(Post post) async {
    final String? uid = _authCubit.state.userId;
    if (uid == null) {
      return;
    }

    try {
      final bool nowLiked = await _repository.togglePostLike(
        postId: post.id,
        uid: uid,
      );
      final List<Post> updatedPosts = state.posts
          .map((Post existing) {
            if (existing.id != post.id) {
              return existing;
            }
            final int nextCount = (existing.likeCount + (nowLiked ? 1 : -1))
                .clamp(0, 1 << 31)
                .toInt();
            return existing.copyWith(likeCount: nextCount, isLiked: nowLiked);
          })
          .toList(growable: false);

      final Set<String> liked = Set<String>.from(state.likedPostIds);
      if (nowLiked) {
        liked.add(post.id);
      } else {
        liked.remove(post.id);
      }

      emit(state.copyWith(posts: updatedPosts, likedPostIds: liked));
    } catch (_) {
      emit(state.copyWith(errorMessage: '좋아요 처리 중 오류가 발생했습니다.'));
    }
  }

  Future<void> toggleBookmark(Post post) async {
    final String? uid = _authCubit.state.userId;
    if (uid == null) {
      return;
    }

    try {
      await _repository.toggleBookmark(uid: uid, postId: post.id);
      final bool nowBookmarked = !state.bookmarkedPostIds.contains(post.id);
      final List<Post> updatedPosts = state.posts
          .map((Post existing) {
            if (existing.id != post.id) {
              return existing;
            }
            return existing.copyWith(isBookmarked: nowBookmarked);
          })
          .toList(growable: false);

      final Set<String> bookmarked = Set<String>.from(state.bookmarkedPostIds);
      if (nowBookmarked) {
        bookmarked.add(post.id);
      } else {
        bookmarked.remove(post.id);
      }

      emit(state.copyWith(posts: updatedPosts, bookmarkedPostIds: bookmarked));
    } catch (_) {
      emit(state.copyWith(errorMessage: '스크랩 처리 중 오류가 발생했습니다.'));
    }
  }

  Future<void> incrementViewCount(String postId) async {
    unawaited(_repository.incrementViewCount(postId));
  }

  Future<void> seedDummyChirps() async {
    final AuthState auth = _authCubit.state;
    final String? uid = auth.userId;
    if (uid == null) {
      return;
    }
    try {
      await _repository.seedSamplePosts(
        uid: uid,
        nickname: auth.nickname,
        track: auth.careerTrack,
        serial: auth.serial,
        count: 16,
      );
      await refresh();
    } catch (_) {
      emit(state.copyWith(errorMessage: '더미 데이터를 추가하지 못했습니다.'));
    }
  }

  @override
  Future<void> close() async {
    await _authSubscription.cancel();
    return super.close();
  }

  void _handleAuthChanged(AuthState authState) {
    final bool serialChanged = authState.serial != state.serial;
    final bool trackChanged = authState.careerTrack != state.careerTrack;

    final bool supporterChanged = state.showAds != _shouldShowAds;

    if (serialChanged || trackChanged || supporterChanged) {
      emit(
        state.copyWith(
          careerTrack: authState.careerTrack,
          serial: authState.serial,
          showAds: _shouldShowAds,
        ),
      );
      if (state.scope == LoungeScope.serial && serialChanged) {
        unawaited(loadInitial(scope: LoungeScope.serial));
      }
    }
  }

  Future<PaginatedQueryResult<Post>> _fetchPosts(
    LoungeScope scope,
    LoungeSort sort, {
    required bool reset,
  }) async {
    final String? uid = _authCubit.state.userId;
    final String key = _cursorKey(scope, sort);
    final QueryDocumentSnapshotJson? startAfter = reset ? null : _cursors[key];

    final String serial = _authCubit.state.serial;

    if (scope == LoungeScope.serial &&
        (serial == 'unknown' || serial.isEmpty)) {
      return const PaginatedQueryResult<Post>(
        items: <Post>[],
        lastDocument: null,
        hasMore: false,
      );
    }

    return _repository.fetchLoungeFeed(
      scope: scope,
      sort: sort,
      limit: _pageSize,
      startAfter: startAfter,
      serial: scope == LoungeScope.serial ? serial : null,
      currentUid: uid,
    );
  }
}
