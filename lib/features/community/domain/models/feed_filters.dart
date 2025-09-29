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

enum LoungeSort { latest, popular, likes }

extension LoungeSortLabel on LoungeSort {
  String get label {
    switch (this) {
      case LoungeSort.latest:
        return '최신순';
      case LoungeSort.popular:
        return '오늘의 인기순';
      case LoungeSort.likes:
        return '오늘의 좋아요순';
    }
  }

  IconData get icon {
    switch (this) {
      case LoungeSort.latest:
        return Icons.access_time;
      case LoungeSort.popular:
        return Icons.local_fire_department;
      case LoungeSort.likes:
        return Icons.favorite;
    }
  }

  Color getColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (this) {
      case LoungeSort.latest:
        return isDark ? Colors.blue.shade300 : Colors.blue.shade600;
      case LoungeSort.popular:
        return isDark ? Colors.orange.shade300 : Colors.deepOrange.shade600;
      case LoungeSort.likes:
        return isDark ? Colors.red.shade300 : Colors.red.shade600;
    }
  }
}
