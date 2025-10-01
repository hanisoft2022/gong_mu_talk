const admin = require('firebase-admin');

// Firebase Admin 초기화
admin.initializeApp();

const db = admin.firestore();

// 라운지 데이터 (간략 버전 - 전체는 다음에)
const loungesData = [
  // 신규 라운지 12개만 먼저 추가
  {
    id: 'education_admin',
    name: '교육행정직',
    emoji: '📋',
    type: 'category',
    accessType: 'careerOnly',
    requiredCareerIds: [
      'education_admin_9th_national',
      'education_admin_7th_national',
      'education_admin_9th_local',
      'education_admin_7th_local'
    ],
    memberCount: 18000,
    order: 16,
    isActive: true,
    childLoungeIds: [
      'national_education_admin',
      'local_education_admin'
    ]
  }
  // ... 더 추가 예정
];

async function migrateLounges(dryRun = true) {
  console.log('🚀 라운지 마이그레이션 시작');
  console.log(`모드: ${dryRun ? 'DRY RUN (시뮬레이션)' : '실제 마이그레이션'}`);
  console.log('='.repeat(60));

  try {
    const loungesCollection = db.collection('lounges');
    
    // 기존 라운지 확인
    const snapshot = await loungesCollection.get();
    console.log(`\n📋 기존 라운지: ${snapshot.size}개`);
    console.log(`📋 신규 라운지: ${loungesData.length}개`);

    if (!dryRun) {
      const batch = db.batch();
      
      for (const lounge of loungesData) {
        const docRef = loungesCollection.doc(lounge.id);
        batch.set(docRef, {
          ...lounge,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        }, { merge: true });
      }

      await batch.commit();
      console.log(`\n✅ ${loungesData.length}개 라운지 마이그레이션 완료!`);
    } else {
      console.log('\n✅ DRY RUN 완료 - 실제 변경 없음');
      console.log('\n실제 마이그레이션 실행:');
      console.log('  node migrate_lounges_node.js');
    }

    process.exit(0);
  } catch (error) {
    console.error('\n❌ 오류 발생:', error);
    process.exit(1);
  }
}

// 명령행 인자로 dry-run 여부 결정
const dryRun = !process.argv.includes('--execute');
migrateLounges(dryRun);
