/// Government Email Verification Card
///
/// Simple prompt card that navigates to dedicated verification page.
/// - Shows verification status
/// - Navigates to full verification page on tap
///
/// Phase 5 - Simplified to navigation-only card
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../auth/presentation/cubit/auth_cubit.dart';

class GovernmentEmailVerificationCard extends StatelessWidget {
  const GovernmentEmailVerificationCard({super.key});

  /// 인증 페이지 경로
  static const String verificationRoute = '/profile/government-email-verification';

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final bool isVerified = state.isGovernmentEmailVerified;

        // 인증 완료 - 완료 카드 표시
        if (isVerified) {
          return Card(
            color: colorScheme.primaryContainer,
            child: InkWell(
              onTap: () => context.push(verificationRoute),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.verified_outlined, color: colorScheme.onPrimaryContainer, size: 28),
                    const Gap(12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '공직자 통합 메일 인증 완료',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                          Text(
                            '확장 기능을 모두 이용할 수 있습니다',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: colorScheme.onPrimaryContainer),
                  ],
                ),
              ),
            ),
          );
        }

        // 인증 미완료 - 프롬프트 카드 표시
        return Card(
          child: InkWell(
            onTap: () => context.push(verificationRoute),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.mark_email_unread_outlined, color: colorScheme.primary, size: 28),
                      const Gap(12),
                      Expanded(
                        child: Text(
                          '공직자 통합 메일 인증',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
                    ],
                  ),
                  const Gap(8),
                  Text(
                    '커뮤니티, 계산기 상세 분석 등 확장 기능을 이용하세요',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Gap(12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lightbulb_outline, size: 18, color: colorScheme.primary),
                        const Gap(8),
                        Expanded(
                          child: Text(
                            '직렬 인증을 완료하시면 메일 인증 없이도 바로 커뮤니티를 이용하실 수 있습니다',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
