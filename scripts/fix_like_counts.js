#!/usr/bin/env node

/**
 * Script to fix incorrect likeCount values in posts
 *
 * This script:
 * 1. Queries all posts from Firestore
 * 2. Counts actual like documents for each post
 * 3. Compares with stored likeCount
 * 4. Updates posts with incorrect counts
 */

const admin = require('firebase-admin');
const path = require('path');
const serviceAccount = require(path.join(__dirname, '../functions/serviceAccountKey.json'));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function fixLikeCounts() {
  console.log('🔍 Checking all posts for incorrect likeCount...\n');

  // Get all posts
  const postsSnapshot = await db.collection('posts').get();
  console.log(`📊 Found ${postsSnapshot.size} total posts\n`);

  let incorrectCount = 0;
  const fixes = [];

  // Check each post
  for (const postDoc of postsSnapshot.docs) {
    const postData = postDoc.data();
    const postId = postDoc.id;
    const storedLikeCount = postData.likeCount || 0;

    // Count actual likes
    const likesSnapshot = await db.collection('likes')
      .where('postId', '==', postId)
      .get();

    const actualLikeCount = likesSnapshot.size;

    if (storedLikeCount !== actualLikeCount) {
      incorrectCount++;
      console.log(`❌ MISMATCH FOUND:`);
      console.log(`   Post ID: ${postId}`);
      console.log(`   Stored likeCount: ${storedLikeCount}`);
      console.log(`   Actual likes: ${actualLikeCount}`);
      console.log(`   Difference: ${storedLikeCount - actualLikeCount}`);
      console.log('');

      fixes.push({ postId, actualLikeCount });
    }
  }

  if (incorrectCount === 0) {
    console.log('✅ All likeCount values are correct!');
    return;
  }

  console.log(`\n⚠️  Found ${incorrectCount} posts with incorrect likeCount\n`);
  console.log('🔧 Fixing incorrect counts...\n');

  // Fix each post
  const batch = db.batch();
  for (const { postId, actualLikeCount } of fixes) {
    const postRef = db.collection('posts').doc(postId);
    batch.update(postRef, { likeCount: actualLikeCount });
    console.log(`✅ Updated post ${postId}: likeCount = ${actualLikeCount}`);
  }

  await batch.commit();
  console.log(`\n✅ Successfully fixed ${fixes.length} posts!`);
}

fixLikeCounts()
  .then(() => {
    console.log('\n🎉 Fix complete!');
    process.exit(0);
  })
  .catch(err => {
    console.error('❌ Error:', err);
    process.exit(1);
  });
