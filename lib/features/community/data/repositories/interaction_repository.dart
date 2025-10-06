import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/firebase/paginated_query.dart';
import '../../../../core/constants/engagement_points.dart';
import '../../../../core/firebase/firestore_refs.dart';
import '../../../profile/data/user_profile_repository.dart';

typedef JsonMap = Map<String, Object?>;
typedef DocSnapshotJson = DocumentSnapshot<JsonMap>;

/// Interaction Repository - Manages user interactions with content
///
/// Responsibilities:
/// - Toggle likes on posts and comments
/// - Toggle scraps on posts
/// - Fetch liked and scrapped post IDs
/// - Fetch scrapped posts with pagination
/// - Award engagement points for interactions
///
/// Dependencies: UserProfileRepository, FirebaseFirestore
class InteractionRepository {
  InteractionRepository({
    FirebaseFirestore? firestore,
    required UserProfileRepository userProfileRepository,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _userProfileRepository = userProfileRepository;

  final FirebaseFirestore _firestore;
  final UserProfileRepository _userProfileRepository;
  final Random _random = Random();
  static const int _counterShardCount = 10;

  CollectionReference<JsonMap> get _postsRef => _firestore.collection(Fs.posts);
  CollectionReference<JsonMap> get _likesRef => _firestore.collection(Fs.likes);

  DocumentReference<JsonMap> _postDoc(String postId) => _postsRef.doc(postId);

  CollectionReference<JsonMap> _commentsRef(String postId) =>
      _postDoc(postId).collection(Fs.comments);

  CollectionReference<JsonMap> _commentLikesRef(String postId) =>
      _postDoc(postId).collection('comment_likes');

  CollectionReference<JsonMap> _postCounterShard(String postId) =>
      _firestore.collection(Fs.postCounters).doc(postId).collection(Fs.shards);

  CollectionReference<JsonMap> _scrapsRef(String uid) =>
      _userDoc(uid).collection('scraps');

  DocumentReference<JsonMap> _userDoc(String uid) =>
      _firestore.collection(Fs.users).doc(uid);

  DocumentReference<JsonMap> _counterShardRef(String postId) {
    final int shardIndex = _random.nextInt(_counterShardCount);
    return _postCounterShard(postId).doc('shard_$shardIndex');
  }

  Future<bool> togglePostLike({
    required String postId,
    required String uid,
  }) async {
    final DocumentReference<JsonMap> likeDoc = _likesRef.doc('${postId}_$uid');
    final DocumentReference<JsonMap> postDoc = _postDoc(postId);
    final DocumentReference<JsonMap> shardDoc = _counterShardRef(postId);
    String? postAuthorUid;
    final bool liked = await _firestore.runTransaction<bool>((
      Transaction transaction,
    ) async {
      final DocSnapshotJson postSnapshot = await transaction.get(postDoc);
      if (!postSnapshot.exists) {
        throw StateError('게시글을 찾을 수 없습니다.');
      }
      postAuthorUid = (postSnapshot.data()?['authorUid'] as String?) ?? '';

      final DocSnapshotJson likeSnapshot = await transaction.get(likeDoc);
      final bool willLike = !likeSnapshot.exists;

      transaction.set(
        postDoc,
        <String, Object?>{
          'likeCount': FieldValue.increment(willLike ? 1 : -1),
          'updatedAt': Timestamp.now(),
        },
        SetOptions(merge: true),
      );

      transaction.set(
        shardDoc,
        <String, Object?>{
          'likes': FieldValue.increment(willLike ? 1 : -1),
        },
        SetOptions(merge: true),
      );

      if (willLike) {
        transaction.set(likeDoc, <String, Object?>{
          'postId': postId,
          'uid': uid,
          'createdAt': Timestamp.now(),
        });
      } else {
        transaction.delete(likeDoc);
      }

      return willLike;
    });

    if (liked &&
        postAuthorUid != null &&
        postAuthorUid!.isNotEmpty &&
        postAuthorUid != uid) {
      try {
        await _userProfileRepository.incrementPoints(
          uid: postAuthorUid!,
          delta: EngagementPoints.contentReceivedLike,
        );
      } catch (error, stackTrace) {
        debugPrint('Failed to award points for post like: $error\n$stackTrace');
      }
    }

    return liked;
  }

  Future<bool> toggleCommentLike({
    required String postId,
    required String commentId,
    required String uid,
  }) async {
    final CollectionReference<JsonMap> commentLikes = _commentLikesRef(postId);
    final DocumentReference<JsonMap> likeDoc =
        commentLikes.doc('${commentId}_$uid');
    final DocumentReference<JsonMap> commentDoc =
        _commentsRef(postId).doc(commentId);
    String? commentAuthorUid;
    final bool liked = await _firestore.runTransaction<bool>((
      Transaction transaction,
    ) async {
      final DocSnapshotJson commentSnapshot = await transaction.get(commentDoc);
      if (!commentSnapshot.exists) {
        throw StateError('댓글을 찾을 수 없습니다.');
      }
      commentAuthorUid =
          (commentSnapshot.data()?['authorUid'] as String?) ?? '';

      final DocSnapshotJson likeSnapshot = await transaction.get(likeDoc);
      final bool willLike = !likeSnapshot.exists;

      transaction.update(commentDoc, <String, Object?>{
        'likeCount': FieldValue.increment(willLike ? 1 : -1),
      });

      if (willLike) {
        transaction.set(likeDoc, <String, Object?>{
          'commentId': commentId,
          'uid': uid,
          'createdAt': Timestamp.now(),
        });
      } else {
        transaction.delete(likeDoc);
      }

      return willLike;
    });

    if (liked &&
        commentAuthorUid != null &&
        commentAuthorUid!.isNotEmpty &&
        commentAuthorUid != uid) {
      try {
        await _userProfileRepository.incrementPoints(
          uid: commentAuthorUid!,
          delta: EngagementPoints.contentReceivedLike,
        );
      } catch (error, stackTrace) {
        debugPrint(
          'Failed to award points for comment like: $error\n$stackTrace',
        );
      }
    }

    return liked;
  }

  Future<void> toggleScrap({
    required String uid,
    required String postId,
  }) async {
    final DocumentReference<JsonMap> scrapDoc =
        _scrapsRef(uid).doc(postId);
    final DocSnapshotJson snapshot = await scrapDoc.get();
    if (snapshot.exists) {
      await scrapDoc.delete();
    } else {
      await scrapDoc.set(<String, Object?>{
        'createdAt': Timestamp.now(),
        'postId': postId,
      });
    }
  }

  Future<Set<String>> fetchScrappedPostIds(String uid) async {
    final QuerySnapshot<JsonMap> snapshot = await _scrapsRef(uid).get();
    return snapshot.docs
        .map((QueryDocumentSnapshot<JsonMap> doc) => doc.id)
        .toSet();
  }

  Future<PaginatedQueryResult<String>> fetchScrappedPostIdsPage({
    required String uid,
    int limit = 20,
    QueryDocumentSnapshotJson? startAfter,
  }) async {
    Query<JsonMap> scrapQuery =
        _scrapsRef(uid).orderBy('createdAt', descending: true).limit(limit);
    if (startAfter != null) {
      scrapQuery = scrapQuery.startAfterDocument(startAfter);
    }

    final QuerySnapshot<JsonMap> scrapSnapshot = await scrapQuery.get();
    final List<String> postIds = scrapSnapshot.docs
        .map((QueryDocumentSnapshot<JsonMap> doc) => doc.id)
        .toList(growable: false);

    final bool hasMore = scrapSnapshot.docs.length == limit;
    final QueryDocumentSnapshot<JsonMap>? last = scrapSnapshot.docs.isEmpty
        ? null
        : scrapSnapshot.docs.last;

    return PaginatedQueryResult<String>(
      items: postIds,
      hasMore: hasMore,
      lastDocument: last,
    );
  }

  Future<Set<String>> fetchLikedPostIds({
    required String uid,
    required List<String> postIds,
  }) async {
    if (postIds.isEmpty) {
      return const <String>{};
    }

    final Set<String> likedIds = <String>{};
    final Iterable<List<String>> chunks = _chunk(postIds, size: 10);
    for (final List<String> chunk in chunks) {
      final QuerySnapshot<JsonMap> snapshot = await _likesRef
          .where('uid', isEqualTo: uid)
          .where('postId', whereIn: chunk)
          .get();
      likedIds.addAll(
        snapshot.docs.map(
          (QueryDocumentSnapshot<JsonMap> doc) => doc['postId'] as String,
        ),
      );
    }
    return likedIds;
  }

  Future<Set<String>> fetchScrappedIds({
    required String uid,
    required List<String> postIds,
  }) async {
    if (postIds.isEmpty) {
      return const <String>{};
    }

    final Set<String> scrapped = <String>{};
    final Iterable<List<String>> chunks = _chunk(postIds, size: 10);
    for (final List<String> chunk in chunks) {
      final List<Future<DocumentSnapshot<JsonMap>>> futures = chunk
          .map((String postId) => _scrapsRef(uid).doc(postId).get())
          .toList(growable: false);
      final List<DocumentSnapshot<JsonMap>> results =
          await Future.wait(futures);
      for (int index = 0; index < results.length; index += 1) {
        if (results[index].exists) {
          scrapped.add(chunk[index]);
        }
      }
    }

    return scrapped;
  }

  /// Fetch liked post IDs for a user with pagination
  Future<PaginatedQueryResult<String>> fetchLikedPostIdsPage({
    required String uid,
    int limit = 20,
    QueryDocumentSnapshotJson? startAfter,
  }) async {
    Query<JsonMap> likeQuery = _likesRef
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (startAfter != null) {
      likeQuery = likeQuery.startAfterDocument(startAfter);
    }

    final QuerySnapshot<JsonMap> likeSnapshot = await likeQuery.get();
    final List<String> postIds = likeSnapshot.docs
        .map((QueryDocumentSnapshot<JsonMap> doc) => doc['postId'] as String)
        .toList(growable: false);

    final bool hasMore = likeSnapshot.docs.length == limit;
    final QueryDocumentSnapshot<JsonMap>? last = likeSnapshot.docs.isEmpty
        ? null
        : likeSnapshot.docs.last;

    return PaginatedQueryResult<String>(
      items: postIds,
      hasMore: hasMore,
      lastDocument: last,
    );
  }

  Future<Set<String>> fetchLikedCommentIds({
    required String postId,
    required String uid,
    required List<String> commentIds,
  }) async {
    if (commentIds.isEmpty) {
      return const <String>{};
    }

    final Set<String> likedIds = <String>{};
    final Iterable<List<String>> chunks = _chunk(commentIds, size: 10);
    for (final List<String> chunk in chunks) {
      final QuerySnapshot<JsonMap> snapshot = await _commentLikesRef(postId)
          .where('uid', isEqualTo: uid)
          .where('commentId', whereIn: chunk)
          .get();
      likedIds.addAll(
        snapshot.docs.map(
          (QueryDocumentSnapshot<JsonMap> doc) => doc['commentId'] as String,
        ),
      );
    }
    return likedIds;
  }

  Iterable<List<T>> _chunk<T>(List<T> items, {int size = 10}) sync* {
    for (int i = 0; i < items.length; i += size) {
      yield items.sublist(i, i + size > items.length ? items.length : i + size);
    }
  }
}
