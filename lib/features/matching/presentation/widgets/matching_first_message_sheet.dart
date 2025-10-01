import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class MatchingFirstMessageSheet extends StatefulWidget {
  const MatchingFirstMessageSheet({super.key, required this.prompts});

  final List<String> prompts;

  @override
  State<MatchingFirstMessageSheet> createState() => _MatchingFirstMessageSheetState();
}

class _MatchingFirstMessageSheetState extends State<MatchingFirstMessageSheet> {
  String? _selectedPrompt;
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    if (widget.prompts.length == 1) {
      _selectedPrompt = widget.prompts.first;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canSubmit => _selectedPrompt != null && _controller.text.trim().isNotEmpty;

  void _handleSubmit() {
    if (!_canSubmit) {
      return;
    }
    Navigator.of(
      context,
    ).pop(FirstMessageSelection(prompt: _selectedPrompt!, answer: _controller.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sheet Handle Section
              _buildSheetHandle(theme),
              const Gap(16),

              // Header Section
              Text(
                '관심 보내기',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Gap(8),
              Text('서로 묻고 싶은 질문 중 하나를 골라 답변을 함께 보내주세요.', style: theme.textTheme.bodyMedium),
              const Gap(16),

              // Prompt Options Section
              ...widget.prompts.map(_buildPromptOption),
              const Gap(12),

              // Answer Input Section
              TextField(
                controller: _controller,
                maxLines: 4,
                maxLength: 200,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  labelText: '내 답변',
                  hintText: '상대가 대화를 이어갈 수 있도록 진심을 담아 적어주세요.',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const Gap(12),

              // Info Section
              _buildInfoSection(theme),
              const Gap(20),

              // Submit Button Section
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: _canSubmit ? _handleSubmit : null,
                      child: const Text('첫 질문과 함께 관심 보내기'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== UI Components ====================

  Widget _buildSheetHandle(ThemeData theme) {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: theme.colorScheme.outlineVariant,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildPromptOption(String prompt) {
    final ThemeData theme = Theme.of(context);
    final bool isSelected = _selectedPrompt == prompt;
    final Color borderColor = isSelected
        ? theme.colorScheme.primary
        : theme.colorScheme.outlineVariant;
    final Color iconColor = isSelected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => _selectedPrompt = prompt),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Text(prompt, style: theme.textTheme.bodyMedium),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(ThemeData theme) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.timer_outlined, size: 18, color: theme.colorScheme.primary),
            const Gap(8),
            Expanded(
              child: Text(
                '상대는 24시간 내에 응답하도록 1회 리마인드를 받아요. 응답이 없으면 "예의 있게 종료" 버튼이 활성화돼요.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const Gap(8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.report_outlined, size: 18, color: theme.colorScheme.primary),
            const Gap(8),
            Expanded(
              child: Text(
                '무례함·불법 권유·외부 연락 강요는 신고/차단해주세요. 누적 신고 시 자동 제재가 적용됩니다.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ==================== Data Models ====================

class FirstMessageSelection {
  const FirstMessageSelection({required this.prompt, required this.answer});

  final String prompt;
  final String answer;
}
