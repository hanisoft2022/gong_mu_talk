import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:gong_mu_talk/core/utils/number_formatter.dart';
import 'package:gong_mu_talk/core/utils/snackbar_helpers.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/monthly_net_income.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/teacher_profile.dart';
import 'package:gong_mu_talk/features/calculator/domain/constants/performance_bonus_constants.dart';
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

    const annualTeachingAllowance = AllowanceTable.teachingAllowance * 12;
    final annualHomeroomAllowance = (profile?.isHomeroom ?? false)
        ? AllowanceTable.homeroomAllowance * 12
        : 0;
    final annualHeadTeacherAllowance = (profile?.hasPosition ?? false)
        ? AllowanceTable.headTeacherAllowance * 12
        : 0;

    // 시간외근무수당(정액분)도 승급월 고려
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
      BreakdownItem.sectionHeader('📅 매월 지급 × 12개월'),

      BreakdownItem(
        label: '📋 본봉',
        amount: annualBasePay,
        detailedWidget: DetailedInfoWidget(
          sections: [
            const DetailSection(
              title: '공무원 보수규정',
              icon: Icons.gavel,
              children: [
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
                titleColor: Colors.teal.shade900,
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
                ],
              ),
              DetailSection(
                title: '${nickname ?? "선생"}님의 연간 본봉 계산',
                icon: Icons.calculate,
                titleColor: Colors.teal.shade900,
                children: [
                  DetailInfoBox(
                    type: DetailInfoBoxType.info,
                    content:
                        '승급 전 ($gradeBeforePromotion호봉):\n'
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
                title: '${nickname ?? "선생"}님의 호봉 정보',
                icon: Icons.badge,
                backgroundColor: Colors.teal.shade50,

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

                titleColor: Colors.teal.shade900,
                children: [
                  DetailCalculation(
                    label: '연간 본봉',
                    baseAmount: NumberFormatter.formatCurrency(payBeforePromotion),
                    rate: '12개월',
                    result: NumberFormatter.formatCurrency(annualBasePay),
                    steps: ['$currentGrade호봉 기준'],
                  ),
                ],
              ),
            ],
          ],
          userExample: '${nickname ?? "선생님"}의 승급월을 반영하여 계산되었습니다.',
        ),
      ),
      const BreakdownItem(
        label: '📚 교직수당',
        amount: annualTeachingAllowance,
        detailedWidget: DetailedInfoWidget(
          sections: [
            DetailSection(
              title: '지급액',
              icon: Icons.school,
              children: [DetailInfoBox(type: DetailInfoBoxType.highlight, content: '월 250,000원')],
            ),
            DetailSection(
              title: '지급 대상',
              icon: Icons.people,
              children: [DetailInfoBox(type: DetailInfoBoxType.info, content: '고등학교 이하 각급 학교 교원')],
            ),
            DetailSection(
              title: '교직수당 가산금',
              icon: Icons.add_circle_outline,
              children: [
                DetailInfoBox(type: DetailInfoBoxType.info, content: '해당되는 가산금은 별도 항목으로 표시됩니다.'),
                Gap(10),
                DetailTable(
                  headers: ['번호', '가산금 명칭', '월 금액(원)'],
                  rows: [
                    ['1', '원로교사 (30년+, 55세+)', '50,000'],
                    ['2', '보직교사', '150,000'],
                    ['3', '특수교사', '120,000'],
                    ['4', '담임교사', '200,000'],
                    ['5', '특성화교사 (호봉별)', '25,000~50,000'],
                    ['6', '보건교사', '40,000'],
                    ['7', '겸직수당', '50,000~100,000'],
                    ['8', '영양교사', '40,000'],
                    ['9', '사서교사', '30,000'],
                    ['10', '전문상담교사', '30,000'],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      if (profile?.isHomeroom ?? false)
        BreakdownItem(
          label: '🏛️ 담임수당',
          amount: annualHomeroomAllowance,
          onTap: () {
            SnackbarHelpers.showInfo(context, '담임수당: 월 200,000원');
          },
        ),
      if (profile?.hasPosition ?? false)
        BreakdownItem(
          label: '👔 보직교사수당',
          amount: annualHeadTeacherAllowance,
          onTap: () {
            SnackbarHelpers.showInfo(context, '보직교사수당: 월 150,000원');
          },
        ),
      if (annualSpecialEducationAllowance > 0)
        BreakdownItem(
          label: '🎓 특수교사수당',
          amount: annualSpecialEducationAllowance,
          onTap: () {
            SnackbarHelpers.showInfo(context, '특수교사수당: 월 120,000원');
          },
        ),
      if (annualVocationalEducationAllowance > 0)
        BreakdownItem(
          label: '🏫 특성화교사수당 (전문교과)',
          amount: annualVocationalEducationAllowance,
          detailedWidget: DetailedInfoWidget(
            sections: [
              const DetailSection(
                title: '지급액',
                icon: Icons.account_balance_wallet,
                children: [DetailInfoBox(type: DetailInfoBoxType.info, content: '호봉에 따른 차등 지급')],
              ),
              DetailSection(
                title: '호봉별 지급액',
                icon: Icons.table_chart,
                backgroundColor: Colors.teal.shade50,
                titleColor: Colors.teal.shade900,
                children: const [
                  DetailTable(
                    headers: ['호봉 범위', '월 지급액'],
                    rows: [
                      ['1~4호봉', '25,000원'],
                      ['5~8호봉', '30,000원'],
                      ['9~13호봉', '35,000원'],
                      ['14~21호봉', '40,000원'],
                      ['22~30호봉', '45,000원'],
                      ['31~40호봉', '50,000원'],
                    ],
                  ),
                ],
              ),
              const DetailSection(
                title: '지급 대상',
                icon: Icons.people,
                children: [
                  DetailListItem(text: '특성화고등학교 교사', isChecked: true),
                  DetailListItem(text: '마이스터고 교사', isChecked: true),
                  DetailListItem(text: '실업계 고교 실습 지도 교사', isChecked: true),
                ],
              ),
              DetailSection(
                title: '${nickname ?? "선생"}님의 특성화교사수당',
                icon: Icons.person,
                backgroundColor: Colors.teal.shade50,
                titleColor: Colors.teal.shade900,
                children: [
                  DetailInfoBox(
                    type: DetailInfoBoxType.highlight,
                    content: monthlyBreakdown.isNotEmpty
                        ? '월 지급액: ${NumberFormatter.formatCurrency(monthlyBreakdown.first.vocationalEducationAllowance)}\n'
                              '연간 총액: ${NumberFormatter.formatCurrency(annualVocationalEducationAllowance)}'
                        : '데이터 로딩 중...',
                  ),
                ],
              ),
              const DetailInfoBox(type: DetailInfoBoxType.tip, content: '기타 수당과 중복 수령 가능합니다.'),
            ],
          ),
        ),
      if (annualHealthTeacherAllowance > 0)
        BreakdownItem(
          label: '⚕️ 보건교사수당',
          amount: annualHealthTeacherAllowance,
          onTap: () {
            SnackbarHelpers.showInfo(context, '보건교사수당: 월 40,000원');
          },
        ),
      if (annualConcurrentPositionAllowance > 0)
        BreakdownItem(
          label: '💼 겸직수당',
          amount: annualConcurrentPositionAllowance,
          detailedWidget: DetailedInfoWidget(
            sections: [
              DetailSection(
                title: '지급액',
                icon: Icons.account_balance_wallet,
                backgroundColor: Colors.teal.shade50,
                titleColor: Colors.teal.shade900,
                children: const [
                  DetailInfoBox(type: DetailInfoBoxType.info, content: '겸직 업무에 따라 차등 지급'),
                  SizedBox(height: 8),
                  DetailTable(
                    headers: ['구분', '월 지급액'],
                    rows: [
                      ['일반 겸직', '50,000원'],
                      ['중요 겸직', '100,000원'],
                    ],
                  ),
                ],
              ),
              const DetailSection(
                title: '지급 대상',
                icon: Icons.people,
                children: [
                  DetailListItem(text: '타 학교 겸임교사', isChecked: true),
                  DetailListItem(text: '교육청 겸직 발령 교사', isChecked: true),
                  DetailListItem(text: '대학 겸임교수 등', isChecked: true),
                  SizedBox(height: 8),
                  DetailInfoBox(type: DetailInfoBoxType.tip, content: '기타 수당과 중복 수령 가능합니다.'),
                ],
              ),
            ],
          ),
        ),
      if (annualNutritionTeacherAllowance > 0)
        BreakdownItem(
          label: '🍽️ 영양교사수당',
          amount: annualNutritionTeacherAllowance,
          onTap: () {
            SnackbarHelpers.showInfo(context, '영양교사수당: 월 40,000원');
          },
        ),
      if (annualLibrarianAllowance > 0)
        BreakdownItem(
          label: '📚 사서교사수당',
          amount: annualLibrarianAllowance,
          onTap: () {
            SnackbarHelpers.showInfo(context, '사서교사수당: 월 30,000원');
          },
        ),
      if (annualCounselorAllowance > 0)
        BreakdownItem(
          label: '💬 전문상담교사수당',
          amount: annualCounselorAllowance,
          onTap: () {
            SnackbarHelpers.showInfo(context, '전문상담교사수당: 월 30,000원');
          },
        ),
      if (annualVeteranAllowance > 0)
        BreakdownItem(
          label: '🎓 원로교사수당',
          amount: annualVeteranAllowance,
          detailedWidget: DetailedInfoWidget(
            sections: [
              const DetailSection(
                title: '지급액',
                icon: Icons.account_balance_wallet,
                children: [DetailInfoBox(type: DetailInfoBoxType.highlight, content: '월 50,000원')],
              ),
              DetailSection(
                title: '지급 대상',
                icon: Icons.people,
                backgroundColor: Colors.teal.shade50,
                titleColor: Colors.teal.shade900,
                children: const [
                  DetailListItem(text: '재직연수 30년 이상', isChecked: true),
                  DetailListItem(text: '만 55세 이상', isChecked: true),
                  SizedBox(height: 8),
                  DetailInfoBox(type: DetailInfoBoxType.warning, content: '두 조건을 모두 충족해야 지급됩니다.'),
                  SizedBox(height: 8),
                  DetailInfoBox(type: DetailInfoBoxType.tip, content: '기타 수당과 중복 수령 가능합니다.'),
                ],
              ),
            ],
          ),
        ),
      if (annualFamilyAllowance > 0)
        BreakdownItem(
          label: '👨‍👩‍👧‍👦 가족수당',
          amount: annualFamilyAllowance,
          detailedWidget: DetailedInfoWidget(
            sections: [
              const DetailSection(
                title: '👨‍👩‍👧‍👦 가족수당',
                children: [
                  DetailInfoBox(type: DetailInfoBoxType.info, content: '가족 구성원에 따라 차등 지급되는 수당입니다.'),
                ],
              ),
              DetailSection(
                title: '지급 기준',
                icon: Icons.account_balance_wallet,
                backgroundColor: Colors.teal.shade50,
                titleColor: Colors.teal.shade900,
                children: const [
                  DetailTable(
                    headers: ['구분', '월 지급액'],
                    rows: [
                      ['배우자', '40,000원'],
                      ['첫째 자녀', '50,000원'],
                      ['둘째 자녀', '80,000원'],
                      ['셋째 이상 자녀', '각 120,000원'],
                      ['60세 이상 직계존속', '1인당 20,000원 (최대 2명)'],
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      BreakdownItem(
        label: '📖 교원연구비',
        amount: annualResearchAllowance,
        detailedWidget: DetailedInfoWidget(
          sections: [
            const DetailSection(
              title: '2023.3.1 개정 기준 (최신 개정)',
              icon: Icons.update,
              children: [
                DetailInfoBox(
                  type: DetailInfoBoxType.info,
                  content:
                      '교원 연구비는 교육부 훈령 기준을 따르되 시·도교육청 예산 및 집행지침에 따라 단가가 상이할 수 있어, 지역별 최신 단가표를 기준으로 산정합니다.',
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
                  content:
                      '교원연구비는 여러 기준에 해당하더라도 가장 높은 단가 1개만 지급됩니다.\n\n'
                      '예시:\n'
                      '• 보직 60,000원 + 5년 미만 75,000원 → 75,000원 적용(금액 우선)\n'
                      '• 보직 60,000원 + 5년 이상 60,000원 → 60,000원 1건만 지급(중복 불가)',
                ),
              ],
            ),
            if (monthlyBreakdown.isNotEmpty)
              DetailSection(
                title: '${nickname ?? "선생"}님의 교원연구비',
                icon: Icons.person,
                backgroundColor: Colors.teal.shade50,
                titleColor: Colors.teal.shade900,
                children: [
                  DetailInfoBox(
                    type: DetailInfoBoxType.highlight,
                    content:
                        '월 지급액: ${NumberFormatter.formatCurrency(monthlyBreakdown.first.researchAllowance)}\n'
                        '연간 총액: ${NumberFormatter.formatCurrency(monthlyBreakdown.first.researchAllowance * 12)}',
                  ),
                ],
              ),
          ],
        ),
      ),
      BreakdownItem(
        label: '🕓 시간외근무수당(정액분)',
        amount: annualOvertimeAllowance,
        detailedWidget: DetailedInfoWidget(
          sections: [
            const DetailSection(
              title: '시간외근무수당(정액분) 지급 기준',
              icon: Icons.access_time,
              children: [
                DetailTable(
                  headers: ['항목', '내용'],
                  rows: [
                    ['지급 방식', '정액 지급'],
                    ['지급 기준', '호봉별 차등'],
                    ['정상근무 기준', '15일 이상 시 전액'],
                  ],
                ),
              ],
            ),
            DetailSection(
              title: '호봉별 지급액',
              icon: Icons.table_chart,
              backgroundColor: Colors.teal.shade50,
              titleColor: Colors.teal.shade900,
              children: const [
                DetailTable(
                  headers: ['호봉 범위', '월 지급액'],
                  rows: [
                    ['1~10호봉', '30,000원'],
                    ['11~20호봉', '40,000원'],
                    ['21~30호봉', '50,000원'],
                    ['31~40호봉', '60,000원'],
                  ],
                ),
              ],
            ),
            DetailSection(
              title: '${nickname ?? "선생"}님의 시간외근무수당(정액분)',
              icon: Icons.person,
              backgroundColor: Colors.teal.shade50,
              titleColor: Colors.teal.shade900,
              children: [
                DetailInfoBox(
                  type: DetailInfoBoxType.highlight,
                  content: monthlyBreakdown.isNotEmpty
                      ? '월 지급액: ${NumberFormatter.formatCurrency(monthlyBreakdown.first.overtimeAllowance)}\n'
                            '연간 총액: ${NumberFormatter.formatCurrency(annualOvertimeAllowance)}'
                      : '데이터 로딩 중...',
                ),
              ],
            ),
            const DetailSection(
              title: '지급 방식',
              icon: Icons.payments,
              children: [
                DetailInfoBox(
                  type: DetailInfoBoxType.info,
                  content: '시간외근무수당(정액분)은 정상근무 15일 이상 시 전액 지급됩니다.',
                ),
                SizedBox(height: 8),
                DetailInfoBox(
                  type: DetailInfoBoxType.warning,
                  content: '해당 월 출근(또는 출장) 근무일수가 15일 미만이면 미달 1일당 15분의 1씩 감액합니다.',
                ),
              ],
            ),
          ],
        ),
      ),
      BreakdownItem(
        label: '🎖 정근수당 가산금',
        amount: annualLongevityMonthly,
        detailedWidget: DetailedInfoWidget(
          sections: [
            const DetailSection(
              title: '🎖 정근수당 가산금',
              icon: Icons.military_tech,
              children: [
                DetailTable(
                  headers: ['항목', '내용'],
                  rows: [
                    ['지급 횟수', '매월 (연 12회)'],
                    ['지급 기준', '재직연수별 차등'],
                  ],
                ),
              ],
            ),
            DetailSection(
              title: '재직연수별 지급액',
              icon: Icons.trending_up,
              backgroundColor: Colors.teal.shade50,
              titleColor: Colors.teal.shade900,
              children: const [
                DetailTable(
                  headers: ['재직연수', '월 지급액'],
                  rows: [
                    ['5년 미만', '30,000원'],
                    ['5~10년', '50,000원'],
                    ['10~15년', '60,000원'],
                    ['15~20년', '80,000원'],
                    ['20~25년', '110,000원 (기본 10만원 + 가산금 1만원)'],
                    ['25년 이상', '130,000원 (기본 10만원 + 가산금 3만원)'],
                  ],
                ),
              ],
            ),
            DetailSection(
              title: '${nickname ?? "선생"}님의 정근수당 가산금',
              icon: Icons.person,
              backgroundColor: Colors.teal.shade50,
              titleColor: Colors.teal.shade900,
              children: [
                DetailInfoBox(
                  type: DetailInfoBoxType.highlight,
                  content: monthlyBreakdown.isNotEmpty
                      ? '월 지급액: ${NumberFormatter.formatCurrency(monthlyBreakdown.first.longevityMonthly)}\n'
                            '연간 총액: ${NumberFormatter.formatCurrency(annualLongevityMonthly)}'
                      : '데이터 로딩 중...',
                ),
              ],
            ),
            const DetailSection(
              title: '지급 방식',
              icon: Icons.calendar_month,
              children: [
                DetailListItem(text: '정근수당(1월/7월)과는 별도', isChecked: true),
                SizedBox(height: 8),
                DetailInfoBox(
                  type: DetailInfoBoxType.tip,
                  content: '정근수당(1월/7월)은 특별 지급이며, 정근수당 가산금은 매월 지급됩니다.',
                ),
              ],
            ),
          ],
        ),
      ),

      // 특별 지급 섹션 헤더
      BreakdownItem.sectionHeader('💰 특별 지급 (연 5회)'),

      if (annualPerformanceBonus > 0)
        BreakdownItem(
          label: '⭐ 성과상여금 (${PerformanceBonusConstants.paymentMonth}월)',
          amount: annualPerformanceBonus,
          isHighlight: true,
          detailedWidget: DetailedInfoWidget(
            sections: [
              const DetailSection(
                title: '지급 시기',
                icon: Icons.calendar_today,
                children: [
                  DetailInfoBox(
                    type: DetailInfoBoxType.info,
                    content: '매년 ${PerformanceBonusConstants.paymentMonth}월 지급',
                  ),
                ],
              ),
              DetailSection(
                title: '💡 계산 기준',
                icon: Icons.calculate,
                backgroundColor: Colors.amber.shade50,
                titleColor: Colors.amber.shade900,
                children: const [
                  DetailInfoBox(
                    type: DetailInfoBoxType.highlight,
                    content: '본 앱은 A등급(차등지급률 50%) 기준으로 계산합니다.',
                  ),
                  SizedBox(height: 8),
                  DetailInfoBox(
                    type: DetailInfoBoxType.info,
                    content:
                        '• A등급은 전체 교원의 50%에 배정되는 중위 등급입니다\n'
                        '• 통계적으로 가장 높은 확률로 받을 수 있는 등급입니다\n'
                        '• 차등지급률 50%는 2025년 정부 정책 기준입니다',
                  ),
                ],
              ),
              const DetailSection(
                title: '등급별 지급액 (2025년)',
                icon: Icons.star,
                children: [
                  DetailTable(
                    headers: ['등급', '차등지급률', '지급액', '배정 비율'],
                    rows: [
                      ['S등급', '60%', '5,102,970원', '상위 30%'],
                      ['A등급', '50%', '4,273,220원', '중위 50%'],
                      ['B등급', '43%', '3,650,900원', '하위 20%'],
                    ],
                  ),
                ],
              ),
              DetailSection(
                title: '📊 직책별 추가 지급액',
                icon: Icons.workspace_premium,
                backgroundColor: Colors.purple.shade50,
                titleColor: Colors.purple.shade900,
                children: const [
                  DetailInfoBox(
                    type: DetailInfoBoxType.info,
                    content: '직책에 따라 기본 성과상여금에 추가 지급액이 있습니다.',
                  ),
                  SizedBox(height: 8),
                  DetailTable(
                    headers: ['직책', '추가 지급률'],
                    rows: [
                      ['교장', '약 30% 추가'],
                      ['교감', '약 20% 추가'],
                      ['수석교사', '약 10% 추가'],
                      ['보직교사(부장)', '약 5% 추가'],
                    ],
                  ),
                  SizedBox(height: 8),
                  DetailInfoBox(
                    type: DetailInfoBoxType.warning,
                    content: '본 앱은 일반 교사 기준으로 계산하며, 직책 가산금은 포함하지 않습니다.',
                  ),
                ],
              ),
              const DetailSection(
                title: '등급 산정 방식',
                icon: Icons.assessment,
                children: [
                  DetailListItem(text: '전년도 근무실적 평가', isChecked: true),
                  DetailListItem(text: '학교별 차등 배분', isChecked: true),
                  DetailListItem(text: '개인별 등급 통보', isChecked: true),
                ],
              ),
              DetailSection(
                title: '🔮 미래 예측 (생애소득 계산 시)',
                icon: Icons.trending_up,
                backgroundColor: Colors.blue.shade50,
                titleColor: Colors.blue.shade900,
                children: const [
                  DetailInfoBox(
                    type: DetailInfoBoxType.info,
                    content: '생애 소득 계산 시 미래 성과상여금은 물가상승률(연 2.3%)을 반영하여 예측합니다.',
                  ),
                  SizedBox(height: 8),
                  DetailTable(
                    headers: ['연도', '예상 지급액(A등급)'],
                    rows: [
                      ['2025년', '4,273,220원'],
                      ['2030년', '4,787,772원'],
                      ['2040년', '6,010,212원'],
                      ['2060년', '9,471,144원'],
                    ],
                  ),
                  SizedBox(height: 8),
                  DetailInfoBox(
                    type: DetailInfoBoxType.warning,
                    content: '실제 지급액은 정부 정책 변경, 학교별 차등지급률 등에 따라 달라질 수 있습니다.',
                  ),
                ],
              ),
              const DetailSection(
                title: '참고사항',
                icon: Icons.info_outline,
                children: [
                  DetailInfoBox(
                    type: DetailInfoBoxType.tip,
                    content:
                        '• 근무성적평정 결과에 따라 매년 등급이 변동될 수 있습니다\n'
                        '• 학교별로 차등지급률이 다를 수 있습니다 (40~60% 범위)\n'
                        '• 정부 정책 변경에 따라 지급액이 조정될 수 있습니다',
                  ),
                  SizedBox(height: 8),
                  DetailInfoBox(
                    type: DetailInfoBoxType.warning,
                    content:
                        '⚠️ 공무원연금 기준소득월액 산정 시:\n'
                        '성과상여금은 개인별 실제 금액이 제외되고, 직종별 평균액이 가산됩니다.',
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
              const DetailSection(
                title: '지급 시기',
                icon: Icons.event,
                children: [
                  DetailInfoBox(type: DetailInfoBoxType.info, content: '매년 1월, 7월 (연 2회)'),
                ],
              ),
              DetailSection(
                title: '재직연수별 지급률',
                icon: Icons.trending_up,
                backgroundColor: Colors.teal.shade50,
                titleColor: Colors.teal.shade900,
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
                backgroundColor: Colors.teal.shade50,
                titleColor: Colors.teal.shade900,
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
                    content:
                        '• 월봉급액 = 본봉 + 각종 수당 합계 기준으로 계산됩니다\n'
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
              const DetailSection(
                title: '지급 기준',
                icon: Icons.celebration,
                children: [
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
                backgroundColor: Colors.teal.shade50,
                titleColor: Colors.teal.shade900,
                children: const [
                  DetailListItem(text: '설날: 음력 설 전월 급여 시', isChecked: true),
                  DetailListItem(text: '추석: 음력 추석 전월 급여 시', isChecked: true),
                ],
              ),
              const DetailSection(
                title: '2025년 지급 예정월',
                icon: Icons.calendar_month,
                children: [
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
                  content:
                      '실제 간이세액표는 매우 복잡하여 단순화된 공식을 사용합니다.\n\n'
                      '• 실제 급여명세서와 차이가 있을 수 있습니다 (오차범위: ±10,000원 내외)\n'
                      '• 연말정산에서 최종 세액이 확정됩니다',
                ),
              ],
            ),
            const DetailSection(
              title: '소득세 세율 구간 (2025년)',
              icon: Icons.account_balance,
              children: [
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
                DetailListItem(text: '매월 급여에서 자동 공제', isChecked: true),
                DetailListItem(text: '간이세액표 기준 적용', isChecked: true),
                DetailListItem(text: '부양가족 수 반영', isChecked: true),
              ],
            ),
            const DetailSection(
              title: '공제율 계산 반영 사항',
              icon: Icons.calculate,
              children: [
                DetailListItem(text: '총 급여액 (본봉 + 수당)', isChecked: true, color: Colors.teal),
                DetailListItem(text: '부양가족 수', isChecked: true, color: Colors.teal),
                DetailListItem(text: '각종 공제 (연금, 보험료 등)', isChecked: true, color: Colors.teal),
              ],
            ),
            if (monthlyBreakdown.isNotEmpty)
              DetailSection(
                title: '${nickname ?? "선생"}님의 월평균 소득세',
                icon: Icons.person,
                backgroundColor: Colors.teal.shade50,
                titleColor: Colors.teal.shade900,
                children: [
                  DetailInfoBox(
                    type: DetailInfoBoxType.info,
                    content:
                        '월 평균: ${NumberFormatter.formatCurrency((annualIncomeTax / 12).round())}\n'
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
                  content:
                      '• 실제 부담률은 누진공제 적용으로 표시 세율보다 낮습니다\n'
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
            const DetailSection(
              title: '지방소득세 계산 방식',
              icon: Icons.home_work,
              children: [
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
                backgroundColor: Colors.teal.shade50,
                titleColor: Colors.teal.shade900,
                children: [
                  DetailCalculation(
                    label: '지방세 계산',
                    baseAmount: NumberFormatter.formatCurrency(annualIncomeTax),
                    rate: '10%',
                    result: NumberFormatter.formatCurrency(annualLocalTax),
                    steps: const ['소득세 × 10%'],
                  ),
                  const SizedBox(height: 8),
                  DetailInfoBox(
                    type: DetailInfoBoxType.info,
                    content:
                        '월 평균: ${NumberFormatter.formatCurrency((annualLocalTax / 12).round())}',
                  ),
                ],
              ),
            const DetailSection(
              title: '용도',
              icon: Icons.location_city,
              children: [
                DetailListItem(text: '지방자치단체 재원', isChecked: true),
                DetailListItem(text: '지역 교육 사업', isChecked: true),
                DetailListItem(text: '지역 복지 사업', isChecked: true),
              ],
            ),
            const DetailSection(
              title: '납부 방식',
              icon: Icons.payment,
              children: [
                DetailInfoBox(type: DetailInfoBoxType.tip, content: '소득세와 함께 매월 급여에서 자동 공제됩니다.'),
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
            const DetailSection(
              title: '기여율 (공무원연금법)',
              icon: Icons.percent,
              children: [
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
              backgroundColor: Colors.teal.shade50,
              titleColor: Colors.teal.shade900,
              children: const [
                DetailListItem(text: '본봉', isChecked: true),
                DetailListItem(text: '교직수당', isChecked: true),
                DetailListItem(text: '담임수당', isChecked: true),
                DetailListItem(text: '보직수당', isChecked: true),
                DetailListItem(text: '가족수당', isChecked: true),
                DetailListItem(text: '교원연구비', isChecked: true),
                DetailListItem(text: '정근수당 가산금', isChecked: true),
                DetailListItem(text: '정근수당 (1/7월)', isChecked: true),
                DetailListItem(text: '명절휴가비', isChecked: true),
              ],
            ),
            const DetailSection(
              title: '기준소득월액 제외 항목',
              icon: Icons.cancel_outlined,
              children: [
                DetailListItem(text: '시간외근무수당(정액분)', isChecked: false, color: Colors.red),
                DetailListItem(text: '성과상여금', isChecked: false, color: Colors.red),
              ],
            ),
            if (monthlyBreakdown.isNotEmpty)
              DetailSection(
                title: '${nickname ?? "선생"}님의 계산',
                icon: Icons.person,
                backgroundColor: Colors.teal.shade50,
                titleColor: Colors.teal.shade900,
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
                    steps: const ['본봉 + 수당(포함 항목만)'],
                  ),
                  const SizedBox(height: 8),
                  DetailInfoBox(
                    type: DetailInfoBoxType.info,
                    content:
                        '연간 기여금 = ${NumberFormatter.formatCurrency((annualPensionContribution / 12).round())} = ${NumberFormatter.formatCurrency(annualPensionContribution)}',
                  ),
                ],
              ),
            const DetailSection(
              title: '연금 수령 조건',
              icon: Icons.savings_outlined,
              children: [
                DetailListItem(text: '재직기간 10년 이상: 연금 수령 가능', isChecked: true, color: Colors.teal),
                DetailListItem(text: '재직기간 10년 미만: 퇴직일시금'),
                DetailInfoBox(
                  type: DetailInfoBoxType.tip,
                  content: '퇴직연금 지급 개시 연령: 만 60~65세 (단계적 상향)',
                ),
              ],
            ),
            const DetailSection(
              title: '국민연금과의 차이',
              icon: Icons.compare_arrows,
              children: [
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
            const DetailSection(
              title: '건강보험 부담률 (2025년)',
              icon: Icons.health_and_safety,
              children: [
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
              backgroundColor: Colors.teal.shade50,
              titleColor: Colors.teal.shade900,
              children: const [
                DetailInfoBox(type: DetailInfoBoxType.info, content: '건강보험료의 12.95% (2025년 요율)'),
                SizedBox(height: 8),
                DetailListItem(text: '노인장기요양 서비스 재원으로 사용', isChecked: true),
                DetailListItem(text: '건강보험과 함께 자동 징수', isChecked: true),
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
                title: '${nickname ?? "선생"}님의 계산',
                icon: Icons.person,
                backgroundColor: Colors.teal.shade50,
                titleColor: Colors.teal.shade900,
                children: [
                  DetailCalculation(
                    label: '1단계: 건강보험료 계산',
                    baseAmount: NumberFormatter.formatCurrency(
                      (monthlyBreakdown.first.healthInsurance / 0.03545).round(),
                    ),
                    rate: '3.545%',
                    result: NumberFormatter.formatCurrency(monthlyBreakdown.first.healthInsurance),
                    steps: const ['월 과세 대상 소득 전체 기준'],
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
                    steps: const ['건강보험료의 12.95%'],
                  ),
                  const SizedBox(height: 8),
                  DetailInfoBox(
                    type: DetailInfoBoxType.highlight,
                    content:
                        '월 합계: ${NumberFormatter.formatCurrency(monthlyBreakdown.first.healthInsurance + monthlyBreakdown.first.longTermCareInsurance)}\n'
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
                  content:
                      '건강보험은 과세 대상 소득 전체에 대해 계산됩니다.\n\n'
                      '포함 항목: 본봉, 각종 수당, 상여금 등\n'
                      '제외 항목: 비과세 수당 (식대, 자녀학비 등)',
                ),
              ],
            ),
          ],
        ),
      ),
      if (profile != null && profile!.teacherAssociationFee > 0)
        BreakdownItem(
          label: '🏦 교직원공제회비 (연간)',
          amount: profile!.teacherAssociationFee * 12,
          isDeduction: true,
          detailedWidget: DetailedInfoWidget(
            sections: [
              const DetailSection(
                title: '교직원공제회 개요',
                icon: Icons.account_balance,
                children: [
                  DetailInfoBox(
                    type: DetailInfoBoxType.info,
                    content: '교직원의 경제적 안정과 복리 증진을 위한 상호부조 단체입니다.',
                  ),
                ],
              ),
              DetailSection(
                title: '공제회 사업',
                icon: Icons.business_center,
                backgroundColor: Colors.teal.shade50,
                titleColor: Colors.teal.shade900,
                children: const [
                  DetailListItem(text: '저금리 대출 사업 (주택, 생활안정자금)', isChecked: true),
                  DetailListItem(text: '목돈마련 적금 상품', isChecked: true),
                  DetailListItem(text: '경조사비 지원', isChecked: true),
                  DetailListItem(text: '의료비 지원', isChecked: true),
                  DetailListItem(text: '퇴직급여 부가 급부금', isChecked: true),
                ],
              ),
              const DetailSection(
                title: '가입 방식',
                icon: Icons.how_to_reg,
                children: [
                  DetailListItem(text: '임의 가입', isChecked: true, color: Colors.teal),
                  DetailListItem(text: '월 회비 자율 결정', isChecked: true, color: Colors.teal),
                  DetailListItem(text: '급여에서 자동 공제', isChecked: true, color: Colors.teal),
                ],
              ),
              DetailSection(
                title: '${nickname ?? "선생님"}의 교직원공제회비',
                icon: Icons.person,
                backgroundColor: Colors.teal.shade50,
                titleColor: Colors.teal.shade900,
                children: [
                  DetailInfoBox(
                    type: DetailInfoBoxType.highlight,
                    content:
                        '월 회비: ${NumberFormatter.formatCurrency(profile!.teacherAssociationFee)}\n'
                        '연간 합계: ${NumberFormatter.formatCurrency(profile!.teacherAssociationFee * 12)}',
                  ),
                ],
              ),
              const DetailSection(
                title: '참고사항',
                icon: Icons.info_outline,
                children: [
                  DetailInfoBox(
                    type: DetailInfoBoxType.tip,
                    content:
                        '• 공제회 회원은 다양한 복지 혜택을 받을 수 있습니다\n'
                        '• 회비는 소득공제 대상이 아닙니다\n'
                        '• 탈퇴 시 회비 반환 가능',
                  ),
                ],
              ),
            ],
          ),
        ),
      if (profile != null && profile!.otherDeductions > 0)
        BreakdownItem(
          label: '📋 기타 공제 (연간)',
          amount: profile!.otherDeductions * 12,
          isDeduction: true,
          detailedWidget: DetailedInfoWidget(
            sections: [
              const DetailSection(
                title: '기타 공제 항목 예시',
                icon: Icons.receipt_long,
                children: [
                  DetailListItem(text: '교원단체(교총/전교조) 회비', isChecked: true),
                  DetailListItem(text: '노동조합비', isChecked: true),
                  DetailListItem(text: '체육회비', isChecked: true),
                  DetailListItem(text: '급여이체 수수료', isChecked: true),
                  DetailListItem(text: '기타 단체 회비', isChecked: true),
                ],
              ),
              DetailSection(
                title: '공제 방식',
                icon: Icons.payment,
                backgroundColor: Colors.teal.shade50,
                titleColor: Colors.teal.shade900,
                children: const [
                  DetailInfoBox(
                    type: DetailInfoBoxType.info,
                    content: '급여에서 자동으로 공제되거나, 본인이 선택한 항목에 대해 공제됩니다.',
                  ),
                ],
              ),
              DetailSection(
                title: '${nickname ?? "선생님"}의 기타 공제',
                icon: Icons.person,
                backgroundColor: Colors.teal.shade50,
                titleColor: Colors.teal.shade900,
                children: [
                  DetailInfoBox(
                    type: DetailInfoBoxType.highlight,
                    content:
                        '월 공제액: ${NumberFormatter.formatCurrency(profile!.otherDeductions)}\n'
                        '연간 합계: ${NumberFormatter.formatCurrency(profile!.otherDeductions * 12)}',
                  ),
                ],
              ),
              const DetailSection(
                title: '참고사항',
                icon: Icons.info_outline,
                children: [
                  DetailInfoBox(
                    type: DetailInfoBoxType.tip,
                    content:
                        '• 대부분의 단체 회비는 소득공제 대상이 아닙니다\n'
                        '• 공제 항목은 개인별로 다를 수 있습니다\n'
                        '• 급여명세서에서 상세 내역 확인 가능',
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
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 16),
    );
  }
}
