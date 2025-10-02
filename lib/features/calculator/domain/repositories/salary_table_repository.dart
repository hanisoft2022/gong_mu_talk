import '../entities/allowance_standard.dart';
import '../entities/salary_table.dart';

/// 봉급표 및 수당 기준 리포지토리
abstract class SalaryTableRepository {
  /// 봉급표 조회
  /// 
  /// [year]: 적용 연도
  /// [track]: 직렬 (general, special 등)
  Future<SalaryTable?> getSalaryTable({
    required int year,
    required String track,
  });

  /// 특정 계급/호봉의 봉급 조회
  /// 
  /// [year]: 적용 연도
  /// [track]: 직렬
  /// [gradeId]: 계급 ID
  /// [step]: 호봉
  Future<double?> getBaseSalary({
    required int year,
    required String track,
    required String gradeId,
    required int step,
  });

  /// 수당 기준표 조회
  /// 
  /// [year]: 적용 연도
  Future<AllowanceStandard?> getAllowanceStandard({
    required int year,
  });

  /// 특정 수당의 기준액 조회
  /// 
  /// [year]: 적용 연도
  /// [type]: 수당 종류
  Future<double?> getAllowanceAmount({
    required int year,
    required AllowanceType type,
  });

  /// 사용 가능한 연도 목록 조회
  Future<List<int>> getAvailableYears();

  /// 로컬 캐시 업데이트
  Future<void> refreshCache();
}
