import '../../domain/entities/allowance_standard.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/salary_table.dart';
import '../../domain/repositories/salary_table_repository.dart';
import '../datasources/salary_table_local_data_source.dart';
import '../datasources/salary_table_remote_data_source.dart';

/// 봉급표 리포지토리 구현
/// 
/// 캐시 전략: Cache-First
/// 1. 로컬 캐시에서 먼저 조회
/// 2. 캐시가 없으면 원격에서 조회 후 캐시 저장
@LazySingleton(as: SalaryTableRepository)
class SalaryTableRepositoryImpl implements SalaryTableRepository {
  SalaryTableRepositoryImpl({
    required SalaryTableRemoteDataSource remoteDataSource,
    required SalaryTableLocalDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  final SalaryTableRemoteDataSource _remoteDataSource;
  final SalaryTableLocalDataSource _localDataSource;

  @override
  Future<SalaryTable?> getSalaryTable({
    required int year,
    required String track,
  }) async {
    // 1. 로컬 캐시 조회
    final cached = _localDataSource.getCachedSalaryTable(
      year: year,
      track: track,
    );

    if (cached != null) {
      return cached;
    }

    // 2. 원격 조회
    final remote = await _remoteDataSource.getSalaryTable(
      year: year,
      track: track,
    );

    // 3. 캐시 저장
    if (remote != null) {
      await _localDataSource.cacheSalaryTable(remote);
    }

    return remote;
  }

  @override
  Future<double?> getBaseSalary({
    required int year,
    required String track,
    required String gradeId,
    required int step,
  }) async {
    final table = await getSalaryTable(year: year, track: track);
    return table?.getSalary(gradeId, step);
  }

  @override
  Future<AllowanceStandard?> getAllowanceStandard({
    required int year,
  }) async {
    // 1. 로컬 캐시 조회
    final cached = _localDataSource.getCachedAllowanceStandard(year: year);

    if (cached != null) {
      return cached;
    }

    // 2. 원격 조회
    final remote = await _remoteDataSource.getAllowanceStandard(year: year);

    // 3. 캐시 저장
    if (remote != null) {
      await _localDataSource.cacheAllowanceStandard(remote);
    }

    return remote;
  }

  @override
  Future<double?> getAllowanceAmount({
    required int year,
    required AllowanceType type,
  }) async {
    final standard = await getAllowanceStandard(year: year);
    return standard?.getStandard(type);
  }

  @override
  Future<List<int>> getAvailableYears() async {
    // 1. 로컬 캐시 조회
    final cached = _localDataSource.getCachedAvailableYears();

    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    // 2. 원격 조회
    final remote = await _remoteDataSource.getAvailableYears();

    // 3. 캐시 저장
    if (remote.isNotEmpty) {
      await _localDataSource.cacheAvailableYears(remote);
    }

    return remote;
  }

  @override
  Future<void> refreshCache() async {
    await _localDataSource.clearCache();
  }
}
