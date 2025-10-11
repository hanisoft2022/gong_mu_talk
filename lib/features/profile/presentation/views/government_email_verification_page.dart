/// Government Email Verification Page
///
/// Dedicated page for government email verification with:
/// - Comprehensive information about benefits
/// - Email input with validation
/// - Verification email sending
/// - Status refresh functionality
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/cubit/auth_cubit.dart';

class GovernmentEmailVerificationPage extends StatefulWidget {
  const GovernmentEmailVerificationPage({super.key});

  @override
  State<GovernmentEmailVerificationPage> createState() => _GovernmentEmailVerificationPageState();
}

class _GovernmentEmailVerificationPageState extends State<GovernmentEmailVerificationPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('공직자 통합 메일 인증')),
      body: BlocConsumer<AuthCubit, AuthState>(
        listenWhen: (previous, current) =>
            previous.lastMessage != current.lastMessage && current.lastMessage != null,
        listener: (context, authState) {
          final String? message = authState.lastMessage;
          if (message == null || message.isEmpty) {
            return;
          }
          _showMessage(context, message);
          context.read<AuthCubit>().clearLastMessage();
        },
        builder: (context, state) {
          final bool isLoading = state.isGovernmentEmailVerificationInProgress;
          final bool isVerified = state.isGovernmentEmailVerified;

          // 이미 인증 완료된 경우
          if (isVerified) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('✅', style: TextStyle(fontSize: 80)),
                    const Gap(24),
                    Text(
                      '공직자 통합 메일 인증 완료',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    const Gap(12),
                    Text(
                      '확장 기능을 모두 이용할 수 있습니다.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const Gap(32),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('확인'),
                    ),
                  ],
                ),
              ),
            );
          }

          // 인증 미완료 - 인증 폼 표시
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 헤더 섹션
                  const Center(child: Text('✉️', style: TextStyle(fontSize: 64))),
                  const Gap(16),
                  Center(
                    child: Text(
                      '공직자 통합 메일 인증',
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Gap(8),
                  Center(
                    child: Text(
                      '커뮤니티, 매칭 등 확장 기능을 이용하세요',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const Gap(32),

                  // 혜택 안내 카드
                  _buildBenefitsCard(theme, colorScheme),
                  const Gap(24),

                  // 인증 방법 안내 카드
                  _buildMethodsCard(theme, colorScheme),
                  const Gap(24),

                  // 직렬 인증 안내 카드
                  _buildCareerTrackHintCard(theme, colorScheme),
                  const Gap(32),

                  // 이메일 입력 폼
                  Text(
                    '이메일 주소 입력',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const Gap(12),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: '공무원 메일 주소',
                      hintText: 'example@korea.kr',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: _validateGovernmentEmail,
                  ),
                  const Gap(20),

                  // 인증 메일 보내기 버튼
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: isLoading ? null : _submit,
                      icon: isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_outlined),
                      label: const Text('인증 메일 보내기'),
                    ),
                  ),
                  const Gap(12),

                  // 상태 새로고침 버튼
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: isLoading
                          ? null
                          : () => context.read<AuthCubit>().refreshAuthStatus(),
                      icon: const Icon(Icons.refresh_outlined),
                      label: const Text('메일 확인 후 상태 새로고침'),
                    ),
                  ),
                  const Gap(24),

                  // 안내 사항
                  _buildNoticeCard(theme, colorScheme),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBenefitsCard(ThemeData theme, ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('⭐', style: TextStyle(fontSize: 20)),
                const Gap(8),
                Text(
                  '인증 시 이용 가능한 기능',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const Gap(12),
            _buildBenefitItem(
              emoji: '💬',
              title: '라운지 글/댓글 작성',
              description: '전체 라운지와 직렬별 라운지에서 자유롭게 소통',
            ),
            const Gap(8),
            _buildBenefitItem(
              emoji: '📊',
              title: '급여 계산기 상세 분석',
              description: '월별/연별 분석, 5-10년 시뮬레이션 이용 가능',
            ),
            const Gap(8),
            _buildBenefitItem(
              emoji: '👥',
              title: '커뮤니티 확장 기능',
              description: '프로필, 팔로우, 매칭 등 다양한 커뮤니티 기능',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitItem({
    required String emoji,
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const Gap(12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              const Gap(4),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMethodsCard(ThemeData theme, ColorScheme colorScheme) {
    return Card(
      color: colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('ℹ️', style: TextStyle(fontSize: 20)),
                const Gap(8),
                Text(
                  '인증 가능한 이메일',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const Gap(12),
            _buildMethodItem('공무원 통합 메일: @korea.kr'),
            _buildMethodItem('정부기관 메일: .go.kr'),
            _buildMethodItem('공직자메일 서비스: @naver.com'),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodItem(String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, size: 18, color: theme.colorScheme.primary),
          const Gap(8),
          Text(text, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildCareerTrackHintCard(ThemeData theme, ColorScheme colorScheme) {
    return Card(
      color: colorScheme.primaryContainer.withValues(alpha: 0.3),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: InkWell(
        onTap: () => context.push('/profile/verify-paystub'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text('💡', style: TextStyle(fontSize: 24)),
              const Gap(12),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
                    children: [
                      TextSpan(
                        text: '직렬 인증',
                        style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary),
                      ),
                      const TextSpan(text: '을 완료하시면\n메일 인증 없이도 바로 커뮤니티를 이용하실 수 있습니다.'),
                    ],
                  ),
                ),
              ),
              const Gap(8),
              Icon(Icons.arrow_forward_ios, size: 16, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoticeCard(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🔒', style: TextStyle(fontSize: 20)),
              const Gap(8),
              Text(
                '안내사항',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const Gap(8),
          Text(
            '• 인증 메일에 포함된 링크를 24시간 이내에 열어야 합니다.\n'
            '• 링크를 열면 계정 이메일이 공무원 메일로 변경되지만, '
            '기존에 사용하던 로그인 방식(이메일 또는 소셜 계정)은 계속 사용할 수 있습니다.\n'
            '• 본인의 공무원 메일만 인증 가능합니다.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  void _submit() {
    final FormState? form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    final String email = _emailController.text.trim();
    context.read<AuthCubit>().requestGovernmentEmailVerification(email: email);
  }

  String? _validateGovernmentEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '공무원 메일 주소를 입력해주세요.';
    }

    final String email = value.trim().toLowerCase();
    // 임시로 @naver.com 도메인도 허용
    if (!email.endsWith('@korea.kr') &&
        !email.endsWith('.go.kr') &&
        !email.endsWith('@naver.com')) {
      return '공무원 메일(@korea.kr, .go.kr) 또는 공직자메일 서비스(@naver.com) 주소만 인증할 수 있습니다.';
    }

    return null;
  }
}
