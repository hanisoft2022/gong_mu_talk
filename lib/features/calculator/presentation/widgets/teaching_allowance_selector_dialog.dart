import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/teaching_allowance_bonus.dart';

/// 교직수당 가산금 선택 다이얼로그
class TeachingAllowanceSelectorDialog extends StatefulWidget {
  final Set<TeachingAllowanceBonus> initialSelection;

  const TeachingAllowanceSelectorDialog({
    super.key,
    required this.initialSelection,
  });

  @override
  State<TeachingAllowanceSelectorDialog> createState() =>
      _TeachingAllowanceSelectorDialogState();

  /// 다이얼로그를 표시하고 선택된 가산금을 반환
  static Future<Set<TeachingAllowanceBonus>?> show(
    BuildContext context, {
    required Set<TeachingAllowanceBonus> initialSelection,
  }) async {
    return showDialog<Set<TeachingAllowanceBonus>>(
      context: context,
      builder: (context) => TeachingAllowanceSelectorDialog(
        initialSelection: initialSelection,
      ),
    );
  }
}

class _TeachingAllowanceSelectorDialogState
    extends State<TeachingAllowanceSelectorDialog> {
  late Set<TeachingAllowanceBonus> _tempSelection;

  @override
  void initState() {
    super.initState();
    _tempSelection = Set<TeachingAllowanceBonus>.from(widget.initialSelection);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.school, color: Colors.teal.shade700, size: 24),
          const Gap(12),
          const Expanded(
            child: Text(
              '교직수당 가산금 선택',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      contentPadding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '해당되는 항목을 모두 선택하세요',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),
              const Gap(16),
              ...TeachingAllowanceBonus.values.map((bonus) {
                final isSelected = _tempSelection.contains(bonus);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildBonusItem(bonus, isSelected),
                );
              }),
            ],
          ),
        ),
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  '취소',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ),
            const Gap(8),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, _tempSelection);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.teal.shade600,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  '확인 (${_tempSelection.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBonusItem(TeachingAllowanceBonus bonus, bool isSelected) {
    return InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            _tempSelection.remove(bonus);
          } else {
            _tempSelection.add(bonus);
          }
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.teal.shade400 : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? Colors.teal.shade50 : Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Checkbox
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.teal.shade600 : Colors.white,
                  border: Border.all(
                    color: isSelected
                        ? Colors.teal.shade600
                        : Colors.grey.shade400,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.white,
                      )
                    : null,
              ),
              const Gap(16),
              // 항목 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bonus.displayName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color:
                            isSelected ? Colors.teal.shade900 : Colors.black87,
                      ),
                    ),
                    const Gap(4),
                    Text(
                      bonus.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(12),
              // 금액
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color:
                      isSelected ? Colors.teal.shade600 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${(bonus.amount / 10000).toInt()}만원',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
