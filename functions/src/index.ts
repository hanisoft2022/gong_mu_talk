import {setGlobalOptions} from "firebase-functions/v2";
import {
  onDocumentCreated,
  onDocumentWritten,
} from "firebase-functions/v2/firestore";
import {onSchedule} from "firebase-functions/v2/scheduler";
import {initializeApp} from "firebase-admin/app";
import {
  FieldValue,
  Timestamp,
  getFirestore,
} from "firebase-admin/firestore";
import {getMessaging} from "firebase-admin/messaging";

initializeApp();
setGlobalOptions({region: "us-central1"});

export {handlePaystubUpload} from "./paystubVerification";
export {
  sendGovernmentEmailVerification,
  verifyEmailToken,
} from "./emailVerification";
export {generateThumbnail} from "./thumbnailGeneration";

const db = getFirestore();
const COUNTER_SHARD_COUNT = 10; // Reduced from 20 for cost optimization

const HOT_SCORE_WEIGHTS = {
  likeLogScale: 10.0, // Multiplier for log10(likes + 1)
  comment: 3.0, // Linear weight for comments
  timeDecayHours: 24,
  decayFactor: 0.8,
};

/**
 * Calculate a time-decayed hot score based on post engagement.
 *
 * Uses logarithmic scaling for likes to reduce gaming/bot abuse:
 * - First 10 likes have same weight as next 100 likes
 * - Prioritizes early engagement (Reddit/HackerNews style)
 * - Comments remain linear (discussion is valuable)
 *
 * Formula:
 *   baseScore = log10(likes+1)*10 + comments*3
 *   hotScore = baseScore * (0.8 ^ (hoursAgo / 24))
 *
 * @param {number} likeCount Total likes for the post.
 * @param {number} commentCount Total comments for the post.
 * @param {Timestamp} createdAt Creation timestamp.
 * @param {Timestamp=} now Optional override for current time.
 * @return {number} Decayed hot score.
 */
function calculateHotScore(
  likeCount: number,
  commentCount: number,
  createdAt: Timestamp,
  now?: Timestamp
): number {
  const currentTime = now ?? Timestamp.now();
  const hoursAgo =
    (currentTime.toMillis() - createdAt.toMillis()) / (1000 * 60 * 60);

  // Logarithmic scaling for likes (anti-gaming)
  const voteScore = Math.log10(likeCount + 1) * HOT_SCORE_WEIGHTS.likeLogScale;

  // Linear scaling for comments (discussion value)
  const commentScore = commentCount * HOT_SCORE_WEIGHTS.comment;

  const baseScore = voteScore + commentScore;

  // Exponential time decay
  const timeDecayFactor = Math.pow(
    HOT_SCORE_WEIGHTS.decayFactor,
    hoursAgo / HOT_SCORE_WEIGHTS.timeDecayHours
  );

  return baseScore * timeDecayFactor;
}

/**
 * Get FCM token for a user from Firestore.
 *
 * @param {string} uid User ID
 * @return {Promise<string | null>} FCM token or null if not found
 */
async function getUserFcmToken(uid: string): Promise<string | null> {
  try {
    const userDoc = await db.doc(`users/${uid}`).get();
    if (!userDoc.exists) {
      return null;
    }
    const fcmToken = userDoc.data()?.fcmToken as string | undefined;
    return fcmToken ?? null;
  } catch (error) {
    console.error(`Error getting FCM token for user ${uid}:`, error);
    return null;
  }
}

/**
 * Save notification history to Firestore.
 *
 * @param {string} targetUid User ID to receive notification
 * @param {string} type Notification type (e.g., "commentReply")
 * @param {string} title Notification title
 * @param {string} body Notification body
 * @param {Record<string, unknown>} data Additional data
 */
async function saveNotificationHistory(
  targetUid: string,
  type: string,
  title: string,
  body: string,
  data: Record<string, unknown>
): Promise<void> {
  try {
    await db.collection(`users/${targetUid}/notifications`).add({
      type,
      title,
      body,
      data,
      read: false,
      createdAt: FieldValue.serverTimestamp(),
    });
  } catch (error) {
    console.error(
      `Error saving notification history for user ${targetUid}:`,
      error
    );
  }
}

/**
 * Update post hot score when like is added or removed.
 *
 * NOTE: likeCount is updated client-side using FieldValue.increment()
 * in the transaction. This function only calculates and updates the
 * derived hotScore value. This prevents double-increment race
 * conditions between client and server.
 */
