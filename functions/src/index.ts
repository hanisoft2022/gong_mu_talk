import {setGlobalOptions} from "firebase-functions";
import {onDocumentWritten} from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import {initializeApp} from "firebase-admin/app";
import {FieldValue, Timestamp, getFirestore} from "firebase-admin/firestore";

type CommentSnapshotData = {
  text?: string;
  likeCount?: number;
  authorNickname?: string;
  deleted?: boolean;
};

type PostSnapshotData = {
  likeCount?: number;
  commentCount?: number;
  viewCount?: number;
  createdAt?: Timestamp | Date | string | number | null;
  visibility?: string;
  authorUid?: string;
  audience?: string;
  serial?: string;
  text?: string;
  authorNickname?: string;
  tags?: unknown;
  keywords?: unknown;
};

const REGION = "asia-northeast3";
const LIKE_WEIGHT = 3;
const COMMENT_WEIGHT = 5;
const VIEW_WEIGHT = 1;
const DECAY_LAMBDA = 1.2;
const MAX_KEYWORD_TOKENS = 150;
const MAX_TOKEN_LENGTH = 20;

setGlobalOptions({region: REGION, maxInstances: 10});

initializeApp();
const db = getFirestore();

function toDate(value: Timestamp | Date | string | number | null | undefined): Date {
  if (value instanceof Timestamp) {
    return value.toDate();
  }
  if (value instanceof Date) {
    return value;
  }
  if (typeof value === "number") {
    return new Date(value);
  }
  if (typeof value === "string") {
    const parsed = new Date(value);
    if (!Number.isNaN(parsed.getTime())) {
      return parsed;
    }
  }
  return new Date();
}

function calculateHotScore(
  likeCount: number,
  commentCount: number,
  viewCount: number,
  createdAt: Timestamp | Date | string | number | null | undefined,
): number {
  const created = toDate(createdAt);
  const ageMillis = Date.now() - created.getTime();
  const hours = ageMillis / (1000 * 60 * 60);
  const baseScore =
    likeCount * LIKE_WEIGHT + commentCount * COMMENT_WEIGHT + viewCount * VIEW_WEIGHT;
  if (!Number.isFinite(hours) || hours <= 0) {
    return baseScore;
  }
  const timeDecay = Math.pow(2, hours / DECAY_LAMBDA);
  if (!Number.isFinite(timeDecay) || timeDecay <= 0) {
    return baseScore;
  }
  return baseScore / timeDecay;
}

