import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

/// 재사용 가능한 정보 안내 다이얼로그
///
/// 모던하고 미니멀한 Material 3 스타일
///
/// 색상 시스템:
/// - Primary: Teal.shade600 (제목, 버튼, 강조)
/// - Neutral: Grey.shade50/100 (배경, 테이블)
/// - Warning: Orange.shade50 (경고만)
///
/// Usage:
/// ```dart
/// await InfoDialog.show(
///   context,
///   title: '공제 항목 안내',
///   icon: Icons.info_outline,
///   content: '매월 급여에서 공제되는 항목을 입력할 수 있습니다...',
/// );
/// ```
class InfoDialog extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Color? iconColor;
  final Widget content;
  final String confirmText;
  final VoidCallback? onConfirm;

  const InfoDialog({
    super.key,
    required this.title,
    this.icon,
    this.iconColor,
    required this.content,
    this.confirmText = '확인',
    this.onConfirm,
  });

  /// 다이얼로그 표시 (텍스트 버전)
  static Future<void> show(
    BuildContext context, {
    required String title,
    IconData? icon,
    Color? iconColor,
    required String content,
    String confirmText = '확인',
    VoidCallback? onConfirm,
  }) {
    return showDialog(
      context: context,
      builder: (context) => InfoDialog(
        title: title,
        icon: icon,
        iconColor: iconColor,
        content: SingleChildScrollView(
          child: Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.6,
            ),
          ),
        ),
        confirmText: confirmText,
        onConfirm: onConfirm,
      ),
    );
  }

  /// 다이얼로그 표시 (위젯 버전)
  static Future<void> showWidget(
    BuildContext context, {
    required String title,
    IconData? icon,
    Color? iconColor,
    required Widget content,
    String confirmText = '확인',
    VoidCallback? onConfirm,
  }) {
    return showDialog(
      context: context,
      builder: (context) => InfoDialog(
        title: title,
        icon: icon,
        iconColor: iconColor,
        content: content,
        confirmText: confirmText,
        onConfirm: onConfirm,
      ),
    );
  }

  /// 다이얼로그 표시 (리스트 항목 버전)
  static Future<void> showList(
    BuildContext context, {
    required String title,
    IconData? icon,
    Color? iconColor,
    required List<InfoListItem> items,
    String? description,
    String confirmText = '확인',
    VoidCallback? onConfirm,
  }) {
    return showDialog(
      context: context,
      builder: (context) => InfoDialog(
        title: title,
        icon: icon,
        iconColor: iconColor,
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (description != null) ...[
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.6,
                  ),
                ),
                const Gap(16),
              ],
              ...items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isLast = index == items.length - 1;
                return Column(
                  children: [
                    _InfoListItemWidget(item: item),
                    if (!isLast)
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: Colors.grey.shade200,
                      ),
                  ],
                );
              }),
            ],
          ),
        ),
        confirmText: confirmText,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 기본 색상: Teal (모던한 청록색)
    final primaryColor = iconColor ?? Colors.teal.shade600;

    return AlertDialog(
      title: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: primaryColor,
              size: 24,
            ),
            const Gap(12),
          ],
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      content: SizedBox(
        width: double.maxFinite,
        child: content,
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              onConfirm?.call();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              confirmText,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 정보 다이얼로그 리스트 항목
class InfoListItem {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;

  const InfoListItem({
    required this.title,
    this.subtitle,
    this.icon,
    this.iconColor,
  });
}

/// 리스트 항목 위젯
class _InfoListItemWidget extends StatelessWidget {
  final InfoListItem item;

  const _InfoListItemWidget({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.icon != null) ...[
            Icon(
              item.icon,
              size: 20,
              color: item.iconColor ?? Colors.teal.shade600, // Teal로 변경
            ),
            const Gap(12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                if (item.subtitle != null) ...[
                  const Gap(4),
                  Text(
                    item.subtitle!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
