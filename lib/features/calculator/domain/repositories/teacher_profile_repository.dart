import 'package:gong_mu_talk/features/calculator/domain/entities/teacher_profile.dart';

/// TeacherProfile Firestore 저장소 인터페이스
abstract class TeacherProfileRepository {
  /// 프로필 저장 (Firestore)
  Future<void> saveProfile(String userId, TeacherProfile profile);

  /// 프로필 불러오기 (Firestore)
  Future<TeacherProfile?> loadProfile(String userId);

  /// 프로필 삭제 (Firestore)
  Future<void> deleteProfile(String userId);

  /// 프로필 존재 여부 확인 (Firestore)
  Future<bool> hasProfile(String userId);
}
