import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../domain/entities/salary_grade_option.dart';
import '../../domain/entities/salary_track.dart';

class SalaryReferenceLocalDataSource {
  SalaryReferenceLocalDataSource();

  Map<String, dynamic>? _cache;

  Future<void> _ensureLoaded() async {
    if (_cache != null) {
      return;
    }
    final String raw = await rootBundle.loadString(
      'assets/data/salary_tables.json',
    );
    _cache = jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<List<SalaryGradeOption>> fetchGrades({
    required SalaryTrack track,
    required int year,
  }) async {
    await _ensureLoaded();
    final Map<String, dynamic>? trackNode =
        _cache?['tracks']?[track.id] as Map<String, dynamic>?;
    if (trackNode == null) {
      return const [];
    }

    final Map<String, dynamic>? yearNode = _resolveYearNode(trackNode, year);
    if (yearNode == null) {
      return const [];
    }

    final Map<String, dynamic>? grades =
        yearNode['grades'] as Map<String, dynamic>?;
    if (grades == null) {
      return const [];
    }

    return grades.entries.map((entry) {
      final Map<String, dynamic> gradeData =
          entry.value as Map<String, dynamic>;
      return SalaryGradeOption(
        id: entry.key,
        name: gradeData['name'] as String? ?? entry.key,
        minStep: gradeData['minStep'] as int? ?? 1,
        maxStep: gradeData['maxStep'] as int? ?? 33,
      );
    }).toList()..sort((a, b) => a.id.compareTo(b.id));
  }

  Future<double?> fetchBaseSalary({
    required SalaryTrack track,
    required int year,
    required String gradeId,
    required int step,
  }) async {
    await _ensureLoaded();
    final Map<String, dynamic>? trackNode =
        _cache?['tracks']?[track.id] as Map<String, dynamic>?;
    if (trackNode == null) {
      return null;
    }
    final Map<String, dynamic>? yearNode = _resolveYearNode(trackNode, year);
    if (yearNode == null) {
      return null;
    }
    final Map<String, dynamic>? gradeData =
        (yearNode['grades'] as Map<String, dynamic>?)?[gradeId]
            as Map<String, dynamic>?;
    if (gradeData == null) {
      return null;
    }
    final Map<String, dynamic>? steps =
        gradeData['steps'] as Map<String, dynamic>?;
    if (steps == null) {
      return null;
    }
    final num? value = steps['$step'] as num?;
    return value?.toDouble();
  }

  Map<String, dynamic>? _resolveYearNode(
    Map<String, dynamic> trackNode,
    int year,
  ) {
    final Map<String, dynamic>? years =
        trackNode['years'] as Map<String, dynamic>?;
    if (years == null) {
      return null;
    }

    if (years['$year'] is Map<String, dynamic>) {
      final Map<String, dynamic> node = years['$year'] as Map<String, dynamic>;
      if (node.containsKey('inherit')) {
        final String inheritYear = node['inherit'] as String;
        return _resolveYearNode(trackNode, int.parse(inheritYear));
      }
      return node;
    }

    final List<int> availableYears = years.keys.map(int.parse).toList()..sort();
    if (availableYears.isEmpty) {
      return null;
    }
    final int fallbackYear = availableYears.lastWhere(
      (value) => value <= year,
      orElse: () => availableYears.last,
    );
    return _resolveYearNode(trackNode, fallbackYear);
  }
}
