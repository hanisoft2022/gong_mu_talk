import 'package:flutter/material.dart';

/// UI 관련 공통 유틸리티 함수들
class UiHelpers {
  UiHelpers._();

  /// ScaffoldMessenger를 사용한 스낵바 표시
  static void showSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
    SnackBarBehavior behavior = SnackBarBehavior.floating,
    Color? backgroundColor,
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: duration,
          behavior: behavior,
          backgroundColor: backgroundColor,
          action: action,
        ),
      );
  }

  /// 에러 스낵바 표시
  static void showErrorSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    showSnackBar(
      context,
      message,
      duration: duration,
      backgroundColor: Theme.of(context).colorScheme.error,
    );
  }

  /// 성공 스낵바 표시
  static void showSuccessSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    showSnackBar(
      context,
      message,
      duration: duration,
      backgroundColor: Colors.green,
    );
  }

  /// Theme.of(context) 접근을 위한 헬퍼
  static ThemeData getTheme(BuildContext context) => Theme.of(context);

  /// ColorScheme 접근을 위한 헬퍼
  static ColorScheme getColorScheme(BuildContext context) =>
      Theme.of(context).colorScheme;

  /// TextTheme 접근을 위한 헬퍼
  static TextTheme getTextTheme(BuildContext context) =>
      Theme.of(context).textTheme;

  /// 표준 패딩 값들
  static const EdgeInsets standardPadding = EdgeInsets.all(16.0);
  static const EdgeInsets horizontalPadding = EdgeInsets.symmetric(
    horizontal: 16.0,
  );
  static const EdgeInsets verticalPadding = EdgeInsets.symmetric(
    vertical: 16.0,
  );
  static const EdgeInsets cardPadding = EdgeInsets.all(20.0);
  static const EdgeInsets smallPadding = EdgeInsets.all(8.0);
  static const EdgeInsets largePadding = EdgeInsets.all(24.0);

  /// 표준 간격 값들
  static const double smallGap = 8.0;
  static const double standardGap = 16.0;
  static const double largeGap = 24.0;
  static const double extraLargeGap = 32.0;

  /// 표준 보더 반경 값들
  static const double smallRadius = 8.0;
  static const double standardRadius = 12.0;
  static const double largeRadius = 16.0;
  static const double circularRadius = 999.0;

  /// 표준 애니메이션 지속시간들
  static const Duration fastAnimation = Duration(milliseconds: 150);
  static const Duration standardAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 500);
}
