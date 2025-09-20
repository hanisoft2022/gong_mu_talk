import 'package:shared_preferences/shared_preferences.dart';

class LoginSessionStore {
  LoginSessionStore(this._preferences);

  final SharedPreferences _preferences;

  static const String _lastLoginKey = 'auth_last_login_at';

  DateTime? getLastLoginAt() {
    final int? timestamp = _preferences.getInt(_lastLoginKey);
    if (timestamp == null) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  bool isSessionExpired(Duration maxAge) {
    final DateTime? lastLoginAt = getLastLoginAt();
    if (lastLoginAt == null) {
      return false;
    }

    final Duration elapsed = DateTime.now().difference(lastLoginAt);
    return elapsed > maxAge;
  }

  Future<void> saveLoginTimestamp(DateTime timestamp) {
    return _preferences.setInt(_lastLoginKey, timestamp.millisecondsSinceEpoch);
  }

  Future<void> clearLoginTimestamp() {
    return _preferences.remove(_lastLoginKey);
  }
}
