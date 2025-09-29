import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../profile/domain/career_track.dart';
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
    return false;
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

    // 이미 처리 중인 좋아요 요청인지 확인
    if (state.pendingLikePostIds.contains(post.id)) {
      debugPrint('⚠️  이미 처리 중인 좋아요 요청 - PostId: ${post.id}');
      return;
    }

    final List<Post> previousPosts = List<Post>.from(state.posts);
    final Set<String> previousLiked = Set<String>.from(state.likedPostIds);
    final bool willLike = !previousLiked.contains(post.id);

    final List<Post> optimisticPosts = previousPosts
        .map((Post existing) {
          if (existing.id != post.id) {
            return existing;
          }
          final int delta = willLike ? 1 : -1;
          final int nextCount = (existing.likeCount + delta).clamp(0, 1 << 31);
          return existing.copyWith(likeCount: nextCount, isLiked: willLike);
        })
        .toList(growable: false);

    final Set<String> optimisticLiked = Set<String>.from(previousLiked);
    if (willLike) {
      optimisticLiked.add(post.id);
    } else {
      optimisticLiked.remove(post.id);
    }

    // 좋아요 처리 시작을 UI에 알림
    final Set<String> pendingLikes = Set<String>.from(state.pendingLikePostIds)..add(post.id);
    emit(state.copyWith(
      posts: optimisticPosts,
      likedPostIds: optimisticLiked,
      pendingLikePostIds: pendingLikes,
    ));

    bool success = false;
    Object? lastError;
    StackTrace? lastStackTrace;

    // 재시도 로직 (최대 3회)
    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        await _repository.togglePostLike(postId: post.id, uid: uid);
        success = true;
        break; // 성공 시 루프 종료
      } catch (e, stackTrace) {
        lastError = e;
        lastStackTrace = stackTrace;

        final String errorType = _classifyError(e);

        // 재시도 가능한 에러인지 확인
        final bool shouldRetry = _shouldRetryError(errorType) && attempt < 3;

        debugPrint('❌ 좋아요 처리 실패 (시도 $attempt/3) - PostId: ${post.id}, UserId: $uid');
        debugPrint('   에러 타입: $errorType');
        debugPrint('   에러 내용: $e');

        if (shouldRetry) {
          debugPrint('   🔄 ${_getRetryDelay(attempt)}ms 후 재시도...');
          await Future.delayed(Duration(milliseconds: _getRetryDelay(attempt)));
        } else {
          debugPrint('   ❌ 재시도 불가능한 에러이거나 최대 시도 횟수 도달');
          break;
        }
      }
    }

    // pending 상태에서 제거
    final Set<String> finalPendingLikes = Set<String>.from(state.pendingLikePostIds)..remove(post.id);

    if (!success && lastError != null) {
      // 모든 재시도가 실패한 경우
      final String userMessage = _getUserFriendlyErrorMessage(lastError);

      debugPrint('   스택 트레이스: $lastStackTrace');

      // 실패 시 이전 상태로 복원하고 사용자에게 알림
      emit(
        state.copyWith(
          posts: previousPosts,
          likedPostIds: previousLiked,
          pendingLikePostIds: finalPendingLikes,
          errorMessage: userMessage,
        ),
      );
    } else if (success) {
      debugPrint('✅ 좋아요 처리 성공 - PostId: ${post.id}, UserId: $uid');
      // 성공 시 pending 상태만 업데이트 (이미 optimistic update 완료)
      emit(state.copyWith(pendingLikePostIds: finalPendingLikes));
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

  /// 에러 타입을 분류하여 문자열로 반환
  String _classifyError(Object error) {
    final String errorString = error.toString().toLowerCase();

    if (errorString.contains('network') ||
        errorString.contains('socket') ||
        errorString.contains('connection') ||
        errorString.contains('timeout')) {
      return 'NETWORK_ERROR';
    }

    if (errorString.contains('permission') ||
        errorString.contains('unauthorized') ||
        errorString.contains('auth') ||
        errorString.contains('forbidden')) {
      return 'PERMISSION_ERROR';
    }

    if (errorString.contains('not found') ||
        errorString.contains('게시글을 찾을 수 없습니다')) {
      return 'POST_NOT_FOUND';
    }

    if (errorString.contains('firestore') ||
        errorString.contains('database') ||
        errorString.contains('transaction')) {
      return 'DATABASE_ERROR';
    }

    return 'UNKNOWN_ERROR';
  }

  /// 사용자에게 친화적인 에러 메시지 생성
  String _getUserFriendlyErrorMessage(Object error) {
    final String errorType = _classifyError(error);

    switch (errorType) {
      case 'NETWORK_ERROR':
        return '네트워크 연결을 확인한 후 다시 시도해주세요.';
      case 'PERMISSION_ERROR':
        return '권한이 없습니다. 로그인 상태를 확인해주세요.';
      case 'POST_NOT_FOUND':
        return '게시글을 찾을 수 없습니다. 새로고침 후 다시 시도해주세요.';
      case 'DATABASE_ERROR':
        return '서버에 일시적인 문제가 있습니다. 잠시 후 다시 시도해주세요.';
      default:
        return '좋아요 처리 중 오류가 발생했습니다. 다시 시도해주세요.';
    }
  }

  /// 에러 타입에 따라 재시도 가능 여부 판단
  bool _shouldRetryError(String errorType) {
    switch (errorType) {
      case 'NETWORK_ERROR':
      case 'DATABASE_ERROR':
        return true; // 네트워크나 데이터베이스 오류는 재시도 가능
      case 'PERMISSION_ERROR':
      case 'POST_NOT_FOUND':
        return false; // 권한이나 데이터 누락 오류는 재시도 불가
      default:
        return false; // 알 수 없는 에러는 재시도하지 않음
    }
  }

  /// 재시도 딜레이 계산 (Exponential backoff)
  int _getRetryDelay(int attempt) {
    // 1초, 2초, 4초 순으로 증가
    return (1000 * (1 << (attempt - 1))).clamp(1000, 4000);
  }
}
