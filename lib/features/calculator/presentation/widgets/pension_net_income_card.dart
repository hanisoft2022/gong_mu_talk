import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:gong_mu_talk/core/utils/number_formatter.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/pension_estimate.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/after_tax_pension.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/teacher_profile.dart';
import 'package:gong_mu_talk/features/calculator/presentation/views/pension_detail_page.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/feature_access_level.dart';
import 'package:gong_mu_talk/core/theme/app_color_extension.dart';
import 'package:gong_mu_talk/features/auth/presentation/cubit/auth_cubit.dart';
import 'dart:ui';

/// 퇴직 후 연금 실수령액 카드 (3단계 공개 전략)
///
/// - Guest/Member (Level 0-1): 카드 표시, 숫자 블러 처리
/// - Email Verified (Level 2): 숫자 공개, 상세 분석 버튼 활성화
/// - Career Verified (Level 3): 전체 접근 가능
class PensionNetIncomeCard extends StatelessWidget {
  final bool isLocked;
  final PensionEstimate? pensionEstimate;
  final AfterTaxPension? afterTaxPension;
  final TeacherProfile? profile;

  const PensionNetIncomeCard({
    super.key,
    required this.isLocked,
    this.pensionEstimate,
    this.afterTaxPension,
    this.profile,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        final currentLevel = authState.currentAccessLevel;
        final canSeeNumbers = currentLevel >= FeatureAccessLevel.emailVerified;

        return Card(
          elevation: 2,
          child: Opacity(
            opacity: isLocked ? 0.5 : 1.0,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isLocked)
                    // 정보 미입력 상태
                    Center(
                      child: Column(
                        children: [
                          Icon(Icons.lock_outline, size: 48, color: colorScheme.outline),
                          const Gap(8),
                          Text(
                            '정보 입력 후 이용 가능',
                            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  else if (pensionEstimate != null && afterTaxPension != null)
                    // 정보 입력 완료 - 3단계 공개 전략
                    Column(
                      children: [
                        // 메인 강조: 세후 월 실수령액
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                context.appColors.successLight.withValues(alpha: 0.2),
                                context.appColors.successLight.withValues(alpha: 0.1),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: context.appColors.success.withValues(alpha: 0.4),
                              width: 2,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '월 실수령액 (세후)',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: context.appColors.successDark,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Gap(12),
                              // 숫자 표시 (Level 0-1: 블러, Level 2+: 공개)
                              if (canSeeNumbers)
                                Text(
                                  NumberFormatter.formatCurrency(
                                    afterTaxPension!.monthlyPensionAfterTax,
                                  ),
                                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: context.appColors.successDark,
                                  ),
                                )
                              else
                                // Guest/Member: 블러 처리된 숫자
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    ImageFiltered(
                                      imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                      child: Text(
                                        '₩ 3,456,789',
                                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: context.appColors.successDark,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.lock_outline,
                                      size: 32,
                                      color: context.appColors.successDark.withValues(alpha: 0.7),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),

                        const Gap(20),

                        // 수령 기간 및 총액
                        _buildInfoRow(
                          context,
                          '📅 수령 기간',
                          canSeeNumbers
                              ? '${pensionEstimate!.retirementAge}세~${pensionEstimate!.lifeExpectancy}세 (${pensionEstimate!.receivingYears}년)'
                              : '••세~••세 (••년)',
                          isBlurred: !canSeeNumbers,
                        ),

                        const Gap(12),

                        _buildInfoRow(
                          context,
                          '💰 총 수령 예상액',
                          canSeeNumbers
                              ? NumberFormatter.formatCurrency(pensionEstimate!.totalPension)
                              : '₩ •,•••,•••,•••',
                          isHighlight: true,
                          isBlurred: !canSeeNumbers,
                        ),

                        const Gap(20),

                        // 연금 공백 경고 (62세 정년인 경우, Level 2+ 공개)
                        if (canSeeNumbers && pensionEstimate!.retirementAge == 62)
                          _buildPensionGapWarning(context),

                        // 상세 페이지 버튼 (모든 레벨 접근 가능, 페이지 내부에서 블러 처리)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PensionDetailPage(
                                    pensionEstimate: pensionEstimate!,
                                    afterTaxPension: afterTaxPension,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.analytics, size: 18),
                            label: const Text('상세 분석'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value, {
    bool isHighlight = false,
    bool isBlurred = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isHighlight ? context.appColors.successDark : colorScheme.onSurfaceVariant,
            fontWeight: isHighlight ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        if (isBlurred)
          // 블러 처리된 텍스트
          Stack(
            alignment: Alignment.centerRight,
            children: [
              ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                child: Text(
                  value,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isHighlight ? context.appColors.success : context.appColors.success,
                  ),
                ),
              ),
              Icon(
                Icons.lock_outline,
                size: 14,
                color: (isHighlight ? context.appColors.success : context.appColors.success)
                    .withValues(alpha: 0.7),
              ),
            ],
          )
        else
          // 일반 텍스트
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isHighlight ? context.appColors.success : context.appColors.success,
            ),
          ),
      ],
    );
  }

  Widget _buildPensionGapWarning(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.appColors.warningLight.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.appColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, size: 20, color: context.appColors.warning),
          const Gap(8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '연금 공백 주의',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: context.appColors.warningDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '62~65세 사이 3년간 연금 수령 불가',
                  style: TextStyle(fontSize: 12, color: context.appColors.warning),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
