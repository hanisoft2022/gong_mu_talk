#!/usr/bin/env node

/**
 * Script to remove unused fields from Firestore
 *
 * This script removes:
 * 1. User fields: points, level, supporterLevel, premiumTier, supporterBadgeVisible, badges
 * 2. Post fields: authorSupporterLevel, authorIsSupporter
 * 3. Comment fields: authorSupporterLevel, authorIsSupporter
 *
 * Usage:
 *   node scripts/remove_unused_fields.js [--dry-run]
 *
 * Options:
 *   --dry-run  Show what would be deleted without actually deleting
 */

const admin = require('firebase-admin');
const path = require('path');
const serviceAccount = require(path.join(__dirname, '../functions/serviceAccountKey.json'));

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;

// Check if dry-run mode
const isDryRun = process.argv.includes('--dry-run');

// Firestore batch limit
const BATCH_SIZE = 500;

async function removeUserFields() {
  console.log('\n📋 Step 1: Removing fields from users collection...\n');

  const fieldsToRemove = [
    'points',
    'level',
    'supporterLevel',
    'premiumTier',
    'supporterBadgeVisible',
    'badges'
  ];

  const usersSnapshot = await db.collection('users').get();
  console.log(`📊 Found ${usersSnapshot.size} users\n`);

  let affectedCount = 0;
  let batches = [];
  let currentBatch = db.batch();
  let operationCount = 0;

  for (const userDoc of usersSnapshot.docs) {
    const userData = userDoc.data();
    const hasAnyField = fieldsToRemove.some(field => field in userData);

    if (hasAnyField) {
      affectedCount++;

      if (isDryRun) {
        const existingFields = fieldsToRemove.filter(field => field in userData);
        console.log(`   User ${userDoc.id} has fields: ${existingFields.join(', ')}`);
      } else {
        // Create update object with FieldValue.delete() for each field
        const updateObj = {};
        fieldsToRemove.forEach(field => {
          updateObj[field] = FieldValue.delete();
        });

        currentBatch.update(userDoc.ref, updateObj);
        operationCount++;

        // Start new batch if limit reached
        if (operationCount >= BATCH_SIZE) {
          batches.push(currentBatch);
          currentBatch = db.batch();
          operationCount = 0;
        }
      }
    }
  }

  // Add the last batch if it has operations
  if (operationCount > 0 && !isDryRun) {
    batches.push(currentBatch);
  }

  if (!isDryRun && batches.length > 0) {
    console.log(`\n🔧 Committing ${batches.length} batch(es)...`);
    for (let i = 0; i < batches.length; i++) {
      await batches[i].commit();
      console.log(`   ✅ Batch ${i + 1}/${batches.length} committed`);
    }
  }

  console.log(`\n✅ ${affectedCount} users ${isDryRun ? 'would be' : 'were'} updated`);
}

async function removePostFields() {
  console.log('\n📋 Step 2: Removing fields from posts collection...\n');

  const fieldsToRemove = ['authorSupporterLevel', 'authorIsSupporter'];

  const postsSnapshot = await db.collection('posts').get();
  console.log(`📊 Found ${postsSnapshot.size} posts\n`);

  let affectedCount = 0;
  let batches = [];
  let currentBatch = db.batch();
  let operationCount = 0;

  for (const postDoc of postsSnapshot.docs) {
    const postData = postDoc.data();
    const hasAnyField = fieldsToRemove.some(field => field in postData);

    if (hasAnyField) {
      affectedCount++;

      if (isDryRun) {
        const existingFields = fieldsToRemove.filter(field => field in postData);
        console.log(`   Post ${postDoc.id} has fields: ${existingFields.join(', ')}`);
      } else {
        const updateObj = {};
        fieldsToRemove.forEach(field => {
          updateObj[field] = FieldValue.delete();
        });

        currentBatch.update(postDoc.ref, updateObj);
        operationCount++;

        if (operationCount >= BATCH_SIZE) {
          batches.push(currentBatch);
          currentBatch = db.batch();
          operationCount = 0;
        }
      }
    }
  }

  if (operationCount > 0 && !isDryRun) {
    batches.push(currentBatch);
  }

  if (!isDryRun && batches.length > 0) {
    console.log(`\n🔧 Committing ${batches.length} batch(es)...`);
    for (let i = 0; i < batches.length; i++) {
      await batches[i].commit();
      console.log(`   ✅ Batch ${i + 1}/${batches.length} committed`);
    }
  }

  console.log(`\n✅ ${affectedCount} posts ${isDryRun ? 'would be' : 'were'} updated`);
}

