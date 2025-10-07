import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../profile/domain/career_track.dart';
import '../../../profile/domain/lounge_info.dart';
import '../../domain/services/lounge_access_service.dart';
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

  // 동기적 pending 상태 관리 (race condition 방지)
  final Set<String> _pendingLikePostIds = <String>{};

  // 차단된 사용자 목록 캐시
  Set<String> _blockedUserIds = <String>{};

  static const int _pageSize = 20;

  String _cursorKey(LoungeScope scope, LoungeSort sort) =>
      '${scope.name}_${sort.name}';

  bool get _shouldShowAds {
    return false;
  }

  Future<void> loadInitial({
    LoungeScope? scope,
    LoungeSort? sort,
    bool isSortChange = false,
    bool isLoungeChange = false,
  }) async {
    if (_isFetching) {
      return;
    }

    _isFetching = true;
    final LoungeScope targetScope = scope ?? state.scope;
    final LoungeSort targetSort = sort ?? state.sort;

    // 상태 결정: sorting/lounging/loading
    final CommunityFeedStatus newStatus;
    if (isSortChange) {
      newStatus = CommunityFeedStatus.sorting;
    } else if (isLoungeChange) {
      newStatus = CommunityFeedStatus.lounging;
    } else {
      newStatus = CommunityFeedStatus.loading;
    }

    emit(
      state.copyWith(
        status: newStatus,
        scope: targetScope,
        sort: targetSort,
        errorMessage: null,
        careerTrack: _authCubit.state.careerTrack,
        serial: _authCubit.state.serial,
        // sorting 중에는 기존 posts 유지 (posts 파라미터 전달하지 않음)
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
      final Set<String> scrapped = result.items
          .where((Post post) => post.isScrapped)
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
          scrappedPostIds: scrapped,
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
      final Set<String> scrapped = result.items
          .where((Post post) => post.isScrapped)
          .map((Post post) => post.id)
          .toSet();
      emit(
        state.copyWith(
          status: CommunityFeedStatus.loaded,
          posts: result.items,
          hasMore: result.hasMore,
          isLoadingMore: false,
          likedPostIds: liked,
          scrappedPostIds: scrapped,
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
      final Set<String> scrapped = Set<String>.from(state.scrappedPostIds)
        ..addAll(
          result.items
              .where((Post post) => post.isScrapped)
              .map((Post post) => post.id),
        );

      emit(
        state.copyWith(
          posts: combined,
          hasMore: result.hasMore,
          isLoadingMore: false,
          likedPostIds: liked,
          scrappedPostIds: scrapped,
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

  /// 라운지 선택 변경
  Future<void> changeLounge(LoungeInfo loungeInfo) async {
    final LoungeScope newScope = LoungeScope(loungeInfo.id);
    if (state.scope == newScope && state.status == CommunityFeedStatus.loaded) {
      // 메뉴만 닫기
      closeLoungeMenu();
      return;
    }

    // 라운지 전환 상태로 변경 (기존 posts 유지하면서 fade + skeleton 효과)
    emit(
      state.copyWith(
        selectedLoungeInfo: loungeInfo,
        isLoungeMenuOpen: false, // 라운지 변경 시 메뉴 닫기
        status: CommunityFeedStatus.lounging,
        scope: newScope,
        // posts는 유지 (파라미터 전달하지 않음)
      ),
    );
    await loadInitial(scope: newScope, isLoungeChange: true);
  }

  /// 라운지 메뉴 토글
  void toggleLoungeMenu() {
    emit(state.copyWith(isLoungeMenuOpen: !state.isLoungeMenuOpen));
  }

  /// 라운지 메뉴 열기
  void openLoungeMenu() {
    if (!state.isLoungeMenuOpen) {
      emit(state.copyWith(isLoungeMenuOpen: true));
    }
  }

  /// 라운지 메뉴 닫기
  void closeLoungeMenu() {
    if (state.isLoungeMenuOpen) {
      emit(state.copyWith(isLoungeMenuOpen: false));
    }
  }

  Future<void> changeSort(LoungeSort sort) async {
    if (state.sort == sort && state.status == CommunityFeedStatus.loaded) {
      return;
    }
    await loadInitial(sort: sort, isSortChange: true);
  }

  Future<void> toggleLike(Post post) async {
    final String? uid = _authCubit.state.userId;
    if (uid == null) {
      return;
    }

    // 동기적 체크: 클래스 레벨 변수로 race condition 방지
    if (_pendingLikePostIds.contains(post.id)) {
      debugPrint('⚠️  이미 처리 중인 좋아요 요청 - PostId: ${post.id}');
      return;
    }

    // 즉시 pending에 추가 (동기적)
    _pendingLikePostIds.add(post.id);

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
    final Set<String> pendingLikes = Set<String>.from(state.pendingLikePostIds)
      ..add(post.id);
    emit(
      state.copyWith(
        posts: optimisticPosts,
        likedPostIds: optimisticLiked,
        pendingLikePostIds: pendingLikes,
      ),
    );

    bool success = false;
    Object? lastError;

    // 한 번만 시도 (Firestore 트랜잭션이 자동으로 재시도 처리)
    try {
      await _repository.togglePostLike(postId: post.id, uid: uid);
      success = true;
    } catch (e, stackTrace) {
      lastError = e;
      debugPrint('❌ 좋아요 처리 실패 - PostId: ${post.id}');
      debugPrint('   에러: $e');
      debugPrint('   스택: $stackTrace');
    }

    // pending 상태에서 제거 (동기적)
    _pendingLikePostIds.remove(post.id);

    final Set<String> finalPendingLikes = Set<String>.from(
      state.pendingLikePostIds,
    )..remove(post.id);

    if (!success && lastError != null) {
      // 실패 시 이전 상태로 복원
      emit(
        state.copyWith(
          posts: previousPosts,
          likedPostIds: previousLiked,
          pendingLikePostIds: finalPendingLikes,
          errorMessage: '좋아요 처리 중 오류가 발생했습니다.',
        ),
      );
    } else if (success) {
      // 성공 시 pending 상태만 업데이트 (이미 optimistic update 완료)
      emit(state.copyWith(pendingLikePostIds: finalPendingLikes));
    }
  }

  Future<void> toggleScrap(Post post) async {
    final String? uid = _authCubit.state.userId;
    if (uid == null) {
      return;
    }

    try {
      await _repository.toggleScrap(uid: uid, postId: post.id);
      final bool nowScrapped = !state.scrappedPostIds.contains(post.id);
      final List<Post> updatedPosts = state.posts
          .map((Post existing) {
            if (existing.id != post.id) {
              return existing;
            }
            return existing.copyWith(isScrapped: nowScrapped);
          })
          .toList(growable: false);

      final Set<String> scrapped = Set<String>.from(state.scrappedPostIds);
      if (nowScrapped) {
        scrapped.add(post.id);
      } else {
        scrapped.remove(post.id);
      }

      emit(state.copyWith(posts: updatedPosts, scrappedPostIds: scrapped));
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

    // 접근 가능한 라운지 업데이트
    List<LoungeInfo> accessibleLounges = [];
    LoungeInfo? selectedLoungeInfo;

    if (authState.careerHierarchy != null) {
      try {
        accessibleLounges = LoungeAccessService.convertToLoungeInfos(
          authState.careerHierarchy!,
        );
      } catch (e) {
        accessibleLounges = [];
      }

      // 현재 선택된 라운지 정보 찾기
      if (accessibleLounges.isNotEmpty) {
        // 기존 선택된 라운지가 여전히 접근 가능한지 확인
        selectedLoungeInfo = accessibleLounges.firstWhere(
          (lounge) => lounge.id == state.scope.loungeId,
          orElse: () => accessibleLounges.first, // 접근 불가능하면 첫 번째 라운지로
        );
      }
    } else {
      // 계층 정보가 없으면 전체 라운지만 접근 가능
      accessibleLounges = [
        const LoungeInfo(
          id: 'all',
          name: '전체',
          emoji: '🏛️',
          shortName: '전체',
          memberCount: 1000000,
          description: '모든 공무원이 참여하는 라운지',
        ),
      ];
      selectedLoungeInfo = accessibleLounges.first;
    }

    final bool loungeAccessChanged =
        accessibleLounges != state.accessibleLounges;

    if (serialChanged ||
        trackChanged ||
        supporterChanged ||
        loungeAccessChanged) {
      emit(
        state.copyWith(
          careerTrack: authState.careerTrack,
          serial: authState.serial,
          showAds: _shouldShowAds,
          accessibleLounges: accessibleLounges,
          selectedLoungeInfo: selectedLoungeInfo,
          scope: selectedLoungeInfo != null
              ? LoungeScope(selectedLoungeInfo.id)
              : state.scope,
        ),
      );

      // 라운지 접근 권한이 변경되었거나 시리얼 탭이 더 이상 사용 불가능한 경우 새로고침
      if (loungeAccessChanged) {
        unawaited(loadInitial());
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

    // 전체 라운지가 아닌 경우, 접근 권한 확인
    if (scope.loungeId != 'all') {
      final bool hasAccess = state.accessibleLounges.any(
        (lounge) => lounge.id == scope.loungeId,
      );
      if (!hasAccess) {
        return const PaginatedQueryResult<Post>(
          items: <Post>[],
          lastDocument: null,
          hasMore: false,
        );
      }
    }

    // 차단 목록 로드 (캐시 갱신)
    await _loadBlockedUsers();

    final result = await _repository.fetchLoungeFeed(
      scope: scope,
      sort: sort,
      limit: _pageSize,
      startAfter: startAfter,
      serial: scope.loungeId != 'all' ? scope.loungeId : null,
      currentUid: uid,
    );

    // 차단된 사용자 필터링
    final filteredPosts = result.items
        .where((post) => !_blockedUserIds.contains(post.authorUid))
        .toList();

    return PaginatedQueryResult<Post>(
      items: filteredPosts,
      hasMore: result.hasMore,
      lastDocument: result.lastDocument,
    );
  }

  /// 차단된 사용자 목록 로드
  Future<void> _loadBlockedUsers() async {
    final String? uid = _authCubit.state.userId;
    if (uid == null) {
      _blockedUserIds = <String>{};
      return;
    }

    try {
      _blockedUserIds = await _repository.getBlockedUserIds(uid);
    } catch (e) {
      debugPrint('Failed to load blocked users: $e');
      // 실패해도 계속 진행 (차단 필터링 없이)
      _blockedUserIds = <String>{};
    }
  }

  /// 사용자 차단 후 피드 새로고침
  Future<void> refreshAfterBlock() async {
    await _loadBlockedUsers();
    await refresh();
  }
}
