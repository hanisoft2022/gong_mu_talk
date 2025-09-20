import 'package:equatable/equatable.dart';

class BlindPost extends Equatable {
  const BlindPost({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.likes,
    required this.comments,
    required this.department,
  });

  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final int likes;
  final int comments;
  final String department;

  String get initial => title.isEmpty ? '?' : title.substring(0, 1);

  @override
  List<Object?> get props => [
        id,
        title,
        content,
        createdAt,
        likes,
        comments,
        department,
      ];
}
