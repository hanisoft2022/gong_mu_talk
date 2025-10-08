/**
 * Count comments per user (simple version without complex queries)
 */

const admin = require('firebase-admin');
const serviceAccount = require('../serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function countUserComments() {
  console.log('Counting comments per user...\n');

  // Fetch all comments using simple collection group query
  const commentsSnapshot = await db.collectionGroup('comments').get();

  console.log(`Total comments in database: ${commentsSnapshot.size}\n`);

  // Count by author
  const commentsByAuthor = {};
  let deletedCount = 0;

  commentsSnapshot.forEach(doc => {
    const data = doc.data();
    const authorUid = data.authorUid;
    const deleted = data.deleted;

    if (deleted) {
      deletedCount++;
    }

    if (authorUid) {
      if (!commentsByAuthor[authorUid]) {
        commentsByAuthor[authorUid] = {
          total: 0,
          active: 0,
          deleted: 0
        };
      }
      commentsByAuthor[authorUid].total++;
      if (deleted) {
        commentsByAuthor[authorUid].deleted++;
      } else {
        commentsByAuthor[authorUid].active++;
      }
    }
  });

  console.log(`Deleted comments: ${deletedCount}`);
  console.log(`Active comments: ${commentsSnapshot.size - deletedCount}`);
  console.log(`Unique authors: ${Object.keys(commentsByAuthor).length}\n`);

  console.log('=== Comments by Author ===\n');
  for (const [authorUid, counts] of Object.entries(commentsByAuthor)) {
    const userDoc = await db.collection('users').doc(authorUid).get();
    const nickname = userDoc.exists ? userDoc.data().nickname : 'Unknown';
    console.log(`${nickname} (${authorUid})`);
    console.log(`  Total: ${counts.total}, Active: ${counts.active}, Deleted: ${counts.deleted}`);
  }
}

countUserComments()
  .then(() => {
    console.log('\n✅ Done!');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\n❌ Error:', error);
    process.exit(1);
  });
