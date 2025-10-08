import 'package:flutter/material.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/lifetime_salary.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/monthly_net_income.dart';
import 'package:gong_mu_talk/core/utils/number_formatter.dart';
import 'package:fl_chart/fl_chart.dart';

/// 급여 분석 통합 페이지
///
/// 월별 급여명세, 연도별 급여 증가, 생애 시뮬레이션을 탭으로 통합
class SalaryAnalysisPage extends StatelessWidget {
  final LifetimeSalary lifetimeSalary;
  final List<MonthlyNetIncome>? monthlyBreakdown;

  const SalaryAnalysisPage({
    super.key,
    required this.lifetimeSalary,
    this.monthlyBreakdown,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('급여 분석'),
          centerTitle: true,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.calendar_month), text: '월별 명세'),
              Tab(icon: Icon(Icons.trending_up), text: '연도별 증가'),
              Tab(icon: Icon(Icons.timeline), text: '생애 시뮬레이션'),
            ],
          ),
        ),
        body: TabBarView(
          physics: const NeverScrollableScrollPhysics(),
          children: [
            // 탭 1: 월별 급여명세
            _MonthlyBreakdownTab(monthlyBreakdown: monthlyBreakdown),
            // 탭 2: 연도별 급여 증가
            _AnnualGrowthTab(lifetimeSalary: lifetimeSalary),
            // 탭 3: 생애 시뮬레이션
            _LifetimeSimulationTab(lifetimeSalary: lifetimeSalary),
          ],
        ),
      ),
    );
  }
}

/// 탭 1: 월별 급여명세
class _MonthlyBreakdownTab extends StatelessWidget {
  final List<MonthlyNetIncome>? monthlyBreakdown;

  const _MonthlyBreakdownTab({this.monthlyBreakdown});

