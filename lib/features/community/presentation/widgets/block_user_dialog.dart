import 'package:flutter/material.dart';

/// Block User Confirmation Dialog
///
/// Responsibilities:
/// - Show confirmation dialog before blocking a user
/// - Return true if user confirms, false/null if cancelled
///
/// Usage:
/// ```dart
/// final confirmed = await BlockUserDialog.show(context, nickname: '사용자123');
/// if (confirmed == true) {
///   // Block the user
/// }
/// ```
class BlockUserDialog extends StatelessWidget {
  const BlockUserDialog({
    super.key,
    required this.targetNickname,
  });

  final String targetNickname;

  /// Show the block confirmation dialog
  static Future<bool?> show(
    BuildContext context, {
    required String nickname,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => BlockUserDialog(targetNickname: nickname),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return AlertDialog(
      title: const Text('사용자 차단'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$targetNickname님을 차단하시겠습니까?',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          Text(
            '차단하면:',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _buildInfoItem(
            context,
            icon: Icons.visibility_off_outlined,
            text: '이 사용자의 게시글과 댓글이 보이지 않습니다',
          ),
          const SizedBox(height: 6),
          _buildInfoItem(
            context,
            icon: Icons.chat_bubble_outline,
            text: '이 사용자가 회원님의 게시글에 댓글을 남길 수 없습니다',
          ),
          const SizedBox(height: 6),
          _buildInfoItem(
            context,
            icon: Icons.undo_outlined,
            text: '프로필 > 설정에서 언제든 차단을 해제할 수 있습니다',
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
          ),
          child: const Text('차단하기'),
        ),
      ],
    );
  }

  Widget _buildInfoItem(
    BuildContext context, {
    required IconData icon,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
