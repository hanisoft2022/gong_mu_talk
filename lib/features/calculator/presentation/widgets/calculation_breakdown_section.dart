import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:gap/gap.dart';
import 'package:gong_mu_talk/common/widgets/info_dialog.dart';
import 'package:gong_mu_talk/core/utils/number_formatter.dart';
import 'package:url_launcher/url_launcher.dart';

/// 계산 근거 표시 섹션 (ExpansionTile)
///
/// Progressive Disclosure 패턴으로 계산 상세를 접기/펼치기
class CalculationBreakdownSection extends StatelessWidget {
  final List<BreakdownItem> items;
  final int? totalAmount;
  final String? totalLabel;
  final bool initiallyExpanded;

  const CalculationBreakdownSection({
    super.key,
    required this.items,
    this.totalAmount,
    this.totalLabel,
    this.initiallyExpanded = false,
  });

  void _showOvertimeAllowanceInfo(BuildContext context) {
    InfoDialog.showWidget(
      context,
      title: '시간외근무수당 지급 기준',
      icon: Icons.access_time_outlined,
      iconColor: Colors.teal.shade600,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '2025년 기준 정액분 (월)',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const Gap(16),
          _buildInfoItem('1~19호봉', '123,130원', '(시간당 12,313원 × 10시간)'),
          Divider(height: 24, thickness: 1, color: Colors.grey.shade200),
          _buildInfoItem('20~29호봉', '137,330원', '(시간당 13,733원 × 10시간)'),
          Divider(height: 24, thickness: 1, color: Colors.grey.shade200),
          _buildInfoItem('30호봉 이상', '147,410원', '(시간당 14,741원 × 10시간)'),
          const Gap(16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, size: 16, color: Colors.teal.shade700),
                const Gap(8),
                Expanded(
                  child: Text(
                    '승급 시 해당 월부터 새 기준 적용',
                    style: TextStyle(fontSize: 12, color: Colors.teal.shade700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String grade, String amount, String detail) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              grade,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            Text(
              amount,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.teal.shade700,
              ),
            ),
          ],
        ),
        const Gap(4),
        Text(
          detail,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildDetailedInfoText(String text) {
    final spans = <TextSpan>[];
    int currentIndex = 0;

    // 교육공무원 호봉표 링크 패턴
    final salaryTablePattern = RegExp(r'교육공무원 호봉표');
    // 닉네임 패턴: "[닉네임] 선생님의"
    final nicknamePattern = RegExp(r'^(.+?)\s*선생님의');

    // 닉네임 패턴 먼저 처리
    final nicknameMatch = nicknamePattern.firstMatch(text);
    String? nickname;
    int nicknameStart = -1;
    int nicknameEnd = -1;

    if (nicknameMatch != null && nicknameMatch.group(1) != '선생님') {
      nickname = nicknameMatch.group(1);
      nicknameStart = nicknameMatch.start;
      nicknameEnd = nicknameMatch.end;
    }

    // 교육공무원 호봉표 패턴 처리
    for (final match in salaryTablePattern.allMatches(text)) {
      // 현재 위치부터 매치 시작까지의 텍스트
      if (currentIndex < match.start) {
        final segment = text.substring(currentIndex, match.start);

        // 닉네임 영역과 겹치는지 확인
        if (nickname != null && currentIndex <= nicknameStart && nicknameStart < match.start) {
          // 닉네임 이전 텍스트
          if (currentIndex < nicknameStart) {
            spans.add(TextSpan(text: text.substring(currentIndex, nicknameStart)));
          }
          // 닉네임 (강조)
          spans.add(TextSpan(
            text: nickname,
            style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
          ));
          // "선생님의"
          spans.add(const TextSpan(text: ' 선생님의'));
          // 닉네임 끝부터 링크 시작까지
          if (nicknameEnd < match.start) {
            spans.add(TextSpan(text: text.substring(nicknameEnd, match.start)));
          }
        } else {
          spans.add(TextSpan(text: segment));
        }
      }

      // 교육공무원 호봉표 (링크)
      spans.add(
        TextSpan(
          text: match.group(0),
          style: TextStyle(
            color: Colors.teal.shade700,
            decoration: TextDecoration.underline,
            fontWeight: FontWeight.w600,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () async {
              final url = Uri.parse('https://www.mpm.go.kr/mpm/info/resultPay/bizSalary/2025/');
              debugPrint('🔗 Attempting to open URL: $url');

              final canLaunch = await canLaunchUrl(url);
              debugPrint('🔗 canLaunchUrl result: $canLaunch');

              if (canLaunch) {
                final result = await launchUrl(url, mode: LaunchMode.externalApplication);
                debugPrint('🔗 launchUrl result: $result');
              } else {
                debugPrint('❌ Cannot launch URL: $url');
              }
            },
        ),
      );

      currentIndex = match.end;
    }

    // 남은 텍스트 처리
    if (currentIndex < text.length) {
      final remaining = text.substring(currentIndex);

      // 닉네임 영역과 겹치는지 확인
      if (nickname != null && currentIndex <= nicknameStart) {
        // 닉네임 이전 텍스트
        if (currentIndex < nicknameStart) {
          spans.add(TextSpan(text: text.substring(currentIndex, nicknameStart)));
        }
        // 닉네임 (강조)
        spans.add(TextSpan(
          text: nickname,
          style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
        ));
        // "선생님의"
        spans.add(const TextSpan(text: ' 선생님의'));
        // 닉네임 이후 텍스트
        if (nicknameEnd < text.length) {
          spans.add(TextSpan(text: text.substring(nicknameEnd)));
        }
      } else {
        spans.add(TextSpan(text: remaining));
      }
    }

    // 패턴이 없으면 기본 텍스트 반환
    if (spans.isEmpty) {
      return Text(text, style: const TextStyle(fontSize: 14, height: 1.6));
    }

    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 14, height: 1.6, color: Colors.black87),
        children: spans,
      ),
    );
  }

