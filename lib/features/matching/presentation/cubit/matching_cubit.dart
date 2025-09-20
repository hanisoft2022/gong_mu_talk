import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../profile/domain/career_track.dart';
import '../../data/matching_repository.dart';
import '../../domain/entities/match_profile.dart';

part 'matching_state.dart';

class MatchingCubit extends Cubit<MatchingState> {
  MatchingCubit({
    required MatchingRepository repository,
    required AuthCubit authCubit,
  }) : _repository = repository,
       _authCubit = authCubit,
       super(const MatchingState()) {
    _authSubscription = _authCubit.stream.listen((authState) {
      if (state.status == MatchingStatus.loaded) {
        _filterCandidates(authState.excludedTracks);
      }
    });
  }

  final MatchingRepository _repository;
  final AuthCubit _authCubit;
  late final StreamSubscription<AuthState> _authSubscription;
  List<MatchProfile> _allCandidates = const <MatchProfile>[];

  Future<void> loadCandidates() async {
    final AuthState authState = _authCubit.state;
    if (!authState.isGovernmentEmailVerified) {
      _allCandidates = const <MatchProfile>[];
      emit(
        state.copyWith(
          status: MatchingStatus.locked,
          candidates: const <MatchProfile>[],
          lastActionMessage: '공직자 이메일 인증을 완료하면 매칭을 이용할 수 있습니다.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(status: MatchingStatus.loading, lastActionMessage: null),
    );

    try {
      _allCandidates = await _repository.fetchCandidates(
        currentUserId: authState.userId ?? authState.email ?? 'anonymous',
      );
      _filterCandidates(
        authState.excludedTracks,
        status: MatchingStatus.loaded,
      );
    } catch (_) {
      emit(
        state.copyWith(status: MatchingStatus.error, lastActionMessage: null),
      );
    }
  }

  Future<void> refreshCandidates() async {
    await loadCandidates();
  }

  Future<void> requestMatch(String candidateId) async {
    if (state.status != MatchingStatus.loaded) {
      return;
    }

    emit(
      state.copyWith(actionInProgressId: candidateId, lastActionMessage: null),
    );
    try {
      final MatchRequestResult result = await _repository.requestMatch(
        candidateId,
      );
      emit(
        state.copyWith(
          lastActionMessage: result.message,
          actionInProgressId: null,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          lastActionMessage: '매칭 요청 중 오류가 발생했습니다. 잠시 후 다시 시도해주세요.',
          actionInProgressId: null,
        ),
      );
    }
  }

  void clearMessage() {
    emit(state.copyWith(lastActionMessage: null));
  }

  void _filterCandidates(Set<CareerTrack> excluded, {MatchingStatus? status}) {
    final List<MatchProfile> filtered = _allCandidates
        .where((profile) => !excluded.contains(profile.authorTrack))
        .toList(growable: false);

    emit(state.copyWith(candidates: filtered, status: status ?? state.status));
  }

  @override
  Future<void> close() async {
    await _authSubscription.cancel();
    return super.close();
  }
}
