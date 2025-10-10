import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/teacher_profile.dart';

/// TeacherProfile 로컬 저장 서비스
/// User-specific key 구조로 계정별 데이터 격리
class ProfileStorageService {
  static const String _profileKeyPrefix = 'teacher_profile';
  static const String _guestProfileKey = 'teacher_profile_guest';

  final SharedPreferences _prefs;

  ProfileStorageService(this._prefs);

  /// User-specific key 생성
  /// userId가 null이면 guest key 반환
  String _getProfileKey(String? userId) {
    if (userId == null || userId.isEmpty) {
      return _guestProfileKey;
    }
    return '${_profileKeyPrefix}_$userId';
  }

  /// 프로필 저장
  Future<void> saveProfile(TeacherProfile profile, {String? userId}) async {
    final jsonString = jsonEncode(profile.toJson());
    final key = _getProfileKey(userId);
    await _prefs.setString(key, jsonString);
  }

  /// 프로필 불러오기
  TeacherProfile? loadProfile({String? userId}) {
    final key = _getProfileKey(userId);
    final jsonString = _prefs.getString(key);
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
  Future<void> clearProfile({String? userId}) async {
    final key = _getProfileKey(userId);
    await _prefs.remove(key);
  }

  /// 모든 사용자 프로필 삭제 (로그아웃 시 사용)
  Future<void> clearAllProfiles() async {
    final keys = _prefs.getKeys();
    final profileKeys = keys.where((key) => key.startsWith(_profileKeyPrefix));
    for (final key in profileKeys) {
      await _prefs.remove(key);
    }
  }

  /// 프로필 존재 여부 확인
  bool hasProfile({String? userId}) {
    final key = _getProfileKey(userId);
    return _prefs.containsKey(key);
  }
}
