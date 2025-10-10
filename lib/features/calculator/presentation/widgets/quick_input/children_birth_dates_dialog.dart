import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';

/// 자녀 생년월일 입력 다이얼로그
///
/// 만 6세 이하 자녀의 생년월일을 입력받아 비과세 혜택을 계산합니다.
/// 각 자녀의 서수(첫째, 둘째, 셋째 등)를 표시하고 개별 날짜 선택을 지원합니다.
class ChildrenBirthDatesDialog extends StatefulWidget {
  const ChildrenBirthDatesDialog({
    super.key,
    required this.numberOfChildren,
    required this.initialBirthDates,
  });

  final int numberOfChildren;
  final List<DateTime?> initialBirthDates;

  /// Show the dialog and return updated birth dates list
  ///
  /// Returns null if cancelled, or `List<DateTime?>` if confirmed
  static Future<List<DateTime?>?> show({
    required BuildContext context,
    required int numberOfChildren,
    required List<DateTime?> initialBirthDates,
  }) async {
    return showDialog<List<DateTime?>>(
      context: context,
      builder: (BuildContext context) => ChildrenBirthDatesDialog(
        numberOfChildren: numberOfChildren,
        initialBirthDates: initialBirthDates,
      ),
    );
  }

  @override
  State<ChildrenBirthDatesDialog> createState() => _ChildrenBirthDatesDialogState();
}

class _ChildrenBirthDatesDialogState extends State<ChildrenBirthDatesDialog> {
  late List<DateTime?> _tempBirthDates;

  @override
  void initState() {
    super.initState();
    _tempBirthDates = List.from(widget.initialBirthDates);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.child_care, color: Theme.of(context).primaryColor),
          const Gap(8),
          const Expanded(
            child: Text(
              '자녀 생년월일 입력',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '만 6세 이하 자녀만 입력하시면 비과세 혜택을 받을 수 있습니다.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
            const Gap(16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.numberOfChildren,
                itemBuilder: (context, index) => _buildChildCard(context, index),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _tempBirthDates),
          child: const Text('완료'),
        ),
      ],
    );
  }

  Widget _buildChildCard(BuildContext context, int index) {
    final ordinal = _getChildOrdinal(index);
    final birthDate = _tempBirthDates[index];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.teal.shade100,
          child: Text(
            '${index + 1}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.teal.shade700,
            ),
          ),
        ),
        title: Text(
          '$ordinal 생년월일',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: birthDate != null
            ? Text(
                '${birthDate.year}년 ${birthDate.month}월 ${birthDate.day}일',
                style: const TextStyle(color: Colors.black87),
              )
            : const Text(
                '선택 안 함 (만 6세 초과)',
                style: TextStyle(color: Colors.grey),
              ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (birthDate != null)
              IconButton(
                icon: const Icon(Icons.clear, size: 20),
                onPressed: () {
                  setState(() {
                    _tempBirthDates[index] = null;
                  });
                },
                tooltip: '삭제',
              ),
            Icon(Icons.calendar_today, color: Theme.of(context).primaryColor),
          ],
        ),
        onTap: () => _showDatePicker(context, index, ordinal),
      ),
    );
  }

  Future<void> _showDatePicker(BuildContext context, int index, String ordinal) async {
    DateTime tempDate = _tempBirthDates[index] ?? DateTime.now();

    await showCupertinoModalPopup(
      context: context,
      builder: (BuildContext pickerContext) {
        return DefaultTextStyle(
          style: GoogleFonts.notoSansKr(color: Colors.black87),
          child: Container(
            height: 300,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade300, width: 0.5),
                    ),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '취소',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                        ),
                        onPressed: () => Navigator.pop(pickerContext),
                      ),
                      Text(
                        '$ordinal 생년월일',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      CupertinoButton(
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '완료',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          setState(() {
                            _tempBirthDates[index] = tempDate;
                          });
                          Navigator.pop(pickerContext);
                        },
                      ),
                    ],
                  ),
                ),
                // Date Picker
                Expanded(
                  child: CupertinoTheme(
                    data: CupertinoThemeData(
                      textTheme: CupertinoTextThemeData(
                        dateTimePickerTextStyle: GoogleFonts.notoSansKr(
                          color: Colors.black87,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.date,
                      backgroundColor: Colors.white,
                      initialDateTime: tempDate,
                      minimumYear: 2015,
                      maximumDate: DateTime.now(),
                      onDateTimeChanged: (DateTime picked) {
                        HapticFeedback.selectionClick();
                        tempDate = picked;
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getChildOrdinal(int index) {
    const ordinals = ['첫째', '둘째', '셋째', '넷째', '다섯째'];
    if (index < ordinals.length) {
      return ordinals[index];
    }
    return '${index + 1}번째';
  }
}
