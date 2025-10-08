/**
 * Check post document structure
 */

const admin = require('firebase-admin');
const serviceAccount = require('../serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function checkPostStructure() {
  console.log('Checking post document structure...\n');

  const postsSnapshot = await db.collection('posts').limit(3).get();

  console.log(`Found ${postsSnapshot.size} posts\n`);

  postsSnapshot.forEach((doc, index) => {
    console.log(`\n=== Post ${index + 1} (ID: ${doc.id}) ===`);
    const data = doc.data();
    console.log('Fields:');
    Object.keys(data).forEach(key => {
      const value = data[key];
      const type = typeof value;
      const preview = type === 'object' ? JSON.stringify(value).substring(0, 50) : value;
      console.log(`  ${key}: (${type}) ${preview}`);
    });
  });
}

checkPostStructure()
  .then(() => {
    console.log('\n✅ Done!');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\n❌ Error:', error);
    process.exit(1);
  });
