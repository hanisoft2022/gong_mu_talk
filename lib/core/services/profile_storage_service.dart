import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/teacher_profile.dart';

/// TeacherProfile 로컬 저장 서비스
class ProfileStorageService {
  static const String _profileKey = 'teacher_profile';

  final SharedPreferences _prefs;

  ProfileStorageService(this._prefs);

  /// 프로필 저장
  Future<void> saveProfile(TeacherProfile profile) async {
    final jsonString = jsonEncode(profile.toJson());
    await _prefs.setString(_profileKey, jsonString);
  }

  /// 프로필 불러오기
  TeacherProfile? loadProfile() {
    final jsonString = _prefs.getString(_profileKey);
    if (jsonString == null) return null;

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return TeacherProfile.fromJson(json);
    } catch (e) {
      // JSON 파싱 실패 시 null 반환
      return null;
    }
  }

  /// 프로필 삭제
  Future<void> clearProfile() async {
    await _prefs.remove(_profileKey);
  }

  /// 프로필 존재 여부 확인
  bool hasProfile() {
    return _prefs.containsKey(_profileKey);
  }
}
