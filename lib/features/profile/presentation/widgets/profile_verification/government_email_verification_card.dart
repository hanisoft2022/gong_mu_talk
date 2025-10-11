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
import 'verification_card_base.dart';

/// Variant for GovernmentEmailVerificationCard
enum EmailVerificationCardVariant {
  /// Full variant: Shows detailed info and hint card
  full,

  /// Compact variant: Shows minimal info, used in tight spaces (e.g., InlinePostComposer)
  compact,
}

class GovernmentEmailVerificationCard extends StatelessWidget {
  const GovernmentEmailVerificationCard({
    super.key,
    this.variant = EmailVerificationCardVariant.full,
  });

  final EmailVerificationCardVariant variant;

  /// 인증 페이지 경로
  static const String verificationRoute = '/profile/government-email-verification';

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final bool isVerified = state.isGovernmentEmailVerified;

        // Compact variant: 간결한 버전
        if (variant == EmailVerificationCardVariant.compact) {
          // 인증 완료 시 카드 숨김
          if (isVerified) {
            return const SizedBox.shrink();
          }

          // 인증 미완료 - 간단한 카드만
          return VerificationCardBase(
            leadingIcon: buildIconContainer(
              context: context,
              icon: Icons.lock_outline,
              backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
              iconColor: colorScheme.primary,
            ),
            title: '공직자 메일 인증 필요',
            subtitle: '커뮤니티 기능 이용을 위해 인증하세요',
            onTap: () => context.push(verificationRoute),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: colorScheme.onSurfaceVariant,
            ),
          );
        }

        // Full variant: 상세 버전
        // 인증 완료 - 완료 카드 표시
        if (isVerified) {
          return VerificationCardBase(
            leadingIcon: buildIconContainer(
              context: context,
              icon: Icons.verified_outlined,
              backgroundColor: colorScheme.onPrimaryContainer.withValues(alpha: 0.2),
              iconColor: colorScheme.onPrimaryContainer,
            ),
            title: '공직자 통합 메일 인증 완료',
            subtitle: '확장 기능을 모두 이용할 수 있습니다',
            onTap: () => context.push(verificationRoute),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: colorScheme.onPrimaryContainer,
            ),
            backgroundColor: colorScheme.primaryContainer,
          );
        }

        // 인증 미완료 - 프롬프트 카드 표시
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            VerificationCardBase(
              leadingIcon: buildIconContainer(
                context: context,
                icon: Icons.mark_email_unread_outlined,
                backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                iconColor: colorScheme.primary,
              ),
              title: '공직자 통합 메일 인증',
              subtitle: '커뮤니티, 계산기 상세 분석 등 확장 기능을 이용하세요',
              onTap: () => context.push(verificationRoute),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
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
                  const Text('💡', style: TextStyle(fontSize: 18)),
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
        );
      },
    );
  }
}
