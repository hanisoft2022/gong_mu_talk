/// Post Detail Dialogs - Dialog helpers for post actions
///
/// Responsibilities:
/// - Shows delete confirmation dialog
/// - Shows report confirmation dialog
/// - Shows block user confirmation dialog
/// - Handles dialog interactions and callbacks

import 'package:flutter/material.dart';

class PostDetailDialogs {
  // ==================== Delete Dialog ====================

  static Future<bool?> showDeleteDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('게시글 삭제'),
        content: const Text('이 게시글을 삭제하시겠습니까?\n삭제된 게시글은 복구할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  // ==================== Report Dialog ====================

  static Future<bool?> showReportDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('신고하기'),
        content: const Text('이 게시글이 커뮤니티 가이드라인을 위반했다고 신고하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('신고'),
          ),
        ],
      ),
    );
  }

  // ==================== Block Dialog ====================

  static Future<bool?> showBlockDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('사용자 차단'),
        content: const Text(
          '이 사용자를 차단하시겠습니까?\n차단하면 해당 사용자의 게시글과 댓글을 볼 수 없습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('차단'),
          ),
        ],
      ),
    );
  }
}
