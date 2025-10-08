import 'package:flutter/material.dart';
import 'package:gong_mu_talk/core/utils/number_formatter.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/monthly_net_income.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/teacher_profile.dart';
import 'package:gong_mu_talk/features/calculator/presentation/widgets/calculation_breakdown_section.dart';
import 'package:gong_mu_talk/features/calculator/presentation/widgets/detailed_info_widget.dart';
import 'package:gong_mu_talk/features/calculator/domain/constants/salary_table.dart';

/// 급여 상세 계산 내역 위젯
///
/// current_salary_card.dart의 _buildCalculationBreakdown 메서드를 별도 위젯으로 분리
/// 토큰 사용량 최적화를 위해 1,311 lines를 독립 파일로 추출
class SalaryBreakdownWidget extends StatelessWidget {
  final TeacherProfile? profile;
  final List<MonthlyNetIncome> monthlyBreakdown;
  final String? nickname;

  const SalaryBreakdownWidget({
    super.key,
    required this.profile,
    required this.monthlyBreakdown,
    this.nickname,
  });

  @override
  Widget build(BuildContext context) {
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

    // 개별 교직수당 가산금 (매월)
    final annualSpecialEducationAllowance = monthlyBreakdown.fold<int>(
      0,
      (sum, m) => sum + m.specialEducationAllowance,
    );
    final annualVocationalEducationAllowance = monthlyBreakdown.fold<int>(
      0,
      (sum, m) => sum + m.vocationalEducationAllowance,
    );
    final annualHealthTeacherAllowance = monthlyBreakdown.fold<int>(
      0,
      (sum, m) => sum + m.healthTeacherAllowance,
    );
    final annualConcurrentPositionAllowance = monthlyBreakdown.fold<int>(
      0,
      (sum, m) => sum + m.concurrentPositionAllowance,
    );
    final annualNutritionTeacherAllowance = monthlyBreakdown.fold<int>(
      0,
      (sum, m) => sum + m.nutritionTeacherAllowance,
    );
    final annualLibrarianAllowance = monthlyBreakdown.fold<int>(
      0,
      (sum, m) => sum + m.librarianAllowance,
    );
    final annualCounselorAllowance = monthlyBreakdown.fold<int>(
      0,
      (sum, m) => sum + m.counselorAllowance,
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
        detailedWidget: DetailedInfoWidget(
          sections: [
            DetailSection(
              title: '공무원 보수규정',
              icon: Icons.gavel,
              backgroundColor: Colors.blue.shade50,
              titleColor: Colors.blue.shade900,
              children: const [
                DetailInfoBox(
                  type: DetailInfoBoxType.info,
                  content: '공무원 보수규정 별표 1에 따라 교육공무원 호봉표 기준으로 지급됩니다.',
                ),
              ],
            ),
            if (gradeBeforePromotion != gradeAfterPromotion) ...[
              DetailSection(
                title: '승급월 반영',
                icon: Icons.trending_up,
                backgroundColor: Colors.green.shade50,
                titleColor: Colors.green.shade900,
                children: [
                  DetailTable(
                    headers: const ['기간', '호봉', '월 급여'],
                    rows: [
                      [
                        '1~${promotionMonth - 1}월',
                        '$gradeBeforePromotion호봉',
                        NumberFormatter.formatCurrency(payBeforePromotion),
                      ],
                      [
                        '$promotionMonth~12월',
                        '$gradeAfterPromotion호봉',
                        NumberFormatter.formatCurrency(payAfterPromotion),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  const DetailInfoBox(
                    type: DetailInfoBoxType.tip,
                    content: '승급월부터 새 호봉이 적용됩니다.',
                  ),
                ],
              ),
              DetailSection(
                title: '${nickname ?? "선생님"}의 연간 본봉 계산',
                icon: Icons.calculate,
                backgroundColor: Colors.purple.shade50,
                titleColor: Colors.purple.shade900,
                children: [
                  DetailInfoBox(
                    type: DetailInfoBoxType.info,
                    content: '승급 전 ($gradeBeforePromotion호봉):\n'
                        '${NumberFormatter.formatCurrency(payBeforePromotion)} × $monthsBeforePromotion개월 = ${NumberFormatter.formatCurrency(payBeforePromotion * monthsBeforePromotion)}\n\n'
                        '승급 후 ($gradeAfterPromotion호봉):\n'
                        '${NumberFormatter.formatCurrency(payAfterPromotion)} × $monthsAfterPromotion개월 = ${NumberFormatter.formatCurrency(payAfterPromotion * monthsAfterPromotion)}',
                  ),
                  const SizedBox(height: 8),
                  DetailInfoBox(
                    type: DetailInfoBoxType.highlight,
                    content: '연간 총액: ${NumberFormatter.formatCurrency(annualBasePay)}',
                  ),
                ],
              ),
            ] else ...[
              DetailSection(
                title: '${nickname ?? "선생님"}의 호봉 정보',
                icon: Icons.badge,
                backgroundColor: Colors.green.shade50,
                titleColor: Colors.green.shade900,
                children: [
                  DetailInfoBox(
                    type: DetailInfoBoxType.info,
                    content: '승급월: $promotionMonth월\n연간 동일 호봉 적용 ($currentGrade호봉)',
                  ),
                ],
              ),
              DetailSection(
                title: '연간 본봉 계산',
                icon: Icons.calculate,
                backgroundColor: Colors.purple.shade50,
                titleColor: Colors.purple.shade900,
                children: [
                  DetailCalculation(
                    label: '연간 본봉',
                    baseAmount: NumberFormatter.formatCurrency(payBeforePromotion),
                    rate: '12개월',
                    result: NumberFormatter.formatCurrency(annualBasePay),
                    steps: [
                      '$currentGrade호봉 기준',
                    ],
                  ),
                ],
              ),
            ],
          ],
          userExample: '${nickname ?? "선생님"}의 승급월을 반영하여 계산되었습니다.',
        ),
      ),
      BreakdownItem(
        label: '📚 교직수당 × 12개월',
        amount: annualTeachingAllowance,
        detailedWidget: DetailedInfoWidget(
          sections: [
            DetailSection(
              title: '기본 지급액',
              icon: Icons.school,
              backgroundColor: Colors.blue.shade50,
              titleColor: Colors.blue.shade900,
              children: const [
                DetailTable(
                  headers: ['구분', '지급액'],
                  rows: [
                    ['월 지급액', '250,000원'],
                    ['연 지급액', '3,000,000원'],
                    ['대상', '모든 교육공무원'],
                  ],
                ),
              ],
            ),
            DetailSection(
              title: '교직수당 가산금 종류',
              icon: Icons.add_circle_outline,
              backgroundColor: Colors.green.shade50,
              titleColor: Colors.green.shade900,
              children: const [
                DetailInfoBox(
                  type: DetailInfoBoxType.info,
                  content: '해당되는 가산금은 별도 항목으로 표시됩니다.',
                ),
                SizedBox(height: 8),
                DetailTable(
                  headers: ['가산금 종류', '월 금액', '표시 항목'],
                  rows: [
                    ['담임교사 (가산금 4)', '200,000원', '담임수당'],
                    ['보직교사 (가산금 3)', '150,000원', '보직수당'],
                  ],
                ),
              ],
            ),
            const DetailSection(
              title: '그 외 교직수당 가산금',
              icon: Icons.more_horiz,
              children: [
                DetailTable(
                  headers: ['가산금 종류', '월 금액'],
                  rows: [
                    ['원로교사 (30년+, 55세+)', '50,000원'],
                    ['특수교사', '120,000원'],
                    ['특성화교사 (호봉별)', '25,000~50,000원'],
                    ['보건교사', '40,000원'],
                    ['사서교사', '30,000원'],
                    ['영양교사', '40,000원'],
                    ['전문상담교사', '30,000원'],
                    ['겸직수당', '50,000~100,000원'],
                  ],
                ),
                SizedBox(height: 8),
                DetailInfoBox(
                  type: DetailInfoBoxType.tip,
                  content: '위 가산금은 해당되는 경우 "💼 그 외 교직수당 가산금" 항목으로 표시됩니다.',
                ),
              ],
            ),
          ],
        ),
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
      if (annualSpecialEducationAllowance > 0)
        BreakdownItem(
          label: '🎓 특수교사 가산금 × 12개월',
          amount: annualSpecialEducationAllowance,
          detailedInfo: '''🎓 특수교사 가산금

【지급 기준】
• 월 120,000원 (연 1,440,000원)
• 교직수당 가산금 2 해당

【지급 대상】
• 특수학교 교사
• 일반학교 특수학급 담당 교사
• 특수교육 자격증 소지자

【지급 방식】
• 매월 급여와 함께 지급
• 담임수당, 보직교사수당과 중복 수령 가능

💡 특수교육 대상 학생을 위한 전문성에 대한 수당입니다.''',
        ),
      if (annualVocationalEducationAllowance > 0)
        BreakdownItem(
          label: '🏫 특성화교사 가산금 (전문교과) × 12개월',
          amount: annualVocationalEducationAllowance,
          detailedInfo: '''🏫 특성화교사 가산금 (전문교과)

【지급 기준】
• 교직수당 가산금 5 해당
• 호봉에 따라 차등 지급

【호봉별 지급액】
• 31~40호봉: 50,000원
• 22~30호봉: 45,000원
• 14~21호봉: 40,000원
• 9~13호봉: 35,000원
• 5~8호봉: 30,000원
• 1~4호봉: 25,000원

【지급 대상】
• 특성화고등학교 교사
• 마이스터고 교사
• 실업계 고교 실습 지도 교사

【지급 방식】
• 매월 급여와 함께 지급
• 담임수당, 보직교사수당과 중복 수령 가능

💡 직업교육을 담당하는 교사에 대한 수당입니다.''',
        ),
      if (annualHealthTeacherAllowance > 0)
        BreakdownItem(
          label: '⚕️ 보건교사 가산금 × 12개월',
          amount: annualHealthTeacherAllowance,
          detailedInfo: '''⚕️ 보건교사 가산금

【지급 기준】
• 월 40,000원 (연 480,000원)
• 교직수당 가산금 8 해당

【지급 대상】
• 학교 보건교사
• 보건실 전담 교사
• 간호사 자격 소지 교사

【지급 방식】
• 매월 급여와 함께 지급
• 담임수당, 보직교사수당과 중복 수령 가능

💡 학생 건강관리 업무를 담당하는 교사에 대한 수당입니다.''',
        ),
      if (annualConcurrentPositionAllowance > 0)
        BreakdownItem(
          label: '💼 겸직수당 × 12개월',
          amount: annualConcurrentPositionAllowance,
          detailedInfo: '''💼 겸직수당

【지급 기준】
• 교직수당 가산금 6 해당
• 겸직 업무에 따라 차등 지급

【지급액】
• 일반 겸직: 50,000원
• 중요 겸직: 100,000원

【지급 대상】
• 타 학교 겸임교사
• 교육청 겸직 발령 교사
• 대학 겸임교수 등

【지급 방식】
• 매월 급여와 함께 지급
• 담임수당, 보직교사수당과 중복 수령 가능

💡 본직 외 추가 업무를 겸하는 교사에 대한 수당입니다.''',
        ),
      if (annualNutritionTeacherAllowance > 0)
        BreakdownItem(
          label: '🍽️ 영양교사 가산금 × 12개월',
          amount: annualNutritionTeacherAllowance,
          detailedInfo: '''🍽️ 영양교사 가산금

【지급 기준】
• 월 40,000원 (연 480,000원)
• 교직수당 가산금 8 해당

【지급 대상】
• 학교 영양교사
• 급식 전담 교사
• 영양사 자격 소지 교사

【지급 방식】
• 매월 급여와 함께 지급
• 담임수당, 보직교사수당과 중복 수령 가능

💡 학생 급식 및 영양관리를 담당하는 교사에 대한 수당입니다.''',
        ),
      if (annualLibrarianAllowance > 0)
        BreakdownItem(
          label: '📚 사서교사 가산금 × 12개월',
          amount: annualLibrarianAllowance,
          detailedInfo: '''📚 사서교사 가산금

【지급 기준】
• 월 30,000원 (연 360,000원)
• 교직수당 가산금 9 해당

【지급 대상】
• 학교 사서교사
• 도서관 전담 교사
• 사서 자격증 소지 교사

【지급 방식】
• 매월 급여와 함께 지급
• 담임수당, 보직교사수당과 중복 수령 가능

💡 학교 도서관 운영 및 독서교육을 담당하는 교사에 대한 수당입니다.''',
        ),
      if (annualCounselorAllowance > 0)
        BreakdownItem(
          label: '💬 전문상담교사 가산금 × 12개월',
          amount: annualCounselorAllowance,
          detailedInfo: '''💬 전문상담교사 가산금

【지급 기준】
• 월 30,000원 (연 360,000원)
• 교직수당 가산금 9 해당

【지급 대상】
• 전문상담교사
• 상담실 전담 교사
• 상담 자격증 소지 교사

【지급 방식】
• 매월 급여와 함께 지급
• 담임수당, 보직교사수당과 중복 수령 가능

💡 학생 상담 및 진로지도를 전담하는 교사에 대한 수당입니다.''',
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
      BreakdownItem(
        label: '📖 연구비 × 12개월',
        amount: annualResearchAllowance,
        detailedWidget: DetailedInfoWidget(
          sections: [
            DetailSection(
              title: '2023.3.1 개정 기준',
              icon: Icons.update,
              backgroundColor: Colors.blue.shade50,
              titleColor: Colors.blue.shade900,
              children: const [
                DetailInfoBox(
                  type: DetailInfoBoxType.info,
                  content: '직책별, 학교급별로 지급단가가 다르며, 중복 지급되지 않습니다.',
                ),
              ],
            ),
            const DetailSection(
              title: '직급별 · 학교급별 지급 기준',
              icon: Icons.table_chart,
              children: [
                DetailTable(
                  headers: ['직급', '유·초등', '중등'],
                  rows: [
                    ['교장', '75,000원', '60,000원'],
                    ['교감', '65,000원', '60,000원'],
                    ['수석교사', '60,000원', '60,000원'],
                    ['보직교사', '60,000원', '60,000원'],
                    ['교사 (5년+)', '60,000원', '60,000원'],
                    ['교사 (5년-)', '75,000원', '75,000원'],
                  ],
                ),
              ],
            ),
            DetailSection(
              title: '중복 지급 불가 원칙',
              icon: Icons.warning_amber,
              backgroundColor: Colors.orange.shade50,
              titleColor: Colors.orange.shade900,
              children: const [
                DetailInfoBox(
                  type: DetailInfoBoxType.warning,
                  content: '여러 직책을 겸할 경우 가장 높은 직책 기준만 적용됩니다.\n\n'
                      '예시:\n'
                      '• 부장교사 + 담임 → 부장교사 기준 60,000원만 지급\n'
                      '• 보직교사 + 5년 이상 → 보직교사 기준 60,000원만 지급',
                ),
              ],
            ),
            if (monthlyBreakdown.isNotEmpty)
              DetailSection(
                title: '${nickname ?? "선생님"}의 연구비',
                icon: Icons.person,
                backgroundColor: Colors.green.shade50,
                titleColor: Colors.green.shade900,
                children: [
                  DetailInfoBox(
                    type: DetailInfoBoxType.highlight,
                    content: '월 지급액: ${NumberFormatter.formatCurrency(monthlyBreakdown.first.researchAllowance)}\n'
                        '연간 총액: ${NumberFormatter.formatCurrency(monthlyBreakdown.first.researchAllowance * 12)}',
                  ),
                ],
              ),
          ],
        ),
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

      // 특별 지급 섹션 헤더
      BreakdownItem.sectionHeader('💰 특별 지급 (연 5회)'),

      if (annualPerformanceBonus > 0)
        BreakdownItem(
          label: '⭐ 성과상여금 (3월)',
          amount: annualPerformanceBonus,
          isHighlight: true,
          detailedWidget: DetailedInfoWidget(
            sections: [
              DetailSection(
                title: '지급 시기',
                icon: Icons.calendar_today,
                backgroundColor: Colors.blue.shade50,
                titleColor: Colors.blue.shade900,
                children: const [
                  DetailInfoBox(
                    type: DetailInfoBoxType.info,
                    content: '매년 3월 지급',
                  ),
                ],
              ),
              DetailSection(
                title: '등급별 지급액 (2025년)',
                icon: Icons.star,
                backgroundColor: Colors.amber.shade50,
                titleColor: Colors.amber.shade900,
                children: const [
                  DetailTable(
                    headers: ['등급', '지급액', '비율'],
                    rows: [
                      ['S등급', '5,102,970원', '상위 30%'],
                      ['A등급', '4,273,220원', '중위 50% (기본)'],
                      ['B등급', '3,650,900원', '하위 20%'],
                    ],
                  ),
                ],
              ),
              const DetailSection(
                title: '등급 산정 방식',
                icon: Icons.assessment,
                children: [
                  DetailListItem(
                    text: '전년도 근무실적 평가',
                    isChecked: true,
                  ),
                  DetailListItem(
                    text: '학교별 차등 배분',
                    isChecked: true,
                  ),
                  DetailListItem(
                    text: '개인별 등급 통보',
                    isChecked: true,
                  ),
                ],
              ),
              const DetailSection(
                title: '참고사항',
                icon: Icons.info_outline,
                children: [
                  DetailInfoBox(
                    type: DetailInfoBoxType.tip,
                    content: '근무성적평정 결과에 따라 매년 등급이 변동될 수 있습니다.',
                  ),
                ],
              ),
            ],
          ),
        ),
      if (annualLongevityBonus > 0)
        BreakdownItem(
          label: '🎉 정근수당 (1월, 7월)',
          amount: annualLongevityBonus,
          isHighlight: true,
          detailedWidget: DetailedInfoWidget(
            sections: [
              DetailSection(
                title: '지급 시기',
                icon: Icons.event,
                backgroundColor: Colors.blue.shade50,
                titleColor: Colors.blue.shade900,
                children: const [
                  DetailInfoBox(
                    type: DetailInfoBoxType.info,
                    content: '매년 1월, 7월 (연 2회)',
                  ),
                ],
              ),
              DetailSection(
                title: '재직연수별 지급률',
                icon: Icons.trending_up,
                backgroundColor: Colors.green.shade50,
                titleColor: Colors.green.shade900,
                children: const [
                  DetailTable(
                    headers: ['재직연수', '지급률'],
                    rows: [
                      ['2년 미만', '월봉급액의 10%'],
                      ['2~5년', '월봉급액의 20%'],
                      ['5~6년', '월봉급액의 25%'],
                      ['6~7년', '월봉급액의 30%'],
                      ['7~8년', '월봉급액의 35%'],
                      ['8~9년', '월봉급액의 40%'],
                      ['9~10년', '월봉급액의 45%'],
                      ['10년 이상', '월봉급액의 50%'],
                    ],
                  ),
                ],
              ),
              DetailSection(
                title: '정근수당 가산금 (매월 지급)',
                icon: Icons.add_circle,
                backgroundColor: Colors.purple.shade50,
                titleColor: Colors.purple.shade900,
                children: const [
                  DetailTable(
                    headers: ['재직연수', '월 지급액'],
                    rows: [
                      ['5년 미만', '30,000원'],
                      ['5~10년', '50,000원'],
                      ['10~15년', '60,000원'],
                      ['15~20년', '80,000원'],
                      ['20~25년', '110,000원'],
                      ['25년 이상', '130,000원'],
                    ],
                  ),
                ],
              ),
              const DetailSection(
                title: '참고사항',
                icon: Icons.info_outline,
                children: [
                  DetailInfoBox(
                    type: DetailInfoBoxType.tip,
                    content: '• 월봉급액 = 본봉 + 각종 수당 합계 기준으로 계산됩니다\n'
                        '• 정근수당(1월/7월)과 정근수당 가산금(매월)은 별도로 지급됩니다',
                  ),
                ],
              ),
            ],
          ),
        ),
      if (annualHolidayBonus > 0)
        BreakdownItem(
          label: '🎂 명절휴가비 (설날, 추석)',
          amount: annualHolidayBonus,
          isHighlight: true,
          detailedWidget: DetailedInfoWidget(
            sections: [
              DetailSection(
                title: '지급 기준',
                icon: Icons.celebration,
                backgroundColor: Colors.blue.shade50,
                titleColor: Colors.blue.shade900,
                children: const [
                  DetailTable(
                    headers: ['항목', '내용'],
                    rows: [
                      ['지급 기준', '본봉의 60%'],
                      ['지급 횟수', '연 2회 (설날, 추석)'],
                    ],
                  ),
                ],
              ),
              DetailSection(
                title: '지급 시기',
                icon: Icons.schedule,
                backgroundColor: Colors.green.shade50,
                titleColor: Colors.green.shade900,
                children: const [
                  DetailListItem(
                    text: '설날: 음력 설 전월 급여 시',
                    isChecked: true,
                  ),
                  DetailListItem(
                    text: '추석: 음력 추석 전월 급여 시',
                    isChecked: true,
                  ),
                ],
              ),
              DetailSection(
                title: '2025년 지급 예정월',
                icon: Icons.calendar_month,
                backgroundColor: Colors.amber.shade50,
                titleColor: Colors.amber.shade900,
                children: const [
                  DetailTable(
                    headers: ['명절', '지급월', '음력 날짜'],
                    rows: [
                      ['설날', '1월 급여', '음력 1/29'],
                      ['추석', '10월 급여', '음력 10/6'],
                    ],
                  ),
                ],
              ),
              const DetailSection(
                title: '참고사항',
                icon: Icons.info_outline,
                children: [
                  DetailInfoBox(
                    type: DetailInfoBoxType.tip,
                    content: '음력 기준이므로 매년 지급 월이 변경될 수 있습니다.',
                  ),
                ],
              ),
            ],
          ),
        ),
    ];

    final deductions = <BreakdownItem>[
      BreakdownItem(
        label: '🏛 소득세 (연간)',
        amount: annualIncomeTax,
        isDeduction: true,
        detailedWidget: DetailedInfoWidget(
          sections: [
            DetailSection(
              title: '⚠️ 추정치 안내',
              icon: Icons.warning_amber_rounded,
              backgroundColor: Colors.orange.shade50,
              titleColor: Colors.orange.shade900,
              children: const [
                DetailInfoBox(
                  type: DetailInfoBoxType.warning,
                  content: '실제 간이세액표는 매우 복잡하여 단순화된 공식을 사용합니다.\n\n'
                      '• 실제 급여명세서와 차이가 있을 수 있습니다 (오차범위: ±10,000원 내외)\n'
                      '• 연말정산에서 최종 세액이 확정됩니다',
                ),
              ],
            ),
            DetailSection(
              title: '소득세 세율 구간 (2025년)',
              icon: Icons.account_balance,
              backgroundColor: Colors.blue.shade50,
              titleColor: Colors.blue.shade900,
              children: const [
                DetailTable(
                  headers: ['과세표준', '세율'],
                  rows: [
                    ['1,400만원 이하', '6%'],
                    ['1,400만원 ~ 5,000만원', '15%'],
                    ['5,000만원 ~ 8,800만원', '24%'],
                    ['8,800만원 ~ 1.5억원', '35%'],
                    ['1.5억원 ~ 3억원', '38%'],
                    ['3억원 ~ 5억원', '40%'],
                    ['5억원 초과', '45%'],
                  ],
                ),
              ],
            ),
            const DetailSection(
              title: '원천징수 방식',
              icon: Icons.receipt_long,
              children: [
                DetailListItem(
                  text: '매월 급여에서 자동 공제',
                  isChecked: true,
                ),
                DetailListItem(
                  text: '간이세액표 기준 적용',
                  isChecked: true,
                ),
                DetailListItem(
                  text: '부양가족 수 반영',
                  isChecked: true,
                ),
              ],
            ),
            const DetailSection(
              title: '공제율 계산 반영 사항',
              icon: Icons.calculate,
              children: [
                DetailListItem(
                  text: '총 급여액 (본봉 + 수당)',
                  isChecked: true,
                  color: Colors.blue,
                ),
                DetailListItem(
                  text: '부양가족 수',
                  isChecked: true,
                  color: Colors.blue,
                ),
                DetailListItem(
                  text: '각종 공제 (연금, 보험료 등)',
                  isChecked: true,
                  color: Colors.blue,
                ),
              ],
            ),
            if (monthlyBreakdown.isNotEmpty)
              DetailSection(
                title: '${nickname ?? "선생님"}의 월평균 소득세',
                icon: Icons.person,
                backgroundColor: Colors.green.shade50,
                titleColor: Colors.green.shade900,
                children: [
                  DetailInfoBox(
                    type: DetailInfoBoxType.info,
                    content: '월 평균: ${NumberFormatter.formatCurrency(
                      (annualIncomeTax / 12).round(),
                    )}\n'
                        '연간 합계: ${NumberFormatter.formatCurrency(annualIncomeTax)}',
                  ),
                ],
              ),
            const DetailSection(
              title: '참고사항',
              icon: Icons.info_outline,
              children: [
                DetailInfoBox(
                  type: DetailInfoBoxType.tip,
                  content: '• 실제 부담률은 누진공제 적용으로 표시 세율보다 낮습니다\n'
                      '• 연말정산 시 환급/추가납부가 발생할 수 있습니다',
                ),
              ],
            ),
          ],
        ),
      ),
      BreakdownItem(
        label: '🏢 지방세 (연간)',
        amount: annualLocalTax,
        isDeduction: true,
        detailedWidget: DetailedInfoWidget(
          sections: [
            DetailSection(
              title: '⚠️ 추정치 안내',
              icon: Icons.warning_amber_rounded,
              backgroundColor: Colors.orange.shade50,
              titleColor: Colors.orange.shade900,
              children: const [
                DetailInfoBox(
                  type: DetailInfoBoxType.warning,
                  content: '소득세 추정치를 기반으로 계산되므로 실제와 차이가 있을 수 있습니다.',
                ),
              ],
            ),
            DetailSection(
              title: '지방소득세 계산 방식',
              icon: Icons.home_work,
              backgroundColor: Colors.blue.shade50,
              titleColor: Colors.blue.shade900,
              children: const [
                DetailTable(
                  headers: ['항목', '내용'],
                  rows: [
                    ['계산 방식', '소득세의 10%'],
                    ['근거 법령', '지방세법 제71조'],
                    ['납부 방식', '소득세와 함께 원천징수'],
                  ],
                ),
              ],
            ),
            if (annualIncomeTax > 0)
              DetailSection(
                title: '${nickname ?? "선생님"}의 지방세 계산',
                icon: Icons.person,
                backgroundColor: Colors.green.shade50,
                titleColor: Colors.green.shade900,
                children: [
                  DetailCalculation(
                    label: '지방세 계산',
                    baseAmount: NumberFormatter.formatCurrency(annualIncomeTax),
                    rate: '10%',
                    result: NumberFormatter.formatCurrency(annualLocalTax),
                    steps: const [
                      '소득세 × 10%',
                    ],
                  ),
                  const SizedBox(height: 8),
                  DetailInfoBox(
                    type: DetailInfoBoxType.info,
                    content: '월 평균: ${NumberFormatter.formatCurrency(
                      (annualLocalTax / 12).round(),
                    )}',
                  ),
                ],
              ),
            const DetailSection(
              title: '용도',
              icon: Icons.location_city,
              children: [
                DetailListItem(
                  text: '지방자치단체 재원',
                  isChecked: true,
                ),
                DetailListItem(
                  text: '지역 교육 사업',
                  isChecked: true,
                ),
                DetailListItem(
                  text: '지역 복지 사업',
                  isChecked: true,
                ),
              ],
            ),
            const DetailSection(
              title: '납부 방식',
              icon: Icons.payment,
              children: [
                DetailInfoBox(
                  type: DetailInfoBoxType.tip,
                  content: '소득세와 함께 매월 급여에서 자동 공제됩니다.',
                ),
              ],
            ),
          ],
        ),
      ),
      BreakdownItem(
        label: '💰 공무원연금 기여금 (연간)',
        amount: annualPensionContribution,
        isDeduction: true,
        detailedWidget: DetailedInfoWidget(
          sections: [
            DetailSection(
              title: '기여율 (공무원연금법)',
              icon: Icons.percent,
              backgroundColor: Colors.blue.shade50,
              titleColor: Colors.blue.shade900,
              children: const [
                DetailTable(
                  headers: ['구분', '기여율'],
                  rows: [
                    ['본인 부담', '9%'],
                    ['국가 부담', '9%'],
                    ['합계', '18%'],
                  ],
                ),
              ],
            ),
            DetailSection(
              title: '기준소득월액 포함 항목',
              icon: Icons.check_circle_outline,
              backgroundColor: Colors.green.shade50,
              titleColor: Colors.green.shade900,
              children: const [
                DetailListItem(text: '본봉', isChecked: true),
                DetailListItem(text: '교직수당', isChecked: true),
                DetailListItem(text: '담임수당', isChecked: true),
                DetailListItem(text: '보직수당', isChecked: true),
                DetailListItem(text: '가족수당', isChecked: true),
                DetailListItem(text: '연구비', isChecked: true),
                DetailListItem(text: '정근수당 가산금', isChecked: true),
                DetailListItem(text: '정근수당 (1/7월)', isChecked: true),
                DetailListItem(text: '명절휴가비', isChecked: true),
              ],
            ),
            DetailSection(
              title: '기준소득월액 제외 항목',
              icon: Icons.cancel_outlined,
              backgroundColor: Colors.red.shade50,
              titleColor: Colors.red.shade900,
              children: const [
                DetailListItem(
                  text: '시간외근무수당',
                  isChecked: false,
                  color: Colors.red,
                ),
                DetailListItem(
                  text: '성과상여금',
                  isChecked: false,
                  color: Colors.red,
                ),
              ],
            ),
            if (monthlyBreakdown.isNotEmpty)
              DetailSection(
                title: '${nickname ?? "선생님"}의 계산',
                icon: Icons.person,
                backgroundColor: Colors.purple.shade50,
                titleColor: Colors.purple.shade900,
                children: [
                  DetailCalculation(
                    label: '월 평균 기준소득',
                    baseAmount: NumberFormatter.formatCurrency(
                      (annualPensionContribution / 12 / 0.09).round(),
                    ),
                    rate: '9%',
                    result: NumberFormatter.formatCurrency(
                      (annualPensionContribution / 12).round(),
                    ),
                    steps: const [
                      '본봉 + 수당(포함 항목만)',
                    ],
                  ),
                  const SizedBox(height: 8),
                  DetailInfoBox(
                    type: DetailInfoBoxType.info,
                    content: '연간 기여금 = ${NumberFormatter.formatCurrency((annualPensionContribution / 12).round())} × 12개월 = ${NumberFormatter.formatCurrency(annualPensionContribution)}',
                  ),
                ],
              ),
            const DetailSection(
              title: '연금 수령 조건',
              icon: Icons.savings_outlined,
              children: [
                DetailListItem(
                  text: '재직기간 10년 이상: 연금 수령 가능',
                  isChecked: true,
                  color: Colors.blue,
                ),
                DetailListItem(
                  text: '재직기간 10년 미만: 퇴직일시금',
                ),
                DetailInfoBox(
                  type: DetailInfoBoxType.tip,
                  content: '퇴직연금 지급 개시 연령: 만 60~65세 (단계적 상향)',
                ),
              ],
            ),
            DetailSection(
              title: '국민연금과의 차이',
              icon: Icons.compare_arrows,
              backgroundColor: Colors.amber.shade50,
              titleColor: Colors.amber.shade900,
              children: const [
                DetailTable(
                  headers: ['구분', '공무원연금', '국민연금'],
                  rows: [
                    ['적용 대상', '공무원', '일반 근로자'],
                    ['기여율', '9%', '4.5%'],
                    ['상대 수령액', '높음', '보통'],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      BreakdownItem(
        label: '🛡 건강보험 + 장기요양 (연간)',
        amount: annualInsurance,
        isDeduction: true,
        detailedWidget: DetailedInfoWidget(
          sections: [
            DetailSection(
              title: '건강보험 부담률 (2025년)',
              icon: Icons.health_and_safety,
              backgroundColor: Colors.blue.shade50,
              titleColor: Colors.blue.shade900,
              children: const [
                DetailTable(
                  headers: ['구분', '부담률'],
                  rows: [
                    ['본인 부담', '3.545%'],
                    ['국가 부담', '3.545%'],
                    ['합계', '7.09%'],
                  ],
                ),
              ],
            ),
            DetailSection(
              title: '장기요양보험료 계산',
              icon: Icons.elderly,
              backgroundColor: Colors.purple.shade50,
              titleColor: Colors.purple.shade900,
              children: const [
                DetailInfoBox(
                  type: DetailInfoBoxType.info,
                  content: '건강보험료의 12.95% (2025년 요율)',
                ),
                SizedBox(height: 8),
                DetailListItem(
                  text: '노인장기요양 서비스 재원으로 사용',
                  isChecked: true,
                ),
                DetailListItem(
                  text: '건강보험과 함께 자동 징수',
                  isChecked: true,
                ),
              ],
            ),
            DetailSection(
              title: '공무원 사회보험 특징',
              icon: Icons.badge,
              backgroundColor: Colors.orange.shade50,
              titleColor: Colors.orange.shade900,
              children: const [
                DetailTable(
                  headers: ['보험 종류', '가입 여부', '비고'],
                  rows: [
                    ['건강보험', '✅ 가입', '의료비 보장'],
                    ['장기요양보험', '✅ 가입', '건강보험의 12.95%'],
                    ['국민연금', '❌ 제외', '공무원연금 적용'],
                    ['고용보험', '❌ 제외', '공무원 제외'],
                  ],
                ),
              ],
            ),
            if (monthlyBreakdown.isNotEmpty)
              DetailSection(
                title: '${nickname ?? "선생님"}의 계산',
                icon: Icons.person,
                backgroundColor: Colors.green.shade50,
                titleColor: Colors.green.shade900,
                children: [
                  DetailCalculation(
                    label: '1단계: 건강보험료 계산',
                    baseAmount: NumberFormatter.formatCurrency(
                      (monthlyBreakdown.first.healthInsurance / 0.03545).round(),
                    ),
                    rate: '3.545%',
                    result: NumberFormatter.formatCurrency(
                      monthlyBreakdown.first.healthInsurance,
                    ),
                    steps: const [
                      '월 과세 대상 소득 전체 기준',
                    ],
                  ),
                  const SizedBox(height: 12),
                  DetailCalculation(
                    label: '2단계: 장기요양보험료 계산',
                    baseAmount: NumberFormatter.formatCurrency(
                      monthlyBreakdown.first.healthInsurance,
                    ),
                    rate: '12.95%',
                    result: NumberFormatter.formatCurrency(
                      monthlyBreakdown.first.longTermCareInsurance,
                    ),
                    steps: const [
                      '건강보험료의 12.95%',
                    ],
                  ),
                  const SizedBox(height: 8),
                  DetailInfoBox(
                    type: DetailInfoBoxType.highlight,
                    content: '월 합계: ${NumberFormatter.formatCurrency(
                      monthlyBreakdown.first.healthInsurance +
                          monthlyBreakdown.first.longTermCareInsurance,
                    )}\n'
                        '연간 합계: ${NumberFormatter.formatCurrency(annualInsurance)}',
                  ),
                ],
              ),
            const DetailSection(
              title: '기준 소득 범위',
              icon: Icons.info_outline,
              children: [
                DetailInfoBox(
                  type: DetailInfoBoxType.tip,
                  content: '건강보험은 과세 대상 소득 전체에 대해 계산됩니다.\n\n'
                      '포함 항목: 본봉, 각종 수당, 상여금 등\n'
                      '제외 항목: 비과세 수당 (식대, 자녀학비 등)',
                ),
              ],
            ),
          ],
        ),
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
