import * as admin from 'firebase-admin';
import { setGlobalOptions } from 'firebase-functions';
import * as functions from 'firebase-functions/v1';
import { Change, EventContext } from 'firebase-functions/v1';
import {
  DocumentData,
  DocumentReference,
  QuerySnapshot,
  Transaction,
} from 'firebase-admin/firestore';

admin.initializeApp();

setGlobalOptions({ maxInstances: 10 });

const db = admin.firestore();

const COUNTER_SHARD_COUNT = 20;
const LIKE_WEIGHT = 3;
const COMMENT_WEIGHT = 5;
const VIEW_WEIGHT = 1;
const DECAY_LAMBDA = 1.2; // TODO: Move weights to Remote Config for runtime tuning.

export const onLikeWrite = functions.firestore
  .document('likes/{likeId}')
  .onWrite(async (
    change: Change<functions.firestore.DocumentSnapshot>,
    _context: EventContext,
  ) => {
    if (change.before.exists === change.after.exists) {
      return;
    }

    const snapshot = change.after.exists ? change.after : change.before;
    if (!snapshot.exists) {
      return;
    }

    const data = snapshot.data() as DocumentData | undefined;
    const postId = data?.postId as string | undefined;
    if (!postId) {
      return;
    }

    const delta = change.after.exists ? 1 : -1;
    await updatePostMetrics(postId, delta, 0, { updateTopComment: false });
    await incrementShardCounter(postId, 'likes', delta);
  });

export const onCommentWrite = functions.firestore
  .document('posts/{postId}/comments/{commentId}')
  .onWrite(async (
    change: Change<functions.firestore.DocumentSnapshot>,
    context: EventContext,
  ) => {
    const postId = context.params.postId as string | undefined;
    if (!postId) {
      return;
    }

    const beforeData = change.before.data() as DocumentData | undefined;
    const afterData = change.after.data() as DocumentData | undefined;

    const beforeDeleted = beforeData?.deleted === true;
    const afterDeleted = afterData?.deleted === true;

    let delta = 0;
    if (!change.before.exists && change.after.exists && !afterDeleted) {
      delta = 1;
    } else if (change.before.exists && !change.after.exists && !beforeDeleted) {
      delta = -1;
    } else if (change.before.exists && change.after.exists) {
      if (!beforeDeleted && afterDeleted) {
        delta = -1;
      } else if (beforeDeleted && !afterDeleted) {
        delta = 1;
      }
    }

    await updatePostMetrics(postId, 0, delta, { updateTopComment: true });
    if (delta !== 0) {
      await incrementShardCounter(postId, 'comments', delta);
    }
  });

export const onPostWrite = functions.firestore
  .document('posts/{postId}')
  .onWrite(async (
    change: Change<functions.firestore.DocumentSnapshot>,
    _context: EventContext,
  ) => {
    const beforeData = change.before.data() as DocumentData | undefined;
    const afterData = change.after.data() as DocumentData | undefined;

    const beforeVisibility = (beforeData?.visibility as string | undefined) ?? 'public';
    const beforeTokens = extractKeywordSet(beforeData);

    if (!afterData) {
      if (beforeVisibility === 'public' && beforeTokens.size > 0) {
        await adjustSuggestionCounts(beforeTokens, new Set<string>());
      }
      return;
    }

    const normalizedTags = normalizeTags(afterData.tags);
    const keywords = buildPrefixes({
      title: typeof afterData.title === 'string' ? afterData.title : undefined,
      body: typeof afterData.text === 'string' ? afterData.text : undefined,
      tags: normalizedTags,
    });

    const updates: DocumentData = {};
    const currentTags: string[] = Array.isArray(afterData.tags)
      ? afterData.tags.filter((value: unknown): value is string => typeof value === 'string')
      : [];
    if (!arraysEqual(normalizedTags, currentTags)) {
      updates.tags = normalizedTags;
    }

    const currentKeywords: string[] = Array.isArray(afterData.keywords)
      ? (afterData.keywords as string[])
      : [];
    if (!arraysEqual(keywords, currentKeywords)) {
      updates.keywords = keywords;
    }

    if (Object.keys(updates).length > 0) {
      updates.updatedAt = admin.firestore.FieldValue.serverTimestamp();
      await change.after.ref.update(updates);
    }

    const afterVisibility = (afterData.visibility as string | undefined) ?? 'public';
    const includeBefore = beforeVisibility === 'public';
    const includeAfter = afterVisibility === 'public';

    const previousSet = includeBefore ? beforeTokens : new Set<string>();
    const currentSet = includeAfter ? new Set<string>(keywords) : new Set<string>();

    await adjustSuggestionCounts(previousSet, currentSet);
  });

