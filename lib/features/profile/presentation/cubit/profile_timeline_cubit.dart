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
  List<Object?> get props => <Object?>[
    status,
    posts,
    hasMore,
    isLoadingMore,
    errorMessage,
  ];
}

class ProfileTimelineCubit extends Cubit<ProfileTimelineState> {
  ProfileTimelineCubit({
    required CommunityRepository repository,
    required AuthCubit authCubit,
  }) : _repository = repository,
       _authCubit = authCubit,
       super(const ProfileTimelineState()) {
    _authSubscription = _authCubit.stream.listen(_handleAuthChanged);
  }

  final CommunityRepository _repository;
  final AuthCubit _authCubit;
  late final StreamSubscription<AuthState> _authSubscription;
  QueryDocumentSnapshotJson? _cursor;
  bool _isFetching = false;
  static const int _pageSize = 20;

  Future<void> loadInitial() async {
    if (_isFetching) {
      return;
    }

    final String? uid = _authCubit.state.userId;
    if (uid == null) {
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
      final PaginatedQueryResult<Post> result = await _repository
          .fetchPostsByAuthor(
            authorUid: uid,
            currentUid: uid,
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

    final String? uid = _authCubit.state.userId;
    if (uid == null) {
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
      final PaginatedQueryResult<Post> result = await _repository
          .fetchPostsByAuthor(
            authorUid: uid,
            currentUid: uid,
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
          errorMessage: '타임라인 새로고침에 실패했습니다.',
        ),
      );
    } finally {
      _isFetching = false;
    }
  }

  Future<void> loadMore() async {
    if (_isFetching || !state.hasMore || state.isLoadingMore) {
      return;
    }

    final String? uid = _authCubit.state.userId;
    if (uid == null) {
      return;
    }

    _isFetching = true;
    emit(state.copyWith(isLoadingMore: true));

    try {
      final PaginatedQueryResult<Post> result = await _repository
          .fetchPostsByAuthor(
            authorUid: uid,
            currentUid: uid,
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
    if (!authState.isLoggedIn) {
      _cursor = null;
      emit(const ProfileTimelineState());
    }
  }

  @override
  Future<void> close() async {
    await _authSubscription.cancel();
    return super.close();
  }
}
