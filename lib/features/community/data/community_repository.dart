import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../../../core/firebase/paginated_query.dart';
import '../../../core/utils/hot_score.dart';
import '../../../core/utils/prefix_tokenizer.dart';
import '../../../core/utils/result.dart';
import '../../../core/constants/engagement_points.dart';
import '../../notifications/data/notification_repository.dart';
import '../../profile/domain/career_track.dart';
import '../domain/models/board.dart';
import '../domain/models/comment.dart';
import '../domain/models/feed_filters.dart';
import '../domain/models/post.dart';
import '../domain/models/report.dart';
import '../domain/models/search_suggestion.dart';
import '../domain/models/search_result.dart';
import '../../auth/domain/user_session.dart';
import '../../profile/data/user_profile_repository.dart';
import '../../../core/firebase/firestore_refs.dart';

typedef JsonMap = Map<String, Object?>;

typedef QueryJson = Query<JsonMap>;

typedef DocSnapshotJson = DocumentSnapshot<JsonMap>;

class CommunityRepository {
  CommunityRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    required UserSession userSession,
    required UserProfileRepository userProfileRepository,
    required NotificationRepository notificationRepository,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance,
       _userSession = userSession,
       _userProfileRepository = userProfileRepository,
       _notificationRepository = notificationRepository;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final UserSession _userSession;
  final UserProfileRepository _userProfileRepository;
  final NotificationRepository _notificationRepository;
  final Random _random = Random();
  final PrefixTokenizer _tokenizer = const PrefixTokenizer();
  final HotScoreCalculator _hotScoreCalculator = const HotScoreCalculator();
  static const int _counterShardCount = 20;
  static const Duration _loungeLookback = Duration(hours: 24);

  String get currentUserId => _userSession.userId;

  Future<String> get currentUserNickname async {
    final profile = await _userProfileRepository.fetchProfile(currentUserId);
    return profile?.nickname ?? 'Unknown User';
  }

  CollectionReference<JsonMap> get _postsRef => _firestore.collection(Fs.posts);

  CollectionReference<JsonMap> get _likesRef => _firestore.collection(Fs.likes);

  CollectionReference<JsonMap> get _boardsRef =>
      _firestore.collection(Fs.boards);

  CollectionReference<JsonMap> get _searchSuggestionRef =>
      _firestore.collection(Fs.suggestions);

  CollectionReference<JsonMap> get _reportsRef =>
      _firestore.collection('reports');

  DocumentReference<JsonMap> _postDoc(String postId) => _postsRef.doc(postId);

  CollectionReference<JsonMap> _commentsRef(String postId) =>
      _postDoc(postId).collection(Fs.comments);

  CollectionReference<JsonMap> _commentLikesRef(String postId) =>
      _postDoc(postId).collection('comment_likes');

  CollectionReference<JsonMap> _postCounterShard(String postId) =>
      _firestore.collection(Fs.postCounters).doc(postId).collection(Fs.shards);

  CollectionReference<JsonMap> _bookmarksRef(String uid) =>
      _userDoc(uid).collection('bookmarks');

  DocumentReference<JsonMap> _userDoc(String uid) =>
      _firestore.collection(Fs.users).doc(uid);

  Future<Post> createPost({
    required PostType type,
    required String authorUid,
    required String authorNickname,
    required CareerTrack authorTrack,
    bool authorSerialVisible = true,
    int authorSupporterLevel = 0,
    bool authorIsSupporter = false,
    required String text,
    required PostAudience audience,
    required String serial,
    List<PostMedia> media = const <PostMedia>[],
    List<String> tags = const <String>[],
    String? boardId,
    bool awardPoints = true,
  }) async {
    final DocumentReference<JsonMap> ref = _postsRef.doc();
    final DateTime now = DateTime.now();
    final List<String> keywords = _tokenizer.buildPrefixes(
      title: authorNickname,
      body: text,
      tags: tags,
    );

    final Map<String, Object?> data = <String, Object?>{
      'type': type.name,
      'audience': audience.name,
      'serial': serial,
      'boardId': boardId,
      'authorUid': authorUid,
      'authorNickname': authorNickname,
      'authorTrack': authorTrack.name,
      'authorSerialVisible': authorSerialVisible,
      'authorSupporterLevel': authorSupporterLevel,
      'authorIsSupporter': authorIsSupporter,
      'text': text,
      'media': media
          .map((PostMedia media) => media.toMap())
          .toList(growable: false),
      'tags': tags,
      'keywords': keywords,
      'likeCount': 0,
      'commentCount': 0,
      'viewCount': 0,
      'hotScore': _hotScoreCalculator.calculate(
        likeCount: 0,
        commentCount: 0,
        viewCount: 0,
        createdAt: now,
        now: now,
      ),
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
      'visibility': PostVisibility.public.name,
      'topComment': null,
    };

    await ref.set(data);
    if (awardPoints) {
      try {
        await _userProfileRepository.incrementPoints(
          uid: authorUid,
          delta: EngagementPoints.postCreation,
        );
      } catch (error, stackTrace) {
        debugPrint(
          'Failed to award points for post creation: $error\n$stackTrace',
        );
      }
    }
    return Post.fromMap(ref.id, data);
  }