async function updatePostMetrics(
  postId: string,
  likeDelta: number,
  commentDelta: number,
  { updateTopComment }: { updateTopComment: boolean },
): Promise<void> {
  const postRef = db.collection('posts').doc(postId);
  await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(postRef);
    if (!snapshot.exists) {
      return;
    }

    const data = snapshot.data() as DocumentData;
    const currentLikes = typeof data.likeCount === 'number' ? data.likeCount : 0;
    const currentComments = typeof data.commentCount === 'number' ? data.commentCount : 0;
    const currentViews = typeof data.viewCount === 'number' ? data.viewCount : 0;
    const likeCount = Math.max(currentLikes + likeDelta, 0);
    const commentCount = Math.max(currentComments + commentDelta, 0);
    const createdAt = toDate(data.createdAt);
    const hotScore = calculateHotScore(likeCount, commentCount, currentViews, createdAt);

    const updates: DocumentData = {
      hotScore,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    if (likeDelta !== 0) {
      updates.likeCount = admin.firestore.FieldValue.increment(likeDelta);
    }
    if (commentDelta !== 0) {
      updates.commentCount = admin.firestore.FieldValue.increment(commentDelta);
    }

    if (updateTopComment) {
      updates.topComment = await fetchTopComment(transaction, postRef);
    }

    transaction.update(postRef, updates);
  });
}

async function fetchTopComment(
  transaction: Transaction,
  postRef: DocumentReference<DocumentData>,
): Promise<DocumentData | null> {
  const commentsQuery = postRef
    .collection('comments')
    .where('deleted', '==', false)
    .orderBy('likeCount', 'desc')
    .orderBy('createdAt', 'asc')
    .limit(1);

  const snapshot: QuerySnapshot<DocumentData> = await transaction.get(commentsQuery);
  if (snapshot.empty) {
    return null;
  }

  const doc = snapshot.docs[0];
  const data = doc.data();
  return {
    id: doc.id,
    text: typeof data.text === 'string' ? data.text : '',
    likeCount: typeof data.likeCount === 'number' ? data.likeCount : 0,
    authorNickname: typeof data.authorNickname === 'string' ? data.authorNickname : '익명',
  };
}

async function incrementShardCounter(postId: string, field: string, delta: number): Promise<void> {
  if (delta === 0) {
    return;
  }
  const shardRef = db
    .collection('post_counters')
    .doc(postId)
    .collection('shards')
    .doc(randomShardId());
  await shardRef.set({ [field]: admin.firestore.FieldValue.increment(delta) }, { merge: true });
}

async function adjustSuggestionCounts(
  previous: Set<string>,
  current: Set<string>,
): Promise<void> {
  const deltas = new Map<string, number>();
  for (const token of current) {
    deltas.set(token, (deltas.get(token) ?? 0) + 1);
  }
  for (const token of previous) {
    deltas.set(token, (deltas.get(token) ?? 0) - 1);
  }

  const tasks: Promise<void>[] = [];
  for (const [token, delta] of deltas.entries()) {
    if (delta !== 0) {
      tasks.push(applySuggestionDelta(token, delta));
    }
  }

  await Promise.all(tasks);
}

