part of 'blind_feed_cubit.dart';

enum BlindFeedStatus { initial, loading, loaded, error }

class BlindFeedState extends Equatable {
  const BlindFeedState({
    this.status = BlindFeedStatus.initial,
    this.posts = const <BlindPost>[],
    this.query = '',
    this.selectedDepartment,
    this.departments = const <String>[],
  });

  final BlindFeedStatus status;
  final List<BlindPost> posts;
  final String query;
  final String? selectedDepartment;
  final List<String> departments;

  BlindFeedState copyWith({
    BlindFeedStatus? status,
    List<BlindPost>? posts,
    String? query,
    Object? selectedDepartment = _unset,
    List<String>? departments,
  }) {
    return BlindFeedState(
      status: status ?? this.status,
      posts: posts ?? this.posts,
      query: query ?? this.query,
      selectedDepartment: selectedDepartment == _unset
          ? this.selectedDepartment
          : selectedDepartment as String?,
      departments: departments ?? this.departments,
    );
  }

  @override
  List<Object?> get props => [
    status,
    posts,
    query,
    selectedDepartment,
    departments,
  ];
}

const Object _unset = Object();
