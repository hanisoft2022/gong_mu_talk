import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/teacher_profile.dart';
import 'package:gong_mu_talk/features/calculator/domain/repositories/teacher_profile_repository.dart';

/// TeacherProfile Firestore 구현체
class FirestoreTeacherProfileRepository implements TeacherProfileRepository {
  final FirebaseFirestore _firestore;

  FirestoreTeacherProfileRepository(this._firestore);

  /// Firestore 경로: users/{userId}/calculatorProfile
  DocumentReference<Map<String, dynamic>> _getProfileDoc(String userId) {
    return _firestore.collection('users').doc(userId).collection('private').doc('calculatorProfile');
  }

  @override
  Future<void> saveProfile(String userId, TeacherProfile profile) async {
    try {
      await _getProfileDoc(userId).set(profile.toJson());
    } catch (e) {
      throw Exception('Firestore 프로필 저장 실패: $e');
    }
  }

  @override
  Future<TeacherProfile?> loadProfile(String userId) async {
    try {
      final doc = await _getProfileDoc(userId).get();
      if (!doc.exists || doc.data() == null) return null;

      return TeacherProfile.fromJson(doc.data()!);
    } catch (e) {
      throw Exception('Firestore 프로필 로드 실패: $e');
    }
  }

  @override
  Future<void> deleteProfile(String userId) async {
    try {
      await _getProfileDoc(userId).delete();
    } catch (e) {
      throw Exception('Firestore 프로필 삭제 실패: $e');
    }
  }

  @override
  Future<bool> hasProfile(String userId) async {
    try {
      final doc = await _getProfileDoc(userId).get();
      return doc.exists;
    } catch (e) {
      throw Exception('Firestore 프로필 확인 실패: $e');
    }
  }
}