export const onLikeWrite = onDocumentWritten(
  {
    document: "likes/{likeId}",
    region: "us-central1",
  },
  async (event) => {
    const {likeId} = event.params;
    const [postId] = likeId.split("_");
    if (!postId) {
      return;
    }

    const before = event.data?.before;
    const after = event.data?.after;
    const beforeExists = before?.exists ?? false;
    const afterExists = after?.exists ?? false;
    const isCreate = !beforeExists && afterExists;
    const isDelete = beforeExists && !afterExists;

    if (!isCreate && !isDelete) {
      return;
    }

    const postRef = db.doc(`posts/${postId}`);
    const postSnap = await postRef.get();
    if (!postSnap.exists) {
      return;
    }

    const postData = postSnap.data() ?? {};
    const currentLikes = (postData.likeCount as number | undefined) ?? 0;
    const createdAt = postData.createdAt as Timestamp | undefined;
    if (!createdAt) {
      return;
    }

    // Calculate hotScore using current likeCount (already updated by client)
    // Client-side transaction handles likeCount with FieldValue.increment()
    const newHotScore = calculateHotScore(
      currentLikes,
      (postData.commentCount as number | undefined) ?? 0,
      createdAt
    );

    // Only update hotScore (likeCount is handled client-side)
    await postRef.update({
      hotScore: newHotScore,
      updatedAt: FieldValue.serverTimestamp(),
    });

    const shardId = `shard_${Math.floor(Math.random() * COUNTER_SHARD_COUNT)}`;
    const shardRef = db.doc(`post_counters/${postId}/shards/${shardId}`);
    const increment = isDelete ? -1 : 1;

    await shardRef.set(
      {
        likes: FieldValue.increment(increment),
      },
      {merge: true}
    );
  }
);

/** Update post counters and hot score when comment is added or removed. */
export const onCommentWrite = onDocumentWritten(
  {
    document: "posts/{postId}/comments/{commentId}",
    region: "us-central1",
  },
  async (event) => {
    const {postId} = event.params;

    const before = event.data?.before;
    const after = event.data?.after;
    const beforeExists = before?.exists ?? false;
    const afterExists = after?.exists ?? false;

    // Hard delete: document completely removed
    const isHardDelete = beforeExists && !afterExists;

    // Soft delete: deleted field changed from false to true
    const isSoftDelete =
      beforeExists &&
      afterExists &&
      before?.data()?.deleted === false &&
      after?.data()?.deleted === true;

    // Restore: deleted field changed from true to false (undo)
    const isRestore =
      beforeExists &&
      afterExists &&
      before?.data()?.deleted === true &&
      after?.data()?.deleted === false;

    // Create: new comment added
    const isCreate = !beforeExists && afterExists;

    // Determine increment value
    let increment = 0;
    if (isCreate) {
      increment = 1;
    } else if (isHardDelete || isSoftDelete) {
      increment = -1;
    } else if (isRestore) {
      increment = 1;
    } else {
      // Just an update (e.g., like count changed), no count change needed
      return;
    }

    // Update post with FieldValue.increment for atomic operation
    const postRef = db.doc(`posts/${postId}`);
    const postSnap = await postRef.get();
    if (!postSnap.exists) {
      return;
    }

    const postData = postSnap.data() ?? {};
    const createdAt = postData.createdAt as Timestamp | undefined;
    if (!createdAt) {
      return;
    }

    // Calculate new comment count (for hot score calculation only)
    const currentComments = (postData.commentCount as number | undefined) ?? 0;
    const estimatedNewCount = Math.max(0, currentComments + increment);

    const newHotScore = calculateHotScore(
      (postData.likeCount as number | undefined) ?? 0,
      estimatedNewCount,
      createdAt
    );

    let topComment: Record<string, unknown> | null = null;
    if (estimatedNewCount > 0) {
      const topCommentsSnap = await db.collection(`posts/${postId}/comments`)
        .where("deleted", "==", false)
        .orderBy("likeCount", "desc")
        .limit(1)
        .get();

      if (!topCommentsSnap.empty) {
        const topDoc = topCommentsSnap.docs[0];
        const topData = topDoc.data();
        topComment = {
          id: topDoc.id,
          text: topData.text,
          likeCount: topData.likeCount ?? 0,
          authorNickname: topData.authorNickname,
        };
      }
    }

    await postRef.update({
      commentCount: FieldValue.increment(increment),
      hotScore: newHotScore,
      topComment,
      updatedAt: FieldValue.serverTimestamp(),
    });

    const shardId = `shard_${Math.floor(Math.random() * COUNTER_SHARD_COUNT)}`;
    const shardRef = db.doc(`post_counters/${postId}/shards/${shardId}`);

    await shardRef.set(
      {
        comments: FieldValue.increment(increment),
      },
      {merge: true}
    );
  }
);

