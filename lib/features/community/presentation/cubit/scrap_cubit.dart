import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/community_repository.dart';
import '../../domain/models/post.dart';

part 'scrap_state.dart';

class ScrapCubit extends Cubit<ScrapState> {
  ScrapCubit(this._repository) : super(const ScrapState()) {
    debugPrint('🆕 ScrapCubit created - hashCode: $hashCode');
  }

  final CommunityRepository _repository;
  static const int _pageSize = 20;

  // Undo state
  Timer? _undoTimer;
  Post? _pendingRemovalPost;
  int? _pendingRemovalIndex;

  Future<void> loadInitial() async {
    debugPrint('📥 ScrapCubit(hashCode: $hashCode).loadInitial called');
    emit(state.copyWith(isLoading: true));

    try {
      final result = await _repository.fetchScrappedPosts(
        uid: _repository.currentUserId,
        limit: _pageSize,
      );

      emit(state.copyWith(isLoading: false, scraps: result.items, hasMore: result.hasMore));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: '스크랩을 불러오는 중 오류가 발생했습니다.'));
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading) return;

    emit(state.copyWith(isLoading: true));

    try {
      // In a real implementation, you'd use pagination with startAfter
      // For now, we'll just return empty to indicate no more results
      final moreScraps = <Post>[];

      emit(
        state.copyWith(
          isLoading: false,
          scraps: [...state.scraps, ...moreScraps],
          hasMore: moreScraps.length == _pageSize,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: '추가 스크랩을 불러오는 중 오류가 발생했습니다.'));
    }
  }

  Future<void> refresh() async {
    // Clear cache to fetch fresh data from Firestore
    _repository.clearInteractionCache(uid: _repository.currentUserId);
    await loadInitial();
  }

  Future<void> toggleLike(Post post) async {
    final scraps = List<Post>.from(state.scraps);
    final index = scraps.indexWhere((p) => p.id == post.id);

    if (index == -1) return;

    final updatedPost = post.copyWith(
      isLiked: !post.isLiked,
      likeCount: post.isLiked ? post.likeCount - 1 : post.likeCount + 1,
    );

    scraps[index] = updatedPost;
    emit(state.copyWith(scraps: scraps));

    try {
      await _repository.toggleLike(post.id);
    } catch (e) {
      // Revert on error
      scraps[index] = post;
      emit(state.copyWith(scraps: scraps));
    }
  }

  Future<void> removeScrap(Post post) async {
    debugPrint('🔵 ScrapCubit(hashCode: $hashCode).removeScrap called for post ${post.id}');
    final scraps = List<Post>.from(state.scraps);
    final index = scraps.indexWhere((p) => p.id == post.id);

    if (index == -1) {
      debugPrint('⚠️ ScrapCubit: Post ${post.id} not found in scraps list');
      return;
    }

    // Cancel any existing undo timer
    _undoTimer?.cancel();

    // Store for undo
    _pendingRemovalPost = post;
    _pendingRemovalIndex = index;

    // Optimistically remove from UI
    scraps.removeAt(index);

    final newTime = DateTime.now();
    debugPrint('🗑️ ScrapCubit: Removing scrap for post ${post.id} at $newTime');
    debugPrint(
      '🔍 Before emit - current state: scraps.length=${state.scraps.length}, lastUndoTime=${state.lastUndoNotificationTime}',
    );

    final newState = state.copyWith(scraps: scraps, lastUndoNotificationTime: newTime);

    debugPrint(
      '🔍 New state: scraps.length=${newState.scraps.length}, lastUndoTime=${newState.lastUndoNotificationTime}',
    );
    debugPrint('🔍 States equal? ${state == newState}');

    emit(newState);

    debugPrint(
      '🔍 After emit - current state: scraps.length=${state.scraps.length}, lastUndoTime=${state.lastUndoNotificationTime}',
    );

    // Set timer to actually remove after 5 seconds
    _undoTimer = Timer(const Duration(seconds: 5), () async {
      if (_pendingRemovalPost != null) {
        try {
          await _repository.togglePostScrap(_pendingRemovalPost!.id);
          debugPrint('✅ ScrapCubit: Scrap removal confirmed for ${_pendingRemovalPost!.id}');
          _pendingRemovalPost = null;
          _pendingRemovalIndex = null;
        } catch (e) {
          // Revert on error
          debugPrint('❌ ScrapCubit: Scrap removal failed, reverting: $e');
          final currentScraps = List<Post>.from(state.scraps);
          if (_pendingRemovalIndex != null && _pendingRemovalPost != null) {
            currentScraps.insert(_pendingRemovalIndex!, _pendingRemovalPost!);
            emit(state.copyWith(scraps: currentScraps));
          }
          _pendingRemovalPost = null;
          _pendingRemovalIndex = null;
        }
      }
    });
  }

  Future<void> undoRemoveScrap() async {
    // Cancel the timer
    _undoTimer?.cancel();

    // Restore the post
    if (_pendingRemovalPost != null && _pendingRemovalIndex != null) {
      debugPrint('↩️ ScrapCubit: Restoring post ${_pendingRemovalPost!.id}');
      final scraps = List<Post>.from(state.scraps);
      scraps.insert(_pendingRemovalIndex!, _pendingRemovalPost!);
      emit(state.copyWith(scraps: scraps));

      _pendingRemovalPost = null;
      _pendingRemovalIndex = null;
    }
  }

  Future<void> clearAll() async {
    final originalScraps = List<Post>.from(state.scraps);

    // Optimistically clear
    emit(state.copyWith(scraps: []));

    try {
      // Clear all scraps for current user
      await Future.wait(
        originalScraps.map(
          (Post post) => _repository.toggleScrap(uid: _repository.currentUserId, postId: post.id),
        ),
      );
    } catch (e) {
      // Revert on error
      emit(state.copyWith(scraps: originalScraps, error: '스크랩 삭제 중 오류가 발생했습니다.'));
    }
  }

  @override
  Future<void> close() {
    _undoTimer?.cancel();
    return super.close();
  }
}
