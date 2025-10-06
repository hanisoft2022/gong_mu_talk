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

initializeApp();
setGlobalOptions({region: "us-central1"});

export {handlePaystubUpload} from "./paystubVerification";
export {
  sendGovernmentEmailVerification,
  verifyEmailToken,
} from "./emailVerification";
export {migrateMyData, migrateAllUsers} from "./migrateSensitiveInfo";
export {
  migrateFollowsData,
  cleanupOldFollowsCollection,
} from "./migrateFollowsData";

const db = getFirestore();
const COUNTER_SHARD_COUNT = 20;

const HOT_SCORE_WEIGHTS = {
  like: 2.0,
  comment: 3.0,
  view: 0.1,
  timeDecayHours: 24,
  decayFactor: 0.8,
};

/**
 * Calculate a time-decayed hot score based on post engagement.
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

  const baseScore =
    (likeCount * HOT_SCORE_WEIGHTS.like) +
    (commentCount * HOT_SCORE_WEIGHTS.comment) +
    (viewCount * HOT_SCORE_WEIGHTS.view);

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
    const currentComments = (postData.commentCount as number | undefined) ?? 0;
    const createdAt = postData.createdAt as Timestamp | undefined;
    if (!createdAt) {
      return;
    }

    let newCommentCount = currentComments;
    if (isCreate) {
      newCommentCount = currentComments + 1;
    } else if (isDelete) {
      newCommentCount = Math.max(0, currentComments - 1);
    }

    const newHotScore = calculateHotScore(
      (postData.likeCount as number | undefined) ?? 0,
      newCommentCount,
      (postData.viewCount as number | undefined) ?? 0,
      createdAt
    );

    let topComment: Record<string, unknown> | null = null;
    if (newCommentCount > 0) {
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
      commentCount: newCommentCount,
      hotScore: newHotScore,
      topComment,
      updatedAt: FieldValue.serverTimestamp(),
    });

    const shardId = `shard_${Math.floor(Math.random() * COUNTER_SHARD_COUNT)}`;
    const shardRef = db.doc(`post_counters/${postId}/shards/${shardId}`);
    const increment = isDelete ? -1 : 1;

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
