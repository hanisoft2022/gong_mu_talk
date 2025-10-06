import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../../routing/app_router.dart';
import '../../../domain/models/post.dart';

/// Post Share Handler
///
/// Responsibilities:
/// - Show share options bottom sheet
/// - Copy post link to clipboard
/// - Share post to other apps
/// - Handle share errors gracefully
class PostShareHandler {
  /// Show share options for a post
  static void showShareOptions(BuildContext context, Post post) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        final ThemeData theme = Theme.of(context);
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '공유하기',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.link),
                title: const Text('링크 복사'),
                onTap: () {
                  copyLinkToClipboard(context, post);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('다른 앱으로 공유'),
                onTap: () {
                  sharePost(context, post);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  /// Copy post link to clipboard
  static void copyLinkToClipboard(BuildContext context, Post post) {
    final Uri shareUri = Uri.parse(
      'gongmutalk://community/posts/${post.id}',
    );

    Clipboard.setData(ClipboardData(text: shareUri.toString()));

    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('링크가 클립보드에 복사되었습니다'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  /// Share post to other apps
  static Future<void> sharePost(BuildContext context, Post post) async {
    final String source = post.text.trim();
    final String truncated = source.length > 120 ? '${source.substring(0, 120)}...' : source;
    final String snippet = truncated.replaceAll(RegExp(r'\s+'), ' ').trim();
    final Uri shareUri = Uri.parse(
      'gongmutalk://community/posts/${post.id}',
    );

    final String message = snippet.isEmpty ? shareUri.toString() : '$snippet\n\n${shareUri.toString()}';

    try {
      await Share.share(message, subject: '공뮤톡 라운지 글 공유');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('공유하기를 실행할 수 없습니다'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
      }
    }
  }
}
