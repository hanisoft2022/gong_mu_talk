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
const COUNTER_SHARD_COUNT = 20;

const HOT_SCORE_WEIGHTS = {
  likeLogScale: 10.0, // Multiplier for log10(likes + 1)
  comment: 3.0, // Linear weight for comments
  viewLogScale: 0.5, // Multiplier for log10(views + 1)
  timeDecayHours: 24,
  decayFactor: 0.8,
};

/**
 * Calculate a time-decayed hot score based on post engagement.
 *
 * Uses logarithmic scaling for likes and views to reduce gaming/bot abuse:
 * - First 10 likes have same weight as next 100 likes
 * - Prioritizes early engagement (Reddit/HackerNews style)
 * - Comments remain linear (discussion is valuable)
 *
 * Formula:
 *   baseScore = log10(likes+1)*10 + comments*3 + log10(views+1)*0.5
 *   hotScore = baseScore * (0.8 ^ (hoursAgo / 24))
 *
 * @param {number} likeCount Total likes for the post.
 * @param {number} commentCount Total comments for the post.
 * @param {number} viewCount Total views for the post.
 * @param {Timestamp} createdAt Creation timestamp.
 * @param {Timestamp=} now Optional override for current time.
 * @return {number} Decayed hot score.
 */
function calculateHotScore(
  likeCount: number,
  commentCount: number,
  viewCount: number,
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

  // Logarithmic scaling for views (engagement signal)
  const viewScore = Math.log10(viewCount + 1) * HOT_SCORE_WEIGHTS.viewLogScale;

  const baseScore = voteScore + commentScore + viewScore;

  // Exponential time decay
  const timeDecayFactor = Math.pow(
    HOT_SCORE_WEIGHTS.decayFactor,
    hoursAgo / HOT_SCORE_WEIGHTS.timeDecayHours
  );

  return baseScore * timeDecayFactor;
}

/** Update post counters and hot score when like is added or removed. */
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

    let newLikeCount = currentLikes;
    if (isCreate) {
      newLikeCount = currentLikes + 1;
    } else if (isDelete) {
      newLikeCount = Math.max(0, currentLikes - 1);
    }

    const newHotScore = calculateHotScore(
      newLikeCount,
      (postData.commentCount as number | undefined) ?? 0,
      (postData.viewCount as number | undefined) ?? 0,
      createdAt
    );

    await postRef.update({
      likeCount: newLikeCount,
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
      (postData.viewCount as number | undefined) ?? 0,
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

    const sevenDaysAgo = Timestamp.fromMillis(
      Date.now() - (7 * 24 * 60 * 60 * 1000)
    );

    const postsSnap = await db.collection("posts")
      .where("createdAt", ">=", sevenDaysAgo)
      .where("visibility", "==", "public")
      .limit(1000)
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
        postData.viewCount ?? 0,
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

/**
 * Send push notification when someone replies to a comment.
 * Triggers when a new comment is created with a parentCommentId.
 */
export const onReplyNotification = onDocumentCreated(
  {
    document: "posts/{postId}/comments/{commentId}",
    region: "us-central1",
  },
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      return;
    }

    const commentData = snapshot.data();
    if (!commentData) {
      return;
    }

    const {postId} = event.params;
    const parentCommentId = commentData.parentCommentId as string | undefined;

    // Only proceed if this is a reply (has parentCommentId)
    if (!parentCommentId) {
      return;
    }

    try {
      // Get parent comment to find the original author
      const parentCommentRef = db.doc(
        `posts/${postId}/comments/${parentCommentId}`
      );
      const parentCommentSnap = await parentCommentRef.get();

      if (!parentCommentSnap.exists) {
        console.log(`Parent comment ${parentCommentId} not found`);
        return;
      }

      const parentCommentData = parentCommentSnap.data();
      if (!parentCommentData) {
        return;
      }

      const parentAuthorUid = parentCommentData.authorUid as string;
      const replyAuthorNickname = commentData.authorNickname as string;
      const replyText = commentData.text as string;

      // Don't send notification if user replies to their own comment
      if (parentAuthorUid === commentData.authorUid) {
        return;
      }

      // Get FCM token for the parent comment author
      const userRef = db.doc(`users/${parentAuthorUid}`);
      const userSnap = await userRef.get();

      if (!userSnap.exists) {
        console.log(`User ${parentAuthorUid} not found`);
        return;
      }

      const userData = userSnap.data();
      const fcmToken = userData?.fcmToken as string | undefined;

      if (!fcmToken) {
        console.log(`No FCM token for user ${parentAuthorUid}`);
        return;
      }

      // Truncate reply text for notification
      const truncatedText = replyText.length > 100 ?
        `${replyText.substring(0, 100)}...` :
        replyText;

      // Send FCM notification
      const message = {
        token: fcmToken,
        notification: {
          title: `${replyAuthorNickname}님이 답글을 남겼습니다`,
          body: truncatedText,
        },
        data: {
          type: "reply",
          postId: postId,
          commentId: snapshot.id,
          parentCommentId: parentCommentId,
        },
        android: {
          priority: "high" as const,
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
            },
          },
        },
      };

      await getMessaging().send(message);
      console.log(
        `Reply notification sent to ${parentAuthorUid} for comment ` +
        `${snapshot.id}`
      );
    } catch (error) {
      console.error("Error sending reply notification:", error);
    }
  }
);
