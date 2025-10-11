import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../data/follow_repository.dart' show FollowRepository;
import '../../domain/user_profile.dart';
import '../../../../core/firebase/paginated_query.dart';

enum ProfileRelationsStatus { initial, loading, loaded, refreshing, error }

enum ProfileRelationType { followers, following }

class ProfileRelationsState extends Equatable {
  const ProfileRelationsState({
    this.status = ProfileRelationsStatus.initial,
    this.type = ProfileRelationType.followers,
    this.users = const <UserProfile>[],
    this.hasMore = false,
    this.isLoadingMore = false,
    this.errorMessage,
  });

  final ProfileRelationsStatus status;
  final ProfileRelationType type;
  final List<UserProfile> users;
  final bool hasMore;
  final bool isLoadingMore;
  final String? errorMessage;

  ProfileRelationsState copyWith({
    ProfileRelationsStatus? status,
    ProfileRelationType? type,
    List<UserProfile>? users,
    bool? hasMore,
    bool? isLoadingMore,
    String? errorMessage,
  }) {
    return ProfileRelationsState(
      status: status ?? this.status,
      type: type ?? this.type,
      users: users ?? this.users,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    status,
    type,
    users,
    hasMore,
    isLoadingMore,
    errorMessage,
  ];
}

class ProfileRelationsCubit extends Cubit<ProfileRelationsState> {
  ProfileRelationsCubit({
    required FollowRepository followRepository,
    required AuthCubit authCubit,
  }) : _followRepository = followRepository,
       _authCubit = authCubit,
       super(const ProfileRelationsState()) {
    _authSubscription = _authCubit.stream.listen(_handleAuthChanged);
  }

  final FollowRepository _followRepository;
  final AuthCubit _authCubit;
  late final StreamSubscription<AuthState> _authSubscription;
  QueryDocumentSnapshotJson? _cursor;
  bool _isFetching = false;
  ProfileRelationType _currentType = ProfileRelationType.followers;
  String? _targetUid; // Track which user's relations we're viewing
  static const int _pageSize = 20;

  Future<void> load(ProfileRelationType type, {String? targetUid}) async {
    if (_isFetching) {
      return;
    }
    _currentType = type;
    _cursor = null;

    // Use targetUid if provided, otherwise use current user's uid
    final String? uid = targetUid ?? _authCubit.state.userId;
    if (uid == null) {
      emit(
        state.copyWith(
          status: ProfileRelationsStatus.error,
          type: type,
          errorMessage: '로그인이 필요합니다.',
          users: const <UserProfile>[],
          hasMore: false,
          isLoadingMore: false,
        ),
      );
      return;
    }

    _targetUid = uid; // Store target uid for pagination
    _isFetching = true;
    emit(
      state.copyWith(
        status: ProfileRelationsStatus.loading,
        type: type,
        isLoadingMore: false,
        hasMore: false,
        errorMessage: null,
      ),
    );

    try {
      final PaginatedQueryResult<UserProfile> result = await _fetchByType(
        uid: uid,
        type: type,
        startAfter: null,
      );
      _cursor = result.lastDocument;
      emit(
        state.copyWith(
          status: ProfileRelationsStatus.loaded,
          type: type,
          users: result.items,
          hasMore: result.hasMore,
          isLoadingMore: false,
          errorMessage: null,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: ProfileRelationsStatus.error,
          type: type,
          errorMessage: '목록을 불러오지 못했습니다.',
          users: const <UserProfile>[],
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

    // Use stored target uid for refresh
    final String? uid = _targetUid ?? _authCubit.state.userId;
    if (uid == null) {
      emit(
        state.copyWith(
          status: ProfileRelationsStatus.error,
          errorMessage: '로그인이 필요합니다.',
          users: const <UserProfile>[],
          hasMore: false,
          isLoadingMore: false,
        ),
      );
      return;
    }

    _isFetching = true;
    emit(state.copyWith(status: ProfileRelationsStatus.refreshing));

    try {
      final PaginatedQueryResult<UserProfile> result = await _fetchByType(
        uid: uid,
        type: _currentType,
        startAfter: null,
      );
      _cursor = result.lastDocument;
      emit(
        state.copyWith(
          status: ProfileRelationsStatus.loaded,
          users: result.items,
          hasMore: result.hasMore,
          isLoadingMore: false,
          errorMessage: null,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: ProfileRelationsStatus.error,
          errorMessage: '목록 새로고침에 실패했습니다.',
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

    // Use stored target uid for loadMore
    final String? uid = _targetUid ?? _authCubit.state.userId;
    if (uid == null) {
      return;
    }

    _isFetching = true;
    emit(state.copyWith(isLoadingMore: true));

    try {
      final PaginatedQueryResult<UserProfile> result = await _fetchByType(
        uid: uid,
        type: _currentType,
        startAfter: _cursor,
      );
      _cursor = result.lastDocument;
      emit(
        state.copyWith(
          status: ProfileRelationsStatus.loaded,
          users: List<UserProfile>.from(state.users)..addAll(result.items),
          hasMore: result.hasMore,
          isLoadingMore: false,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          isLoadingMore: false,
          status: ProfileRelationsStatus.error,
          errorMessage: '추가 목록을 불러오지 못했습니다.',
        ),
      );
    } finally {
      _isFetching = false;
    }
  }

  Future<void> unfollow(String targetUid) async {
    final String? uid = _authCubit.state.userId;
    if (uid == null) {
      return;
    }

    try {
      await _followRepository.unfollow(followerUid: uid, targetUid: targetUid);
      await refresh();
    } catch (_) {
      emit(
        state.copyWith(
          status: ProfileRelationsStatus.error,
          errorMessage: '언팔로우 처리에 실패했습니다.',
        ),
      );
    }
  }

  Future<PaginatedQueryResult<UserProfile>> _fetchByType({
    required String uid,
    required ProfileRelationType type,
    QueryDocumentSnapshotJson? startAfter,
  }) {
    switch (type) {
      case ProfileRelationType.followers:
        return _followRepository.fetchFollowers(
          uid: uid,
          limit: _pageSize,
          startAfter: startAfter,
        );
      case ProfileRelationType.following:
        return _followRepository.fetchFollowing(
          uid: uid,
          limit: _pageSize,
          startAfter: startAfter,
        );
    }
  }

  void _handleAuthChanged(AuthState authState) {
    if (!authState.isLoggedIn) {
      _cursor = null;
      emit(const ProfileRelationsState());
    }
  }

  @override
  Future<void> close() async {
    await _authSubscription.cancel();
    return super.close();
  }
}
