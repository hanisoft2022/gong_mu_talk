/**
 * Standalone script to verify and fix comment counts
 * Run with: node verify_counts.js
 */

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function verifyCommentCounts() {
  console.log('Starting comment count verification...\n');

  const postsSnapshot = await db.collection('posts').get();
  console.log(`Found ${postsSnapshot.docs.length} posts\n`);

  let totalChecked = 0;
  let mismatchCount = 0;
  let fixedCount = 0;

  for (const postDoc of postsSnapshot.docs) {
    const postId = postDoc.id;
    const postData = postDoc.data();

    if (!postData) {
      console.log(`Post ${postId} has no data, skipping`);
      continue;
    }

    const storedCount = postData.commentCount || 0;

    const commentsSnapshot = await db
      .collection('posts')
      .doc(postId)
      .collection('comments')
      .where('deleted', '==', false)
      .get();

    const actualCount = commentsSnapshot.docs.length;

    totalChecked++;

    if (storedCount !== actualCount) {
      mismatchCount++;
      console.log('Mismatch found:');
      console.log(`   Post ID: ${postId}`);
      console.log(`   Stored count: ${storedCount}`);
      console.log(`   Actual count: ${actualCount}`);
      console.log(`   Difference: ${storedCount - actualCount}`);

      try {
        await postDoc.ref.update({
          commentCount: actualCount,
        });
        fixedCount++;
        console.log('   Fixed!\n');
      } catch (error) {
        console.log(`   Failed to fix: ${error.message}\n`);
      }
    }
  }

  console.log('\n' + '='.repeat(60));
  console.log('Verification Summary:');
  console.log('='.repeat(60));
  console.log(`Total posts checked: ${totalChecked}`);
  console.log(`Mismatches found: ${mismatchCount}`);
  console.log(`Successfully fixed: ${fixedCount}`);
  console.log(`Failed to fix: ${mismatchCount - fixedCount}`);
  console.log('='.repeat(60));

  if (mismatchCount === 0) {
    console.log('\nAll comment counts are correct!');
  } else if (fixedCount === mismatchCount) {
    console.log('\nAll mismatches have been fixed!');
  } else {
    console.log('\nSome mismatches could not be fixed. Check errors above.');
  }

  process.exit(0);
}

verifyCommentCounts().catch((error) => {
  console.error('\nError during verification:', error);
  process.exit(1);
});