  Future<void> updatePost({
    required String postId,
    required String authorUid,
    String? text,
    List<PostMedia>? media,
    List<String>? tags,
    PostVisibility? visibility,
  }) async {
    final DocumentReference<JsonMap> doc = _postDoc(postId);
    await _firestore.runTransaction<void>((Transaction transaction) async {
      final DocSnapshotJson snapshot = await transaction.get(doc);
      if (!snapshot.exists) {
        throw StateError('게시글을 찾을 수 없습니다.');
      }
      final Map<String, Object?> data = snapshot.data()!;
      if (data['authorUid'] != authorUid) {
        throw StateError('게시글 수정 권한이 없습니다.');
      }

      final Map<String, Object?> updates = <String, Object?>{
        'updatedAt': Timestamp.now(),
      };
      if (text != null) {
        updates['text'] = text;
        final List<String> keywords = _tokenizer.buildPrefixes(
          body: text,
          title: data['authorNickname'] as String?,
          tags: (tags ?? data['tags'] as List<Object?>?)?.cast<String>(),
        );
        updates['keywords'] = keywords;
      }
      if (media != null) {
        updates['media'] = media
            .map((PostMedia m) => m.toMap())
            .toList(growable: false);
      }
      if (tags != null) {
        updates['tags'] = tags;
      }
      if (visibility != null) {
        updates['visibility'] = visibility.name;
      }

      transaction.update(doc, updates);
    });
  }

  Future<void> deletePost({
    required String postId,
    required String authorUid,
  }) async {
    final DocumentReference<JsonMap> doc = _postDoc(postId);
    await _firestore.runTransaction<void>((Transaction transaction) async {
      final DocSnapshotJson snapshot = await transaction.get(doc);
      if (!snapshot.exists) {
        throw StateError('게시글을 찾을 수 없습니다.');
      }

      final Map<String, Object?> data = snapshot.data()!;
      if (data['authorUid'] != authorUid) {
        throw StateError('게시글 삭제 권한이 없습니다.');
      }

      transaction.update(doc, <String, Object?>{
        'visibility': PostVisibility.deleted.name,
        'updatedAt': Timestamp.now(),
      });
    });
  }

  Future<Post?> fetchPostById(String postId, {String? currentUid}) async {
    final DocSnapshotJson snapshot = await _postDoc(postId).get();
    if (!snapshot.exists) {
      return null;
    }

    bool liked = false;
    bool bookmarked = false;
    if (currentUid != null) {
      final DocumentSnapshot<JsonMap> likeSnapshot = await _likesRef
          .doc('${postId}_$currentUid')
          .get();
      liked = likeSnapshot.exists;
      final DocumentSnapshot<JsonMap> bookmarkSnapshot = await _bookmarksRef(
        currentUid,
      ).doc(postId).get();
      bookmarked = bookmarkSnapshot.exists;
    }

    Post post = Post.fromSnapshot(
      snapshot,
      isLiked: liked,
      isBookmarked: bookmarked,
    );

    if (post.topComment == null && post.commentCount > 0) {
      final CachedComment? topComment = await _loadTopComment(post.id);
      if (topComment != null) {
        post = post.copyWith(topComment: topComment);
      }
    }

    return post;
  }

  Future<PaginatedQueryResult<Post>> fetchChirpFeed({
    int limit = 20,
    QueryDocumentSnapshotJson? startAfter,
    String? currentUid,
  }) async {
    try {
      QueryJson query = _postsRef
          .where('type', isEqualTo: PostType.chirp.name)
          .where('visibility', isEqualTo: PostVisibility.public.name)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final QuerySnapshot<JsonMap> snapshot = await query.get();
      return _buildPostPage(snapshot, currentUid: currentUid, limit: limit);
    } catch (e) {
      debugPrint('Error fetching chirp feed: $e');
      return const PaginatedQueryResult<Post>(
        items: <Post>[],
        hasMore: false,
        lastDocument: null,
      );
    }
  }

  Future<PaginatedQueryResult<Post>> fetchLoungeFeed({
    required LoungeScope scope,
    required LoungeSort sort,
    int limit = 20,
    QueryDocumentSnapshotJson? startAfter,
    String? serial,
    String? currentUid,
  }) async {
    try {
      QueryJson query = _postsRef
          .where('type', isEqualTo: PostType.chirp.name)
          .where('visibility', isEqualTo: PostVisibility.public.name);

      if (scope == LoungeScope.serial) {
        if (serial == null || serial.isEmpty || serial == 'unknown') {
          return const PaginatedQueryResult<Post>(
            items: <Post>[],
            lastDocument: null,
            hasMore: false,
          );
        }

        query = query
            .where('audience', isEqualTo: PostAudience.serial.name)
            .where('serial', isEqualTo: serial);
      }

      query = _applyLoungeSort(query, sort);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final QuerySnapshot<JsonMap> snapshot = await query.limit(limit).get();
      return _buildPostPage(snapshot, currentUid: currentUid, limit: limit);
    } catch (e) {
      debugPrint('Error fetching lounge feed: $e');
      return const PaginatedQueryResult<Post>(
        items: <Post>[],
        hasMore: false,
        lastDocument: null,
      );
    }
  }

