import 'package:flutter/material.dart';
import 'package:gong_mu_talk/core/utils/number_formatter.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/retirement_benefit.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/early_retirement_bonus.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/teacher_profile.dart';
import 'package:gong_mu_talk/features/calculator/presentation/views/retirement_lumpsum_detail_page.dart';
import 'package:gong_mu_talk/features/calculator/presentation/widgets/calculation_source_badge.dart';
import 'package:gong_mu_talk/features/calculator/presentation/widgets/calculation_breakdown_section.dart';

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
    final totalLumpsum = (retirementBenefit?.totalBenefit ?? 0) +
        (earlyRetirementBonus?.totalAmount ?? 0);

    final hasEarlyBonus = earlyRetirementBonus != null &&
        earlyRetirementBonus!.totalAmount > 0;

    return Card(
      elevation: 2,
      child: Opacity(
        opacity: isLocked ? 0.5 : 1.0,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isLocked
                          ? Colors.grey.withValues(alpha: 0.1)
                          : Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.account_balance,
                      size: 28,
                      color: isLocked ? Colors.grey : Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '퇴직 시 일시금 총액',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  if (isLocked) const Icon(Icons.lock, color: Colors.grey),
                ],
              ),

              const SizedBox(height: 12),

              // 신뢰 배지
              if (!isLocked)
                const CalculationSourceBadge(
                  source: '공무원 보수규정 퇴직급여',
                  year: '2025',
                ),

              const SizedBox(height: 20),

              if (isLocked)
                // 잠금 상태
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '정보 입력 후 이용 가능',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
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
                        border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.4),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.diamond,
                                color: Colors.orange[800],
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '퇴직 시 수령 총액',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: Colors.orange[900],
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
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

                    const SizedBox(height: 20),

                    // 상세 내역 (Expandable)
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: Row(
                        children: [
                          Icon(
                            Icons.list_alt,
                            size: 20,
                            color: Colors.grey[700],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '상세 내역 보기',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[800],
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              // 퇴직급여
                              _buildDetailSection(
                                context,
                                title: '📋 퇴직급여',
                                amount: retirementBenefit!.totalBenefit,
                                children: [
                                  if (retirementBenefit!.period1Years > 0)
                                    _buildDetailRow(
                                      context,
                                      '1기간 (${retirementBenefit!.period1Years}년)',
                                      retirementBenefit!.period1Benefit,
                                    ),
                                  if (retirementBenefit!.period2Years > 0)
                                    _buildDetailRow(
                                      context,
                                      '2기간 (${retirementBenefit!.period2Years}년)',
                                      retirementBenefit!.period2Benefit,
                                    ),
                                  if (retirementBenefit!.period3Years > 0)
                                    _buildDetailRow(
                                      context,
                                      '3기간 (${retirementBenefit!.period3Years}년)',
                                      retirementBenefit!.period3Benefit,
                                    ),
                                  const Divider(height: 16),
                                  _buildDetailRow(
                                    context,
                                    '퇴직수당',
                                    retirementBenefit!.retirementAllowance,
                                  ),
                                ],
                              ),

                              // 명예퇴직금 (있는 경우만)
                              if (hasEarlyBonus) ...[
                                const SizedBox(height: 16),
                                _buildDetailSection(
                                  context,
                                  title: '🎁 명예퇴직금',
                                  amount: earlyRetirementBonus!.totalAmount,
                                  color: Colors.purple,
                                  children: [
                                    _buildDetailRow(
                                      context,
                                      '기본 명퇴금',
                                      earlyRetirementBonus!.baseAmount,
                                    ),
                                    if (earlyRetirementBonus!.bonusAmount > 0)
                                      _buildDetailRow(
                                        context,
                                        '가산금 (10%)',
                                        earlyRetirementBonus!.bonusAmount,
                                      ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          size: 14,
                                          color: Colors.purple[700],
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            '정년까지 ${earlyRetirementBonus!.remainingYears}년 ${earlyRetirementBonus!.remainingMonths}개월 잔여',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.purple[700],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // 계산 근거 섹션
                    if (retirementBenefit != null)
                      _buildCalculationBreakdown(context),

                    const SizedBox(height: 16),

                    // 안내 메시지
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.blue.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            size: 16,
                            color: Colors.blue[700],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '퇴직 시점에 일시금으로 수령하는 금액입니다.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

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
                        label: const Text('상세 계산 로직 보기'),
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

  Widget _buildCalculationBreakdown(BuildContext context) {
    if (retirementBenefit == null) return const SizedBox.shrink();

    final items = <BreakdownItem>[
      BreakdownItem(
        label: '퇴직급여',
        amount: retirementBenefit!.totalBenefit,
        description: '평균보수 × 재직월수 ÷ 12',
      ),
    ];

    // 기간별 상세
    if (retirementBenefit!.period1Years > 0) {
      items.add(BreakdownItem(
        label: '  └ 1기간 (${retirementBenefit!.period1Years}년)',
        amount: retirementBenefit!.period1Benefit,
        description: '2009.12.31 이전',
      ));
    }
    if (retirementBenefit!.period2Years > 0) {
      items.add(BreakdownItem(
        label: '  └ 2기간 (${retirementBenefit!.period2Years}년)',
        amount: retirementBenefit!.period2Benefit,
        description: '2010.1.1 ~ 2015.12.31',
      ));
    }
    if (retirementBenefit!.period3Years > 0) {
      items.add(BreakdownItem(
        label: '  └ 3기간 (${retirementBenefit!.period3Years}년)',
        amount: retirementBenefit!.period3Benefit,
        description: '2016.1.1 이후',
      ));
    }

    // 퇴직수당
    if (retirementBenefit!.retirementAllowance > 0) {
      items.add(BreakdownItem(
        label: '퇴직수당',
        amount: retirementBenefit!.retirementAllowance,
        description: '재직기간별 가산금',
      ));
    }

    // 명예퇴직금
    if (earlyRetirementBonus != null && earlyRetirementBonus!.totalAmount > 0) {
      items.add(BreakdownItem(
        label: '명예퇴직금',
        amount: earlyRetirementBonus!.totalAmount,
        description: '정년 ${earlyRetirementBonus!.remainingYears}년 전 퇴직',
        icon: Icons.card_giftcard,
        isHighlight: true,
      ));
    }

    final totalLumpsum = (retirementBenefit?.totalBenefit ?? 0) +
        (earlyRetirementBonus?.totalAmount ?? 0);

    return CalculationBreakdownSection(
      items: items,
      totalAmount: totalLumpsum,
      totalLabel: '퇴직 시 일시금 총액',
    );
  }

  Widget _buildDetailSection(
    BuildContext context, {
    required String title,
    required int amount,
    required List<Widget> children,
    MaterialColor color = Colors.orange,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color[900],
                  ),
            ),
            Text(
              NumberFormatter.formatCurrency(amount),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color[800],
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, int amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '  • $label',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[700],
                ),
          ),
          Text(
            NumberFormatter.formatCurrency(amount),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
          ),
        ],
      ),
    );
  }
}