  @override
  Widget build(BuildContext context) {
    if (monthlyBreakdown == null || monthlyBreakdown!.isEmpty) {
      return const Center(child: Text('월별 급여 데이터가 없습니다.'));
    }

    final annualNet = monthlyBreakdown!.fold<int>(
      0,
      (sum, m) => sum + m.netIncome,
    );

    return Column(
      children: [
        // 연간 총액 요약
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal.shade400, Colors.teal.shade600],
            ),
          ),
          child: Column(
            children: [
              const Text(
                '연간 총 실수령액',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                NumberFormatter.formatCurrency(annualNet),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '평균 월 ${NumberFormatter.formatCurrency(annualNet ~/ 12)}',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),

        // 월별 리스트
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: monthlyBreakdown!.length,
            itemBuilder: (context, index) {
              final month = monthlyBreakdown![index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  title: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: (month.hasPerformanceBonus ||
                                  month.hasLongevityBonus ||
                                  month.hasHolidayBonus)
                              ? Colors.orange.shade100
                              : Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${month.month}월',
                          style: TextStyle(
                            color: (month.hasPerformanceBonus ||
                                    month.hasLongevityBonus ||
                                    month.hasHolidayBonus)
                                ? Colors.orange.shade900
                                : Colors.teal.shade900,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (month.hasPerformanceBonus) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star, size: 12, color: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                '성과상여금',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (month.hasLongevityBonus) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.teal,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.celebration, size: 12, color: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                '정근수당',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (month.hasHolidayBonus) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.pink,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.card_giftcard, size: 12, color: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                '명절휴가비',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '실수령액: ${NumberFormatter.formatCurrency(month.netIncome)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildDetailRow('기본급', month.baseSalary),
                          const SizedBox(height: 8),
                          // 교직 수당 (확장 가능)
                          _buildExpandableAllowanceSection(context, month),
                          if (month.performanceBonus > 0) ...[
                            const SizedBox(height: 8),
                            _buildDetailRow(
                              '성과상여금 (${month.month}월)',
                              month.performanceBonus,
                              highlight: true,
                              color: Colors.amber.shade900,
                            ),
                          ],
                          if (month.longevityBonus > 0) ...[
                            const SizedBox(height: 8),
                            _buildDetailRow(
                              '정근수당 (${month.month}월)',
                              month.longevityBonus,
                              highlight: true,
                              color: Colors.teal.shade700,
                            ),
                          ],
                          if (month.holidayBonus > 0) ...[
                            const SizedBox(height: 8),
                            _buildDetailRow(
                              '명절휴가비 (${month.month}월)',
                              month.holidayBonus,
                              highlight: true,
                              color: Colors.pink.shade700,
                            ),
                          ],
                          const Divider(height: 24),
                          _buildDetailRow(
                            '총 지급액',
                            month.grossSalary,
                            isBold: true,
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            '총 공제액 (${month.deductionRate.toStringAsFixed(1)}%)',
                            -month.totalDeductions,
                            color: Colors.red,
                          ),
                          const Divider(height: 24),
                          _buildDetailRow(
                            '실수령액',
                            month.netIncome,
                            isBold: true,
                            isHighlight: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(
    String label,
    int amount, {
    bool isBold = false,
    bool isHighlight = false,
    bool highlight = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
              color: color ?? (highlight ? Colors.orange.shade900 : null),
            ),
          ),
          Text(
            NumberFormatter.formatCurrency(amount),
            style: TextStyle(
              fontWeight: isBold || highlight
                  ? FontWeight.bold
                  : FontWeight.normal,
              color:
                  color ??
                  (isHighlight
                      ? Colors.teal[700]
                      : (highlight ? Colors.orange.shade900 : null)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableAllowanceSection(
    BuildContext context,
    MonthlyNetIncome month,
  ) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(left: 16, bottom: 8),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('교직 수당'),
            Text(
              NumberFormatter.formatCurrency(month.totalAllowances),
              style: const TextStyle(fontWeight: FontWeight.normal),
            ),
          ],
        ),
        children: [
          if (month.teachingAllowance > 0)
            _buildTappableDetailRow(
              context,
              '교직수당 (모든 교사)',
              month.teachingAllowance,
              detailedInfo: '''📚 교직수당

【지급 대상】
• 모든 교육공무원

【지급액】
• 250,000원 (고정)

【지급 방식】
• 매월 급여와 함께 지급

💡 교직수당은 모든 교사에게 동일하게 지급되는 기본 수당입니다.''',
            ),
          if (month.homeroomAllowance > 0) ...[
            const SizedBox(height: 4),
            _buildTappableDetailRow(
              context,
              '담임 수당 (가산금 4)',
              month.homeroomAllowance,
              detailedInfo: '''🏛️ 담임수당

【지급 대상】
• 학급 담임을 맡은 교사

【지급액】
• 교직수당 가산금 4 해당

【지급 방식】
• 매월 급여와 함께 지급
• 담임 기간 동안만 지급

💡 학급 담임을 맡으면 추가로 지급되는 수당입니다.''',
            ),
          ],
          if (month.positionAllowance > 0) ...[
            const SizedBox(height: 4),
            _buildTappableDetailRow(
              context,
              '보직교사 수당 (가산금 3)',
              month.positionAllowance,
              detailedInfo: '''👔 보직교사수당

【지급 대상】
• 보직교사 (부장, 교무, 연구부장 등)

【지급액】
• 교직수당 가산금 3 해당

【지급 방식】
• 매월 급여와 함께 지급
• 보직 기간 동안만 지급

💡 보직을 맡은 교사에게 추가로 지급되는 수당입니다.''',
            ),
          ],
          if (month.longevityMonthly > 0) ...[
            const SizedBox(height: 4),
            _buildTappableDetailRow(
              context,
              '정근수당 가산금',
              month.longevityMonthly,
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
          ],
          if (month.veteranAllowance > 0) ...[
            const SizedBox(height: 4),
            _buildTappableDetailRow(
              context,
              '원로교사수당',
              month.veteranAllowance,
              detailedInfo: '''🎓 원로교사수당

【지급 기준】
• 월 50,000원
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
          ],
          if (month.familyAllowance > 0) ...[
            const SizedBox(height: 4),
            _buildTappableDetailRow(
              context,
              '가족수당',
              month.familyAllowance,
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
          ],
          if (month.researchAllowance > 0) ...[
            const SizedBox(height: 4),
            _buildTappableDetailRow(
              context,
              '연구비',
              month.researchAllowance,
              detailedInfo: '''📖 연구비

【지급 기준】
• 5년 미만: 70,000원
• 5년 이상: 60,000원

【지급 방식】
• 매월 급여와 함께 지급
• 교육활동 및 연구 활동 지원

💡 교육 및 연구 활동을 위한 수당입니다.''',
            ),
          ],
          if (month.overtimeAllowance > 0) ...[
            const SizedBox(height: 4),
            _buildTappableDetailRow(
              context,
              '시간외근무수당',
              month.overtimeAllowance,
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
          ],
          if (month.specialEducationAllowance > 0) ...[
            const SizedBox(height: 4),
            _buildTappableDetailRow(
              context,
              '특수교사 가산금',
              month.specialEducationAllowance,
              detailedInfo: '''🎓 특수교사 가산금

【지급 기준】
• 월 120,000원
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
          ],
          if (month.vocationalEducationAllowance > 0) ...[
            const SizedBox(height: 4),
            _buildTappableDetailRow(
              context,
              '특성화교사 가산금',
              month.vocationalEducationAllowance,
              detailedInfo: '''🏫 특성화교사 가산금

【지급 기준】
• 교직수당 가산금 5 해당
• 호봉에 따라 차등 지급

【호봉별 지급액】
• 1~4호봉: 25,000원
• 5~30호봉: 호봉별 선형 증가
• 31~40호봉: 50,000원

【지급 대상】
• 특성화고등학교 교사
• 마이스터고 교사
• 실업계 고교 실습 지도 교사

【지급 방식】
• 매월 급여와 함께 지급
• 담임수당, 보직교사수당과 중복 수령 가능

💡 직업교육을 담당하는 교사에 대한 수당입니다.''',
            ),
          ],
          if (month.healthTeacherAllowance > 0) ...[
            const SizedBox(height: 4),
            _buildTappableDetailRow(
              context,
              '보건교사 가산금',
              month.healthTeacherAllowance,
              detailedInfo: '''⚕️ 보건교사 가산금

【지급 기준】
• 월 40,000원
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
          ],
          if (month.concurrentPositionAllowance > 0) ...[
            const SizedBox(height: 4),
            _buildTappableDetailRow(
              context,
              '겸직수당',
              month.concurrentPositionAllowance,
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
          ],
          if (month.nutritionTeacherAllowance > 0) ...[
            const SizedBox(height: 4),
            _buildTappableDetailRow(
              context,
              '영양교사 가산금',
              month.nutritionTeacherAllowance,
              detailedInfo: '''🍽️ 영양교사 가산금

【지급 기준】
• 월 40,000원
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
          ],
          if (month.librarianAllowance > 0) ...[
            const SizedBox(height: 4),
            _buildTappableDetailRow(
              context,
              '사서교사 가산금',
              month.librarianAllowance,
              detailedInfo: '''📚 사서교사 가산금

【지급 기준】
• 월 30,000원
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
          ],
          if (month.counselorAllowance > 0) ...[
            const SizedBox(height: 4),
            _buildTappableDetailRow(
              context,
              '전문상담교사 가산금',
              month.counselorAllowance,
              detailedInfo: '''💬 전문상담교사 가산금

【지급 기준】
• 월 30,000원
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
          ],
        ],
      ),
    );
  }

  /// 탭 가능한 상세 정보 행
  Widget _buildTappableDetailRow(
    BuildContext context,
    String label,
    int amount, {
    String? detailedInfo,
  }) {
    return InkWell(
      onTap: detailedInfo != null
          ? () => _showDetailDialog(context, label, amount, detailedInfo)
          : null,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(child: Text(label)),
                  if (detailedInfo != null) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                  ],
                ],
              ),
            ),
            Text(
              NumberFormatter.formatCurrency(amount),
              style: const TextStyle(fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
    );
  }

  /// 상세 정보 다이얼로그 표시
  void _showDetailDialog(
    BuildContext context,
    String title,
    int amount,
    String detailedInfo,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '월 지급액',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      NumberFormatter.formatCurrency(amount),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.teal.shade900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                detailedInfo,
                style: const TextStyle(height: 1.6),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }
}

/// 탭 2: 연도별 급여 증가
class _AnnualGrowthTab extends StatelessWidget {
  final LifetimeSalary lifetimeSalary;

  const _AnnualGrowthTab({required this.lifetimeSalary});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 요약 카드
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📊 요약',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSummaryItem(
                    context,
                    '평균 연봉',
                    NumberFormatter.formatCurrency(
                      lifetimeSalary.avgAnnualSalary,
                    ),
                  ),
                  const Divider(height: 24),
                  _buildSummaryItem(
                    context,
                    '총 재직 기간',
                    '${lifetimeSalary.totalYears}년',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 차트
          Text(
            '📈 연도별 급여 증가 추이',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(height: 250, child: _buildLineChart(context)),
            ),
          ),

          const SizedBox(height: 24),

          // 연도별 리스트
          Text(
            '📅 연도별 상세',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: lifetimeSalary.annualSalaries.length,
            itemBuilder: (context, index) {
              final salary = lifetimeSalary.annualSalaries[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(
                    '${salary.year}년 (${salary.grade}호봉)',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '월 실수령: ${NumberFormatter.formatCurrency(salary.netPay)}',
                  ),
                  trailing: Text(
                    NumberFormatter.formatCurrency(salary.annualTotalPay),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.teal[700],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyLarge),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildLineChart(BuildContext context) {
    final theme = Theme.of(context);
    final netPayData = lifetimeSalary.annualSalaries
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.netPay.toDouble()))
        .toList();

    final maxPay = lifetimeSalary.annualSalaries
        .map((s) => s.netPay)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxPay / 5,
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${(value / 10000).toInt()}만',
                  style: theme.textTheme.bodySmall,
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 5,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= lifetimeSalary.annualSalaries.length ||
                    value.toInt() % 5 != 0) {
                  return const SizedBox();
                }
                return Text(
                  '${value.toInt() + 1}년',
                  style: theme.textTheme.bodySmall,
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: netPayData,
            isCurved: true,
            color: theme.colorScheme.primary,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }
}

/// 탭 3: 생애 시뮬레이션
class _LifetimeSimulationTab extends StatelessWidget {
  final LifetimeSalary lifetimeSalary;

  const _LifetimeSimulationTab({required this.lifetimeSalary});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 메인 카드
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.savings,
                    size: 48,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '생애 총 소득',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    NumberFormatter.formatCurrency(lifetimeSalary.totalIncome),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 상세 정보
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '💰 상세 정보',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    context,
                    '명목 가치',
                    NumberFormatter.formatCurrency(lifetimeSalary.totalIncome),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    context,
                    '현재 가치',
                    NumberFormatter.formatCurrency(lifetimeSalary.presentValue),
                    subtitle:
                        '인플레이션 ${NumberFormatter.formatPercent(lifetimeSalary.inflationRate)} 반영',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    context,
                    '평균 연봉',
                    NumberFormatter.formatCurrency(
                      lifetimeSalary.avgAnnualSalary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    context,
                    '재직 기간',
                    '${lifetimeSalary.startYear}년 ~ ${lifetimeSalary.endYear}년 (${lifetimeSalary.totalYears}년)',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 안내 메시지
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '생애 총 소득 계산 방식',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• 명목 가치: 각 연도 급여를 그대로 합산\n'
                        '• 현재 가치: 인플레이션을 고려한 실질 가치\n'
                        '• 실제 수령액은 개인의 승진, 수당 등에 따라 달라질 수 있습니다',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue[800],
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value, {
    String? subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
              textAlign: TextAlign.right,
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          ),
        ],
      ],
    );
  }
}
