/// ThemeSettingsSection
///
/// 테마 설정 섹션 위젯
///
/// Phase 2 - Extracted from profile_page.dart
///
/// Features:
/// - 현재 테마 모드 표시
/// - 테마 선택 다이얼로그 열기
/// - 라이트/다크/시스템 모드 선택
///
/// File Size: ~110 lines (Green Zone ✅)
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/theme/theme_cubit.dart';
import 'theme_option_tile.dart';

class ThemeSettingsSection extends StatelessWidget {
  const ThemeSettingsSection({super.key, required this.isProcessing});

  final bool isProcessing;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, currentThemeMode) {
        return Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                _getThemeIcon(currentThemeMode),
                color: theme.colorScheme.primary,
              ),
              title: const Text('테마 설정'),
              subtitle: Text(_getThemeDescription(currentThemeMode)),
              trailing: Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              onTap: isProcessing ? null : () => _showThemeDialog(context),
            ),
          ],
        );
      },
    );
  }

  IconData _getThemeIcon(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.brightness_auto;
    }
  }

  String _getThemeDescription(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return '라이트 모드';
      case ThemeMode.dark:
        return '다크 모드';
      case ThemeMode.system:
        return '시스템 설정 따르기';
    }
  }

  void _showThemeDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, currentThemeMode) {
            return AlertDialog(
              title: const Text('테마 선택'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ThemeOptionTile(
                    title: '시스템 설정 따르기',
                    subtitle: '기기의 시스템 설정을 따라 자동으로 변경됩니다',
                    icon: Icons.brightness_auto,
                    themeMode: ThemeMode.system,
                    currentThemeMode: currentThemeMode,
                    onTap: () {
                      context.read<ThemeCubit>().setTheme(ThemeMode.system);
                      Navigator.of(context).pop();
                    },
                  ),
                  ThemeOptionTile(
                    title: '라이트 모드',
                    subtitle: '밝은 화면으로 표시됩니다',
                    icon: Icons.light_mode,
                    themeMode: ThemeMode.light,
                    currentThemeMode: currentThemeMode,
                    onTap: () {
                      context.read<ThemeCubit>().setTheme(ThemeMode.light);
                      Navigator.of(context).pop();
                    },
                  ),
                  ThemeOptionTile(
                    title: '다크 모드',
                    subtitle: '어두운 화면으로 표시됩니다',
                    icon: Icons.dark_mode,
                    themeMode: ThemeMode.dark,
                    currentThemeMode: currentThemeMode,
                    onTap: () {
                      context.read<ThemeCubit>().setTheme(ThemeMode.dark);
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
