import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:gong_mu_talk/core/utils/number_formatter.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/retirement_benefit.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/early_retirement_bonus.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/teacher_profile.dart';
import 'package:gong_mu_talk/features/calculator/presentation/views/retirement_lumpsum_detail_page.dart';

/// 퇴직 시 일시금 총액 카드 (퇴직급여 + 명예퇴직금 통합)
class RetirementLumpsumCard extends StatelessWidget {
  final bool isLocked;
  final RetirementBenefit? retirementBenefit;
  final EarlyRetirementBonus? earlyRetirementBonus;
  final TeacherProfile? profile;

  const RetirementLumpsumCard({
    super.key,
    required this.isLocked,
    this.retirementBenefit,
    this.earlyRetirementBonus,
    this.profile,
  });

  @override
  Widget build(BuildContext context) {
    // 총 일시금 계산
    final totalLumpsum =
        (retirementBenefit?.totalBenefit ?? 0) + (earlyRetirementBonus?.totalAmount ?? 0);

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
                // 잠금 상태
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.lock_outline, size: 48, color: Colors.grey[400]),
                      const Gap(8),
                      Text(
                        '정보 입력 후 이용 가능',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                )
              else if (retirementBenefit != null)
                // 활성화 상태
                Column(
                  children: [
                    // 메인 강조: 총 일시금
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.orange.withValues(alpha: 0.2),
                            Colors.orange.withValues(alpha: 0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.withValues(alpha: 0.4), width: 2),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '퇴직 시 수령 총액',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.orange[900],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Gap(12),
                          Text(
                            NumberFormatter.formatCurrency(totalLumpsum),
                            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[900],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Gap(20),

                    // 상세 페이지 버튼
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RetirementLumpsumDetailPage(
                                retirementBenefit: retirementBenefit!,
                                earlyRetirementBonus: earlyRetirementBonus,
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
  }
}
