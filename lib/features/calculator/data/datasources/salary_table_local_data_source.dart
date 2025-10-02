import 'dart:convert';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/allowance_standard.dart';
import '../../domain/entities/salary_table.dart';

/// 로컬 캐시에서 봉급표 데이터를 관리하는 데이터소스
/// SharedPreferences를 사용한 간단한 캐싱 구현
@lazySingleton
class SalaryTableLocalDataSource {
  SalaryTableLocalDataSource({
    required SharedPreferences sharedPreferences,
  }) : _prefs = sharedPreferences;

  final SharedPreferences _prefs;

  /// 캐시 키 프리픽스
  static const String _salaryTablePrefix = 'salary_table_';
  static const String _allowanceStandardPrefix = 'allowance_standard_';
  static const String _availableYearsKey = 'salary_available_years';

  /// 봉급표 조회 (캐시)
  SalaryTable? getCachedSalaryTable({
    required int year,
    required String track,
  }) {
    try {
      final key = '$_salaryTablePrefix${year}_$track';
      final jsonStr = _prefs.getString(key);
      
      if (jsonStr == null) return null;

      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      return _parseSalaryTable(json);
    } catch (e) {
      return null;
    }
  }

  /// 봉급표 저장 (캐시)
  Future<void> cacheSalaryTable(SalaryTable table) async {
    try {
      final key = '$_salaryTablePrefix${table.year}_${table.track}';
      final json = _salaryTableToJson(table);
      final jsonStr = jsonEncode(json);
      
      await _prefs.setString(key, jsonStr);
    } catch (e) {
      // 캐시 저장 실패는 무시
    }
  }

  /// 수당 기준표 조회 (캐시)
  AllowanceStandard? getCachedAllowanceStandard({
    required int year,
  }) {
    try {
      final key = '$_allowanceStandardPrefix$year';
      final jsonStr = _prefs.getString(key);
      
      if (jsonStr == null) return null;

      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      return _parseAllowanceStandard(json);
    } catch (e) {
      return null;
    }
  }

  /// 수당 기준표 저장 (캐시)
  Future<void> cacheAllowanceStandard(AllowanceStandard standard) async {
    try {
      final key = '$_allowanceStandardPrefix${standard.year}';
      final json = _allowanceStandardToJson(standard);
      final jsonStr = jsonEncode(json);
      
      await _prefs.setString(key, jsonStr);
    } catch (e) {
      // 캐시 저장 실패는 무시
    }
  }

  /// 사용 가능한 연도 목록 조회 (캐시)
  List<int>? getCachedAvailableYears() {
    try {
      final jsonStr = _prefs.getString(_availableYearsKey);
      if (jsonStr == null) return null;

      final List<dynamic> json = jsonDecode(jsonStr);
      return json.cast<int>();
    } catch (e) {
      return null;
    }
  }

  /// 사용 가능한 연도 목록 저장 (캐시)
  Future<void> cacheAvailableYears(List<int> years) async {
    try {
      final jsonStr = jsonEncode(years);
      await _prefs.setString(_availableYearsKey, jsonStr);
    } catch (e) {
      // 캐시 저장 실패는 무시
    }
  }

  /// 전체 캐시 삭제
  Future<void> clearCache() async {
    final keys = _prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith(_salaryTablePrefix) ||
          key.startsWith(_allowanceStandardPrefix) ||
          key == _availableYearsKey) {
        await _prefs.remove(key);
      }
    }
  }

  /// SalaryTable을 JSON으로 변환
  Map<String, dynamic> _salaryTableToJson(SalaryTable table) {
    final gradesJson = <String, dynamic>{};
    for (final entry in table.grades.entries) {
      final grade = entry.value;
      gradesJson[entry.key] = {
        'gradeName': grade.gradeName,
        'minStep': grade.minStep,
        'maxStep': grade.maxStep,
        'steps': grade.steps.map((k, v) => MapEntry(k.toString(), v)),
      };
    }

    return {
      'year': table.year,
      'track': table.track,
      'grades': gradesJson,
      'metadata': table.metadata,
    };
  }

  /// JSON을 SalaryTable로 파싱
  SalaryTable _parseSalaryTable(Map<String, dynamic> json) {
    final year = json['year'] as int;
    final track = json['track'] as String;
    final gradesData = json['grades'] as Map<String, dynamic>? ?? {};
    final metadata =
        json['metadata'] as Map<String, dynamic>? ?? <String, dynamic>{};

    final grades = <String, GradeSteps>{};

    for (final entry in gradesData.entries) {
      final gradeId = entry.key;
      final gradeData = entry.value as Map<String, dynamic>;

      final gradeName = gradeData['gradeName'] as String;
      final stepsData = gradeData['steps'] as Map<String, dynamic>;
      final minStep = gradeData['minStep'] as int;
      final maxStep = gradeData['maxStep'] as int;

      final steps = <int, double>{};
      for (final stepEntry in stepsData.entries) {
        final stepNum = int.parse(stepEntry.key);
        final salary = (stepEntry.value as num).toDouble();
        steps[stepNum] = salary;
      }

      grades[gradeId] = GradeSteps(
        gradeId: gradeId,
        gradeName: gradeName,
        steps: steps,
        minStep: minStep,
        maxStep: maxStep,
      );
    }

    return SalaryTable(
      year: year,
      track: track,
      grades: grades,
      metadata: metadata,
    );
  }

  /// AllowanceStandard를 JSON으로 변환
  Map<String, dynamic> _allowanceStandardToJson(AllowanceStandard standard) {
    final standardsJson = <String, dynamic>{};
    for (final entry in standard.standards.entries) {
      standardsJson[entry.key.name] = entry.value;
    }

    return {
      'year': standard.year,
      'standards': standardsJson,
      'metadata': standard.metadata,
    };
  }

  /// JSON을 AllowanceStandard로 파싱
  AllowanceStandard _parseAllowanceStandard(Map<String, dynamic> json) {
    final year = json['year'] as int;
    final standardsData = json['standards'] as Map<String, dynamic>? ?? {};
    final metadata =
        json['metadata'] as Map<String, dynamic>? ?? <String, dynamic>{};

    final standards = <AllowanceType, double>{};

    for (final entry in standardsData.entries) {
      final typeStr = entry.key;
      final amount = (entry.value as num).toDouble();

      final type = AllowanceType.values.firstWhere(
        (e) => e.name == typeStr,
        orElse: () => AllowanceType.mealAllowance,
      );

      standards[type] = amount;
    }

    return AllowanceStandard(
      year: year,
      standards: standards,
      metadata: metadata,
    );
  }
}
