/**
 * Check user career data structure
 */

const admin = require('firebase-admin');
const serviceAccount = require('../serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function checkUserCareerData() {
  console.log('Checking user career data structure...\n');

  // Get current user (you can change this UID)
  const userId = 'Ed0vjyyMjfNDGPDtKPZnkXxNizt1';

  const userDoc = await db.collection('users').doc(userId).get();

  if (!userDoc.exists) {
    console.log('User not found!');
    return;
  }

  const userData = userDoc.data();

  console.log(`=== User: ${userData.nickname} ===\n`);

  console.log('Career-related fields:');
  console.log(`  serial: ${userData.serial || 'N/A'}`);
  console.log(`  careerTrack: ${userData.careerTrack || 'N/A'}`);
  console.log(`  careerHierarchy:`);

  if (userData.careerHierarchy) {
    console.log(`    specificCareer: ${userData.careerHierarchy.specificCareer}`);
    console.log(`    level1: ${userData.careerHierarchy.level1}`);
    console.log(`    level2: ${userData.careerHierarchy.level2}`);
    console.log(`    level3: ${userData.careerHierarchy.level3}`);
    console.log(`    level4: ${userData.careerHierarchy.level4 || 'N/A'}`);
  } else {
    console.log(`    ⚠️  careerHierarchy field is missing!`);
  }

  console.log('\nAll fields:');
  Object.keys(userData).forEach(key => {
    const value = userData[key];
    const type = typeof value;
    const preview = type === 'object' ? JSON.stringify(value).substring(0, 100) : value;
    console.log(`  ${key}: (${type}) ${preview}`);
  });
}

checkUserCareerData()
  .then(() => {
    console.log('\n✅ Done!');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\n❌ Error:', error);
    process.exit(1);
  });
