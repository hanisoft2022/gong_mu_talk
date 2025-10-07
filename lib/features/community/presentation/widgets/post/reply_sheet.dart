/// Reply sheet for writing comment replies
///
/// Responsibilities:
/// - Display target comment preview
/// - Text input for reply with mention
/// - Submit and cancel actions
/// - Handle reply submission
///
/// Used by: PostCard

library;

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../data/community_repository.dart';
import '../../../domain/models/comment.dart';
import '../../../domain/models/feed_filters.dart';

class InlineReplySheet extends StatefulWidget {
  const InlineReplySheet({
    super.key,
    required this.postId,
    required this.target,
    required this.repository,
    required this.scope,
  });

  final String postId;
  final Comment target;
  final CommunityRepository repository;
  final LoungeScope scope;

  @override
  State<InlineReplySheet> createState() => _InlineReplySheetState();
}

class _InlineReplySheetState extends State<InlineReplySheet> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final String rawNickname = widget.target.authorNickname.trim().isNotEmpty
        ? widget.target.authorNickname.trim()
        : widget.target.authorUid;
    final String mention = '@$rawNickname ';
    _controller = TextEditingController(text: mention)
      ..selection = TextSelection.collapsed(offset: mention.length);
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final Comment target = widget.target;
    final String displayName = target.authorNickname.isNotEmpty
        ? target.authorNickname
        : target.authorUid;
    final String preview = target.text.trim();

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                '답글 작성',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Gap(12),

              // Target comment preview
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Gap(6),
                    Text(
                      preview.isEmpty ? '내용이 없는 댓글' : preview,
                      style: theme.textTheme.bodySmall,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Gap(12),

              // Reply input field
              TextField(
                controller: _controller,
                focusNode: _focusNode,
                minLines: 3,
                maxLines: 6,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: '답글을 입력하세요',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const Gap(12),

              // Action buttons
              Row(
                children: [
                  TextButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(false),
                    child: const Text('취소'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('등록'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final String text = _controller.text.trim();
    if (text.isEmpty || _isSubmitting) {
      return;
    }
    setState(() => _isSubmitting = true);

    try {
      final Comment target = widget.target;
      final String? parentId = target.parentCommentId?.isNotEmpty == true
          ? target.parentCommentId
          : target.id;
      await widget.repository.addComment(
        widget.postId,
        text,
        parentCommentId: parentId,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('답글을 저장하지 못했어요. 잠시 후 다시 시도해주세요.')),
        );
    }
  }
}
