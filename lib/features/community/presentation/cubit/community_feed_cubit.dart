import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../profile/domain/career_track.dart';
import '../../data/community_repository.dart';
import '../../domain/entities/community_post.dart';

part 'community_feed_state.dart';

class CommunityFeedCubit extends Cubit<CommunityFeedState> {
  CommunityFeedCubit({
    required CommunityRepository repository,
    required AuthCubit authCubit,
  }) : _repository = repository,
       _authCubit = authCubit,
       super(const CommunityFeedState()) {
    _authSubscription = _authCubit.stream.listen((authState) {
      if (state.scope == CommunityFeedScope.myTrack) {
        _applyFilter(authState.careerTrack);
      }
    });
  }

  final CommunityRepository _repository;
  final AuthCubit _authCubit;
  late final StreamSubscription<AuthState> _authSubscription;
  List<CommunityPost> _allPosts = const <CommunityPost>[];

  Future<void> loadInitial() async {
    emit(state.copyWith(status: CommunityFeedStatus.loading));
    try {
      _allPosts = await _repository.fetchPosts();
      _applyFilter(
        _authCubit.state.careerTrack,
        status: CommunityFeedStatus.loaded,
      );
    } catch (_) {
      emit(state.copyWith(status: CommunityFeedStatus.error));
    }
  }

  Future<void> refresh() async {
    try {
      _allPosts = await _repository.fetchPosts();
      _applyFilter(_authCubit.state.careerTrack);
    } catch (_) {
      emit(state.copyWith(status: CommunityFeedStatus.error));
    }
  }

  void changeScope(CommunityFeedScope scope) {
    emit(state.copyWith(scope: scope));
    _applyFilter(_authCubit.state.careerTrack);
  }

  void _applyFilter(CareerTrack track, {CommunityFeedStatus? status}) {
    final CommunityFeedStatus nextStatus = status ?? state.status;

    List<CommunityPost> filtered;
    switch (state.scope) {
      case CommunityFeedScope.all:
        filtered = List<CommunityPost>.from(_allPosts);
        break;
      case CommunityFeedScope.myTrack:
        if (track == CareerTrack.none) {
          filtered = const <CommunityPost>[];
        } else {
          filtered = _allPosts
              .where(
                (post) =>
                    post.audience == CommunityAudience.track &&
                    post.targetTrack == track,
              )
              .toList(growable: false);
        }
        break;
    }

    emit(
      state.copyWith(
        status: nextStatus,
        posts: filtered,
        currentTrack: track,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _authSubscription.cancel();
    return super.close();
  }
}
