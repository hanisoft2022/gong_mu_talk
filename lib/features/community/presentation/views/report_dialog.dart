import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import '../../../../core/utils/snackbar_helpers.dart';
import '../../data/community_repository.dart';
import '../../domain/models/report.dart';

class ReportDialog extends StatefulWidget {
  const ReportDialog({
    super.key,
    required this.targetType,
    required this.targetId,
    this.targetAuthor,
  });

  final ReportTargetType targetType;
  final String targetId;
  final String? targetAuthor;

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  String? _selectedReason;
  final TextEditingController _detailController = TextEditingController();
  bool _isSubmitting = false;

  final Map<String, String> _reasons = {
    'inappropriate_content': '부적절한 내용',
    'spam': '스팸 또는 도배',
    'harassment': '괴롭힘 또는 혐오 발언',
    'false_information': '거짓 정보',
    'copyright_violation': '저작권 침해',
    'personal_information': '개인정보 노출',
    'other': '기타',
  };

  @override
  void dispose() {
    _detailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String targetName = widget.targetType == ReportTargetType.post
        ? '게시글'
        : '댓글';

    return AlertDialog(
      title: Text('$targetName 신고'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '이 $targetName을 신고하는 이유를 선택해주세요:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Gap(16),
            ..._reasons.entries.map(
              (entry) => ListTile(
                title: Text(entry.value),
                leading: Icon(
                  _selectedReason == entry.key
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: _selectedReason == entry.key
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                onTap: _isSubmitting
                    ? null
                    : () {
                        setState(() {
                          _selectedReason = entry.key;
                        });
                      },
                contentPadding: EdgeInsets.zero,
              ),
            ),
            if (_selectedReason != null) ...[
              const Gap(16),
              TextField(
                controller: _detailController,
                decoration: const InputDecoration(
                  labelText: '상세 설명 (선택사항)',
                  hintText: '추가 설명이 있다면 입력해주세요...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                enabled: !_isSubmitting,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context, false),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: _canSubmit && !_isSubmitting ? _submitReport : null,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('신고'),
        ),
      ],
    );
  }

  bool get _canSubmit => _selectedReason != null;

  Future<void> _submitReport() async {
    if (!_canSubmit) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final repository = context.read<CommunityRepository>();

      await repository.submitReport(
        targetType: widget.targetType,
        targetId: widget.targetId,
        reason: _selectedReason!,
        reporterUid: repository.currentUserId,
        metadata: {
          'detail': _detailController.text.trim(),
          'targetAuthor': widget.targetAuthor,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelpers.showError(context, '신고 접수 중 오류가 발생했습니다. 다시 시도해주세요.');
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}

// Utility function to show report dialog
Future<bool> showReportDialog({
  required BuildContext context,
  required ReportTargetType targetType,
  required String targetId,
  String? targetAuthor,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => ReportDialog(
      targetType: targetType,
      targetId: targetId,
      targetAuthor: targetAuthor,
    ),
  );

  return result ?? false;
}