  void _showItemDetailDialog(BuildContext context, BreakdownItem item) {
    // 항목별 상세 정보 다이얼로그
    String title = item.label;
    Widget content;

    // 시간외근무수당인 경우 기존 다이얼로그 표시
    if (item.label.contains('시간외근무수당')) {
      _showOvertimeAllowanceInfo(context);
      return;
    }

    // 1. 구조화된 위젯이 있으면 우선 사용
    if (item.detailedWidget != null) {
      content = item.detailedWidget!;
    }
    // 2. 텍스트 기반 detailedInfo가 있으면 사용 (하위 호환)
    else if (item.detailedInfo != null) {
      content = SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [_buildDetailedInfoText(item.detailedInfo!)],
        ),
      );
    }
    // 3. 둘 다 없으면 기본 정보만 표시
    else {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.description != null) ...[
            Text(
              item.description!,
              style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.5),
            ),
            const Gap(16),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '지급액',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              Text(
                item.isDeduction
                    ? '- ${NumberFormatter.formatCurrency(item.amount)}'
                    : NumberFormatter.formatCurrency(item.amount),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: item.isDeduction
                      ? Colors.red.shade700
                      : Colors.teal.shade700,
                ),
              ),
            ],
          ),
        ],
      );
    }

    InfoDialog.showWidget(
      context,
      title: title,
      icon: item.icon,
      iconColor: item.iconColor ?? Colors.teal.shade600,
      content: content,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          title: Row(
            children: [
              Icon(Icons.calculate, size: 18, color: Colors.teal.shade700),
              const SizedBox(width: 8),
              Text(
                '계산 근거 보기',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.teal.shade900,
                ),
              ),
            ],
          ),
          children: [
            ...items.map((item) => _buildBreakdownItem(context, item)),
            if (totalAmount != null) ...[
              const SizedBox(height: 12),
              const Divider(thickness: 1.5),
              const SizedBox(height: 12),
              _buildTotalRow(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownItem(BuildContext context, BreakdownItem item) {
    // 구분선 처리
    if (item.isDivider) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Divider(height: 1, thickness: 1),
      );
    }

    // 공백 처리
    if (item.isSpacer) {
      return const SizedBox(height: 16);
    }

    // 섹션 헤더 처리
    if (item.isSectionHeader) {
      return Container(
        margin: const EdgeInsets.only(top: 12, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          item.label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
      );
    }

    // 빈 항목 (Spacer)은 탭 불가능
    final isTappable = item.label.isNotEmpty && item.amount != 0;

    return InkWell(
      onTap: isTappable ? () => _showItemDetailDialog(context, item) : null,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 아이콘 (있는 경우)
            if (item.icon != null) ...[
              Icon(
                item.icon,
                size: 16,
                color:
                    item.iconColor ??
                    (item.isHighlight
                        ? Colors.orange.shade700
                        : (item.isDeduction ? Colors.red.shade600 : Colors.grey[600])),
              ),
              const SizedBox(width: 8),
            ],
            // 레이블
            Expanded(
              child: Text(
                item.label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: item.isHighlight ? FontWeight.w600 : FontWeight.normal,
                  color: item.isHighlight
                      ? Colors.orange.shade900
                      : (item.isDeduction ? Colors.red.shade700 : Colors.black87),
                ),
              ),
            ),
            // 금액
            if (item.amount > 0 || item.isDeduction)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  item.isDeduction
                      ? '- ${NumberFormatter.formatCurrency(item.amount)}'
                      : NumberFormatter.formatCurrency(item.amount),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: item.isHighlight
                        ? Colors.orange.shade900
                        : (item.isDeduction ? Colors.red.shade700 : Colors.black87),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalRow(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            totalLabel ?? '합계',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.teal.shade900,
            ),
          ),
          Text(
            NumberFormatter.formatCurrency(totalAmount!),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.teal.shade900,
            ),
          ),
        ],
      ),
    );
  }
}

