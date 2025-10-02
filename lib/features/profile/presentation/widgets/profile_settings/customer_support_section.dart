/// Customer Support Section Widget
///
/// Provides UI for customer support features.
///
/// **Purpose**:
/// - Allow users to send feedback to developers
/// - Provide contact information
/// - Report bugs and suggest improvements
///
/// **Features**:
/// - Feedback dialog with validation
/// - Email integration via mailto URL
/// - User information auto-included in feedback
/// - Loading state during email composition
/// - Success/error feedback
///
/// **Feedback Process**:
/// 1. User clicks "피드백 보내기"
/// 2. Dialog opens with text field
/// 3. Validates minimum length (10 characters)
/// 4. Composes mailto URL with user info
/// 5. Opens email client
/// 6. Shows success/error message
///
/// **Email Format**:
/// - To: hanisoft2022@gmail.com
/// - Subject: [공무톡] 사용자 피드백
/// - Body: User info + feedback content

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../auth/presentation/cubit/auth_cubit.dart';
import 'settings_section.dart';

/// Customer support section with feedback functionality
class CustomerSupportSection extends StatelessWidget {
  const CustomerSupportSection({
    super.key,
    required this.showMessage,
  });

  final void Function(BuildContext context, String message) showMessage;

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: '고객 지원',
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.feedback_outlined),
          title: const Text('피드백 보내기'),
          subtitle: const Text('개선 사항이나 문제를 신고해주세요.'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showFeedbackDialog(context),
        ),
      ],
    );
  }

  /// Shows feedback dialog with form validation
  void _showFeedbackDialog(BuildContext context) {
    final TextEditingController feedbackController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('피드백 보내기'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('개선 사항이나 문제점을 알려주세요.'),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: feedbackController,
                      maxLines: 5,
                      enabled: !isLoading,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '피드백 내용을 입력해주세요.';
                        }
                        if (value.trim().length < 10) {
                          return '10글자 이상 입력해주세요.';
                        }
                        return null;
                      },
                      decoration: const InputDecoration(
                        hintText: '의견을 자유롭게 작성해주세요...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                  child: const Text('취소'),
                ),
                FilledButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (formKey.currentState?.validate() ?? false) {
                            setState(() => isLoading = true);
                            try {
                              await _sendFeedbackEmail(
                                context,
                                feedbackController.text.trim(),
                              );
                              if (context.mounted) {
                                Navigator.of(context).pop();
                                showMessage(
                                  context,
                                  '피드백이 전송되었습니다. 감사합니다!',
                                );
                              }
                            } catch (error) {
                              if (context.mounted) {
                                setState(() => isLoading = false);
                                showMessage(
                                  context,
                                  '피드백 전송 중 오류가 발생했습니다: $error',
                                );
                              }
                            }
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('전송'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Sends feedback email via mailto URL
  Future<void> _sendFeedbackEmail(
    BuildContext context,
    String feedback,
  ) async {
    final AuthState authState = context.read<AuthCubit>().state;
    final String userEmail = authState.email ?? 'anonymous@example.com';
    final String userName =
        authState.nickname.isNotEmpty ? authState.nickname : '익명 사용자';

    // 이메일 제목과 본문 구성
    final String subject = Uri.encodeComponent('[공무톡] 사용자 피드백');
    final String body = Uri.encodeComponent('''
안녕하세요, 공무톡 개발팀입니다.

사용자로부터 다음과 같은 피드백을 받았습니다.

--- 사용자 정보 ---
이름: $userName
이메일: $userEmail
작성 시간: ${DateTime.now().toString()}

--- 피드백 내용 ---
$feedback

---
이 메시지는 공무톡 앱에서 자동으로 생성되었습니다.
    ''');

    // mailto URL 구성
    final String mailtoUrl =
        'mailto:hanisoft2022@gmail.com?subject=$subject&body=$body';
    final Uri uri = Uri.parse(mailtoUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw Exception(
        '이메일 앱을 열 수 없습니다. 기기에 이메일 앱이 설치되어 있는지 확인해주세요.',
      );
    }
  }
}
