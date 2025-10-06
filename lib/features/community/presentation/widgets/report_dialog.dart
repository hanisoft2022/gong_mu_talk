import 'package:flutter/material.dart';

/// Report Dialog
///
/// Responsibilities:
/// - Show report reason selection dialog
/// - Return selected reason or null if cancelled
///
/// Usage:
/// ```dart
/// final reason = await ReportDialog.show(context);
/// if (reason != null) {
///   // Submit report with reason
/// }
/// ```
class ReportDialog extends StatelessWidget {
  const ReportDialog({super.key});

  /// Show the report dialog and return selected reason
  static Future<String?> show(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (_) => const ReportDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return AlertDialog(
      title: const Text('신고 사유 선택'),
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildReasonTile(
            context,
            icon: Icons.content_copy_outlined,
            title: '스팸 / 도배',
            reason: 'spam',
          ),
          const Divider(height: 1),
          _buildReasonTile(
            context,
            icon: Icons.warning_outlined,
            title: '욕설 / 혐오 발언',
            reason: 'hate_speech',
          ),
          const Divider(height: 1),
          _buildReasonTile(
            context,
            icon: Icons.info_outline,
            title: '허위 정보',
            reason: 'misinformation',
          ),
          const Divider(height: 1),
          _buildReasonTile(
            context,
            icon: Icons.block_outlined,
            title: '부적절한 콘텐츠',
            reason: 'inappropriate',
          ),
          const Divider(height: 1),
          _buildReasonTile(
            context,
            icon: Icons.report_outlined,
            title: '기타',
            reason: 'other',
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
      ],
    );
  }

  Widget _buildReasonTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String reason,
  }) {
    return ListTile(
      leading: Icon(icon, size: 24),
      title: Text(title),
      onTap: () => Navigator.pop(context, reason),
      visualDensity: VisualDensity.compact,
    );
  }
}
