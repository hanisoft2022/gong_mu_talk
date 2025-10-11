/// Paystub Verification Success Page
///
/// Full-screen celebration page shown when paystub verification succeeds.
/// Similar to government email verification success, but tailored for career track verification.
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../domain/career_track.dart';

class PaystubVerificationSuccessPage extends StatelessWidget {
  const PaystubVerificationSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('직렬 인증 완료'), automaticallyImplyLeading: false),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          final CareerTrack careerTrack = state.careerTrack;
          final bool hasCareerTrack = careerTrack != CareerTrack.none;

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Celebration emoji
                  const Text('🎉', style: TextStyle(fontSize: 80)),
                  const Gap(24),

                  // Success title
                  Text(
                    '직렬 인증 완료!',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Gap(16),

                  // Detected career track
                  if (hasCareerTrack) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(careerTrack.emoji, style: const TextStyle(fontSize: 24)),
                          const Gap(12),
                          Text(
                            '${careerTrack.displayName}(으)로 인증되었습니다',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Gap(32),
                  ] else
                    const Gap(32),

                  // Benefits cards
                  _buildBenefitsSection(theme, colorScheme),
                  const Gap(32),

                  // Lounge access info
                  _buildLoungeAccessCard(theme, colorScheme),
                  const Gap(32),

                  // Back to profile button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        // Pop all routes until profile page
                        context.go('/profile');
                      },
                      icon: const Icon(Icons.person_outline),
                      label: const Text('프로필로 돌아가기'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBenefitsSection(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '이용 가능한 기능',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const Gap(16),
        _buildBenefitCard(
          theme,
          colorScheme,
          icon: Icons.forum_outlined,
          title: '전문 라운지 접근',
          description: '같은 직렬 공무원들과 소통할 수 있는 전용 라운지를 이용하세요',
        ),
        const Gap(12),
        _buildBenefitCard(
          theme,
          colorScheme,
          icon: Icons.calculate_outlined,
          title: '모든 계산기 기능',
          description: '급여, 연금, 퇴직금 등 모든 계산기의 상세 기능을 이용하세요',
        ),
        const Gap(12),
        _buildBenefitCard(
          theme,
          colorScheme,
          icon: Icons.auto_graph_outlined,
          title: '상세 연금 데이터',
          description: '예상 연금액, 월별 분석 등 민감한 정보를 열람하세요',
        ),
      ],
    );
  }

  Widget _buildBenefitCard(
    ThemeData theme,
    ColorScheme colorScheme, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: colorScheme.primary, size: 24),
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const Gap(4),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoungeAccessCard(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.tertiaryContainer,
            colorScheme.tertiaryContainer.withValues(alpha: 0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.tertiary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.verified_user, color: colorScheme.tertiary, size: 28),
              const Gap(12),
              Expanded(
                child: Text(
                  '라운지 접근 권한 부여됨',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.tertiary,
                  ),
                ),
              ),
            ],
          ),
          const Gap(16),
          Row(
            children: [
              Icon(Icons.check_circle, color: colorScheme.tertiary, size: 18),
              const Gap(8),
              Expanded(child: Text('전체 라운지', style: theme.textTheme.bodyMedium)),
            ],
          ),
          const Gap(8),
          Row(
            children: [
              Icon(Icons.check_circle, color: colorScheme.tertiary, size: 18),
              const Gap(8),
              Expanded(child: Text('직렬별 전문 라운지', style: theme.textTheme.bodyMedium)),
            ],
          ),
          const Gap(8),
          Row(
            children: [
              Icon(Icons.check_circle, color: colorScheme.tertiary, size: 18),
              const Gap(8),
              Expanded(child: Text('세부 직렬 라운지 (해당 시)', style: theme.textTheme.bodyMedium)),
            ],
          ),
        ],
      ),
    );
  }
}
