import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// 🔒 민감 정보 엔티티
/// users/{uid}/private/sensitive 서브컬렉션에 저장
/// 본인만 접근 가능
class UserSensitiveInfo extends Equatable {
  const UserSensitiveInfo({
    required this.uid,
    this.governmentEmail,
    this.primaryEmail,
    this.phone,
    this.createdAt,
    this.updatedAt,
  });

  final String uid;
  final String? governmentEmail;
  final String? primaryEmail;
  final String? phone;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Firestore에서 읽기
  factory UserSensitiveInfo.fromFirestore(
    String uid,
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    if (!doc.exists) {
      return UserSensitiveInfo(uid: uid);
    }

    final data = doc.data()!;
    return UserSensitiveInfo(
      uid: uid,
      governmentEmail: data['governmentEmail'] as String?,
      primaryEmail: data['primaryEmail'] as String?,
      phone: data['phone'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Firestore에 저장
  Map<String, dynamic> toFirestore() {
    return {
      'governmentEmail': governmentEmail,
      'primaryEmail': primaryEmail,
      'phone': phone,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  UserSensitiveInfo copyWith({
    String? governmentEmail,
    String? primaryEmail,
    String? phone,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserSensitiveInfo(
      uid: uid,
      governmentEmail: governmentEmail ?? this.governmentEmail,
      primaryEmail: primaryEmail ?? this.primaryEmail,
      phone: phone ?? this.phone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    uid,
    governmentEmail,
    primaryEmail,
    phone,
    createdAt,
    updatedAt,
  ];
}
