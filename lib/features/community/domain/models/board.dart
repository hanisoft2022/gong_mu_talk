import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum BoardVisibility { public, hidden }

enum BoardAccessType { anonymousOptional, realnameRequired }

class Board extends Equatable {
  const Board({
    required this.id,
    required this.name,
    required this.slug,
    required this.requireRealname,
    required this.visibility,
    required this.order,
    this.description,
    this.createdAt,
    this.updatedAt,
    this.category,
  });

  final String id;
  final String name;
  final String slug;
  final bool requireRealname;
  final BoardVisibility visibility;
  final int order;
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? category;

  BoardAccessType get accessType => requireRealname
      ? BoardAccessType.realnameRequired
      : BoardAccessType.anonymousOptional;

  bool get isVisible => visibility == BoardVisibility.public;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'name': name,
      'slug': slug,
      'requireRealname': requireRealname,
      'visibility': visibility.name,
      'order': order,
      'description': description,
      'category': category,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  static Board fromSnapshot(DocumentSnapshot<Map<String, Object?>> snapshot) {
    final Map<String, Object?>? data = snapshot.data();
    if (data == null) {
      throw StateError('Board document ${snapshot.id} has no data');
    }

    return fromMap(snapshot.id, data);
  }

  static Board fromMap(String id, Map<String, Object?> data) {
    return Board(
      id: id,
      name: (data['name'] as String?) ?? '이름 없음',
      slug: (data['slug'] as String?) ?? id,
      requireRealname: data['requireRealname'] as bool? ?? false,
      visibility: _parseVisibility(data['visibility']),
      order: (data['order'] as num?)?.toInt() ?? 0,
      description: data['description'] as String?,
      category: data['category'] as String?,
      createdAt: _parseTimestamp(data['createdAt']),
      updatedAt: _parseTimestamp(data['updatedAt']),
    );
  }

  static BoardVisibility _parseVisibility(Object? raw) {
    if (raw is String) {
      return BoardVisibility.values.firstWhere(
        (BoardVisibility value) => value.name == raw,
        orElse: () => BoardVisibility.public,
      );
    }
    return BoardVisibility.public;
  }

  static DateTime? _parseTimestamp(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }
    return null;
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    name,
    slug,
    requireRealname,
    visibility,
    order,
    description,
    category,
    createdAt,
    updatedAt,
  ];
}
