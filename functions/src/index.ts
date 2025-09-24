import {setGlobalOptions} from "firebase-functions";
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();
const db = admin.firestore();

setGlobalOptions({ maxInstances: 10 });

// Hot score calculation weights
const HOT_SCORE_WEIGHTS = {
  like: 2.0,
  comment: 3.0,
  view: 0.1,
  timeDecayHours: 24,
  decayFactor: 0.8
};

function calculateHotScore(
  likeCount: number,
  commentCount: number,
  viewCount: number,
  createdAt: admin.firestore.Timestamp,
  now?: admin.firestore.Timestamp
): number {
  const currentTime = now || admin.firestore.Timestamp.now();
  const hoursAgo = (currentTime.toMillis() - createdAt.toMillis()) / (1000 * 60 * 60);

  const baseScore =
    (likeCount * HOT_SCORE_WEIGHTS.like) +
    (commentCount * HOT_SCORE_WEIGHTS.comment) +
    (viewCount * HOT_SCORE_WEIGHTS.view);

  // Apply time decay
  const timeDecayFactor = Math.pow(
    HOT_SCORE_WEIGHTS.decayFactor,
    hoursAgo / HOT_SCORE_WEIGHTS.timeDecayHours
  );

  return baseScore * timeDecayFactor;
}

// Update post counters and hot score when like is added/removed
export const onLikeWrite = functions.firestore
  .document('likes/{likeId}')
  .onWrite(async (change, context) => {
    const { likeId } = context.params;
    const [postId] = likeId.split('_');

    if (!postId) return;

    const postRef = db.doc(`posts/${postId}`);
    const postSnap = await postRef.get();

    if (!postSnap.exists) return;

    const postData = postSnap.data()!;
    const isDelete = !change.after.exists;
    const currentLikes = postData.likeCount || 0;

    const newLikeCount = isDelete ? Math.max(0, currentLikes - 1) : currentLikes + 1;

    const newHotScore = calculateHotScore(
      newLikeCount,
      postData.commentCount || 0,
      postData.viewCount || 0,
      postData.createdAt
    );

    await postRef.update({
      likeCount: newLikeCount,
      hotScore: newHotScore,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    // Update distributed counter shard
    const shardId = `shard_${Math.floor(Math.random() * 20)}`;
    const shardRef = db.doc(`post_counters/${postId}/shards/${shardId}`);
    const increment = isDelete ? -1 : 1;

    await shardRef.set({
      likes: admin.firestore.FieldValue.increment(increment)
    }, { merge: true });
  });

// Update post counters and hot score when comment is added/removed
export const onCommentWrite = functions.firestore
  .document('posts/{postId}/comments/{commentId}')
  .onWrite(async (change, context) => {
    const { postId } = context.params;
    const postRef = db.doc(`posts/${postId}`);

    const isDelete = !change.after.exists;
    const isCreate = !change.before.exists;

    if (!isCreate && !isDelete) return; // Skip updates

    const postSnap = await postRef.get();
    if (!postSnap.exists) return;

    const postData = postSnap.data()!;
    const currentComments = postData.commentCount || 0;
    const newCommentCount = isDelete ? Math.max(0, currentComments - 1) : currentComments + 1;

    const newHotScore = calculateHotScore(
      postData.likeCount || 0,
      newCommentCount,
      postData.viewCount || 0,
      postData.createdAt
    );

    // Get top comment for caching
    let topComment = null;
    if (newCommentCount > 0) {
      const topCommentsSnap = await db.collection(`posts/${postId}/comments`)
        .where('deleted', '==', false)
        .orderBy('likeCount', 'desc')
        .limit(1)
        .get();

      if (!topCommentsSnap.empty) {
        const topCommentData = topCommentsSnap.docs[0].data();
        topComment = {
          id: topCommentsSnap.docs[0].id,
          text: topCommentData.text,
          likeCount: topCommentData.likeCount || 0,
          authorNickname: topCommentData.authorNickname
        };
      }
    }

    await postRef.update({
      commentCount: newCommentCount,
      hotScore: newHotScore,
      topComment,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    // Update distributed counter shard
    const shardId = `shard_${Math.floor(Math.random() * 20)}`;
    const shardRef = db.doc(`post_counters/${postId}/shards/${shardId}`);
    const increment = isDelete ? -1 : 1;

    await shardRef.set({
      comments: admin.firestore.FieldValue.increment(increment)
    }, { merge: true });
  });

// Recalculate hot scores periodically (run every hour)
export const recalculateHotScores = functions.pubsub
  .schedule('0 * * * *')
  .timeZone('Asia/Seoul')
  .onRun(async (context) => {
    const batch = db.batch();
    let batchCount = 0;
    const maxBatchSize = 500;

    // Get recent posts (last 7 days)
    const sevenDaysAgo = admin.firestore.Timestamp.fromMillis(
      Date.now() - 7 * 24 * 60 * 60 * 1000
    );

    const postsSnap = await db.collection('posts')
      .where('createdAt', '>=', sevenDaysAgo)
      .where('visibility', '==', 'public')
      .limit(1000)
      .get();

    for (const postDoc of postsSnap.docs) {
      const postData = postDoc.data();
      const newHotScore = calculateHotScore(
        postData.likeCount || 0,
        postData.commentCount || 0,
        postData.viewCount || 0,
        postData.createdAt
      );

      batch.update(postDoc.ref, { hotScore: newHotScore });
      batchCount++;

      if (batchCount >= maxBatchSize) {
        await batch.commit();
        batchCount = 0;
      }
    }

    if (batchCount > 0) {
      await batch.commit();
    }

    console.log(`Recalculated hot scores for ${postsSnap.size} posts`);
  });

// Clean up reported content
export const processReports = functions.firestore
  .document('reports/{reportId}')
  .onCreate(async (snapshot, context) => {
    const reportData = snapshot.data();
    const { targetType, targetId, reason } = reportData;

    // Auto-hide content if it receives multiple reports
    const reportsQuery = db.collection('reports')
      .where('targetType', '==', targetType)
      .where('targetId', '==', targetId);

    const reportsSnap = await reportsQuery.get();
    const reportCount = reportsSnap.size;

    // Auto-hide after 3 reports
    if (reportCount >= 3) {
      if (targetType === 'post') {
        await db.doc(`posts/${targetId}`).update({
          visibility: 'hidden',
          moderationReason: 'Multiple reports received',
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });
      }
    }

    console.log(`Processed report for ${targetType}:${targetId}, total reports: ${reportCount}`);
  });
