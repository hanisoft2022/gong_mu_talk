/**
 * Migration Script: follows collection to users subcollections
 *
 * Context:
 * Old structure: follows/followerId_followingId
 * New structure:
 *   users/followingId/followers/followerId
 *   users/followerId/following/followingId
 *
 * This migration ensures data consistency after unifying the follow system.
 *
 * Usage:
 * 1. Deploy: firebase deploy --only functions:migrateFollowsData
 * 2. Run: firebase functions:call migrateFollowsData
 * 3. Monitor: firebase functions:log --only migrateFollowsData
 */

import {onCall} from "firebase-functions/v2/https";
import {getFirestore, FieldValue, Timestamp} from "firebase-admin/firestore";

const db = getFirestore();

interface FollowDocument {
  followerId: string;
  followingId: string;
  createdAt: Timestamp | null;
}

interface MigrationResult {
  success: boolean;
  totalFollows: number;
  migratedFollows: number;
  skippedFollows: number;
  errors: Array<{docId: string; error: string}>;
}

/**
 * Migrate follows/ collection data to subcollections
 *
 * Callable function - must be invoked manually for safety
 */
export const migrateFollowsData = onCall(
  {
    region: "us-central1",
    timeoutSeconds: 540, // 9 minutes max
  },
  async (request): Promise<MigrationResult> => {
    // Only allow admin/authenticated users to run migration
    if (!request.auth) {
      throw new Error("Unauthorized: Authentication required");
    }

    console.log("🚀 Starting follows/ collection migration...");
    console.log(`Initiated by user: ${request.auth.uid}`);

    const result: MigrationResult = {
      success: true,
      totalFollows: 0,
      migratedFollows: 0,
      skippedFollows: 0,
      errors: [],
    };

    try {
      // Fetch all documents from follows/ collection
      const followsSnapshot = await db.collection("follows").get();
      result.totalFollows = followsSnapshot.size;

      const msg = `Found ${result.totalFollows} follows to migrate`;
      console.log(`📊 ${msg}`);

      // Process each follow relationship
      for (const followDoc of followsSnapshot.docs) {
        const docId = followDoc.id;
        const data = followDoc.data() as FollowDocument;

        try {
          const {followerId, followingId, createdAt} = data;

          // Validate data
          if (!followerId || !followingId) {
            const skipMsg = `Skipping ${docId}: Missing data`;
            console.warn(`⚠️  ${skipMsg}`);
            result.skippedFollows++;
            continue;
          }

          // Check if already migrated to avoid duplicates
          const followerDocRef = db
            .collection("users")
            .doc(followingId)
            .collection("followers")
            .doc(followerId);

          const followerDocSnapshot = await followerDocRef.get();

          if (followerDocSnapshot.exists) {
            console.log(`✓ Skipping ${docId}: Already migrated`);
            result.skippedFollows++;
            continue;
          }

          // Migrate to new structure using batch write
          const batch = db.batch();

          // 1. Create followers/{followerId} subcollection
          const followersRef = db
            .collection("users")
            .doc(followingId)
            .collection("followers")
            .doc(followerId);

          batch.set(followersRef, {
            followedAt: createdAt || FieldValue.serverTimestamp(),
          });

          // 2. Create following/{followingId} subcollection
          const followingRef = db
            .collection("users")
            .doc(followerId)
            .collection("following")
            .doc(followingId);

          batch.set(followingRef, {
            followedAt: createdAt || FieldValue.serverTimestamp(),
          });

          // Commit batch
          await batch.commit();

          const successMsg = `Migrated ${docId}`;
          console.log(`✅ ${successMsg}`);
          result.migratedFollows++;
        } catch (error) {
          const errorMessage =
            error instanceof Error ? error.message : String(error);
          console.error(`❌ Error migrating ${docId}:`, errorMessage);
          result.errors.push({docId, error: errorMessage});
          result.success = false;
        }
      }

      console.log("\n📈 Migration Summary:");
      console.log(`Total follows: ${result.totalFollows}`);
      console.log(`Migrated: ${result.migratedFollows}`);
      console.log(`Skipped: ${result.skippedFollows}`);
      console.log(`Errors: ${result.errors.length}`);

      if (result.errors.length > 0) {
        console.error("\n⚠️  Errors encountered:");
        result.errors.forEach((err) => {
          console.error(`  - ${err.docId}: ${err.error}`);
        });
      }

      return result;
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : String(error);
      console.error("❌ Migration failed:", errorMessage);
      throw new Error(`Migration failed: ${errorMessage}`);
    }
  }
);

/**
 * Cleanup old follows/ collection after successful migration
 *
 * WARNING: This is destructive! Only run after verifying migration success.
 * Callable function - must be invoked manually
 */
export const cleanupOldFollowsCollection = onCall(
  {
    region: "us-central1",
    timeoutSeconds: 540,
  },
  async (request): Promise<{deleted: number}> => {
    if (!request.auth) {
      throw new Error("Unauthorized: Authentication required");
    }

    console.log("🗑️  Starting cleanup of follows/ collection...");
    console.log(`Initiated by user: ${request.auth.uid}`);

    const followsSnapshot = await db.collection("follows").get();
    const batchSize = 500;
    let deletedCount = 0;

    // Delete in batches
    for (let i = 0; i < followsSnapshot.docs.length; i += batchSize) {
      const batch = db.batch();
      const batchDocs = followsSnapshot.docs.slice(i, i + batchSize);

      batchDocs.forEach((doc) => {
        batch.delete(doc.ref);
      });

      await batch.commit();
      deletedCount += batchDocs.length;
      console.log(`Deleted ${deletedCount}/${followsSnapshot.size} documents`);
    }

    console.log(`✅ Cleanup complete: Deleted ${deletedCount} documents`);
    return {deleted: deletedCount};
  }
);
