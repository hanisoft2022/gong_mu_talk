import 'package:flutter/material.dart';

enum LoungeScope { all, serial }

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
