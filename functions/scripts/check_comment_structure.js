/**
 * Check comment document structure
 */

const admin = require('firebase-admin');
const serviceAccount = require('../serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function checkCommentStructure() {
  console.log('Checking comment document structure...\n');

  // Fetch a few comments using collection group
  const commentsSnapshot = await db.collectionGroup('comments')
    .limit(5)
    .get();

  console.log(`Found ${commentsSnapshot.size} comments\n`);

  commentsSnapshot.forEach((doc, index) => {
    console.log(`\n=== Comment ${index + 1} (ID: ${doc.id}) ===`);
    console.log(`Path: ${doc.ref.path}`);
    const data = doc.data();
    console.log('Fields:');
    Object.keys(data).forEach(key => {
      const value = data[key];
      const type = typeof value;
      const preview = type === 'object' ? JSON.stringify(value).substring(0, 50) : value;
      console.log(`  ${key}: (${type}) ${preview}`);
    });
  });

  // Count comments by author
  console.log('\n\n=== Comments by Author ===');
  const allComments = await db.collectionGroup('comments')
    .where('deleted', '==', false)
    .get();

  const commentsByAuthor = {};
  allComments.forEach(doc => {
    const data = doc.data();
    const authorUid = data.authorUid;
    if (authorUid) {
      commentsByAuthor[authorUid] = (commentsByAuthor[authorUid] || 0) + 1;
    }
  });

  console.log(`\nTotal non-deleted comments: ${allComments.size}`);
  console.log(`Unique authors: ${Object.keys(commentsByAuthor).length}\n`);

  for (const [authorUid, count] of Object.entries(commentsByAuthor)) {
    const userDoc = await db.collection('users').doc(authorUid).get();
    const nickname = userDoc.exists ? userDoc.data().nickname : 'Unknown';
    console.log(`  ${nickname} (${authorUid}): ${count} comments`);
  }
}

checkCommentStructure()
  .then(() => {
    console.log('\n✅ Done!');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\n❌ Error:', error);
    process.exit(1);
  });
