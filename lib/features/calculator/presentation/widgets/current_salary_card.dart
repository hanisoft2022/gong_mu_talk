import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:gong_mu_talk/core/utils/number_formatter.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/monthly_net_income.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/monthly_salary_detail.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/teacher_profile.dart';
import 'package:gong_mu_talk/features/calculator/presentation/views/salary_analysis_page.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/lifetime_salary.dart';
import 'package:gong_mu_talk/features/calculator/presentation/widgets/calculation_breakdown_section.dart';
import 'package:gong_mu_talk/features/calculator/domain/constants/salary_table.dart';

/// 현재 급여 실수령액 카드 (재직 중)
///
/// 월별 실수령액 분석 카드를 개선하여 사용자의 현재 급여를 강조
class CurrentSalaryCard extends StatelessWidget {
  final bool isLocked;
  final List<MonthlyNetIncome>? monthlyBreakdown;
  final LifetimeSalary? lifetimeSalary;
  final TeacherProfile? profile;
  final String? nickname;

  const CurrentSalaryCard({
    super.key,
    required this.isLocked,
    this.monthlyBreakdown,
    this.lifetimeSalary,
    this.profile,
    this.nickname,
  });

  @override
  Widget build(BuildContext context) {
    // 평균 계산 - 세전
    final avgGrossSalary = monthlyBreakdown != null && monthlyBreakdown!.isNotEmpty
        ? (monthlyBreakdown!.map((m) => m.grossSalary).reduce((a, b) => a + b) /
                  monthlyBreakdown!.length)
              .round()
        : 0;

    // 평균 계산 - 세후
    final avgNetIncome = monthlyBreakdown != null && monthlyBreakdown!.isNotEmpty
        ? (monthlyBreakdown!.map((m) => m.netIncome).reduce((a, b) => a + b) /
                  monthlyBreakdown!.length)
              .round()
        : 0;

    // 연간 계산 - 세전
    final annualGrossSalary = monthlyBreakdown != null && monthlyBreakdown!.isNotEmpty
        ? monthlyBreakdown!.map((m) => m.grossSalary).reduce((a, b) => a + b)
        : 0;

    // 연간 계산 - 세후
    final annualNetIncome = monthlyBreakdown != null && monthlyBreakdown!.isNotEmpty
        ? monthlyBreakdown!.map((m) => m.netIncome).reduce((a, b) => a + b)
        : 0;

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
                          : Colors.teal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet,
                      size: 28,
                      color: isLocked ? Colors.grey : Colors.teal,
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: Text(
                      '현재 급여 실수령액',
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (isLocked) const Icon(Icons.lock, color: Colors.grey),
                ],
              ),

              const Gap(12),

