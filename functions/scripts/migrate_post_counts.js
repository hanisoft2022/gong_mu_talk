/**
 * Migration Script: Update postCount for all users based on existing posts
 *
 * This script:
 * 1. Fetches all posts from Firestore
 * 2. Counts posts per author
 * 3. Updates each user's postCount field
 *
 * Usage:
 *   node scripts/migrate_post_counts.js
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin
const serviceAccount = require('../serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function migratePostCounts() {
  console.log('Starting post count migration...\n');

  try {
    // Step 1: Fetch all posts
    console.log('Fetching all posts...');
    const postsSnapshot = await db.collection('posts').get();
    console.log(`Found ${postsSnapshot.size} total posts\n`);

    // Step 2: Count posts per author
    const postCountsByAuthor = {};

    postsSnapshot.forEach(doc => {
      const data = doc.data();
      const authorUid = data.authorUid;

      if (authorUid) {
        postCountsByAuthor[authorUid] = (postCountsByAuthor[authorUid] || 0) + 1;
      }
    });

    const uniqueAuthors = Object.keys(postCountsByAuthor).length;
    console.log(`Found ${uniqueAuthors} unique authors\n`);

    // Step 3: Update each user's postCount
    console.log('Updating user postCounts...');
    const batch = db.batch();
    let batchCount = 0;
    let updatedUsers = 0;

    for (const [authorId, count] of Object.entries(postCountsByAuthor)) {
      const userRef = db.collection('users').doc(authorId);

      batch.update(userRef, {
        postCount: count,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });

      batchCount++;
      updatedUsers++;

      // Firestore batch limit is 500
      if (batchCount >= 500) {
        await batch.commit();
        console.log(`Committed batch of ${batchCount} updates`);
        batchCount = 0;
      }

      // Log progress every 50 users
      if (updatedUsers % 50 === 0) {
        console.log(`Progress: ${updatedUsers}/${uniqueAuthors} users updated`);
      }
    }

    // Commit remaining batch
    if (batchCount > 0) {
      await batch.commit();
      console.log(`Committed final batch of ${batchCount} updates`);
    }

    console.log('\n✅ Migration completed successfully!');
    console.log(`Total users updated: ${updatedUsers}`);
    console.log('\nSummary:');

    // Show top 10 authors by post count
    const topAuthors = Object.entries(postCountsByAuthor)
      .sort(([, a], [, b]) => b - a)
      .slice(0, 10);

    console.log('\nTop 10 authors by post count:');
    for (const [authorId, count] of topAuthors) {
      const userDoc = await db.collection('users').doc(authorId).get();
      const nickname = userDoc.exists ? userDoc.data().nickname : 'Unknown';
      console.log(`  ${nickname} (${authorId}): ${count} posts`);
    }

  } catch (error) {
    console.error('❌ Migration failed:', error);
    throw error;
  }
}

// Run migration
migratePostCounts()
  .then(() => {
    console.log('\n✅ Done!');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\n❌ Error:', error);
    process.exit(1);
  });
