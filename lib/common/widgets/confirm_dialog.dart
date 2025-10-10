import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

/// 재사용 가능한 확인 다이얼로그
///
/// Material 3 스타일의 확인/취소 다이얼로그
/// 다크 모드 완벽 지원 (colorScheme 사용)
///
/// **특징**:
/// - Material 3 디자인
/// - 타입별 아이콘/색상 (warning, error, info)
/// - Theme colorScheme 사용 (다크 모드 자동 대응)
/// - 커스터마이징 가능한 버튼
///
/// **Usage**:
/// ```dart
/// final confirmed = await ConfirmDialog.show(
///   context,
///   title: '삭제 확인',
///   message: '정말로 삭제하시겠습니까?',
///   type: ConfirmDialogType.error,
///   confirmText: '삭제',
/// );
/// if (confirmed == true) {
///   // 확인 처리
/// }
/// ```
class ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final ConfirmDialogType type;
  final String confirmText;
  final String cancelText;
  final List<Widget>? additionalContent;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.type = ConfirmDialogType.warning,
    this.confirmText = '확인',
    this.cancelText = '취소',
    this.additionalContent,
  });

  /// 다이얼로그 표시 (기본)
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    ConfirmDialogType type = ConfirmDialogType.warning,
    String confirmText = '확인',
    String cancelText = '취소',
    List<Widget>? additionalContent,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => ConfirmDialog(
        title: title,
        message: message,
        type: type,
        confirmText: confirmText,
        cancelText: cancelText,
        additionalContent: additionalContent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // 타입별 색상 및 아이콘
    final IconData icon;
    final Color iconColor;
    final Color confirmButtonColor;
    final Color confirmButtonForeground;

    switch (type) {
      case ConfirmDialogType.error:
        icon = Icons.error_outline_rounded;
        iconColor = colorScheme.error;
        confirmButtonColor = colorScheme.error;
        confirmButtonForeground = colorScheme.onError;
        break;
      case ConfirmDialogType.warning:
        icon = Icons.warning_amber_rounded;
        iconColor = colorScheme.error;
        confirmButtonColor = colorScheme.error;
        confirmButtonForeground = colorScheme.onError;
        break;
      case ConfirmDialogType.info:
        icon = Icons.info_outline_rounded;
        iconColor = colorScheme.primary;
        confirmButtonColor = colorScheme.primary;
        confirmButtonForeground = colorScheme.onPrimary;
        break;
    }

    return AlertDialog(
      icon: Icon(
        icon,
        color: iconColor,
        size: 48,
      ),
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: theme.textTheme.bodyMedium,
          ),
          if (additionalContent != null) ...[
            const Gap(16),
            ...additionalContent!,
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelText),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: confirmButtonColor,
            foregroundColor: confirmButtonForeground,
          ),
          child: Text(confirmText),
        ),
      ],
    );
  }
}

/// 확인 다이얼로그 타입
enum ConfirmDialogType {
  /// 에러 (빨간색, error_outline 아이콘)
  error,

  /// 경고 (빨간색, warning_amber 아이콘)
  warning,

  /// 정보 (primary 색상, info_outline 아이콘)
  info,
}
