import 'package:equatable/equatable.dart';

import '../../../core/firebase/timestamp_utils.dart';

class UserDoc extends Equatable {
  const UserDoc({
    required this.uid,
    this.nickname = '공무원',
    this.serial = 'unknown',
    this.department = 'unknown',
    this.region = 'unknown',
    this.role = 'member',
    this.createdAt,
    this.blocked = false,
  });

  final String uid;
  final String nickname;
  final String serial;
  final String department;
  final String region;
  final String role;
  final DateTime? createdAt;
  final bool blocked;

  UserDoc copyWith({
    String? nickname,
    String? serial,
    String? department,
    String? region,
    String? role,
    DateTime? createdAt,
    bool? blocked,
  }) {
    return UserDoc(
      uid: uid,
      nickname: nickname ?? this.nickname,
      serial: serial ?? this.serial,
      department: department ?? this.department,
      region: region ?? this.region,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      blocked: blocked ?? this.blocked,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'nickname': nickname,
      'serial': serial,
      'department': department,
      'region': region,
      'role': role,
      'createdAt': toFirestoreTimestamp(createdAt),
      'blocked': blocked,
    };
  }

  static UserDoc fromJson(String uid, Map<String, Object?> json) {
    return UserDoc(
      uid: uid,
      nickname: (json['nickname'] as String?) ?? '공무원',
      serial: (json['serial'] as String?) ?? 'unknown',
      department: (json['department'] as String?) ?? 'unknown',
      region: (json['region'] as String?) ?? 'unknown',
      role: (json['role'] as String?) ?? 'member',
      createdAt: parseTimestamp(json['createdAt']),
      blocked: (json['blocked'] as bool?) ?? false,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    uid,
    nickname,
    serial,
    department,
    region,
    role,
    createdAt,
    blocked,
  ];
}
