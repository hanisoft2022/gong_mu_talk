import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/allowance_standard.dart';
import '../../domain/entities/salary_table.dart';

/// Firestore에서 봉급표 데이터를 가져오는 원격 데이터소스
@lazySingleton
class SalaryTableRemoteDataSource {
  SalaryTableRemoteDataSource({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;

  final FirebaseFirestore _firestore;

  /// Firestore 컬렉션 경로
  static const String _salaryTablesCollection = 'salary_tables';
  static const String _allowanceStandardsCollection = 'allowance_standards';

  /// 봉급표 조회
  /// 
  /// Firestore 경로: salary_tables/{year}_{track}
  /// 예: salary_tables/2025_general
  Future<SalaryTable?> getSalaryTable({
    required int year,
    required String track,
  }) async {
    try {
      final docId = '${year}_$track';
      final doc = await _firestore
          .collection(_salaryTablesCollection)
          .doc(docId)
          .get();

      if (!doc.exists || doc.data() == null) {
        return null;
      }

      return _parseSalaryTable(doc.data()!);
    } catch (e) {
      throw SalaryTableDataSourceException(
        'Failed to fetch salary table: $e',
      );
    }
  }

  /// 수당 기준표 조회
  /// 
  /// Firestore 경로: allowance_standards/{year}
  Future<AllowanceStandard?> getAllowanceStandard({
    required int year,
  }) async {
    try {
      final doc = await _firestore
          .collection(_allowanceStandardsCollection)
          .doc(year.toString())
          .get();

      if (!doc.exists || doc.data() == null) {
        return null;
      }

      return _parseAllowanceStandard(doc.data()!);
    } catch (e) {
      throw SalaryTableDataSourceException(
        'Failed to fetch allowance standard: $e',
      );
    }
  }

  /// 사용 가능한 연도 목록 조회
  Future<List<int>> getAvailableYears() async {
    try {
      final snapshot = await _firestore
          .collection(_salaryTablesCollection)
          .get();

      final years = <int>{};
      for (final doc in snapshot.docs) {
        // docId 형식: "2025_general"
        final parts = doc.id.split('_');
        if (parts.isNotEmpty) {
          final year = int.tryParse(parts[0]);
          if (year != null) {
            years.add(year);
          }
        }
      }

      final sortedYears = years.toList()..sort((a, b) => b.compareTo(a));
      return sortedYears;
    } catch (e) {
      throw SalaryTableDataSourceException(
        'Failed to fetch available years: $e',
      );
    }
  }

  /// Firestore 데이터를 SalaryTable 엔티티로 파싱
  SalaryTable _parseSalaryTable(Map<String, dynamic> data) {
    final year = data['year'] as int;
    final track = data['track'] as String;
    final gradesData = data['grades'] as Map<String, dynamic>? ?? {};
    final metadata = data['metadata'] as Map<String, dynamic>? ?? {};

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

  /// Firestore 데이터를 AllowanceStandard 엔티티로 파싱
  AllowanceStandard _parseAllowanceStandard(Map<String, dynamic> data) {
    final year = data['year'] as int;
    final standardsData = data['standards'] as Map<String, dynamic>? ?? {};
    final metadata = data['metadata'] as Map<String, dynamic>? ?? {};

    final standards = <AllowanceType, double>{};
    
    for (final entry in standardsData.entries) {
      // Firestore에서는 enum을 문자열로 저장
      final typeStr = entry.key;
      final amount = (entry.value as num).toDouble();

      // 문자열을 AllowanceType enum으로 변환
      final type = AllowanceType.values.firstWhere(
        (e) => e.name == typeStr,
        orElse: () => AllowanceType.mealAllowance, // 기본값
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

/// 데이터소스 예외
class SalaryTableDataSourceException implements Exception {
  SalaryTableDataSourceException(this.message);
  
  final String message;

  @override
  String toString() => 'SalaryTableDataSourceException: $message';
}
