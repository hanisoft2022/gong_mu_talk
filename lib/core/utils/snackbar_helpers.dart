import 'package:flutter/material.dart';

/// Snackbar 관련 모든 유틸리티 함수들
///
/// Material 3 디자인 가이드 기반
/// - 일관된 아이콘 + 색상 테마
/// - 부드러운 애니메이션
/// - 미니멀하지만 명확한 피드백
class SnackbarHelpers {
  SnackbarHelpers._();

  /// 기본 duration 값들
  static const Duration _shortDuration = Duration(seconds: 2);
  static const Duration _mediumDuration = Duration(seconds: 3);
  static const Duration _longDuration = Duration(seconds: 5);

  /// 정보성 메시지 스낵바 (파란색 + info 아이콘)
  ///
  /// 예시: '신고가 접수되었습니다', '게시물이 등록되었어요'
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = _shortDuration,
    SnackBarAction? action,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    _showSnackBar(
      context,
      message: message,
      duration: duration,
      backgroundColor: colorScheme.primaryContainer,
      textColor: colorScheme.onPrimaryContainer,
      icon: Icons.info_outline,
      iconColor: colorScheme.primary,
      action: action,
    );
  }

  /// 성공 메시지 스낵바 (초록색 + check 아이콘)
  ///
  /// 예시: '저장 완료', '설정이 변경되었습니다'
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = _shortDuration,
    SnackBarAction? action,
  }) {
    _showSnackBar(
      context,
      message: message,
      duration: duration,
      backgroundColor: const Color(0xFF4CAF50).withValues(alpha: 0.9),
      textColor: Colors.white,
      icon: Icons.check_circle_outline,
      iconColor: Colors.white,
      action: action,
    );
  }

  /// 에러 메시지 스낵바 (빨간색 + error 아이콘)
  ///
  /// 예시: '저장 실패', '네트워크 오류'
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = _mediumDuration,
    SnackBarAction? action,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    _showSnackBar(
      context,
      message: message,
      duration: duration,
      backgroundColor: colorScheme.errorContainer,
      textColor: colorScheme.onErrorContainer,
      icon: Icons.error_outline,
      iconColor: colorScheme.error,
      action: action,
    );
  }

  /// 경고 메시지 스낵바 (주황색 + warning 아이콘)
  ///
  /// 예시: '필수 입력 항목입니다', '권한이 필요합니다'
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = _mediumDuration,
    SnackBarAction? action,
  }) {
    _showSnackBar(
      context,
      message: message,
      duration: duration,
      backgroundColor: const Color(0xFFFF9800).withValues(alpha: 0.9),
      textColor: Colors.white,
      icon: Icons.warning_amber_outlined,
      iconColor: Colors.white,
      action: action,
    );
  }

  /// 실행 취소 기능이 있는 스낵바
  ///
  /// 예시: 삭제, 차단, 스크랩 등 되돌릴 수 있는 액션
  ///
  /// Usage:
  /// ```dart
  /// SnackbarHelpers.showUndo(
  ///   context,
  ///   message: '게시물을 스크랩했습니다',
  ///   onUndo: () => _repository.undoScrap(),
  /// );
  /// ```
  static void showUndo(
    BuildContext context, {
    required String message,
    required VoidCallback onUndo,
    Duration duration = _longDuration,
    String undoLabel = '실행 취소',
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    _showSnackBar(
      context,
      message: message,
      duration: duration,
      backgroundColor: colorScheme.inverseSurface,
      textColor: colorScheme.onInverseSurface,
      icon: Icons.info_outline,
      iconColor: colorScheme.inversePrimary,
      action: SnackBarAction(
        label: undoLabel,
        textColor: colorScheme.inversePrimary,
        onPressed: onUndo,
      ),
    );
  }

  /// 내부 공통 스낵바 생성 함수
  static void _showSnackBar(
    BuildContext context, {
    required String message,
    required Duration duration,
    required Color backgroundColor,
    required Color textColor,
    required IconData icon,
    required Color iconColor,
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(color: textColor, fontSize: 14),
                ),
              ),
            ],
          ),
          duration: duration,
          behavior: SnackBarBehavior.floating,
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          action: action,
          elevation: 3,
        ),
      );
  }
}
