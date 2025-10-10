import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';

/// 교육경력 수정 모달
///
/// 추가할 경력과 제외할 경력을 년/월 단위로 입력받아
/// 교육경력을 조정합니다 (예: 군 복무 기간 제외).
class TeachingExperienceEditModal extends StatefulWidget {
  const TeachingExperienceEditModal({
    super.key,
    required this.initialAdditionalMonths,
    required this.initialExcludedMonths,
  });

  final int initialAdditionalMonths;
  final int initialExcludedMonths;

  /// Show the modal and return updated months
  ///
  /// Returns null if cancelled, or Map with 'additional' and 'excluded' months if confirmed
  /// Returns {'additional': 0, 'excluded': 0} if reset to auto-calculation
  static Future<Map<String, int>?> show({
    required BuildContext context,
    required int initialAdditionalMonths,
    required int initialExcludedMonths,
  }) async {
    return showCupertinoModalPopup<Map<String, int>>(
      context: context,
      builder: (BuildContext context) => TeachingExperienceEditModal(
        initialAdditionalMonths: initialAdditionalMonths,
        initialExcludedMonths: initialExcludedMonths,
      ),
    );
  }

  @override
  State<TeachingExperienceEditModal> createState() => _TeachingExperienceEditModalState();
}

class _TeachingExperienceEditModalState extends State<TeachingExperienceEditModal> {
  late int _tempAdditionalYears;
  late int _tempAdditionalMonths;
  late int _tempExcludedYears;
  late int _tempExcludedMonths;

  @override
  void initState() {
    super.initState();
    _tempAdditionalYears = widget.initialAdditionalMonths ~/ 12;
    _tempAdditionalMonths = widget.initialAdditionalMonths % 12;
    _tempExcludedYears = widget.initialExcludedMonths ~/ 12;
    _tempExcludedMonths = widget.initialExcludedMonths % 12;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: GoogleFonts.notoSansKr(color: Colors.black87),
      child: Container(
        height: 600,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            _buildHeader(context),
            _buildPickers(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 0.5)),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CupertinoButton(
            minimumSize: Size.zero,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '자동계산',
              style: TextStyle(color: Colors.orange.shade700, fontSize: 15),
            ),
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.pop(context, {'additional': 0, 'excluded': 0});
            },
          ),
          const Text(
            '교육경력 수정',
            style: TextStyle(
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
              Navigator.pop(context, {
                'additional': _tempAdditionalYears * 12 + _tempAdditionalMonths,
                'excluded': _tempExcludedYears * 12 + _tempExcludedMonths,
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPickers(BuildContext context) {
    return Expanded(
      child: CupertinoTheme(
        data: CupertinoThemeData(
          textTheme: CupertinoTextThemeData(
            pickerTextStyle: GoogleFonts.notoSansKr(
              color: Colors.black87,
              fontSize: 20,
            ),
          ),
        ),
        child: Column(
          children: [
            // 추가할 경력 섹션
            _buildSectionHeader(
              icon: Icons.add_circle_outline,
              label: '추가할 경력',
              color: Colors.green.shade700,
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: _buildPicker(
                      initialItem: _tempAdditionalYears,
                      onChanged: (index) => _tempAdditionalYears = index,
                      itemCount: 11,
                      itemBuilder: (index) => '$index년',
                    ),
                  ),
                  Expanded(
                    child: _buildPicker(
                      initialItem: _tempAdditionalMonths,
                      onChanged: (index) => _tempAdditionalMonths = index,
                      itemCount: 12,
                      itemBuilder: (index) => '$index개월',
                    ),
                  ),
                ],
              ),
            ),

            // 제외할 경력 섹션
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.shade300, width: 0.5),
                  bottom: BorderSide(color: Colors.grey.shade300, width: 0.5),
                ),
              ),
              child: Column(
                children: [
                  _buildSectionHeader(
                    icon: Icons.remove_circle_outline,
                    label: '제외할 경력',
                    color: Colors.red.shade700,
                  ),
                  const Gap(2),
                  Text(
                    '예: 군 복무 개월 수',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: _buildPicker(
                      initialItem: _tempExcludedYears,
                      onChanged: (index) => _tempExcludedYears = index,
                      itemCount: 11,
                      itemBuilder: (index) => '$index년',
                    ),
                  ),
                  Expanded(
                    child: _buildPicker(
                      initialItem: _tempExcludedMonths,
                      onChanged: (index) => _tempExcludedMonths = index,
                      itemCount: 12,
                      itemBuilder: (index) => '$index개월',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: color),
          const Gap(6),
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPicker({
    required int initialItem,
    required void Function(int) onChanged,
    required int itemCount,
    required String Function(int) itemBuilder,
  }) {
    return CupertinoPicker(
      scrollController: FixedExtentScrollController(initialItem: initialItem),
      itemExtent: 40,
      backgroundColor: Colors.white,
      diameterRatio: 1.5,
      squeeze: 1.2,
      magnification: 1.1,
      useMagnifier: true,
      selectionOverlay: Container(
        decoration: BoxDecoration(
          border: Border.symmetric(
            horizontal: BorderSide(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
        ),
      ),
      onSelectedItemChanged: (index) {
        HapticFeedback.selectionClick();
        onChanged(index);
      },
      children: List.generate(
        itemCount,
        (index) => Center(child: Text(itemBuilder(index))),
      ),
    );
  }
}
