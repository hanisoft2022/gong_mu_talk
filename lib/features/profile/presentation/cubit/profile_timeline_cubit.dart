import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../community/data/community_repository.dart';
import '../../../community/domain/models/post.dart';
import '../../../../core/firebase/paginated_query.dart';

enum ProfileTimelineStatus { initial, loading, loaded, refreshing, error }

class ProfileTimelineState extends Equatable {
  const ProfileTimelineState({
    this.status = ProfileTimelineStatus.initial,
    this.posts = const <Post>[],
    this.hasMore = false,
    this.isLoadingMore = false,
    this.errorMessage,
  });

  final ProfileTimelineStatus status;
  final List<Post> posts;
  final bool hasMore;
  final bool isLoadingMore;
  final String? errorMessage;

  bool get isInitial => status == ProfileTimelineStatus.initial;

  ProfileTimelineState copyWith({
    ProfileTimelineStatus? status,
    List<Post>? posts,
    bool? hasMore,
    bool? isLoadingMore,
    String? errorMessage,
  }) {
    return ProfileTimelineState(
      status: status ?? this.status,
      posts: posts ?? this.posts,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[status, posts, hasMore, isLoadingMore, errorMessage];
}

class ProfileTimelineCubit extends Cubit<ProfileTimelineState> {
  ProfileTimelineCubit({
    required CommunityRepository repository,
    required AuthCubit authCubit,
    String? targetUserId,
  }) : _repository = repository,
       _authCubit = authCubit,
       _targetUserId = targetUserId,
       super(const ProfileTimelineState()) {
    _authSubscription = _authCubit.stream.listen(_handleAuthChanged);
  }

  final CommunityRepository _repository;
  final AuthCubit _authCubit;
  final String? _targetUserId;
  late final StreamSubscription<AuthState> _authSubscription;
  QueryDocumentSnapshotJson? _cursor;
  bool _isFetching = false;
  static const int _pageSize = 20;

  Future<void> loadInitial() async {
    if (_isFetching) {
      return;
    }

    final String? authorUid = _targetUserId ?? _authCubit.state.userId;
    if (authorUid == null) {
      emit(
        state.copyWith(
          status: ProfileTimelineStatus.error,
          errorMessage: '로그인이 필요합니다.',
          posts: const <Post>[],
          hasMore: false,
          isLoadingMore: false,
        ),
      );
      return;
    }

    _isFetching = true;
    emit(
      state.copyWith(
        status: ProfileTimelineStatus.loading,
        errorMessage: null,
        hasMore: false,
        isLoadingMore: false,
      ),
    );

    try {
      final PaginatedQueryResult<Post> result = await _repository.fetchPostsByAuthor(
        authorUid: authorUid,
        currentUid: _authCubit.state.userId,
        limit: _pageSize,
      );
      _cursor = result.lastDocument;
      emit(
        state.copyWith(
          status: ProfileTimelineStatus.loaded,
          posts: result.items,
          hasMore: result.hasMore,
          isLoadingMore: false,
          errorMessage: null,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: ProfileTimelineStatus.error,
          errorMessage: '타임라인을 불러오지 못했습니다.',
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

    final String? authorUid = _targetUserId ?? _authCubit.state.userId;
    if (authorUid == null) {
      emit(
        state.copyWith(
          status: ProfileTimelineStatus.error,
          errorMessage: '로그인이 필요합니다.',
          posts: const <Post>[],
          hasMore: false,
          isLoadingMore: false,
        ),
      );
      return;
    }

    _isFetching = true;
    emit(state.copyWith(status: ProfileTimelineStatus.refreshing));
    try {
      final PaginatedQueryResult<Post> result = await _repository.fetchPostsByAuthor(
        authorUid: authorUid,
        currentUid: _authCubit.state.userId,
        limit: _pageSize,
      );
      _cursor = result.lastDocument;
      emit(
        state.copyWith(
          status: ProfileTimelineStatus.loaded,
          posts: result.items,
          hasMore: result.hasMore,
          isLoadingMore: false,
          errorMessage: null,
        ),
      );
    } catch (_) {
      emit(state.copyWith(status: ProfileTimelineStatus.error, errorMessage: '타임라인 새로고침에 실패했습니다.'));
    } finally {
      _isFetching = false;
    }
  }

  Future<void> loadMore() async {
    if (_isFetching || !state.hasMore || state.isLoadingMore) {
      return;
    }

    final String? authorUid = _targetUserId ?? _authCubit.state.userId;
    if (authorUid == null) {
      return;
    }

    _isFetching = true;
    emit(state.copyWith(isLoadingMore: true));

    try {
      final PaginatedQueryResult<Post> result = await _repository.fetchPostsByAuthor(
        authorUid: authorUid,
        currentUid: _authCubit.state.userId,
        limit: _pageSize,
        startAfter: _cursor,
      );
      _cursor = result.lastDocument;
      emit(
        state.copyWith(
          status: ProfileTimelineStatus.loaded,
          posts: List<Post>.from(state.posts)..addAll(result.items),
          hasMore: result.hasMore,
          isLoadingMore: false,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          isLoadingMore: false,
          status: ProfileTimelineStatus.error,
          errorMessage: '추가 게시글을 불러오지 못했습니다.',
        ),
      );
    } finally {
      _isFetching = false;
    }
  }

  void _handleAuthChanged(AuthState authState) {
    if (_targetUserId == null && !authState.isLoggedIn) {
      _cursor = null;
      emit(const ProfileTimelineState());
    }
  }

  Future<void> toggleLike(Post post) async {
    final String? currentUid = _authCubit.state.userId;
    if (currentUid == null) {
      return;
    }

    try {
      final bool nowLiked = await _repository.togglePostLike(postId: post.id, uid: currentUid);
      final int delta = nowLiked ? 1 : -1;
      final List<Post> updated = state.posts
          .map(
            (Post existing) => existing.id == post.id
                ? existing.copyWith(
                    likeCount: (existing.likeCount + delta).clamp(0, 1 << 31).toInt(),
                    isLiked: nowLiked,
                  )
                : existing,
          )
          .toList(growable: false);
      emit(state.copyWith(posts: updated));
    } catch (_) {
      // Swallow errors silently; UI will remain unchanged.
    }
  }

  Future<void> toggleScrap(Post post) async {
    final String? currentUid = _authCubit.state.userId;
    if (currentUid == null) {
      return;
    }

    try {
      await _repository.toggleScrap(uid: currentUid, postId: post.id);
      final bool nowScrapped = !post.isScrapped;
      final List<Post> updated = state.posts
          .map(
            (Post existing) =>
                existing.id == post.id ? existing.copyWith(isScrapped: nowScrapped) : existing,
          )
          .toList(growable: false);
      emit(state.copyWith(posts: updated));
    } catch (_) {
      // Ignore errors for now.
    }
  }

  @override
  Future<void> close() async {
    await _authSubscription.cancel();
    return super.close();
  }
}