/**
 * Recalculate hot scores periodically.
 * Run every 12 hours (cost optimized).
 *
 * Cost optimization:
 * - Reduced from 7 days to 3 days (less stale posts)
 * - Reduced limit from 1000 to 500 (lower read costs)
 * - Result: ~72% reduction in monthly Firestore reads
 */
export const recalculateHotScores = onSchedule(
  {
    schedule: "0 */12 * * *",
    timeZone: "Asia/Seoul",
    region: "us-central1",
  },
  async () => {
    const batch = db.batch();
    let batchCount = 0;
    const maxBatchSize = 500;

    const threeDaysAgo = Timestamp.fromMillis(
      Date.now() - (3 * 24 * 60 * 60 * 1000)
    );

    const postsSnap = await db.collection("posts")
      .where("createdAt", ">=", threeDaysAgo)
      .where("visibility", "==", "public")
      .limit(500)
      .get();

    for (const postDoc of postsSnap.docs) {
      const postData = postDoc.data();
      const createdAt = postData.createdAt as Timestamp | undefined;
      if (!createdAt) {
        continue;
      }

      const newHotScore = calculateHotScore(
        postData.likeCount ?? 0,
        postData.commentCount ?? 0,
        createdAt
      );

      batch.update(postDoc.ref, {hotScore: newHotScore});
      batchCount += 1;

      if (batchCount >= maxBatchSize) {
        await batch.commit();
        batchCount = 0;
      }
    }

    if (batchCount > 0) {
      await batch.commit();
    }

    console.log(
      `Recalculated hot scores for ${postsSnap.size} posts`
    );
  }
);

/**
 * Weekly digest of popular posts by career track.
 * Runs every Sunday at 9:00 AM KST.
 *
 * For each career track:
 * 1. Find top 3 posts from the past 7 days
 * 2. Send FCM notification to all users with that track
 * 3. Save notification history to Firestore
 */
export const weeklySerialDigest = onSchedule(
  {
    schedule: "0 9 * * 0", // Every Sunday at 9:00 AM
    timeZone: "Asia/Seoul",
    region: "us-central1",
  },
  async () => {
    const careerTracks = [
      "teacher",
      "police",
      "educationAdmin",
      "firefighter",
      "lawmaker",
      "publicAdministration",
      "customs",
      "itSpecialist",
    ];

    const careerTrackDisplayNames: Record<string, string> = {
      teacher: "교사",
      police: "경찰",
      educationAdmin: "교육행정직",
      firefighter: "소방",
      lawmaker: "국회의원",
      publicAdministration: "행정직",
      customs: "관세직",
      itSpecialist: "정보화전문직",
    };

    const sevenDaysAgo = Timestamp.fromMillis(
      Date.now() - (7 * 24 * 60 * 60 * 1000)
    );

    let totalNotificationsSent = 0;

    for (const track of careerTracks) {
      try {
        // Find top 3 posts for this track from the past week
        const postsSnap = await db.collection("posts")
          .where("audience", "==", "serial")
          .where("serial", "==", track)
          .where("createdAt", ">=", sevenDaysAgo)
          .where("visibility", "==", "public")
          .orderBy("createdAt", "desc")
          .orderBy("likeCount", "desc")
          .limit(3)
          .get();

        if (postsSnap.empty) {
          console.log(`No posts found for track: ${track}`);
          continue;
        }

        // Build notification body with top posts
        const postSummaries: string[] = [];
        postsSnap.docs.forEach((doc, index) => {
          const postData = doc.data();
          const text = postData.text as string | undefined ?? "";
          const preview = text.trim();
          const shortened = preview.length <= 30 ?
            preview :
            `${preview.substring(0, 30)}...`;
          const likeCount = postData.likeCount ?? 0;
          postSummaries.push(`${index + 1}. ${shortened} (${likeCount} 좋아요)`);
        });

        const displayName = careerTrackDisplayNames[track] ?? track;
        const title = `${displayName} 인기글 요약`;
        const body = postSummaries.join("\n");

        // Find all users with this career track
        const usersSnap = await db.collection("users")
          .where("careerTrack", "==", track)
          .get();

        if (usersSnap.empty) {
          console.log(`No users found for track: ${track}`);
          continue;
        }

        // Send notification to each user
        const promises = usersSnap.docs.map(async (userDoc) => {
          const uid = userDoc.id;
          const fcmToken = await getUserFcmToken(uid);

          if (!fcmToken) {
            console.log(`No FCM token for user: ${uid}`);
            return;
          }

          const message = {
            token: fcmToken,
            notification: {
              title: title,
              body: body,
            },
            data: {
              type: "weeklySerialDigest",
              track: track,
            },
            android: {
              notification: {
                channelId: "general_channel",
                sound: "default",
              },
            },
            apns: {
              payload: {
                aps: {
                  sound: "default",
                },
              },
            },
          };

          try {
            await getMessaging().send(message);
            await saveNotificationHistory(
              uid,
              "weeklySerialDigest",
              title,
              body,
              {track}
            );
            totalNotificationsSent++;
          } catch (error) {
            console.error(`Failed to send notification to user ${uid}:`, error);
          }
        });

        await Promise.all(promises);
        console.log(
          `Sent ${usersSnap.size} digest notifications for track: ${track}`
        );
      } catch (error) {
        console.error(`Error processing digest for track ${track}:`, error);
      }
    }

    console.log(
      // eslint-disable-next-line max-len
      `Weekly digest completed. Total notifications sent: ${totalNotificationsSent}`
    );
  }
);

