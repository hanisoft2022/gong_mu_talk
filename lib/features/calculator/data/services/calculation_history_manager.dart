import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/calculation_history.dart';
import '../../domain/entities/salary_breakdown.dart';
import '../../domain/entities/salary_input.dart';

/// 계산 히스토리 관리 서비스
/// 
/// SharedPreferences를 사용하여 최근 계산 결과를 로컬에 저장/조회합니다.
@lazySingleton
class CalculationHistoryManager {
  CalculationHistoryManager({
    required SharedPreferences sharedPreferences,
  }) : _prefs = sharedPreferences;

  final SharedPreferences _prefs;

  static const String _historyKey = 'calculator_history';
  static const int _maxHistoryCount = 10;

  /// 히스토리 저장
  Future<void> saveCalculation({
    required SalaryInput input,
    required SalaryBreakdown result,
    String? label,
  }) async {
    final history = CalculationHistory(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      input: input,
      result: result,
      label: label,
    );

    final List<CalculationHistory> allHistory = await getHistory();
    
    // 새 항목을 맨 앞에 추가
    allHistory.insert(0, history);
    
    // 최대 개수 초과 시 오래된 항목 제거
    if (allHistory.length > _maxHistoryCount) {
      allHistory.removeRange(_maxHistoryCount, allHistory.length);
    }

    // 저장
    final jsonList = allHistory.map((h) => h.toJson()).toList();
    final jsonString = jsonEncode(jsonList);
    await _prefs.setString(_historyKey, jsonString);
  }

  /// 전체 히스토리 조회 (최신순)
  Future<List<CalculationHistory>> getHistory() async {
    final jsonString = _prefs.getString(_historyKey);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    try {
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((json) => CalculationHistory.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // JSON 파싱 실패 시 빈 리스트 반환
      return [];
    }
  }

  /// 특정 히스토리 항목 삭제
  Future<void> deleteHistoryItem(String id) async {
    final allHistory = await getHistory();
    allHistory.removeWhere((h) => h.id == id);

    final jsonList = allHistory.map((h) => h.toJson()).toList();
    final jsonString = jsonEncode(jsonList);
    await _prefs.setString(_historyKey, jsonString);
  }

  /// 모든 히스토리 삭제
  Future<void> clearHistory() async {
    await _prefs.remove(_historyKey);
  }

  /// 특정 히스토리 항목에 라벨 추가/수정
  Future<void> updateLabel(String id, String label) async {
    final allHistory = await getHistory();
    final index = allHistory.indexWhere((h) => h.id == id);
    
    if (index != -1) {
      allHistory[index] = allHistory[index].copyWithLabel(label);
      
      final jsonList = allHistory.map((h) => h.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      await _prefs.setString(_historyKey, jsonString);
    }
  }

  /// 히스토리 개수 조회
  Future<int> getHistoryCount() async {
    final history = await getHistory();
    return history.length;
  }

  /// 최근 계산 결과 조회
  Future<CalculationHistory?> getLatestCalculation() async {
    final history = await getHistory();
    return history.isNotEmpty ? history.first : null;
  }
}