async function applySuggestionDelta(token: string, delta: number): Promise<void> {
  if (!token.trim()) {
    return;
  }
  const suggestionRef = db.collection('search_suggestions').doc(token);
  await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(suggestionRef);
    const currentCount = snapshot.exists
      ? (snapshot.data()?.count as number | undefined ?? 0)
      : 0;
    const next = currentCount + delta;
    if (next <= 0) {
      transaction.delete(suggestionRef);
    } else {
      transaction.set(
        suggestionRef,
        {
          count: next,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    }
  });
}

function randomShardId(): string {
  const index = Math.floor(Math.random() * COUNTER_SHARD_COUNT);
  return `shard_${index}`;
}

function calculateHotScore(
  likeCount: number,
  commentCount: number,
  viewCount: number,
  createdAt: Date,
  reference: Date = new Date(),
): number {
  const ageMs = reference.getTime() - createdAt.getTime();
  const hours = ageMs / (1000 * 60 * 60);
  const timeDecay = Math.pow(2, hours / DECAY_LAMBDA);
  const base = likeCount * LIKE_WEIGHT + commentCount * COMMENT_WEIGHT + viewCount * VIEW_WEIGHT;
  if (timeDecay <= 0) {
    return base;
  }
  return base / timeDecay;
}

function toDate(value: unknown): Date {
  if (!value) {
    return new Date();
  }
  if (value instanceof Date) {
    return value;
  }
  if (value instanceof admin.firestore.Timestamp) {
    return value.toDate();
  }
  if (typeof value === 'number') {
    return new Date(value);
  }
  if (typeof value === 'string') {
    const parsed = new Date(value);
    if (!Number.isNaN(parsed.getTime())) {
      return parsed;
    }
  }
  if (typeof (value as { toDate?: () => Date }).toDate === 'function') {
    return (value as { toDate: () => Date }).toDate();
  }
  return new Date();
}

function normalizeTags(raw: unknown): string[] {
  if (!Array.isArray(raw)) {
    return [];
  }
  const seen = new Set<string>();
  const result: string[] = [];
  for (const entry of raw) {
    if (typeof entry !== 'string') {
      continue;
    }
    const trimmed = entry.trim();
    if (!trimmed || seen.has(trimmed)) {
      continue;
    }
    seen.add(trimmed);
    result.push(trimmed);
  }
  return result;
}

function buildPrefixes({
  title,
  body,
  tags,
}: {
  title?: string;
  body?: string;
  tags?: string[];
}): string[] {
  const tokens = new Set<string>();
  const maxTokens = 50;
  const maxLength = 20;

  const addValue = (value?: string) => {
    if (!value) {
      return;
    }
    const words = value
      .toLowerCase()
      .split(/[\s.,!?@#\-_/]+/)
      .map((word) => word.trim())
      .filter((word) => word.length > 0);

    for (const word of words) {
      const limit = Math.min(word.length, maxLength);
      for (let index = 1; index <= limit; index += 1) {
        tokens.add(word.substring(0, index));
        if (tokens.size >= maxTokens) {
          return;
        }
      }
      if (tokens.size >= maxTokens) {
        return;
      }
    }
  };

  addValue(title);
  addValue(body);
  if (tags) {
    for (const tag of tags) {
      addValue(tag);
      if (tokens.size >= maxTokens) {
        break;
      }
    }
  }

  return Array.from(tokens).slice(0, maxTokens);
}

function arraysEqual(a: string[], b: string[]): boolean {
  if (a.length !== b.length) {
    return false;
  }
  return a.every((value, index) => value === b[index]);
}

function extractKeywordSet(data: DocumentData | undefined): Set<string> {
  if (!data || !Array.isArray(data.keywords)) {
    return new Set<string>();
  }
  const tokens = new Set<string>();
  for (const entry of data.keywords as unknown[]) {
    if (typeof entry === 'string' && entry.trim()) {
      tokens.add(entry);
    }
  }
  return tokens;
}