/** Clean up or moderate reported content as reports accumulate. */
export const processReports = onDocumentCreated(
  {
    document: "reports/{reportId}",
    region: "us-central1",
  },
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      return;
    }

    const reportData = snapshot.data();
    if (!reportData) {
      return;
    }

    const {targetType, targetId} = reportData as {
      targetType: string;
      targetId: string;
    };

    const reportsQuery = db.collection("reports")
      .where("targetType", "==", targetType)
      .where("targetId", "==", targetId);

    const reportsSnap = await reportsQuery.get();
    const reportCount = reportsSnap.size;

    if (reportCount >= 3 && targetType === "post") {
      await db.doc(`posts/${targetId}`).update({
        visibility: "hidden",
        moderationReason: "Multiple reports received",
        updatedAt: FieldValue.serverTimestamp(),
      });
    }

    const message =
      `Processed report for ${targetType}:${targetId}, total reports:` +
      ` ${reportCount}`;
    console.log(message);
  }
);

/**
 * Update user's post count when a post is created or deleted.
 * Automatically increments/decrements postCount in users collection.
 */
export const onPostWrite = onDocumentWritten(
  {
    document: "posts/{postId}",
    region: "us-central1",
  },
  async (event) => {
    const before = event.data?.before;
    const after = event.data?.after;
    const beforeExists = before?.exists ?? false;
    const afterExists = after?.exists ?? false;

    const isCreate = !beforeExists && afterExists;
    const isDelete = beforeExists && !afterExists;

    // Only handle create or delete events
    if (!isCreate && !isDelete) {
      return;
    }

    // Get authorUid from the post data
    const postData = isCreate ? after?.data() : before?.data();
    const authorUid = postData?.authorUid as string | undefined;

    if (!authorUid) {
      console.log("No authorUid found in post data");
      return;
    }

    // Update user's post count
    const increment = isCreate ? 1 : -1;
    const userRef = db.doc(`users/${authorUid}`);

    try {
      await userRef.update({
        postCount: FieldValue.increment(increment),
        updatedAt: FieldValue.serverTimestamp(),
      });

      const action = isCreate ? "incremented" : "decremented";
      const sign = increment > 0 ? "+" : "";
      console.log(
        `Post count ${action} for user ${authorUid} (${sign}${increment})`
      );
    } catch (error) {
      console.error(`Error updating post count for user ${authorUid}:`, error);
    }
  }
);

// NOTE: onReplyNotification removed - replaced by onCommentNotification
// The new onCommentNotification handles all comment notifications:
// - Reply notifications (commentReply)
// - Post comment notifications (postComment)
// - Scrapped post notifications (scrappedPostComment)
