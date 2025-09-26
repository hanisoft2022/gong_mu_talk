import 'package:equatable/equatable.dart';

enum MeetingCategory {
  fitness('헬스', '💪'),
  running('러닝', '🏃'),
  boardGame('보드게임', '🎲'),
  badminton('배드민턴', '🏸'),
  realEstateTour('부동산 임장', '🏠'),
  study('스터디', '📚'),
  volunteer('봉사', '🤝'),
  coffee('카페 탐방', '☕️');

  const MeetingCategory(this.label, this.emoji);

  final String label;
  final String emoji;
}

class MeetingMember extends Equatable {
  const MeetingMember({required this.uid, required this.nickname});

  final String uid;
  final String nickname;

  @override
  List<Object?> get props => <Object?>[uid, nickname];
}

class LifeMeeting extends Equatable {
  const LifeMeeting({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    required this.host,
    required this.capacity,
    required this.members,
    required this.createdAt,
    this.location,
    this.schedule,
    this.tags = const <String>[],
  });

  final String id;
  final MeetingCategory category;
  final String title;
  final String description;
  final MeetingMember host;
  final int capacity;
  final List<MeetingMember> members;
  final DateTime createdAt;
  final String? location;
  final DateTime? schedule;
  final List<String> tags;

  bool get isFull => members.length >= capacity;

  LifeMeeting copyWith({
    MeetingCategory? category,
    String? title,
    String? description,
    MeetingMember? host,
    int? capacity,
    List<MeetingMember>? members,
    DateTime? schedule,
    String? location,
    List<String>? tags,
  }) {
    return LifeMeeting(
      id: id,
      category: category ?? this.category,
      title: title ?? this.title,
      description: description ?? this.description,
      host: host ?? this.host,
      capacity: capacity ?? this.capacity,
      members: members ?? this.members,
      createdAt: createdAt,
      schedule: schedule ?? this.schedule,
      location: location ?? this.location,
      tags: tags ?? this.tags,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    category,
    title,
    description,
    host,
    capacity,
    members,
    createdAt,
    location,
    schedule,
    tags,
  ];
}
