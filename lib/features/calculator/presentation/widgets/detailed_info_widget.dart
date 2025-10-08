import 'package:flutter/material.dart';

/// 상세 정보 표시 유형
enum DetailInfoBoxType {
  tip,      // 💡 팁
  warning,  // ⚠️ 경고
  highlight, // ✨ 강조
  info,     // ℹ️ 정보
}

/// 상세 정보 표시 색상 팔레트
class DetailInfoColors {
  static const income = Colors.teal;
  static const deduction = Colors.red;
  static const warning = Colors.orange;
  static const tip = Colors.blue;
  static const highlight = Colors.green;
  static const neutral = Colors.grey;
}

/// 상세 정보 표시 텍스트 스타일
class DetailInfoTextStyles {
  static const sectionTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );

  static const amount = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );

  static const description = TextStyle(
    fontSize: 14,
    height: 1.5,
  );

  static const tableHeader = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.bold,
  );

  static const tableCell = TextStyle(
    fontSize: 13,
  );
}

/// 구조화된 상세 정보 위젯
class DetailedInfoWidget extends StatelessWidget {
  final List<Widget> sections;
  final String? userExample;

  const DetailedInfoWidget({
    super.key,
    required this.sections,
    this.userExample,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...sections.map((section) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: section,
              )),
          if (userExample != null) ...[
            const SizedBox(height: 4),
            DetailInfoBox(
              type: DetailInfoBoxType.info,
              content: userExample!,
              icon: Icons.person,
            ),
          ],
        ],
      ),
    );
  }
}

/// 섹션 (제목 + 내용)
class DetailSection extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? titleColor;
  final List<Widget> children;

  const DetailSection({
    super.key,
    required this.title,
    this.icon,
    this.backgroundColor,
    this.titleColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: backgroundColor != null
              ? backgroundColor!.withValues(alpha: 0.3)
              : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 18,
                  color: titleColor ?? Colors.black87,
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  title,
                  style: DetailInfoTextStyles.sectionTitle.copyWith(
                    color: titleColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

/// 표 형식 데이터
class DetailTable extends StatelessWidget {
  final List<String> headers;
  final List<List<String>> rows;
  final Color? headerColor;
  final Color? borderColor;

  const DetailTable({
    super.key,
    required this.headers,
    required this.rows,
    this.headerColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor ?? Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // 헤더
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: headerColor ?? Colors.blue.shade50,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(7),
              ),
            ),
            child: Row(
              children: headers.map((header) {
                return Expanded(
                  child: Text(
                    header,
                    style: DetailInfoTextStyles.tableHeader.copyWith(
                      color: Colors.blue.shade900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              }).toList(),
            ),
          ),
          // 행들
          ...rows.asMap().entries.map((entry) {
            final index = entry.key;
            final row = entry.value;
            final isLast = index == rows.length - 1;

            return Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              decoration: BoxDecoration(
                color: index % 2 == 0 ? Colors.white : Colors.grey.shade50,
                border: !isLast
                    ? Border(
                        bottom: BorderSide(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      )
                    : null,
              ),
              child: Row(
                children: row.map((cell) {
                  return Expanded(
                    child: Text(
                      cell,
                      style: DetailInfoTextStyles.tableCell,
                      textAlign: TextAlign.center,
                    ),
                  );
                }).toList(),
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// 계산 과정 표시
class DetailCalculation extends StatelessWidget {
  final String? label;
  final String baseAmount;
  final String rate;
  final String result;
  final List<String>? steps;

  const DetailCalculation({
    super.key,
    this.label,
    required this.baseAmount,
    required this.rate,
    required this.result,
    this.steps,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null) ...[
            Row(
              children: [
                Icon(Icons.calculate, size: 16, color: Colors.blue.shade700),
                const SizedBox(width: 6),
                Text(
                  label!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          if (steps != null && steps!.isNotEmpty) ...[
            ...steps!.map((step) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 8),
            Divider(color: Colors.blue.shade200, height: 1),
            const SizedBox(height: 8),
          ],
          // 계산 공식
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                baseAmount,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              Row(
                children: [
                  const SizedBox(width: 16),
                  Text(
                    '× $rate',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                width: 120,
                height: 1.5,
                color: Colors.blue.shade300,
              ),
              const SizedBox(height: 8),
              Text(
                '= $result',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 정보/팁/경고 박스
class DetailInfoBox extends StatelessWidget {
  final DetailInfoBoxType type;
  final String content;
  final IconData? icon;

  const DetailInfoBox({
    super.key,
    required this.type,
    required this.content,
    this.icon,
  });

  Color _getBackgroundColor() {
    switch (type) {
      case DetailInfoBoxType.tip:
        return Colors.blue.shade50;
      case DetailInfoBoxType.warning:
        return Colors.orange.shade50;
      case DetailInfoBoxType.highlight:
        return Colors.green.shade50;
      case DetailInfoBoxType.info:
        return Colors.grey.shade100;
    }
  }

  Color _getBorderColor() {
    switch (type) {
      case DetailInfoBoxType.tip:
        return Colors.blue.shade200;
      case DetailInfoBoxType.warning:
        return Colors.orange.shade300;
      case DetailInfoBoxType.highlight:
        return Colors.green.shade300;
      case DetailInfoBoxType.info:
        return Colors.grey.shade300;
    }
  }

  Color _getIconColor() {
    switch (type) {
      case DetailInfoBoxType.tip:
        return Colors.blue.shade700;
      case DetailInfoBoxType.warning:
        return Colors.orange.shade700;
      case DetailInfoBoxType.highlight:
        return Colors.green.shade700;
      case DetailInfoBoxType.info:
        return Colors.grey.shade700;
    }
  }

  IconData _getDefaultIcon() {
    switch (type) {
      case DetailInfoBoxType.tip:
        return Icons.lightbulb_outline;
      case DetailInfoBoxType.warning:
        return Icons.warning_amber_rounded;
      case DetailInfoBoxType.highlight:
        return Icons.star_outline;
      case DetailInfoBoxType.info:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getBorderColor()),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon ?? _getDefaultIcon(),
            size: 18,
            color: _getIconColor(),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              content,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 리스트 아이템 (체크박스 스타일)
class DetailListItem extends StatelessWidget {
  final String text;
  final bool isChecked;
  final Color? color;

  const DetailListItem({
    super.key,
    required this.text,
    this.isChecked = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isChecked ? Icons.check_circle : Icons.circle_outlined,
            size: 16,
            color: color ?? (isChecked ? Colors.green : Colors.grey.shade400),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
