const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

// Firebase Admin 초기화 (Service Account 사용)
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'gong-mu-talk'
});

const db = admin.firestore();

// 신규 라운지 12개 (간략 버전)
const newLounges = [
  {
    id: 'education_admin',
    name: '교육행정직',
    emoji: '📋',
    type: 'category',
    accessType: 'careerOnly',
    requiredCareerIds: ['education_admin_9th_national', 'education_admin_7th_national', 'education_admin_9th_local', 'education_admin_7th_local'],
    memberCount: 18000,
    order: 16,
    isActive: true,
    childLoungeIds: ['national_education_admin', 'local_education_admin']
  },
  {
    id: 'national_education_admin',
    name: '국가 교육행정직',
    emoji: '🏛️',
    type: 'specific',
    accessType: 'careerOnly',
    requiredCareerIds: ['education_admin_9th_national', 'education_admin_7th_national'],
    parentLoungeId: 'education_admin',
    memberCount: 9000,
    order: 161,
    isActive: true,
    childLoungeIds: ['education_admin_9th_national', 'education_admin_7th_national']
  },
  {
    id: 'education_admin_9th_national',
    name: '교육행정 9급 (국가)',
    emoji: '📝',
    type: 'specific',
    accessType: 'careerOnly',
    requiredCareerIds: ['education_admin_9th_national'],
    parentLoungeId: 'national_education_admin',
    memberCount: 5000,
    order: 1611,
    isActive: true
  },
  {
    id: 'education_admin_7th_national',
    name: '교육행정 7급 (국가)',
    emoji: '📊',
    type: 'specific',
    accessType: 'careerOnly',
    requiredCareerIds: ['education_admin_7th_national'],
    parentLoungeId: 'national_education_admin',
    memberCount: 4000,
    order: 1612,
    isActive: true
  },
  {
    id: 'local_education_admin',
    name: '지방 교육행정직',
    emoji: '🏫',
    type: 'specific',
    accessType: 'careerOnly',
    requiredCareerIds: ['education_admin_9th_local', 'education_admin_7th_local'],
    parentLoungeId: 'education_admin',
    memberCount: 9000,
    order: 162,
    isActive: true,
    childLoungeIds: ['education_admin_9th_local', 'education_admin_7th_local']
  },
  {
    id: 'education_admin_9th_local',
    name: '교육행정 9급 (지방)',
    emoji: '📝',
    type: 'specific',
    accessType: 'careerOnly',
    requiredCareerIds: ['education_admin_9th_local'],
    parentLoungeId: 'local_education_admin',
    memberCount: 5000,
    order: 1621,
    isActive: true
  },
  {
    id: 'education_admin_7th_local',
    name: '교육행정 7급 (지방)',
    emoji: '📊',
    type: 'specific',
    accessType: 'careerOnly',
    requiredCareerIds: ['education_admin_7th_local'],
    parentLoungeId: 'local_education_admin',
    memberCount: 4000,
    order: 1622,
    isActive: true
  },
  {
    id: 'legal_profession',
    name: '법조직',
    emoji: '⚖️',
    type: 'category',
    accessType: 'careerOnly',
    requiredCareerIds: ['judge', 'prosecutor'],
    memberCount: 5000,
    order: 11,
    isActive: true
  },
  {
    id: 'diplomat',
    name: '외교관',
    emoji: '🌐',
    type: 'category',
    accessType: 'careerOnly',
    requiredCareerIds: ['diplomat_5th', 'diplomat_consular', 'diplomat_3rd'],
    memberCount: 4000,
    order: 12,
    isActive: true
  },
  {
    id: 'culture_arts',
    name: '문화예술직',
    emoji: '🎨',
    type: 'category',
    accessType: 'careerOnly',
    requiredCareerIds: ['curator', 'cultural_heritage'],
    memberCount: 3000,
    order: 50,
    isActive: true
  },
  {
    id: 'science_technology_specialized',
    name: '과학기술 전문직',
    emoji: '🔬',
    type: 'category',
    accessType: 'careerOnly',
    requiredCareerIds: ['meteorologist', 'disaster_safety', 'nursing_assistant', 'health_care'],
    memberCount: 8000,
    order: 51,
    isActive: true
  },
  {
    id: 'independent_agencies',
    name: '독립기관',
    emoji: '🏛️',
    type: 'category',
    accessType: 'careerOnly',
    requiredCareerIds: ['national_assembly', 'constitutional_court', 'election_commission', 'audit_board', 'human_rights_commission'],
    memberCount: 6000,
    order: 52,
    isActive: true
  }
];

async function migrateLounges(execute = false) {
  console.log('🚀 라운지 마이그레이션 시작');
  console.log('모드:', execute ? '실제 마이그레이션' : 'DRY RUN (시뮬레이션)');
  console.log('='.repeat(60));

  try {
    const loungesCollection = db.collection('lounges');

    // 기존 라운지 확인
    const snapshot = await loungesCollection.get();
    console.log('\n📋 기존 라운지:', snapshot.size, '개');
    console.log('📋 추가할 라운지:', newLounges.length, '개');

    console.log('\n🆕 추가될 라운지:');
    newLounges.forEach(l => {
      console.log('  -', l.emoji, l.name, '(' + l.id + ')');
    });

    if (execute) {
      console.log('\n🔄 마이그레이션 실행 중...');
      const batch = db.batch();

      for (const lounge of newLounges) {
        const docRef = loungesCollection.doc(lounge.id);
        batch.set(docRef, {
          ...lounge,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        }, { merge: true });
      }

      await batch.commit();
      console.log('\n✅', newLounges.length, '개 라운지 마이그레이션 완료!');
    } else {
      console.log('\n✅ DRY RUN 완료 - 실제 변경 없음');
      console.log('\n실제 마이그레이션 실행:');
      console.log('  node migrate_lounges_simple.js --execute');
    }

    process.exit(0);
  } catch (error) {
    console.error('\n❌ 오류 발생:', error);
    process.exit(1);
  }
}

// 명령행 인자 확인
const execute = process.argv.includes('--execute');
migrateLounges(execute);