  Future<PaginatedQueryResult<Post>> fetchSerialFeed({
    required String serial,
    int limit = 20,
    QueryDocumentSnapshotJson? startAfter,
    String? currentUid,
  }) async {
    try {
      QueryJson query = _postsRef
          .where('type', isEqualTo: PostType.chirp.name)
          .where('audience', isEqualTo: PostAudience.serial.name)
          .where('serial', isEqualTo: serial)
          .where('visibility', isEqualTo: PostVisibility.public.name)
          .orderBy('createdAt', descending: true)
          .limit(limit);
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }
      final QuerySnapshot<JsonMap> snapshot = await query.get();
      return _buildPostPage(snapshot, currentUid: currentUid, limit: limit);
    } catch (e) {
      debugPrint('Error fetching serial feed: $e');
      return const PaginatedQueryResult<Post>(
        items: <Post>[],
        hasMore: false,
        lastDocument: null,
      );
    }
  }

  Query<JsonMap> _applyLoungeSort(Query<JsonMap> query, LoungeSort sort) {
    switch (sort) {
      case LoungeSort.latest:
        return query.orderBy('createdAt', descending: true);
      case LoungeSort.popular:
        final Timestamp since = _popularCutoffTimestamp();
        return query
            .where('createdAt', isGreaterThanOrEqualTo: since)
            .orderBy('createdAt', descending: true)
            .orderBy('hotScore', descending: true);
      case LoungeSort.likes:
        final Timestamp since = _popularCutoffTimestamp();
        return query
            .where('createdAt', isGreaterThanOrEqualTo: since)
            .orderBy('createdAt', descending: true)
            .orderBy('likeCount', descending: true);
    }
  }

  Timestamp _popularCutoffTimestamp() => Timestamp.fromDate(_popularCutoff());

  DateTime _popularCutoff() => DateTime.now().subtract(_loungeLookback);

  Future<PaginatedQueryResult<Post>> fetchHotFeed({
    int limit = 20,
    QueryDocumentSnapshotJson? startAfter,
    String? currentUid,
  }) async {
    try {
      QueryJson query = _postsRef
          .where('type', isEqualTo: PostType.chirp.name)
          .where('visibility', isEqualTo: PostVisibility.public.name)
          .orderBy('hotScore', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }
      final QuerySnapshot<JsonMap> snapshot = await query.get();
      return _buildPostPage(snapshot, currentUid: currentUid, limit: limit);
    } catch (e) {
      debugPrint('Error fetching hot feed: $e');
      return const PaginatedQueryResult<Post>(
        items: <Post>[],
        hasMore: false,
        lastDocument: null,
      );
    }
  }

  Future<PaginatedQueryResult<Post>> fetchBoardPosts({
    required String boardId,
    int limit = 20,
    QueryDocumentSnapshotJson? startAfter,
    String? currentUid,
  }) async {
    QueryJson query = _postsRef
        .where('type', isEqualTo: PostType.board.name)
        .where('boardId', isEqualTo: boardId)
        .where('visibility', isEqualTo: PostVisibility.public.name)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    final QuerySnapshot<JsonMap> snapshot = await query.get();
    return _buildPostPage(snapshot, currentUid: currentUid, limit: limit);
  }

  Future<PaginatedQueryResult<Post>> fetchPostsByAuthor({
    required String authorUid,
    int limit = 20,
    QueryDocumentSnapshotJson? startAfter,
    String? currentUid,
  }) async {
    try {
      QueryJson query = _postsRef
          .where('authorUid', isEqualTo: authorUid)
          .where('visibility', isEqualTo: PostVisibility.public.name)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final QuerySnapshot<JsonMap> snapshot = await query.get();
      return _buildPostPage(snapshot, currentUid: currentUid, limit: limit);
    } catch (_) {
      return const PaginatedQueryResult<Post>(
        items: <Post>[],
        hasMore: false,
        lastDocument: null,
      );
    }
  }

  Future<PaginatedQueryResult<Post>> fetchBookmarkedPosts({
    required String uid,
    int limit = 20,
    QueryDocumentSnapshotJson? startAfter,
  }) async {
    Query<JsonMap> bookmarkQuery = _bookmarksRef(
      uid,
    ).orderBy('createdAt', descending: true).limit(limit);
    if (startAfter != null) {
      bookmarkQuery = bookmarkQuery.startAfterDocument(startAfter);
    }

    final QuerySnapshot<JsonMap> bookmarkSnapshot = await bookmarkQuery.get();
    final List<String> postIds = bookmarkSnapshot.docs
        .map((QueryDocumentSnapshot<JsonMap> doc) => doc.id)
        .toList(growable: false);

    final bool hasMore = bookmarkSnapshot.docs.length == limit;
    final QueryDocumentSnapshot<JsonMap>? last = bookmarkSnapshot.docs.isEmpty
        ? null
        : bookmarkSnapshot.docs.last;

    if (postIds.isEmpty) {
      return PaginatedQueryResult<Post>(
        items: const <Post>[],
        hasMore: hasMore,
        lastDocument: last,
      );
    }

    final List<Post?> fetchedPosts = await Future.wait(
      postIds.map((String postId) => fetchPostById(postId, currentUid: uid)),
    );
    final List<Post> posts = fetchedPosts.whereType<Post>().toList(
      growable: false,
    );

    return PaginatedQueryResult<Post>(
      items: posts,
      hasMore: hasMore,
      lastDocument: last,
    );
  }

  Future<PaginatedQueryResult<Comment>> fetchComments({
    required String postId,
    int limit = 50,
    QueryDocumentSnapshot<JsonMap>? startAfter,
    String? currentUid,
  }) async {
    Query<JsonMap> query = _commentsRef(
      postId,
    ).orderBy('createdAt', descending: false).limit(limit);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final QuerySnapshot<JsonMap> snapshot = await query.get();
    final List<String> commentIds = snapshot.docs
        .map((QueryDocumentSnapshot<JsonMap> doc) => doc.id)
        .toList();

    final Set<String> likedCommentIds = currentUid == null
        ? const <String>{}
        : await _fetchLikedCommentIds(
            postId: postId,
            uid: currentUid,
            commentIds: commentIds,
          );

    final List<Comment> comments = snapshot.docs
        .map(
          (QueryDocumentSnapshot<JsonMap> doc) => Comment.fromSnapshot(
            doc,
            postId: postId,
            isLiked: likedCommentIds.contains(doc.id),
          ),
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

      final DocumentReference<JsonMap> postRef = _postDoc(postId);
      transaction.update(postRef, <String, Object?>{
        'commentCount': FieldValue.increment(1),
        'updatedAt': Timestamp.fromDate(now),
      });

      final DocumentReference<JsonMap> shardRef = _counterShardRef(postId);
      transaction.set(shardRef, <String, Object?>{
        'comments': FieldValue.increment(1),
      }, SetOptions(merge: true));
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

      try {
        await _dispatchCommentNotifications(
          postId: postId,
          commentText: text,
          commenterNickname: authorNickname,
        );
      } catch (error, stackTrace) {
        debugPrint(
          'Failed to dispatch comment notifications: $error\n$stackTrace',
        );
      }
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
      authorSupporterLevel: authorSupporterLevel,
      authorIsSupporter: authorIsSupporter,
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

      transaction.update(commentDoc, <String, Object?>{
        'deleted': true,
        'text': '[삭제된 댓글]',
      });

      final DocumentReference<JsonMap> postRef = _postDoc(postId);
      transaction.update(postRef, <String, Object?>{
        'commentCount': FieldValue.increment(-1),
        'updatedAt': Timestamp.now(),
      });
      final DocumentReference<JsonMap> shardRef = _counterShardRef(postId);
      transaction.set(shardRef, <String, Object?>{
        'comments': FieldValue.increment(-1),
      }, SetOptions(merge: true));
    });
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

      transaction.set(postDoc, <String, Object?>{
        'likeCount': FieldValue.increment(willLike ? 1 : -1),
        'updatedAt': Timestamp.now(),
      }, SetOptions(merge: true));

      transaction.set(shardDoc, <String, Object?>{
        'likes': FieldValue.increment(willLike ? 1 : -1),
      }, SetOptions(merge: true));

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
    final DocumentReference<JsonMap> likeDoc = commentLikes.doc(
      '${commentId}_$uid',
    );
    final DocumentReference<JsonMap> commentDoc = _commentsRef(
      postId,
    ).doc(commentId);
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

  Future<void> incrementViewCount(String postId) async {
    final DocumentReference<JsonMap> doc = _postDoc(postId);
    try {
      await doc.update(<String, Object?>{'viewCount': FieldValue.increment(1)});
    } on FirebaseException catch (error) {
      if (error.code == 'not-found') {
        return;
      }
      rethrow;
    }

    await _counterShardRef(postId).set(<String, Object?>{
      'views': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  Future<List<Board>> fetchBoards({bool includeHidden = false}) async {
    Query<JsonMap> query = _boardsRef.orderBy('order');
    if (!includeHidden) {
      query = query.where('visibility', isEqualTo: BoardVisibility.public.name);
    }
    final QuerySnapshot<JsonMap> snapshot = await query.get();
    return snapshot.docs.map(Board.fromSnapshot).toList(growable: false);
  }

  Stream<List<Board>> watchBoards({bool includeHidden = false}) {
    Query<JsonMap> query = _boardsRef.orderBy('order');
    if (!includeHidden) {
      query = query.where('visibility', isEqualTo: BoardVisibility.public.name);
    }
    return query.snapshots().map(
      (QuerySnapshot<JsonMap> snapshot) =>
          snapshot.docs.map(Board.fromSnapshot).toList(growable: false),
    );
  }

  Future<void> toggleBookmark({
    required String uid,
    required String postId,
  }) async {
    final DocumentReference<JsonMap> bookmarkDoc = _bookmarksRef(
      uid,
    ).doc(postId);
    final DocSnapshotJson snapshot = await bookmarkDoc.get();
    if (snapshot.exists) {
      await bookmarkDoc.delete();
    } else {
      await bookmarkDoc.set(<String, Object?>{
        'createdAt': Timestamp.now(),
        'postId': postId,
      });
    }
  }

  Future<Set<String>> fetchBookmarkedPostIds(String uid) async {
    final QuerySnapshot<JsonMap> snapshot = await _bookmarksRef(uid).get();
    return snapshot.docs
        .map((QueryDocumentSnapshot<JsonMap> doc) => doc.id)
        .toSet();
  }

  Future<Set<String>> _fetchBookmarkedIds({
    required String uid,
    required List<String> postIds,
  }) async {
    if (postIds.isEmpty) {
      return const <String>{};
    }

    final Set<String> bookmarked = <String>{};
    final Iterable<List<String>> chunks = _chunk(postIds, size: 10);
    for (final List<String> chunk in chunks) {
      final List<Future<DocumentSnapshot<JsonMap>>> futures = chunk
          .map((String postId) => _bookmarksRef(uid).doc(postId).get())
          .toList(growable: false);
      final List<DocumentSnapshot<JsonMap>> results = await Future.wait(
        futures,
      );
      for (int index = 0; index < results.length; index += 1) {
        if (results[index].exists) {
          bookmarked.add(chunk[index]);
        }
      }
    }

    return bookmarked;
  }

  Future<CommunitySearchResults> searchCommunity({
    required String query,
    required SearchScope scope,
    int postLimit = 20,
    int commentLimit = 20,
    String? currentUid,
  }) async {
    final String token = query.trim().toLowerCase();
    if (token.isEmpty) {
      return const CommunitySearchResults();
    }

    final bool includePosts = scope != SearchScope.comments;
    final bool authorOnly = scope == SearchScope.author;
    final bool includeComments =
        scope == SearchScope.comments || scope == SearchScope.all;

    List<Post> posts = const <Post>[];
    List<CommentSearchResult> comments = const <CommentSearchResult>[];

    if (includePosts && postLimit > 0) {
      posts = await _searchPosts(
        token: token,
        limit: postLimit,
        currentUid: currentUid,
        authorOnly: authorOnly,
      );
    }

    if (includeComments && commentLimit > 0) {
      comments = await _searchComments(
        token: token,
        limit: commentLimit,
        currentUid: currentUid,
      );
    }

    _recordSearchToken(token);

    return CommunitySearchResults(posts: posts, comments: comments);
  }

  Future<List<SearchSuggestion>> topSearchSuggestions({int limit = 10}) async {
    final QuerySnapshot<JsonMap> snapshot = await _searchSuggestionRef
        .orderBy('count', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs
        .map(SearchSuggestion.fromSnapshot)
        .toList(growable: false);
  }

  Future<AppResult<List<String>>> autocompleteSearchTokens({
    required String prefix,
    int limit = 10,
  }) async {
    try {
      if (prefix.isEmpty) return AppResultHelpers.success([]);

      final String endPrefix = prefix.substring(0, prefix.length - 1) +
          String.fromCharCode(prefix.codeUnitAt(prefix.length - 1) + 1);

      final QuerySnapshot<JsonMap> snapshot = await _searchSuggestionRef
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: prefix)
          .where(FieldPath.documentId, isLessThan: endPrefix)
          .orderBy(FieldPath.documentId)
          .limit(limit)
          .get();

      final tokens = snapshot.docs.map((doc) => doc.id).toList(growable: false);
      return AppResultHelpers.success(tokens);
    } catch (e) {
      return AppResultHelpers.failure(UnknownError('검색어 자동완성 중 오류가 발생했습니다: $e'));
    }
  }

  Future<void> submitReport({
    required ReportTargetType targetType,
    required String targetId,
    required String reason,
    required String reporterUid,
    Map<String, Object?> metadata = const <String, Object?>{},
  }) async {
    await _reportsRef.add(
      ContentReport(
        id: '',
        targetType: targetType,
        targetId: targetId,
        reason: reason,
        reporterUid: reporterUid,
        createdAt: DateTime.now(),
        metadata: metadata,
      ).toMap(),
    );
  }

  Future<List<Post>> _searchPosts({
    required String token,
    int limit = 20,
    String? currentUid,
    bool authorOnly = false,
  }) async {
    Query<JsonMap> query = _postsRef
        .where('keywords', arrayContains: token)
        .where('visibility', isEqualTo: PostVisibility.public.name)
        .orderBy('hotScore', descending: true)
        .limit(limit);

    final QuerySnapshot<JsonMap> snapshot = await query.get();
    PaginatedQueryResult<Post> page = await _buildPostPage(
      snapshot,
      currentUid: currentUid,
      limit: limit,
    );

    if (authorOnly) {
      final List<Post> filtered = page.items
          .where(
            (Post post) => post.authorNickname.toLowerCase().contains(token),
          )
          .toList(growable: false);
      page = PaginatedQueryResult<Post>(
        items: filtered,
        hasMore: false,
        lastDocument: null,
      );
    }

    return page.items;
  }

  Future<List<CommentSearchResult>> _searchComments({
    required String token,
    int limit = 20,
    String? currentUid,
  }) async {
    final QuerySnapshot<JsonMap> snapshot = await _firestore
        .collectionGroup('comments')
        .where('deleted', isEqualTo: false)
        .where('keywords', arrayContains: token)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    if (snapshot.docs.isEmpty) {
      return const <CommentSearchResult>[];
    }

    final Map<String, List<String>> commentIdsByPost = <String, List<String>>{};
    final List<Comment> comments = snapshot.docs
        .map((doc) {
          final String postId = doc.reference.parent.parent?.id ?? '';
          commentIdsByPost.putIfAbsent(postId, () => <String>[]).add(doc.id);
          return Comment.fromMap(id: doc.id, postId: postId, data: doc.data());
        })
        .toList(growable: false);

    final Map<String, Set<String>> likedCommentIds = <String, Set<String>>{};
    if (currentUid != null) {
      for (final MapEntry<String, List<String>> entry
          in commentIdsByPost.entries) {
        final Set<String> liked = await _fetchLikedCommentIds(
          postId: entry.key,
          uid: currentUid,
          commentIds: entry.value,
        );
        likedCommentIds[entry.key] = liked;
      }
    }

    final Map<String, Post> parentPosts = await _fetchPostsByIds(
      commentIdsByPost.keys,
      currentUid: currentUid,
    );

    return comments
        .map((Comment comment) {
          final Set<String> likedIds =
              likedCommentIds[comment.postId] ?? const <String>{};
          final Comment resolved = comment.copyWith(
            isLiked: likedIds.contains(comment.id),
          );
          return CommentSearchResult(
            comment: resolved,
            post: parentPosts[comment.postId],
          );
        })
        .toList(growable: false);
  }

  Future<Map<String, Post>> _fetchPostsByIds(
    Iterable<String> ids, {
    String? currentUid,
  }) async {
    final List<String> postIds = ids
        .where((String id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (postIds.isEmpty) {
      return const <String, Post>{};
    }

    final List<DocumentSnapshot<JsonMap>> snapshots = await Future.wait(
      postIds.map((String postId) => _postDoc(postId).get()),
    );

    final List<Post> posts = <Post>[];
    for (final DocumentSnapshot<JsonMap> snapshot in snapshots) {
      if (!snapshot.exists) {
        continue;
      }
      final Map<String, Object?>? data = snapshot.data();
      if (data == null) {
        continue;
      }
      if (data['visibility'] != PostVisibility.public.name) {
        continue;
      }
      posts.add(Post.fromSnapshot(snapshot));
    }

    if (posts.isEmpty) {
      return const <String, Post>{};
    }

    Set<String> likedIds = const <String>{};
    Set<String> bookmarkedIds = const <String>{};
    if (currentUid != null) {
      final List<String> idsList = posts
          .map((Post post) => post.id)
          .toList(growable: false);
      likedIds = await _fetchLikedPostIds(uid: currentUid, postIds: idsList);
      bookmarkedIds = await _fetchBookmarkedIds(
        uid: currentUid,
        postIds: idsList,
      );
    }

    final List<Post> enriched = await _attachTopComments(posts);

    return <String, Post>{
      for (final Post post in enriched)
        post.id: post.copyWith(
          isLiked: likedIds.contains(post.id),
          isBookmarked: bookmarkedIds.contains(post.id),
        ),
    };
  }

  void _recordSearchToken(String token) {
    unawaited(
      _searchSuggestionRef.doc(token).set(<String, Object?>{
        'count': FieldValue.increment(1),
        'updatedAt': Timestamp.now(),
      }, SetOptions(merge: true)),
    );
  }

  Future<PostMedia> uploadPostImage({
    required String uid,
    required String postId,
    required String fileName,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
    Uint8List? thumbnailBytes,
    String? thumbnailContentType,
    int? width,
    int? height,
  }) async {
    final Reference fileRef = _storage.ref(
      'post_images/$uid/$postId/$fileName',
    );
    await fileRef.putData(bytes, SettableMetadata(contentType: contentType));
    final String url = await fileRef.getDownloadURL();

    String? thumbnailUrl;
    if (thumbnailBytes != null) {
      final Reference thumbRef = _storage.ref(
        'post_images/$uid/$postId/thumb_$fileName',
      );
      await thumbRef.putData(
        thumbnailBytes,
        SettableMetadata(contentType: thumbnailContentType ?? contentType),
      );
      thumbnailUrl = await thumbRef.getDownloadURL();
    }

    return PostMedia(
      path: fileRef.fullPath,
      url: url,
      thumbnailUrl: thumbnailUrl,
      width: width,
      height: height,
    );
  }

  Future<void> hidePost({required String postId}) async {
    await _postDoc(postId).update(<String, Object?>{
      'visibility': PostVisibility.hidden.name,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> restorePost({required String postId}) async {
    await _postDoc(postId).update(<String, Object?>{
      'visibility': PostVisibility.public.name,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> batchHidePosts(List<String> postIds) async {
    final WriteBatch batch = _firestore.batch();
    for (final String postId in postIds) {
      batch.update(_postDoc(postId), <String, Object?>{
        'visibility': PostVisibility.hidden.name,
        'updatedAt': Timestamp.now(),
      });
    }
    await batch.commit();
  }

  Future<Post?> getPost(String postId) async {
    return fetchPostById(postId, currentUid: currentUserId);
  }

  Future<List<Comment>> getComments(String postId) async {
    final QuerySnapshot<JsonMap> snapshot = await _commentsRef(
      postId,
    ).orderBy('createdAt', descending: false).get();

    final List<String> commentIds = snapshot.docs
        .map((QueryDocumentSnapshot<JsonMap> doc) => doc.id)
        .toList();

    final Set<String> likedIds = await _fetchLikedCommentIds(
      postId: postId,
      uid: currentUserId,
      commentIds: commentIds,
    );

    return snapshot.docs
        .map(
          (QueryDocumentSnapshot<JsonMap> doc) =>
              Comment.fromSnapshot(doc, isLiked: likedIds.contains(doc.id)),
        )
        .toList();
  }

  Future<List<Comment>> getTopComments(String postId, {int limit = 3}) async {
    final QuerySnapshot<JsonMap> snapshot = await _commentsRef(postId)
        .where('deleted', isEqualTo: false)
        .orderBy('likeCount', descending: true)
        .limit(limit)
        .get();

    final List<String> commentIds = snapshot.docs
        .map((QueryDocumentSnapshot<JsonMap> doc) => doc.id)
        .toList();

    final Set<String> likedIds = await _fetchLikedCommentIds(
      postId: postId,
      uid: currentUserId,
      commentIds: commentIds,
    );

    return snapshot.docs
        .map(
          (QueryDocumentSnapshot<JsonMap> doc) =>
              Comment.fromSnapshot(doc, isLiked: likedIds.contains(doc.id)),
        )
        .toList(growable: false);
  }

  Future<void> toggleLike(String postId) async {
    await togglePostLike(postId: postId, uid: currentUserId);
  }

  Future<void> togglePostBookmark(String postId) async {
    final DocumentReference<JsonMap> bookmarkDoc = _bookmarksRef(
      currentUserId,
    ).doc(postId);

    await _firestore.runTransaction((transaction) async {
      final DocumentSnapshot<JsonMap> snapshot = await transaction.get(
        bookmarkDoc,
      );

      if (snapshot.exists) {
        transaction.delete(bookmarkDoc);
      } else {
        transaction.set(bookmarkDoc, {
          'postId': postId,
          'createdAt': Timestamp.now(),
        });
      }
    });
  }

  Future<void> addComment(
    String postId,
    String text, {
    String? parentCommentId,
    List<String>? imageUrls,
  }) async {
    final nickname = await currentUserNickname;
    final CareerTrack track = _userSession.careerTrack;
    final int supporterLevel = _userSession.supporterLevel;
    final bool serialVisible = _userSession.serialVisible;
    await createComment(
      postId: postId,
      authorUid: currentUserId,
      authorNickname: nickname,
      text: text,
      parentCommentId: parentCommentId,
      authorTrack: track,
      authorSerialVisible: serialVisible,
      authorSupporterLevel: supporterLevel,
      authorIsSupporter: supporterLevel > 0,
      imageUrls: imageUrls,
    );
  }

  Future<void> toggleCommentLikeById(String postId, String commentId) async {
    final String likeId = '${commentId}_$currentUserId';
    final DocumentReference<JsonMap> likeDoc = _commentLikesRef(
      postId,
    ).doc(likeId);
    final DocumentReference<JsonMap> commentDoc = _commentsRef(
      postId,
    ).doc(commentId);
    String? commentAuthorUid;
    final bool liked = await _firestore.runTransaction<bool>((
      transaction,
    ) async {
      final DocumentSnapshot<JsonMap> likeSnapshot = await transaction.get(
        likeDoc,
      );
      final DocumentSnapshot<JsonMap> commentSnapshot = await transaction.get(
        commentDoc,
      );

      if (!commentSnapshot.exists) {
        throw StateError('댓글을 찾을 수 없습니다.');
      }

      final Map<String, Object?> commentData = commentSnapshot.data()!;
      commentAuthorUid = (commentData['authorUid'] as String?) ?? '';
      final int currentLikes = (commentData['likeCount'] as num?)?.toInt() ?? 0;

      if (likeSnapshot.exists) {
        // Unlike
        transaction.delete(likeDoc);
        transaction.update(commentDoc, {
          'likeCount': currentLikes - 1,
          'updatedAt': Timestamp.now(),
        });
        return false;
      } else {
        // Like
        transaction.set(likeDoc, {
          'commentId': commentId,
          'uid': currentUserId,
          'createdAt': Timestamp.now(),
        });
        transaction.update(commentDoc, {
          'likeCount': currentLikes + 1,
          'updatedAt': Timestamp.now(),
        });
        return true;
      }
    });

    if (liked &&
        commentAuthorUid != null &&
        commentAuthorUid!.isNotEmpty &&
        commentAuthorUid != currentUserId) {
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
  }

  Future<void> deletePostById(String postId) async {
    await deletePost(postId: postId, authorUid: currentUserId);
  }

  Future<void> reportPost(String postId, String reason) async {
    await submitReport(
      targetType: ReportTargetType.post,
      targetId: postId,
      reason: reason,
      reporterUid: currentUserId,
    );
  }

  Future<void> blockUser(String userId) async {
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('blocked_users')
        .doc(userId)
        .set({'blockedAt': Timestamp.now()});
  }

  Future<PaginatedQueryResult<Post>> _buildPostPage(
    QuerySnapshot<JsonMap> snapshot, {
    String? currentUid,
    required int limit,
  }) async {
    final List<QueryDocumentSnapshot<JsonMap>> docs = snapshot.docs;
    Set<String> likedIds = const <String>{};
    Set<String> bookmarkedIds = const <String>{};

    if (currentUid != null && docs.isNotEmpty) {
      final List<String> postIds = docs
          .map((QueryDocumentSnapshot<JsonMap> doc) => doc.id)
          .toList(growable: false);
      likedIds = await _fetchLikedPostIds(uid: currentUid, postIds: postIds);
      bookmarkedIds = await _fetchBookmarkedIds(
        uid: currentUid,
        postIds: postIds,
      );
    }

    List<Post> posts = docs
        .map(
          (QueryDocumentSnapshot<JsonMap> doc) => Post.fromSnapshot(
            doc,
            isLiked: likedIds.contains(doc.id),
            isBookmarked: bookmarkedIds.contains(doc.id),
          ),
        )
        .toList(growable: false);

    posts = await _attachTopComments(posts);

    final bool hasMore = docs.length == limit;
    final QueryDocumentSnapshot<JsonMap>? last = docs.isEmpty
        ? null
        : docs.last;
    return PaginatedQueryResult<Post>(
      items: posts,
      hasMore: hasMore,
      lastDocument: last,
    );
  }

  Future<Set<String>> _fetchLikedPostIds({
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

  Future<Set<String>> _fetchLikedCommentIds({
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
      final QuerySnapshot<JsonMap> snapshot = await _commentLikesRef(
        postId,
      ).where('uid', isEqualTo: uid).where('commentId', whereIn: chunk).get();
      likedIds.addAll(
        snapshot.docs.map(
          (QueryDocumentSnapshot<JsonMap> doc) => doc['commentId'] as String,
        ),
      );
    }
    return likedIds;
  }

  DocumentReference<JsonMap> _counterShardRef(String postId) {
    final int shardIndex = _random.nextInt(_counterShardCount);
    return _postCounterShard(postId).doc('shard_$shardIndex');
  }

  Iterable<List<T>> _chunk<T>(List<T> items, {int size = 10}) sync* {
    for (int i = 0; i < items.length; i += size) {
      yield items.sublist(i, i + size > items.length ? items.length : i + size);
    }
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

  Future<CachedComment?> _loadTopComment(String postId) async {
    try {
      final QuerySnapshot<JsonMap> snapshot = await _firestore
          .collection(Fs.posts)
          .doc(postId)
          .collection(Fs.comments)
          .orderBy('likeCount', descending: true)
          .limit(1)
          .get();

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
        authorSupporterLevel: (data['authorSupporterLevel'] as num?)?.toInt() ?? 0,
        authorIsSupporter: data['authorIsSupporter'] as bool? ?? false,
      );
    } catch (e) {
      debugPrint('Error loading top comment: $e');
      return null;
    }
  }

  Future<void> _dispatchCommentNotifications({
    required String postId,
    required String commentText,
    required String commenterNickname,
  }) async {
    try {
      // Get the post to find the author
      final postDoc = await _postsRef.doc(postId).get();
      if (!postDoc.exists) return;

      final postData = postDoc.data();
      if (postData == null) return;

      final authorUid = postData['authorUid'] as String?;
      if (authorUid == null || authorUid == _userSession.userId) return;

      // Create excerpt from comment text
      final excerpt = commentText.length > 50
          ? '${commentText.substring(0, 50)}...'
          : commentText;

      // Dispatch notification to post author using existing notification method
      await _notificationRepository.notifyBookmarkedPostComment(
        targetUid: authorUid,
        postId: postId,
        commenterNickname: commenterNickname,
        excerpt: excerpt,
      );
    } catch (e) {
      debugPrint('Error dispatching comment notifications: $e');
    }
  }

  Future<List<Post>> _attachTopComments(List<Post> posts) async {
    final List<Post> enriched = <Post>[];

    for (final Post post in posts) {
      try {
        final CachedComment? topComment = await _loadTopComment(post.id);
        enriched.add(post.copyWith(topComment: topComment));
      } catch (e) {
        debugPrint('Error attaching top comment to post ${post.id}: $e');
        enriched.add(post);
      }
    }

    return enriched;
  }
}
