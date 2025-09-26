part of 'matching_cubit.dart';

enum MatchingStatus { initial, loading, loaded, error, locked }

class MatchingState extends Equatable {
  const MatchingState({
    this.status = MatchingStatus.initial,
    this.candidates = const <CuratedMatch>[],
    this.actionInProgressId,
    this.lastActionMessage,
  });

  final MatchingStatus status;
  final List<CuratedMatch> candidates;
  final String? actionInProgressId;
  final String? lastActionMessage;

  static const Object _unset = Object();

  MatchingState copyWith({
    MatchingStatus? status,
    List<CuratedMatch>? candidates,
    Object? actionInProgressId = _unset,
    Object? lastActionMessage = _unset,
  }) {
    return MatchingState(
      status: status ?? this.status,
      candidates: candidates ?? this.candidates,
      actionInProgressId: actionInProgressId == _unset
          ? this.actionInProgressId
          : actionInProgressId as String?,
      lastActionMessage: lastActionMessage == _unset
          ? this.lastActionMessage
          : lastActionMessage as String?,
    );
  }

  @override
  List<Object?> get props => [
    status,
    candidates,
    actionInProgressId,
    lastActionMessage,
  ];
}
