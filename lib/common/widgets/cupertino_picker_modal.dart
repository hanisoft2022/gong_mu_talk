import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Generic Cupertino Picker Modal
///
/// Reusable picker modal for selecting from a list of items.
/// Replaces 7+ duplicate picker implementations in quick_input_bottom_sheet.dart.
///
/// Example:
/// ```dart
/// final selectedGrade = await CupertinoPickerModal.show<int>(
///   context: context,
///   title: '호봉 선택',
///   items: List.generate(35, (i) => i + 6),
///   initialItem: currentGrade,
///   itemBuilder: (grade) => '$grade호봉',
/// );
/// ```
class CupertinoPickerModal {
  CupertinoPickerModal._();

  /// Show picker modal and return selected item
  ///
  /// [T] - Type of items (e.g., int, String, enum)
  /// [context] - Build context
  /// [title] - Modal title
  /// [items] - List of selectable items
  /// [initialItem] - Initially selected item
  /// [itemBuilder] - Function to convert item to display text
  /// [onItemChanged] - Optional callback when item changes (for haptic feedback)
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required List<T> items,
    required T initialItem,
    required String Function(T) itemBuilder,
    void Function(T)? onItemChanged,
  }) async {
    if (items.isEmpty) {
      throw ArgumentError('items cannot be empty');
    }

    final initialIndex = items.indexOf(initialItem);
    if (initialIndex == -1) {
      throw ArgumentError('initialItem must be in items list');
    }

    T tempItem = initialItem;

    final T? result = await showCupertinoModalPopup<T>(
      context: context,
      builder: (BuildContext modalContext) {
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
                _buildHeader(
                  context: modalContext,
                  title: title,
                  onCancel: () => Navigator.pop(modalContext),
                  onDone: () {
                    HapticFeedback.mediumImpact();
                    Navigator.pop(modalContext, tempItem);
                  },
                ),

                // Picker
                Expanded(
                  child: CupertinoPicker(
                    scrollController: FixedExtentScrollController(
                      initialItem: initialIndex,
                    ),
                    itemExtent: 40,
                    onSelectedItemChanged: (int index) {
                      tempItem = items[index];
                      HapticFeedback.selectionClick();
                      onItemChanged?.call(tempItem);
                    },
                    children: items
                        .map(
                          (item) => Center(
                            child: Text(
                              itemBuilder(item),
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    return result;
  }

  /// Build modal header with cancel/done buttons
  static Widget _buildHeader({
    required BuildContext context,
    required String title,
    required VoidCallback onCancel,
    required VoidCallback onDone,
  }) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade300,
            width: 0.5,
          ),
        ),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CupertinoButton(
            minimumSize: Size.zero,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            onPressed: onCancel,
            child: Text(
              '취소',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          CupertinoButton(
            minimumSize: Size.zero,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            onPressed: onDone,
            child: Text(
              '완료',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