async function removeCommentFields() {
  console.log('\n📋 Step 3: Removing fields from comments subcollections...\n');

  const fieldsToRemove = ['authorSupporterLevel', 'authorIsSupporter'];

  // Get all posts first
  const postsSnapshot = await db.collection('posts').get();
  console.log(`📊 Processing comments from ${postsSnapshot.size} posts\n`);

  let totalComments = 0;
  let affectedCount = 0;
  let batches = [];
  let currentBatch = db.batch();
  let operationCount = 0;

  // Process each post's comments
  for (const postDoc of postsSnapshot.docs) {
    const commentsSnapshot = await postDoc.ref.collection('comments').get();
    totalComments += commentsSnapshot.size;

    for (const commentDoc of commentsSnapshot.docs) {
      const commentData = commentDoc.data();
      const hasAnyField = fieldsToRemove.some(field => field in commentData);

      if (hasAnyField) {
        affectedCount++;

        if (isDryRun) {
          const existingFields = fieldsToRemove.filter(field => field in commentData);
          console.log(`   Comment ${commentDoc.id} (post: ${postDoc.id}) has fields: ${existingFields.join(', ')}`);
        } else {
          const updateObj = {};
          fieldsToRemove.forEach(field => {
            updateObj[field] = FieldValue.delete();
          });

          currentBatch.update(commentDoc.ref, updateObj);
          operationCount++;

          if (operationCount >= BATCH_SIZE) {
            batches.push(currentBatch);
            currentBatch = db.batch();
            operationCount = 0;
          }
        }
      }
    }
  }

  if (operationCount > 0 && !isDryRun) {
    batches.push(currentBatch);
  }

  if (!isDryRun && batches.length > 0) {
    console.log(`\n🔧 Committing ${batches.length} batch(es)...`);
    for (let i = 0; i < batches.length; i++) {
      await batches[i].commit();
      console.log(`   ✅ Batch ${i + 1}/${batches.length} committed`);
    }
  }

  console.log(`\n📊 Total comments processed: ${totalComments}`);
  console.log(`✅ ${affectedCount} comments ${isDryRun ? 'would be' : 'were'} updated`);
}

async function main() {
  console.log('╔════════════════════════════════════════════════════════════╗');
  console.log('║   Firestore Field Removal Script                          ║');
  console.log('║   Removing: points, level, supporter, premium, badges      ║');
  console.log('╚════════════════════════════════════════════════════════════╝');

  if (isDryRun) {
    console.log('\n⚠️  DRY-RUN MODE: No changes will be made\n');
  } else {
    console.log('\n⚠️  LIVE MODE: This will permanently delete data!\n');
    console.log('   Press Ctrl+C within 5 seconds to cancel...\n');

    // 5 second delay before starting
    await new Promise(resolve => setTimeout(resolve, 5000));
  }

  const startTime = Date.now();

  try {
    await removeUserFields();
    await removePostFields();
    await removeCommentFields();

    const duration = ((Date.now() - startTime) / 1000).toFixed(2);

    console.log('\n╔════════════════════════════════════════════════════════════╗');
    console.log(`║   ${isDryRun ? 'Dry-run' : 'Migration'} completed successfully! (${duration}s)${' '.repeat(Math.max(0, 22 - duration.length))}║`);
    console.log('╚════════════════════════════════════════════════════════════╝\n');

    if (isDryRun) {
      console.log('💡 To actually perform the deletion, run:');
      console.log('   node scripts/remove_unused_fields.js\n');
    }
  } catch (error) {
    console.error('\n❌ Migration failed:', error);
    throw error;
  }
}

main()
  .then(() => {
    process.exit(0);
  })
  .catch(err => {
    console.error('❌ Fatal error:', err);
    process.exit(1);
  });
