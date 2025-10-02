// ignore_for_file: avoid_print

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:gong_mu_talk/features/community/domain/models/lounge_definitions.dart';

/// Firestore 라운지 데이터 마이그레이션 스크립트
/// 
/// 실행 방법:
/// ```bash
/// dart run scripts/migrate_lounges.dart [--dry-run]
/// ```
/// 
/// --dry-run: 실제 변경 없이 시뮬레이션만 수행

void main(List<String> arguments) async {
  final isDryRun = arguments.contains('--dry-run');

  print('🚀 라운지 마이그레이션 시작');
  print('모드: ${isDryRun ? "DRY RUN (시뮬레이션)" : "실제 마이그레이션"}');
  print('=' * 60);

  try {
    // Firebase 초기화
    await Firebase.initializeApp();
    print('✅ Firebase 초기화 완료');

    final firestore = FirebaseFirestore.instance;
    final loungesCollection = firestore.collection('lounges');

    // 1. 기존 라운지 백업 (Dry run이 아닐 때만)
    if (!isDryRun) {
      print('\n📦 기존 라운지 백업 중...');
      await _backupExistingLounges(loungesCollection);
    }

    // 2. 새로운 라운지 정의 가져오기
    final newLounges = LoungeDefinitions.defaultLounges;
    print('\n📋 신규 라운지 정의: ${newLounges.length}개');

    // 3. 기존 라운지 목록 가져오기
    final snapshot = await loungesCollection.get();
    final existingIds = snapshot.docs.map((doc) => doc.id).toSet();
    print('📋 기존 라운지: ${existingIds.length}개');

    // 4. 추가할 라운지와 업데이트할 라운지 구분
    final toAdd = <Lounge>[];
    final toUpdate = <Lounge>[];

    for (final lounge in newLounges) {
      if (existingIds.contains(lounge.id)) {
        toUpdate.add(lounge);
      } else {
        toAdd.add(lounge);
      }
    }

    print('\n📊 마이그레이션 계획:');
    print('  - 신규 추가: ${toAdd.length}개');
    print('  - 업데이트: ${toUpdate.length}개');

    if (toAdd.isNotEmpty) {
      print('\n🆕 추가될 라운지:');
      for (final lounge in toAdd) {
        print('  - ${lounge.emoji} ${lounge.name} (${lounge.id})');
      }
    }

    // 5. 실제 마이그레이션 또는 시뮬레이션
    if (isDryRun) {
      print('\n✅ DRY RUN 완료 - 실제 변경 없음');
    } else {
      print('\n🔄 마이그레이션 실행 중...');

      // 배치 작업으로 처리
      final batch = firestore.batch();
      var count = 0;

      // 신규 라운지 추가
      for (final lounge in toAdd) {
        final docRef = loungesCollection.doc(lounge.id);
        batch.set(docRef, lounge.toMap());
        count++;

        // Firestore batch limit (500)
        if (count >= 450) {
          await batch.commit();
          print('  ✅ Batch ${count ~/ 450} 커밋 완료');
          count = 0;
        }
      }

      // 기존 라운지 업데이트
      for (final lounge in toUpdate) {
        final docRef = loungesCollection.doc(lounge.id);
        batch.update(docRef, lounge.toMap());
        count++;

        if (count >= 450) {
          await batch.commit();
          print('  ✅ Batch ${count ~/ 450} 커밋 완료');
          count = 0;
        }
      }

      // 마지막 배치 커밋
      if (count > 0) {
        await batch.commit();
        print('  ✅ 최종 Batch 커밋 완료');
      }

      print('\n✅ 마이그레이션 완료!');
      print('  - 추가: ${toAdd.length}개');
      print('  - 업데이트: ${toUpdate.length}개');
    }

    // 6. 검증
    print('\n🔍 데이터 검증 중...');
    await _verifyMigration(loungesCollection, newLounges, isDryRun);

    print('\n🎉 모든 작업 완료!');
    exit(0);
  } catch (e, stackTrace) {
    print('\n❌ 오류 발생: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  }
}

/// 기존 라운지 백업
Future<void> _backupExistingLounges(CollectionReference loungesCollection) async {
  try {
    final snapshot = await loungesCollection.get();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final backupFile = File('scripts/backup_lounges_$timestamp.json');

    final backupData = snapshot.docs.map((doc) {
      return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
    }).toList();

    await backupFile.writeAsString(backupData.toString());
    print('✅ 백업 완료: ${backupFile.path}');
  } catch (e) {
    print('⚠️  백업 실패: $e');
    print('계속 진행하시겠습니까? (y/N)');
    final answer = stdin.readLineSync();
    if (answer?.toLowerCase() != 'y') {
      exit(1);
    }
  }
}

/// 마이그레이션 검증
Future<void> _verifyMigration(
  CollectionReference loungesCollection,
  List<Lounge> expectedLounges,
  bool isDryRun,
) async {
  if (isDryRun) {
    print('✅ DRY RUN 모드 - 검증 스킵');
    return;
  }

  final snapshot = await loungesCollection.get();
  final actualIds = snapshot.docs.map((doc) => doc.id).toSet();
  final expectedIds = expectedLounges.map((l) => l.id).toSet();

  // 누락된 라운지 확인
  final missing = expectedIds.difference(actualIds);
  if (missing.isNotEmpty) {
    print('⚠️  누락된 라운지: $missing');
  }

  // 고아 라운지 확인 (정의에는 없지만 DB에 있는 것)
  final orphaned = actualIds.difference(expectedIds);
  if (orphaned.isNotEmpty) {
    print('⚠️  고아 라운지 (정의 없음): $orphaned');
  }

  if (missing.isEmpty && orphaned.isEmpty) {
    print('✅ 검증 성공 - 모든 라운지 동기화됨');
  }

  // requiredCareerIds 검증
  print('\n🔍 requiredCareerIds 검증 중...');
  var invalidCount = 0;
  for (final doc in snapshot.docs) {
    final data = doc.data() as Map<String, dynamic>;
    final requiredCareerIds = data['requiredCareerIds'] as List?;

    if (requiredCareerIds == null && data['accessType'] == 'careerOnly') {
      print('⚠️  ${doc.id}: careerOnly이지만 requiredCareerIds가 없음');
      invalidCount++;
    }
  }

  if (invalidCount == 0) {
    print('✅ requiredCareerIds 검증 성공');
  } else {
    print('⚠️  검증 실패: $invalidCount개 라운지에 문제 있음');
  }
}
