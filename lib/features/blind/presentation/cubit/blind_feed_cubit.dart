import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/blind_repository.dart';
import '../../domain/entities/blind_post.dart';

part 'blind_feed_state.dart';

class BlindFeedCubit extends Cubit<BlindFeedState> {
  BlindFeedCubit({required BlindRepository repository})
    : _repository = repository,
      super(const BlindFeedState());

  final BlindRepository _repository;
  List<BlindPost> _allPosts = const <BlindPost>[];

  Future<void> loadInitial() async {
    emit(state.copyWith(status: BlindFeedStatus.loading));
    try {
      _allPosts = await _repository.fetchPosts();
      emit(
        state.copyWith(
          status: BlindFeedStatus.loaded,
          posts: _allPosts,
          departments: _extractDepartments(_allPosts),
        ),
      );
    } catch (_) {
      emit(state.copyWith(status: BlindFeedStatus.error));
    }
  }

  Future<void> refresh() async {
    try {
      _allPosts = await _repository.fetchPosts();
      _applyFilters();
      emit(state.copyWith(departments: _extractDepartments(_allPosts)));
    } catch (_) {
      emit(state.copyWith(status: BlindFeedStatus.error));
    }
  }

  void updateQuery(String query) {
    emit(state.copyWith(query: query));
    _applyFilters();
  }

  void selectDepartment(String? department) {
    emit(state.copyWith(selectedDepartment: department));
    _applyFilters();
  }

  void _applyFilters() {
    List<BlindPost> filtered = List<BlindPost>.from(_allPosts);

    if (state.selectedDepartment != null &&
        state.selectedDepartment!.isNotEmpty) {
      filtered = filtered
          .where((post) => post.department == state.selectedDepartment)
          .toList(growable: false);
    }

    if (state.query.isNotEmpty) {
      final String keyword = state.query.toLowerCase();
      filtered = filtered
          .where(
            (post) =>
                post.title.toLowerCase().contains(keyword) ||
                post.content.toLowerCase().contains(keyword),
          )
          .toList(growable: false);
    }

    emit(state.copyWith(status: BlindFeedStatus.loaded, posts: filtered));
  }

  List<String> _extractDepartments(List<BlindPost> posts) {
    final Set<String> departments = posts
        .map((post) => post.department)
        .where((dept) => dept.isNotEmpty)
        .toSet();
    return departments.toList(growable: false)..sort();
  }
}
