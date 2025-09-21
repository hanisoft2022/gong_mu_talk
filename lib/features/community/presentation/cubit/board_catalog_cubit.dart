import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/community_repository.dart';
import '../../domain/models/board.dart';

enum BoardCatalogStatus { initial, loading, loaded, error }

class BoardCatalogState extends Equatable {
  const BoardCatalogState({
    this.status = BoardCatalogStatus.initial,
    this.boards = const <Board>[],
    this.errorMessage,
  });

  final BoardCatalogStatus status;
  final List<Board> boards;
  final String? errorMessage;

  BoardCatalogState copyWith({
    BoardCatalogStatus? status,
    List<Board>? boards,
    String? errorMessage,
  }) {
    return BoardCatalogState(
      status: status ?? this.status,
      boards: boards ?? this.boards,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[status, boards, errorMessage];
}

class BoardCatalogCubit extends Cubit<BoardCatalogState> {
  BoardCatalogCubit({required CommunityRepository repository})
    : _repository = repository,
      super(const BoardCatalogState());

  final CommunityRepository _repository;
  Completer<void>? _activeRequest;

  Future<void> loadBoards() async {
    if (_activeRequest != null && !_activeRequest!.isCompleted) {
      return;
    }
    emit(state.copyWith(status: BoardCatalogStatus.loading, errorMessage: null));
    _activeRequest = Completer<void>();
    try {
      final List<Board> boards = await _repository.fetchBoards();
      emit(state.copyWith(status: BoardCatalogStatus.loaded, boards: boards, errorMessage: null));
    } catch (_) {
      emit(state.copyWith(status: BoardCatalogStatus.error, errorMessage: '게시판 목록을 불러오지 못했습니다.'));
    } finally {
      _activeRequest?.complete();
    }
  }
}