/// 계산 근거 항목
class BreakdownItem {
  final String label;
  final int amount;
  final String? description;
  final IconData? icon;
  final Color? iconColor;
  final bool isHighlight;
  final bool isDeduction;
  final String? detailedInfo; // 상세 정보 (다이얼로그용 - 텍스트 기반, 하위 호환)
  final Widget? detailedWidget; // 상세 정보 (다이얼로그용 - 구조화된 위젯)
  final String? calculationFormula; // 계산 공식
  final Map<String, dynamic>? userData; // 사용자 실제 값
  final bool isDivider; // 구분선 여부
  final bool isSpacer; // 공백 여부

  const BreakdownItem({
    required this.label,
    required this.amount,
    this.description,
    this.icon,
    this.iconColor,
    this.isHighlight = false,
    this.isDeduction = false,
    this.detailedInfo,
    this.detailedWidget,
    this.calculationFormula,
    this.userData,
    this.isDivider = false,
    this.isSpacer = false,
  });

  /// 구분선 생성자
  const BreakdownItem.divider()
      : label = '',
        amount = 0,
        description = null,
        icon = null,
        iconColor = null,
        isHighlight = false,
        isDeduction = false,
        detailedInfo = null,
        detailedWidget = null,
        calculationFormula = null,
        userData = null,
        isDivider = true,
        isSpacer = false;

  /// 공백 생성자
  const BreakdownItem.spacer()
      : label = '',
        amount = 0,
        description = null,
        icon = null,
        iconColor = null,
        isHighlight = false,
        isDeduction = false,
        detailedInfo = null,
        detailedWidget = null,
        calculationFormula = null,
        userData = null,
        isDivider = false,
        isSpacer = true;

  /// 섹션 헤더 생성자
  BreakdownItem.sectionHeader(String title)
      : label = title,
        amount = 0,
        description = null,
        icon = null,
        iconColor = null,
        isHighlight = false,
        isDeduction = false,
        detailedInfo = null,
        detailedWidget = null,
        calculationFormula = null,
        userData = null,
        isDivider = false,
        isSpacer = false;

  /// 섹션 헤더인지 확인
  bool get isSectionHeader => label.isNotEmpty && amount == 0 && icon == null && !isDivider && !isSpacer;
}

/// 계산 근거 그룹 (섹션 구분용)
class BreakdownGroup extends StatelessWidget {
  final String title;
  final List<BreakdownItem> items;
  final Color? titleColor;

  const BreakdownGroup({super.key, required this.title, required this.items, this.titleColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: titleColor ?? Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (item.icon != null) ...[
                      Icon(item.icon, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                    ],
                    Text(item.label, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
                Text(
                  item.isDeduction
                      ? '- ${NumberFormatter.formatCurrency(item.amount)}'
                      : NumberFormatter.formatCurrency(item.amount),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: item.isDeduction ? Colors.red[700] : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
