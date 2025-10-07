import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/user_sensitive_info.dart';

/// 🔒 민감 정보 Repository
/// users/{uid}/private/sensitive 서브컬렉션 관리
class UserSensitiveInfoRepository {
  UserSensitiveInfoRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _sensitiveDoc(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('private')
        .doc('sensitive');
  }

  /// 민감 정보 조회
  Future<UserSensitiveInfo> getSensitiveInfo(String uid) async {
    final doc = await _sensitiveDoc(uid).get();
    return UserSensitiveInfo.fromFirestore(uid, doc);
  }

  /// 민감 정보 스트림
  Stream<UserSensitiveInfo> watchSensitiveInfo(String uid) {
    return _sensitiveDoc(uid).snapshots().map((doc) {
      return UserSensitiveInfo.fromFirestore(uid, doc);
    });
  }

  /// 민감 정보 저장/업데이트
  Future<void> saveSensitiveInfo(UserSensitiveInfo info) async {
    await _sensitiveDoc(
      info.uid,
    ).set(info.toFirestore(), SetOptions(merge: true));
  }

  /// 공무원 이메일 업데이트
  Future<void> updateGovernmentEmail(String uid, String email) async {
    await _sensitiveDoc(uid).set({
      'governmentEmail': email,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Primary 이메일 업데이트
  Future<void> updatePrimaryEmail(String uid, String email) async {
    await _sensitiveDoc(uid).set({
      'primaryEmail': email,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// 민감 정보 삭제
  Future<void> deleteSensitiveInfo(String uid) async {
    await _sensitiveDoc(uid).delete();
  }
}
