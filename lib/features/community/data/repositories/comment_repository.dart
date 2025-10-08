import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/firebase/paginated_query.dart';
import '../../../../core/utils/prefix_tokenizer.dart';
import '../../../../core/constants/engagement_points.dart';
import '../../../../core/firebase/firestore_refs.dart';
import '../../../profile/domain/career_track.dart';
import '../../../profile/data/user_profile_repository.dart';
import '../../domain/models/comment.dart';
import '../../domain/models/post.dart';

typedef JsonMap = Map<String, Object?>;
typedef DocSnapshotJson = DocumentSnapshot<JsonMap>;

/// Comment Repository - Manages comment CRUD operations
///
/// Responsibilities:
/// - Create, read, delete comments
/// - Fetch comments for posts with pagination
/// - Load top/featured comments
/// - Update post comment counts
///
/// Note: Comment notifications are now handled by Firebase Functions (onCommentNotification)
///
/// Dependencies: UserProfileRepository, FirebaseFirestore
class CommentRepository {
  CommentRepository({
    FirebaseFirestore? firestore,
    required UserProfileRepository userProfileRepository,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _userProfileRepository = userProfileRepository;

  final FirebaseFirestore _firestore;
  final UserProfileRepository _userProfileRepository;
  final PrefixTokenizer _tokenizer = const PrefixTokenizer();

  // NOTE: Counter shard related fields removed as commentCount is now managed
  // by Firebase Functions. If needed, can be restored from git history.
  // Previously: _random, _counterShardCount, _counterShardRef, _postCounterShard

  CollectionReference<JsonMap> get _postsRef => _firestore.collection(Fs.posts);

  DocumentReference<JsonMap> _postDoc(String postId) => _postsRef.doc(postId);

  CollectionReference<JsonMap> _commentsRef(String postId) =>
      _postDoc(postId).collection(Fs.comments);

  Future<PaginatedQueryResult<Comment>> fetchComments({
    required String postId,
    int limit = 50,
    QueryDocumentSnapshot<JsonMap>? startAfter,
  }) async {
    Query<JsonMap> query = _commentsRef(
      postId,
    ).orderBy('createdAt', descending: false).limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final QuerySnapshot<JsonMap> snapshot = await query.get();
    final List<Comment> comments = snapshot.docs
        .map(
          (QueryDocumentSnapshot<JsonMap> doc) =>
              Comment.fromSnapshot(doc, postId: postId),
        )
        .toList(growable: false);

    final bool hasMore = snapshot.docs.length == limit;
    final QueryDocumentSnapshot<JsonMap>? last = snapshot.docs.isEmpty
        ? null
        : snapshot.docs.last;
    return PaginatedQueryResult<Comment>(
      items: comments,
      lastDocument: last,
      hasMore: hasMore,
    );
  }

  Future<Comment> createComment({
    required String postId,
    required String authorUid,
    required String authorNickname,
    required String text,
    String? parentCommentId,
    CareerTrack authorTrack = CareerTrack.none,
    String? authorSpecificCareer,
    bool authorSerialVisible = true,
    int authorSupporterLevel = 0,
    bool authorIsSupporter = false,
    bool awardPoints = true,
    List<String>? imageUrls,
  }) async {
    final CollectionReference<JsonMap> comments = _commentsRef(postId);
    final DocumentReference<JsonMap> commentDoc = comments.doc();
    final DateTime now = DateTime.now();

    await _firestore.runTransaction<void>((Transaction transaction) async {
      transaction.set(commentDoc, <String, Object?>{
        'authorUid': authorUid,
        'authorNickname': authorNickname,
        'authorTrack': authorTrack.name,
        'authorSpecificCareer': authorSpecificCareer,
        'authorSerialVisible': authorSerialVisible,
        'authorSupporterLevel': authorSupporterLevel,
        'authorIsSupporter': authorIsSupporter,
        'text': text,
        'likeCount': 0,
        'createdAt': Timestamp.fromDate(now),
        'parentCommentId': parentCommentId,
        'deleted': false,
        'keywords': _tokenizer.buildPrefixes(title: authorNickname, body: text),
        'imageUrls': imageUrls ?? [],
      });

      // NOTE: commentCount is now handled by Firebase Functions (onCommentWrite)
      // This prevents double-counting race condition between client and server.
      // Functions will detect comment creation and increment commentCount atomically.

      // Update post's updatedAt timestamp only
      final DocumentReference<JsonMap> postRef = _postDoc(postId);
      transaction.update(postRef, <String, Object?>{
        'updatedAt': Timestamp.fromDate(now),
      });
    });

    if (awardPoints) {
      try {
        await _userProfileRepository.incrementPoints(
          uid: authorUid,
          delta: EngagementPoints.commentCreation,
        );
      } catch (error, stackTrace) {
        debugPrint(
          'Failed to award points for comment creation: $error\n$stackTrace',
        );
      }

      // NOTE: Comment notifications are now handled by Firebase Functions
      // (onCommentNotification). This includes:
      // - Reply notifications (commentReply)
      // - Post comment notifications (postComment)
      // - Scrapped post notifications (scrappedPostComment)
      // No client-side notification dispatch needed.
    }

    return Comment(
      id: commentDoc.id,
      postId: postId,
      authorUid: authorUid,
      authorNickname: authorNickname,
      authorTrack: authorTrack,
      authorSerialVisible: authorSerialVisible,
      text: text,
      likeCount: 0,
      createdAt: now,
      parentCommentId: parentCommentId,
    );
  }

  Future<void> deleteComment({
    required String postId,
    required String commentId,
    required String requesterUid,
  }) async {
    final DocumentReference<JsonMap> commentDoc = _commentsRef(
      postId,
    ).doc(commentId);
    await _firestore.runTransaction<void>((Transaction transaction) async {
      final DocSnapshotJson snapshot = await transaction.get(commentDoc);
      if (!snapshot.exists) {
        return;
      }

      final Map<String, Object?> data = snapshot.data()!;
      if (data['authorUid'] != requesterUid) {
        throw StateError('댓글 삭제 권한이 없습니다.');
      }

      // Soft delete: Mark as deleted but keep the document
      transaction.update(commentDoc, <String, Object?>{
        'deleted': true,
        'text': '[삭제된 댓글]',
      });

      // NOTE: commentCount decrement is now handled by Firebase Functions (onCommentWrite)
      // Functions will detect deleted: false → true change and decrement commentCount.
      // This prevents race conditions and ensures consistency.

      // Update post's updatedAt timestamp only
      final DocumentReference<JsonMap> postRef = _postDoc(postId);
      transaction.update(postRef, <String, Object?>{
        'updatedAt': Timestamp.now(),
      });
    });
  }

  /// Undo comment deletion (restore)
  ///
  /// Restores a soft-deleted comment by setting deleted: false.
  /// Firebase Functions will detect this and increment commentCount back.
  Future<void> undoDeleteComment({
    required String postId,
    required String commentId,
    required String requesterUid,
    required String originalText,
  }) async {
    final DocumentReference<JsonMap> commentDoc = _commentsRef(
      postId,
    ).doc(commentId);
    await _firestore.runTransaction<void>((Transaction transaction) async {
      final DocSnapshotJson snapshot = await transaction.get(commentDoc);
      if (!snapshot.exists) {
        return;
      }

      final Map<String, Object?> data = snapshot.data()!;
      if (data['authorUid'] != requesterUid) {
        throw StateError('댓글 복구 권한이 없습니다.');
      }

      // Restore: Set deleted back to false
      transaction.update(commentDoc, <String, Object?>{
        'deleted': false,
        'text': originalText, // Restore original text
      });

      // NOTE: commentCount increment is handled by Firebase Functions (onCommentWrite)
      // Functions will detect deleted: true → false change and increment commentCount.

      // Update post's updatedAt timestamp
      final DocumentReference<JsonMap> postRef = _postDoc(postId);
      transaction.update(postRef, <String, Object?>{
        'updatedAt': Timestamp.now(),
      });
    });
  }

  Future<List<Comment>> getComments(String postId) async {
    final QuerySnapshot<JsonMap> snapshot = await _commentsRef(
      postId,
    ).orderBy('createdAt', descending: false).get();

    return snapshot.docs
        .map(
          (QueryDocumentSnapshot<JsonMap> doc) =>
              Comment.fromSnapshot(doc, postId: postId),
        )
        .toList();
  }

  Future<List<Comment>> getTopComments(String postId, {int limit = 3}) async {
    final QuerySnapshot<JsonMap> snapshot = await _commentsRef(postId)
        .where('deleted', isEqualTo: false)
        .orderBy('likeCount', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map(
          (QueryDocumentSnapshot<JsonMap> doc) =>
              Comment.fromSnapshot(doc, postId: postId),
        )
        .toList(growable: false);
  }

  Future<CachedComment?> loadTopComment(String postId) async {
    try {
      final QuerySnapshot<JsonMap> snapshot = await _commentsRef(
        postId,
      ).orderBy('likeCount', descending: true).limit(1).get();

      if (snapshot.docs.isEmpty) return null;

      final DocumentSnapshot<JsonMap> doc = snapshot.docs.first;
      final Map<String, Object?>? data = doc.data();
      if (data == null) return null;

      return CachedComment(
        id: doc.id,
        text: data['text'] as String? ?? '',
        likeCount: (data['likeCount'] as num?)?.toInt() ?? 0,
        authorNickname: data['authorNickname'] as String? ?? '익명',
        authorTrack: _careerTrackFromRaw(data['authorTrack']),
        authorSerialVisible: data['authorSerialVisible'] as bool? ?? true,
      );
    } catch (e) {
      debugPrint('Error loading top comment: $e');
      return null;
    }
  }

  Future<List<Comment>> searchComments({
    required String token,
    int limit = 20,
  }) async {
    final QuerySnapshot<JsonMap> snapshot = await _firestore
        .collectionGroup('comments')
        .where('deleted', isEqualTo: false)
        .where('keywords', arrayContains: token)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    if (snapshot.docs.isEmpty) {
      return const <Comment>[];
    }

    return snapshot.docs
        .map((doc) {
          final String postId = doc.reference.parent.parent?.id ?? '';
          return Comment.fromMap(id: doc.id, postId: postId, data: doc.data());
        })
        .toList(growable: false);
  }

  /// Fetch comments by author with pagination
  Future<PaginatedQueryResult<Comment>> fetchCommentsByAuthor({
    required String authorUid,
    int limit = 20,
    QueryDocumentSnapshot<JsonMap>? startAfter,
  }) async {
    Query<JsonMap> query = _firestore
        .collectionGroup('comments')
        .where('authorUid', isEqualTo: authorUid)
        .where('deleted', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final QuerySnapshot<JsonMap> snapshot = await query.get();
    final List<Comment> comments = snapshot.docs
        .map((QueryDocumentSnapshot<JsonMap> doc) {
          // Extract postId from document path: posts/{postId}/comments/{commentId}
          final String path = doc.reference.path;
          final List<String> parts = path.split('/');
          final String postId = parts.length >= 2 ? parts[1] : '';

          return Comment.fromSnapshot(doc, postId: postId);
        })
        .toList(growable: false);

    final bool hasMore = snapshot.docs.length == limit;
    final QueryDocumentSnapshot<JsonMap>? last = snapshot.docs.isEmpty
        ? null
        : snapshot.docs.last;

    return PaginatedQueryResult<Comment>(
      items: comments,
      lastDocument: last,
      hasMore: hasMore,
    );
  }

  CareerTrack _careerTrackFromRaw(Object? raw) {
    if (raw is String) {
      for (final CareerTrack track in CareerTrack.values) {
        if (track.name == raw) {
          return track;
        }
      }
    }
    return CareerTrack.none;
  }
}
