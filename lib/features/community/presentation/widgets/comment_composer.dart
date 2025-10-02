/// Comment Composer - Input widget for writing comments and replies
///
/// Responsibilities:
/// - Provides text input field for comment composition
/// - Shows reply target indicator when replying to a comment
/// - Manages submit button state based on text input
/// - Handles submit and cancel actions
/// - Displays loading state during submission
/// - Adjusts padding for keyboard visibility

library;
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../domain/models/comment.dart';
import '../../domain/models/feed_filters.dart';
import 'comment_utils.dart';

class CommentComposer extends StatefulWidget {
  const CommentComposer({
    super.key,
    required this.controller,
    required this.isSubmitting,
    required this.onSubmit,
    required this.focusNode,
    required this.replyingTo,
    required this.onCancelReply,
    required this.scope,
  });

  final TextEditingController controller;
  final bool isSubmitting;
  final Future<void> Function() onSubmit;
  final FocusNode focusNode;
  final Comment? replyingTo;
  final VoidCallback onCancelReply;
  final LoungeScope scope;

  @override
  State<CommentComposer> createState() => _CommentComposerState();
}

class _CommentComposerState extends State<CommentComposer> {
  bool _canSubmit = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_updateSubmitState);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateSubmitState);
    super.dispose();
  }

  void _updateSubmitState() {
    final bool canSubmit = widget.controller.text.trim().isNotEmpty;
    if (_canSubmit != canSubmit) {
      setState(() {
        _canSubmit = canSubmit;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Comment? replyingTo = widget.replyingTo;
    final bool isSerialScope = widget.scope == LoungeScope.serial;

    final List<Widget> children = <Widget>[];

    if (replyingTo != null) {
      children.add(_buildReplyIndicator(theme, replyingTo, isSerialScope));
    }

    children.add(_buildInputRow());

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  // ==================== Reply Indicator ====================

  Widget _buildReplyIndicator(
    ThemeData theme,
    Comment replyingTo,
    bool isSerialScope,
  ) {
    final String nicknameSource = replyingTo.authorNickname.isNotEmpty
        ? replyingTo.authorNickname
        : replyingTo.authorUid;
    final String displayName = isSerialScope
        ? replyingTo.authorNickname
        : maskNickname(nicknameSource);
    final String preview = replyingTo.text.trim();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$displayName 님에게 답글 작성 중',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (preview.isNotEmpty)
                  Text(
                    preview,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: widget.onCancelReply,
            child: const Text('취소'),
          ),
        ],
      ),
    );
  }

  // ==================== Input Row ====================

  Widget _buildInputRow() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            decoration: const InputDecoration(
              hintText: '댓글을 입력하세요...',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            maxLines: null,
            textInputAction: TextInputAction.newline,
          ),
        ),
        const Gap(12),
        FilledButton(
          onPressed: _canSubmit && !widget.isSubmitting
              ? widget.onSubmit
              : null,
          child: widget.isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('등록'),
        ),
      ],
    );
  }
}
