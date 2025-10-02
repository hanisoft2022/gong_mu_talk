import 'package:flutter/material.dart';

/// 라운지 스코프 - 이제 동적 라운지 ID를 지원
class LoungeScope {
  const LoungeScope(this.loungeId);

  final String loungeId;

  // 기본 스코프들 (하위 호환성)
  static const LoungeScope all = LoungeScope('all');
  static const LoungeScope serial = LoungeScope('serial'); // 더 이상 사용되지 않지만 호환성 유지

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoungeScope &&
      runtimeType == other.runtimeType &&
      loungeId == other.loungeId;

  @override
  int get hashCode => loungeId.hashCode;

  @override
  String toString() => 'LoungeScope($loungeId)';

  String get name => loungeId;
}

enum LoungeSort { latest, dailyPopular, weeklyPopular }

extension LoungeSortLabel on LoungeSort {
  String get label {
    switch (this) {
      case LoungeSort.latest:
        return '최신';
      case LoungeSort.dailyPopular:
        return '일간';
      case LoungeSort.weeklyPopular:
        return '주간';
    }
  }

  IconData get icon {
    switch (this) {
      case LoungeSort.latest:
        return Icons.access_time;
      case LoungeSort.dailyPopular:
        return Icons.local_fire_department;
      case LoungeSort.weeklyPopular:
        return Icons.trending_up;
    }
  }

  Color getColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (this) {
      case LoungeSort.latest:
        return isDark ? Colors.blue.shade300 : Colors.blue.shade600;
      case LoungeSort.dailyPopular:
        return isDark ? Colors.orange.shade300 : Colors.deepOrange.shade600;
      case LoungeSort.weeklyPopular:
        return isDark ? Colors.purple.shade300 : Colors.purple.shade600;
    }
  }
}