              const Gap(20),

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
              else if (monthlyBreakdown != null && monthlyBreakdown!.isNotEmpty)
                // 활성화 상태
                Column(
                  children: [
                    // 메인 강조: 월 평균 급여
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.teal.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.teal.withValues(alpha: 0.3), width: 1),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '월 평균 급여',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.teal[800],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Gap(12),
                          // 세전
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '세전',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                              ),
                              Text(
                                NumberFormatter.formatCurrency(avgGrossSalary),
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                          const Gap(8),
                          // 실수령액 (강조)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '실수령',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.teal[800],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                NumberFormatter.formatCurrency(avgNetIncome),
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal[900],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const Gap(12),

                    // 연간 급여
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.teal.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.teal.withValues(alpha: 0.3), width: 1),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '연간 급여',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.teal[800],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Gap(12),
                          // 세전
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '세전',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                              ),
                              Text(
                                NumberFormatter.formatCurrency(annualGrossSalary),
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                          const Gap(8),
                          // 실수령액 (강조)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '실수령',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.teal[800],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                NumberFormatter.formatCurrency(annualNetIncome),
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal[900],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const Gap(16),

                    // 계산 근거 섹션
                    if (profile != null) _buildCalculationBreakdown(context, monthlyBreakdown!),

                    const Gap(20),

                    // 액션 버튼
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: lifetimeSalary != null
                            ? () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SalaryAnalysisPage(
                                      lifetimeSalary: lifetimeSalary!,
                                      monthlyBreakdown: monthlyBreakdown,
                                    ),
                                  ),
                                );
                              }
                            : null,
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

  Widget _buildCalculationBreakdown(BuildContext context, List<MonthlyNetIncome> monthlyBreakdown) {
    // 연봉 기준 계산 (승급월 고려)
    final currentGrade = profile?.currentGrade ?? 0;
    final promotionMonth = profile?.gradePromotionMonth ?? 3;

    // 현재 날짜 기준으로 이미 승급했는지 확인
    final now = DateTime.now();
    final currentMonth = now.month;
    final hasPromoted = currentMonth >= promotionMonth;

    // 승급 전후 호봉 결정
    // - 이미 승급했으면: 현재 호봉이 승급 후 → 승급 전은 currentGrade - 1
    // - 아직 승급 안했으면: 현재 호봉이 승급 전 → 승급 후는 currentGrade + 1
    final gradeBeforePromotion = hasPromoted
        ? (currentGrade > 1 ? currentGrade - 1 : currentGrade)
        : currentGrade;
    final gradeAfterPromotion = hasPromoted
        ? currentGrade
        : (currentGrade < 40 ? currentGrade + 1 : currentGrade);

    // 승급 전후 호봉별 본봉
    final payBeforePromotion = profile != null
        ? SalaryTable.getBasePay(gradeBeforePromotion)
        : monthlyBreakdown.first.baseSalary;
    final payAfterPromotion = profile != null
        ? SalaryTable.getBasePay(gradeAfterPromotion)
        : monthlyBreakdown.first.baseSalary;

    // 승급 전 개월 수 (1월 ~ 승급월-1)
    final monthsBeforePromotion = promotionMonth - 1;
    // 승급 후 개월 수 (승급월 ~ 12월)
    final monthsAfterPromotion = 12 - monthsBeforePromotion;

    // 연간 본봉 (승급월 고려)
    final annualBasePay =
        (payBeforePromotion * monthsBeforePromotion) + (payAfterPromotion * monthsAfterPromotion);

    final annualTeachingAllowance = AllowanceTable.teachingAllowance * 12;
    final annualHomeroomAllowance = (profile?.isHomeroom ?? false)
        ? AllowanceTable.homeroomAllowance * 12
        : 0;
    final annualHeadTeacherAllowance = (profile?.hasPosition ?? false)
        ? AllowanceTable.headTeacherAllowance * 12
        : 0;

    // 시간외근무수당도 승급월 고려
    final overtimeBeforePromotion = profile != null
        ? AllowanceTable.getOvertimeAllowance(gradeBeforePromotion)
        : 0;
    final overtimeAfterPromotion = profile != null
        ? AllowanceTable.getOvertimeAllowance(gradeAfterPromotion)
        : 0;

    final annualOvertimeAllowance =
        (overtimeBeforePromotion * monthsBeforePromotion) +
        (overtimeAfterPromotion * monthsAfterPromotion);

    // 정근수당 가산금 (매월)
    final annualLongevityMonthly = monthlyBreakdown.fold<int>(
      0,
      (sum, m) => sum + m.longevityMonthly,
    );

    // 원로교사수당 (매월)
    final annualVeteranAllowance = monthlyBreakdown.fold<int>(
      0,
      (sum, m) => sum + m.veteranAllowance,
    );

    // 가족수당 (매월)
    final annualFamilyAllowance = monthlyBreakdown.fold<int>(
      0,
      (sum, m) => sum + m.familyAllowance,
    );

    // 연구비 (매월)
    final annualResearchAllowance = monthlyBreakdown.fold<int>(
      0,
      (sum, m) => sum + m.researchAllowance,
    );

    // 그 외 교직수당 가산금 (매월) - 이미 표시한 항목들 제외
    // teachingAllowanceBonuses는 특수교사, 보건교사 등 순수 교직수당 가산금만 포함
    final annualTeachingAllowanceBonuses = monthlyBreakdown.fold<int>(
      0,
      (sum, m) => sum + m.teachingAllowanceBonuses,
    );

    // 특별 수당 합산 (월별로 다름)
    final annualPerformanceBonus = monthlyBreakdown.fold<int>(
      0,
      (sum, m) => sum + m.performanceBonus,
    );
    final annualLongevityBonus = monthlyBreakdown.fold<int>(0, (sum, m) => sum + m.longevityBonus);
    final annualHolidayBonus = monthlyBreakdown.fold<int>(0, (sum, m) => sum + m.holidayBonus);

    // 세금/보험 합산
    final annualIncomeTax = monthlyBreakdown.fold<int>(0, (sum, m) => sum + m.incomeTax);
    final annualLocalTax = monthlyBreakdown.fold<int>(0, (sum, m) => sum + m.localTax);
    // 공무원연금 기여금 (연간)
    final annualPensionContribution = monthlyBreakdown.fold<int>(
      0,
      (sum, m) => sum + m.pensionContribution,
    );
    // 4대보험 (연간) - 건강보험 + 장기요양보험만 (공무원은 국민연금/고용보험 제외)
    final annualInsurance = monthlyBreakdown.fold<int>(
      0,
      (sum, m) => sum + m.healthInsurance + m.longTermCareInsurance,
    );

    final items = <BreakdownItem>[
      // 매월 지급 섹션 헤더
      BreakdownItem.sectionHeader('📅 매월 지급'),

      BreakdownItem(
        label: '📋 본봉 × 12개월',
        amount: annualBasePay,
        detailedInfo:
            '''
${nickname != null ? '$nickname 선생님' : '선생님'}의 승급월을 반영하여 계산되었습니다.

【공무원 보수규정 별표 1】
교육공무원 호봉표에 따라 지급됩니다.

【승급월 반영】
${gradeBeforePromotion != gradeAfterPromotion ? '''• 1~${promotionMonth - 1}월: $gradeBeforePromotion호봉 (${NumberFormatter.formatCurrency(payBeforePromotion)})
• $promotionMonth~12월: $gradeAfterPromotion호봉 (${NumberFormatter.formatCurrency(payAfterPromotion)})
• 승급월부터 새 호봉 적용

【연간 본봉 계산】
• 승급 전 ($gradeBeforePromotion호봉): ${NumberFormatter.formatCurrency(payBeforePromotion)} × $monthsBeforePromotion개월 = ${NumberFormatter.formatCurrency(payBeforePromotion * monthsBeforePromotion)}
• 승급 후 ($gradeAfterPromotion호봉): ${NumberFormatter.formatCurrency(payAfterPromotion)} × $monthsAfterPromotion개월 = ${NumberFormatter.formatCurrency(payAfterPromotion * monthsAfterPromotion)}
• 연간 총액: ${NumberFormatter.formatCurrency(annualBasePay)}''' : '''• 승급월: $promotionMonth월
• 연간 동일 호봉 적용 ($currentGrade호봉)

【연간 본봉 계산】
• $currentGrade호봉: ${NumberFormatter.formatCurrency(payBeforePromotion)} × 12개월 = ${NumberFormatter.formatCurrency(annualBasePay)}'''}
''',
      ),
      BreakdownItem(
        label: '📚 교직수당 × 12개월',
        amount: annualTeachingAllowance,
        detailedInfo: '''📚 교직수당

【기본 지급액】
• 월 250,000원 (연 3,000,000원)
• 모든 교육공무원 동일 지급

【교직수당 가산금 종류】
아래 가산금은 해당되는 경우 별도 항목으로 표시됩니다:

1️⃣ 담임교사 (가산금 4): 200,000원
   → "🏛️ 담임수당 × 12개월" 항목

2️⃣ 보직교사 (가산금 3): 150,000원
   → "보직교사수당 × 12개월" 항목

3️⃣ 그 외 가산금 (해당 시 별도 표시)
   • 원로교사: 50,000원 (30년 이상 + 55세 이상)
   • 특수교사: 120,000원
   • 특성화교사: 25,000~50,000원 (호봉별)
   • 보건교사: 40,000원
   • 사서교사: 30,000원
   • 영양교사: 40,000원
   • 전문상담교사: 30,000원
   • 겸직수당: 50,000~100,000원
   → "💼 그 외 교직수당 가산금 × 12개월" 항목

💡 가산금은 해당되는 경우에만 별도 항목으로 표시됩니다.''',
      ),
      if (profile?.isHomeroom ?? false)
        BreakdownItem(
          label: '🏛️ 담임수당 × 12개월',
          amount: annualHomeroomAllowance,
          detailedInfo: '''
【지급 기준】
• 월 200,000원 (연 2,400,000원)
• 담임교사에게 지급

【지급 대상】
• 학급 담임을 맡은 교사
• 초·중·고등학교 전 학년

💡 담임 배정 시 매월 지급되며, 담임 변경 시 해당 월부터 적용됩니다.''',
        ),
      if (profile?.hasPosition ?? false)
        BreakdownItem(
          label: '👔 보직교사수당 × 12개월',
          amount: annualHeadTeacherAllowance,
          detailedInfo: '''👔 보직교사수당

【지급 기준】
• 월 150,000원 (연 1,800,000원)
• 보직교사(부장)에게 지급

【지급 대상】
• 교무부장, 연구부장 등
• 학년부장, 교과부장 등
• 기타 학교 보직 담당 교사

💡 담임수당과 중복 수령 가능합니다.''',
        ),
      BreakdownItem(
        label: '🕓 시간외근무수당 × 12개월',
        amount: annualOvertimeAllowance,
        detailedInfo: '''🕓 시간외근무수당

【지급 기준】
• 호봉에 따라 차등 지급
• 정액으로 매월 지급 (실제 근무시간 무관)

【호봉별 지급액】
• 1~10호봉: 30,000원
• 11~20호봉: 40,000원
• 21~30호봉: 50,000원
• 31~40호봉: 60,000원

【지급 방식】
• 매월 급여와 함께 지급
• 실제 초과근무 시간과 무관하게 정액 지급

💡 공무원은 시간외근무수당이 정액으로 지급되며, 실제 초과근무 시간과는 별개입니다.''',
      ),
      BreakdownItem(
        label: '🎖 정근수당 가산금 × 12개월',
        amount: annualLongevityMonthly,
        detailedInfo: '''🎖 정근수당 가산금

【지급 기준】
• 매월 지급 (연 12회)
• 재직연수에 따라 차등 지급

【재직연수별 지급액】
• 5년 미만: 30,000원
• 5~10년: 50,000원
• 10~15년: 60,000원
• 15~20년: 80,000원
• 20~25년: 110,000원 (기본 10만원 + 가산금 1만원)
• 25년 이상: 130,000원 (기본 10만원 + 가산금 3만원)

【지급 방식】
• 매월 급여와 함께 지급
• 정근수당(1월/7월)과는 별도

💡 정근수당(1월/7월)은 특별 지급이며, 정근수당 가산금은 매월 지급됩니다.''',
      ),
      if (annualVeteranAllowance > 0)
        BreakdownItem(
          label: '🎓 원로교사수당 × 12개월',
          amount: annualVeteranAllowance,
          detailedInfo: '''🎓 원로교사수당

【지급 기준】
• 월 50,000원 (연 600,000원)
• 교직수당 가산금 1 해당

【지급 대상】
• 재직연수 30년 이상
• 만 55세 이상
• 두 조건 모두 충족 시 지급

【지급 방식】
• 매월 급여와 함께 지급
• 담임수당, 보직교사수당과 중복 수령 가능

💡 장기 근속 교사에 대한 예우 차원의 수당입니다.''',
        ),
      if (annualFamilyAllowance > 0)
        BreakdownItem(
          label: '👨‍👩‍👧‍👦 가족수당 × 12개월',
          amount: annualFamilyAllowance,
          detailedInfo: '''👨‍👩‍👧‍👦 가족수당

【지급 기준】
• 배우자: 40,000원
• 첫째 자녀: 50,000원
• 둘째 자녀: 80,000원
• 셋째 이상 자녀: 각 120,000원
• 60세 이상 직계존속: 1인당 20,000원 (최대 4명)

【지급 방식】
• 매월 급여와 함께 지급
• 가족관계증명서 제출 필요

💡 자녀 수가 많을수록 가산금이 증가합니다.''',
        ),
      if (annualResearchAllowance > 0)
        BreakdownItem(
          label: '📖 연구비 × 12개월',
          amount: annualResearchAllowance,
          detailedInfo: '''📖 연구비

【지급 기준】
• 5년 미만: 70,000원
• 5년 이상: 60,000원

【지급 방식】
• 매월 급여와 함께 지급
• 교육활동 및 연구 활동 지원

💡 교육 및 연구 활동을 위한 수당입니다.''',
        ),
      if (annualTeachingAllowanceBonuses > 0)
        BreakdownItem(
          label: '💼 그 외 교직수당 가산금 × 12개월',
          amount: annualTeachingAllowanceBonuses,
          detailedInfo: '''💼 그 외 교직수당 가산금

【포함 항목 예시】
• 특수교사 가산금: 120,000원
• 보건교사 가산금: 40,000원
• 사서교사 가산금: 30,000원
• 영양교사 가산금: 40,000원
• 전문상담교사 가산금: 30,000원
• 특성화교사 가산금: 25,000~50,000원 (호봉별)
• 겸직수당: 50,000~100,000원
• 기타 특수 업무 가산금

【지급 방식】
• 해당 직무 수행 시 지급
• 매월 급여와 함께 지급
• 담임수당, 보직교사수당과 중복 수령 가능

💡 특수 직무나 자격에 따라 추가로 지급되는 가산금입니다.''',
        ),

      // 특별 지급 섹션 헤더
      BreakdownItem.sectionHeader('💰 특별 지급 (연 5회)'),

      if (annualPerformanceBonus > 0)
        BreakdownItem(
          label: '⭐ 성과상여금 (3월)',
          amount: annualPerformanceBonus,
          isHighlight: true,
          detailedInfo: '''📋 성과상여금

【지급 시기】
• 매년 3월 지급

【등급별 지급액 (2025년 기준)】
⭐ S등급: 5,102,970원 (상위 30%)
⭐ A등급: 4,273,220원 (중위 50%, 기본값)
⭐ B등급: 3,650,900원 (하위 20%)

【등급 산정】
• 전년도 근무실적 평가
• 학교별 차등 배분
• 개인별 등급 통보

💡 근무성적평정 결과에 따라 매년 등급이 변동될 수 있습니다.''',
        ),
      if (annualLongevityBonus > 0)
        BreakdownItem(
          label: '🎉 정근수당 (1월, 7월)',
          amount: annualLongevityBonus,
          isHighlight: true,
          detailedInfo: '''📋 정근수당

【지급 시기】
• 매년 1월, 7월 (연 2회)

【재직연수별 지급률】
• 2년 미만: 월봉급액의 10%
• 2~5년: 월봉급액의 20%
• 5~6년: 월봉급액의 25%
• 6~7년: 월봉급액의 30%
• 7~8년: 월봉급액의 35%
• 8~9년: 월봉급액의 40%
• 9~10년: 월봉급액의 45%
• 10년 이상: 월봉급액의 50%

【정근수당 가산금 (매월 지급)】
• 5년 미만: 30,000원
• 5~10년: 50,000원
• 10~15년: 60,000원
• 15~20년: 80,000원
• 20~25년: 110,000원 (100,000원 + 가산금 10,000원)
• 25년 이상: 130,000원 (100,000원 + 가산금 30,000원)

💡 월봉급액 = 본봉 + 각종 수당 합계 기준으로 계산됩니다.
💡 정근수당(1월/7월)과 정근수당 가산금(매월)은 별도로 지급됩니다.''',
        ),
      if (annualHolidayBonus > 0)
        BreakdownItem(
          label: '🎂 명절휴가비 (설날, 추석)',
          amount: annualHolidayBonus,
          isHighlight: true,
          detailedInfo: '''📋 명절휴가비

【지급 기준】
• 본봉의 60% 지급
• 설날, 추석 (연 2회)

【지급 시기】
• 설날: 음력 설 전월 급여 시
• 추석: 음력 추석 전월 급여 시

【2025년 지급 예정월】
• 설날: 1월 급여 (음력 1/29)
• 추석: 10월 급여 (음력 10/6)

💡 음력 기준이므로 매년 지급 월이 변경될 수 있습니다.''',
        ),
    ];

    final deductions = <BreakdownItem>[
      BreakdownItem(
        label: '🏛 소득세 (연간)',
        amount: annualIncomeTax,
        isDeduction: true,
        detailedInfo: '''📋 소득세

【원천징수 방식】
• 매월 급여에서 자동 공제
• 간이세액표 기준 적용
• 연말정산으로 최종 정산

【공제율 계산】
급여 수준에 따라 자동 계산되며, 다음 요소를 반영합니다:
• 총 급여액 (본봉 + 수당)
• 부양가족 수
• 각종 공제 (연금, 보험료 등)

【세율 구간 (2025년 기준)】
• 1,400만원 이하: 6%
• 1,400~5,000만원: 15%
• 5,000~8,800만원: 24%
• 8,800만원~1.5억원: 35%
• 1.5억원~3억원: 38%
• 3억원~5억원: 40%
• 5억원 초과: 45%

💡 실제 부담률은 누진공제 적용으로 표시 세율보다 낮습니다.
💡 연말정산 시 환급/추가납부가 발생할 수 있습니다.''',
      ),
      BreakdownItem(
        label: '🏢 지방세 (연간)',
        amount: annualLocalTax,
        isDeduction: true,
        detailedInfo:
            '''📋 지방소득세

【계산 방식】
• 소득세의 10% 고정
• 지방세법 제71조

【납부 방식】
• 소득세와 함께 원천징수
• 매월 급여에서 자동 공제

【용도】
• 지방자치단체 재원
• 지역 교육·복지 사업 등

💡 소득세 = ${NumberFormatter.formatCurrency(annualIncomeTax)}
💡 지방세 = 소득세 × 10% = ${NumberFormatter.formatCurrency(annualLocalTax)}''',
      ),
      BreakdownItem(
        label: '💰 공무원연금 기여금 (연간)',
        amount: annualPensionContribution,
        isDeduction: true,
        detailedInfo: '''📋 공무원연금 기여금

【기여율】
• 본인 부담: 9%
• 국가 부담: 9%
• 총 기여금: 18% (공무원연금법)

【기준소득월액】
기여금 계산 기준이 되는 소득으로, 다음 항목을 포함:
• 본봉 ✅
• 교직수당 ✅
• 담임수당 ✅
• 보직수당 ✅
• 가족수당 ✅
• 연구비 ✅
• 정근수당 가산금 ✅
• 정근수당 (1/7월) ✅
• 명절휴가비 ✅

**제외 항목:**
• 시간외근무수당 ❌
• 성과상여금 ❌

【연금 수령】
• 재직기간 10년 이상: 연금 수령 가능
• 재직기간 10년 미만: 퇴직일시금
• 퇴직연금 지급개시: 만 60~65세 (단계적 상향)

【국민연금과의 차이】
• 교사는 공무원연금 적용 (국민연금 ❌)
• 기여율: 공무원 9% vs 국민연금 4.5%
• 연금액: 공무원연금이 상대적으로 높음

💡 2025년 기준 평균 기준소득월액: 5,710,000원
💡 연간 기여금 = 기준소득월액 × 9% × 12개월''',
      ),
      BreakdownItem(
        label: '🛡 건강보험 + 장기요양 (연간)',
        amount: annualInsurance,
        isDeduction: true,
        detailedInfo: '''📋 건강보험 및 장기요양보험

【1️⃣ 건강보험】
• 본인 부담률: 3.545% (총 7.09%, 국가 3.545%)
• 의료비 보장 (2025년 요율)
• 직장가입자 기준
• 과세 대상 소득 전체 기준

【2️⃣ 장기요양보험】
• 건강보험료의 12.95% (2025년 요율)
• 노인장기요양 서비스 재원
• 건강보험과 함께 징수

【공무원 특징】
• 국민연금 ❌ → 공무원연금 적용
• 고용보험 ❌ → 공무원 제외

【계산 예시 (월급 350만원 기준)】
• 건강보험: 124,075원 (3.545%)
• 장기요양: 16,068원 (건강보험의 12.95%)
• 합계: 약 140,143원/월

💡 건강보험은 과세표준 소득 전체에 대해 계산됩니다.''',
      ),
    ];

    return CalculationBreakdownSection(
      items: [
        ...items,

        // 공제 항목 섹션 헤더
        BreakdownItem.sectionHeader('📉 공제 항목 (연간)'),

        ...deductions,
      ],
    );
  }
}

/// MonthlyNetIncome을 MonthlySalaryDetail로 변환하는 확장 메서드
extension MonthlyNetIncomeExtension on MonthlyNetIncome {
  MonthlySalaryDetail toMonthlySalaryDetail() {
    // MonthlyNetIncome은 실수령액 중심, MonthlySalaryDetail은 수당 항목 중심
    // 여기서는 간단히 매핑 (실제로는 UseCase에서 계산되어야 함)
    return MonthlySalaryDetail(
      month: month,
      baseSalary: baseSalary,
      teachingAllowance: 0, // MonthlyNetIncome에는 세부 수당이 없으므로 0
      familyAllowance: 0,
      researchAllowance: 0,
      longevityBonus: longevityBonus,
      longevityMonthly: 0,
      grossSalary: grossSalary,
    );
  }
}