function normalizeTags(raw: unknown): string[] {
  if (!Array.isArray(raw)) {
    return [];
  }
  const normalized = new Set<string>();
  for (const value of raw) {
    if (typeof value !== "string") {
      continue;
    }
    const cleaned = value.replace(/^#+/, "").trim().toLowerCase();
    if (cleaned.length > 0) {
      normalized.add(cleaned);
    }
  }
  return Array.from(normalized).slice(0, 50);
}

function tokenize(value: string, collector: Set<string>): void {
  const segments = value
    .toLowerCase()
    .split(/[\s.,!?@#\-_/]+/)
    .filter((segment) => segment.trim().length > 0);
  for (const segment of segments) {
    const limit = Math.min(segment.length, MAX_TOKEN_LENGTH);
    for (let i = 1; i <= limit; i += 1) {
      collector.add(segment.substring(0, i));
      if (collector.size >= MAX_KEYWORD_TOKENS) {
        return;
      }
    }
    if (collector.size >= MAX_KEYWORD_TOKENS) {
      return;
    }
  }
}

function buildKeywords(post: PostSnapshotData, tags: string[]): string[] {
  const tokens = new Set<string>();
  if (typeof post.authorNickname === "string") {
    tokenize(post.authorNickname, tokens);
  }
  if (typeof post.text === "string") {
    tokenize(post.text, tokens);
  }
  for (const tag of tags) {
    tokenize(tag, tokens);
    if (tokens.size >= MAX_KEYWORD_TOKENS) {
      break;
    }
  }
  return Array.from(tokens).slice(0, MAX_KEYWORD_TOKENS);
}

function arraysEqual(a: unknown, b: unknown): boolean {
  if (!Array.isArray(a) || !Array.isArray(b) || a.length !== b.length) {
    return false;
  }
  return a.every((value, index) => value === b[index]);
}

export const onLikeWrite = onDocumentWritten({
  document: "likes/{likeId}",
}, async (event) => {
  const before = event.data?.before;
  const after = event.data?.after;
  const beforeExists = before?.exists ?? false;
  const afterExists = after?.exists ?? false;

  if (beforeExists === afterExists) {
    return;
  }

  const snapshot = afterExists ? after : before;
  const data = snapshot?.data() as {postId?: string} | undefined;
  const postId = data?.postId;
  if (!postId) {
    logger.warn("Like document missing postId", event.params.likeId);
    return;
  }

  const delta = afterExists ? 1 : -1;
  const postRef = db.collection("posts").doc(postId);

  await db.runTransaction(async (transaction) => {
    const postSnap = await transaction.get(postRef);
    if (!postSnap.exists) {
      logger.warn("Post not found while processing like", postId);
      return;
    }
    const postData = postSnap.data() as PostSnapshotData;
    const likeCount = Math.max(0, (postData.likeCount ?? 0) + delta);
    const commentCount = postData.commentCount ?? 0;
    const viewCount = postData.viewCount ?? 0;
    const hotScore = calculateHotScore(likeCount, commentCount, viewCount, postData.createdAt);

    transaction.update(postRef, {
      likeCount,
      hotScore,
      updatedAt: FieldValue.serverTimestamp(),
    });
  });
});

export const onCommentWrite = onDocumentWritten({
  document: "posts/{postId}/comments/{commentId}",
}, async (event) => {
  const postId = event.params.postId as string;
  const before = event.data?.before;
  const after = event.data?.after;
  const beforeExists = before?.exists ?? false;
  const afterExists = after?.exists ?? false;
  const delta = afterExists && !beforeExists ? 1 : !afterExists && beforeExists ? -1 : 0;

  const postRef = db.collection("posts").doc(postId);

  if (delta !== 0) {
    await db.runTransaction(async (transaction) => {
      const postSnap = await transaction.get(postRef);
      if (!postSnap.exists) {
        logger.warn("Post not found while processing comment", postId);
        return;
      }
      const postData = postSnap.data() as PostSnapshotData;
      const likeCount = postData.likeCount ?? 0;
      const commentCount = Math.max(0, (postData.commentCount ?? 0) + delta);
      const viewCount = postData.viewCount ?? 0;
      const hotScore = calculateHotScore(likeCount, commentCount, viewCount, postData.createdAt);

      transaction.update(postRef, {
        commentCount,
        hotScore,
        updatedAt: FieldValue.serverTimestamp(),
      });
    });
  }

  const commentsSnap = await db
    .collection("posts")
    .doc(postId)
    .collection("comments")
    .where("deleted", "==", false)
    .orderBy("likeCount", "desc")
    .orderBy("createdAt", "asc")
    .limit(1)
    .get();

  if (commentsSnap.empty) {
    await postRef.update({topComment: null});
    return;
  }

  const topDoc = commentsSnap.docs[0];
  const topData = topDoc.data() as CommentSnapshotData;
  await postRef.update({
    topComment: {
      id: topDoc.id,
      text: topData.text ?? "",
      likeCount: topData.likeCount ?? 0,
      authorNickname: topData.authorNickname ?? "익명",
    },
  });
});

export const onPostWrite = onDocumentWritten({
  document: "posts/{postId}",
}, async (event) => {
  const after = event.data?.after;
  if (!after?.exists) {
    return;
  }

  const postData = after.data() as PostSnapshotData;
  const normalizedTags = normalizeTags(postData.tags);
  const keywords = buildKeywords(postData, normalizedTags);

  const updates: Record<string, unknown> = {};
  if (!arraysEqual(postData.tags, normalizedTags)) {
    updates.tags = normalizedTags;
  }
  if (!arraysEqual(postData.keywords, keywords)) {
    updates.keywords = keywords;
  }

  if (Object.keys(updates).length > 0) {
    updates.updatedAt = FieldValue.serverTimestamp();
    await after.ref.update(updates);
  }

  const isCreate = !(event.data?.before?.exists ?? false);
  if (isCreate && keywords.length > 0) {
    const batch = db.batch();
    const suggestions = db.collection("search_suggestions");
    keywords.slice(0, 50).forEach((token) => {
      const suggestionRef = suggestions.doc(token);
      batch.set(
        suggestionRef,
        {
          count: FieldValue.increment(1),
          updatedAt: FieldValue.serverTimestamp(),
        },
        {merge: true},
      );
    });
    await batch.commit();
  }
});
