import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit(this._preferences) : super(ThemeMode.system) {
    _loadThemeMode();
  }

  final SharedPreferences _preferences;
  static const String _themeModeKey = 'theme_mode';

  Future<void> _loadThemeMode() async {
    final String? savedMode = _preferences.getString(_themeModeKey);
    if (savedMode != null) {
      final ThemeMode mode = ThemeMode.values.firstWhere(
        (e) => e.name == savedMode,
        orElse: () => ThemeMode.system,
      );
      emit(mode);
    }
  }

  Future<void> toggle() async {
    final ThemeMode newMode;
    switch (state) {
      case ThemeMode.system:
        newMode = ThemeMode.light;
        break;
      case ThemeMode.light:
        newMode = ThemeMode.dark;
        break;
      case ThemeMode.dark:
        newMode = ThemeMode.system;
        break;
    }
    await setTheme(newMode);
  }

  Future<void> setTheme(ThemeMode mode) async {
    await _preferences.setString(_themeModeKey, mode.name);
    emit(mode);
  }

  String get currentThemeName {
    switch (state) {
      case ThemeMode.system:
        return '시스템 설정';
      case ThemeMode.light:
        return '라이트 모드';
      case ThemeMode.dark:
        return '다크 모드';
    }
  }

  IconData get currentThemeIcon {
    switch (state) {
      case ThemeMode.system:
        return Icons.brightness_auto;
      case ThemeMode.light:
        return Icons.brightness_7;
      case ThemeMode.dark:
        return Icons.brightness_4;
    }
  }
}
