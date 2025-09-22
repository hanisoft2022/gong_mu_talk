import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../profile/domain/career_track.dart';
import '../../../../core/firebase/paginated_query.dart';
import '../../data/community_repository.dart';
import '../../domain/models/post.dart';

part 'community_feed_state.dart';

class CommunityFeedCubit extends Cubit<CommunityFeedState> {
  CommunityFeedCubit({required CommunityRepository repository, required AuthCubit authCubit})
    : _repository = repository,
      _authCubit = authCubit,
      super(const CommunityFeedState()) {
    _authSubscription = _authCubit.stream.listen(_handleAuthChanged);
    emit(state.copyWith(careerTrack: _authCubit.state.careerTrack, serial: _authCubit.state.serial));
  }

  final CommunityRepository _repository;
  final AuthCubit _authCubit;
  late final StreamSubscription<AuthState> _authSubscription;

  final Map<CommunityFeedTab, QueryDocumentSnapshotJson?> _cursors = <CommunityFeedTab, QueryDocumentSnapshotJson?>{};
  bool _isFetching = false;

  static const int _pageSize = 20;

  Future<void> loadInitial({CommunityFeedTab? tab}) async {
    if (_isFetching) {
      return;
    }

    _isFetching = true;
    final CommunityFeedTab targetTab = tab ?? state.tab;
    emit(
      state.copyWith(
        status: CommunityFeedStatus.loading,
        tab: targetTab,
        errorMessage: null,
        careerTrack: _authCubit.state.careerTrack,
        serial: _authCubit.state.serial,
      ),
    );

    _cursors[targetTab] = null;

    try {
      final PaginatedQueryResult<Post> result = await _fetchPostsForTab(targetTab, reset: true);
      final Set<String> liked = result.items.where((Post post) => post.isLiked).map((Post post) => post.id).toSet();
      final Set<String> bookmarked = result.items
          .where((Post post) => post.isBookmarked)
          .map((Post post) => post.id)
          .toSet();

      emit(
        state.copyWith(
          status: CommunityFeedStatus.loaded,
          posts: result.items,
          tab: targetTab,
          hasMore: result.hasMore,
          isLoadingMore: false,
          likedPostIds: liked,
          bookmarkedPostIds: bookmarked,
          errorMessage: null,
          careerTrack: _authCubit.state.careerTrack,
          serial: _authCubit.state.serial,
        ),
      );

      _cursors[targetTab] = result.lastDocument;
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
    emit(state.copyWith(status: CommunityFeedStatus.refreshing, errorMessage: null));
    try {
      final PaginatedQueryResult<Post> result = await _fetchPostsForTab(state.tab, reset: true);
      final Set<String> liked = result.items.where((Post post) => post.isLiked).map((Post post) => post.id).toSet();
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
        ),
      );
      _cursors[state.tab] = result.lastDocument;
    } catch (_) {
      emit(state.copyWith(status: CommunityFeedStatus.error, errorMessage: '새로고침 중 오류가 발생했습니다.'));
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
      final PaginatedQueryResult<Post> result = await _fetchPostsForTab(state.tab, reset: false);
      final List<Post> combined = List<Post>.from(state.posts)..addAll(result.items);
      final Set<String> liked = Set<String>.from(state.likedPostIds)
        ..addAll(result.items.where((Post post) => post.isLiked).map((Post post) => post.id));
      final Set<String> bookmarked = Set<String>.from(state.bookmarkedPostIds)
        ..addAll(result.items.where((Post post) => post.isBookmarked).map((Post post) => post.id));

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

      _cursors[state.tab] = result.lastDocument ?? _cursors[state.tab];
    } catch (_) {
      emit(state.copyWith(isLoadingMore: false, errorMessage: '다음 글을 불러오는 중 문제가 발생했습니다.'));
    } finally {
      _isFetching = false;
    }
  }

  Future<void> changeTab(CommunityFeedTab tab) async {
    if (state.tab == tab && state.status == CommunityFeedStatus.loaded) {
      return;
    }
    await loadInitial(tab: tab);
  }

  Future<void> toggleLike(Post post) async {
    final String? uid = _authCubit.state.userId;
    if (uid == null) {
      return;
    }

    try {
      final bool nowLiked = await _repository.togglePostLike(postId: post.id, uid: uid);
      final List<Post> updatedPosts = state.posts
          .map((Post existing) {
            if (existing.id != post.id) {
              return existing;
            }
            final int nextCount = (existing.likeCount + (nowLiked ? 1 : -1)).clamp(0, 1 << 31).toInt();
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

  @override
  Future<void> close() async {
    await _authSubscription.cancel();
    return super.close();
  }

  void _handleAuthChanged(AuthState authState) {
    final bool serialChanged = authState.serial != state.serial;
    final bool trackChanged = authState.careerTrack != state.careerTrack;

    if (serialChanged || trackChanged) {
      emit(state.copyWith(careerTrack: authState.careerTrack, serial: authState.serial));
      if (state.tab == CommunityFeedTab.serial && serialChanged) {
        unawaited(loadInitial(tab: CommunityFeedTab.serial));
      }
    }
  }

  Future<PaginatedQueryResult<Post>> _fetchPostsForTab(CommunityFeedTab tab, {required bool reset}) async {
    final String? uid = _authCubit.state.userId;
    final QueryDocumentSnapshotJson? startAfter = reset ? null : _cursors[tab];

    switch (tab) {
      case CommunityFeedTab.all:
        return _repository.fetchChirpFeed(limit: _pageSize, startAfter: startAfter, currentUid: uid);
      case CommunityFeedTab.serial:
        final String serial = _authCubit.state.serial;
        if (serial == 'unknown' || serial.isEmpty) {
          return const PaginatedQueryResult<Post>(items: <Post>[], lastDocument: null, hasMore: false);
        }
        return _repository.fetchSerialFeed(serial: serial, limit: _pageSize, startAfter: startAfter, currentUid: uid);
      case CommunityFeedTab.hot:
        return _repository.fetchHotFeed(limit: _pageSize, startAfter: startAfter, currentUid: uid);
    }
  }
}
