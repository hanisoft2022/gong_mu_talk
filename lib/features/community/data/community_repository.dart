import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../core/firebase/paginated_query.dart';
import '../../../core/utils/hot_score.dart';
import '../../../core/utils/prefix_tokenizer.dart';
import '../../profile/domain/career_track.dart';
import '../domain/models/board.dart';
import '../domain/models/comment.dart';
import '../domain/models/post.dart';
import '../domain/models/report.dart';
import '../domain/models/search_suggestion.dart';

typedef JsonMap = Map<String, Object?>;

typedef QueryJson = Query<JsonMap>;

typedef DocSnapshotJson = DocumentSnapshot<JsonMap>;

class CommunityRepository {
  CommunityRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final PrefixTokenizer _tokenizer = const PrefixTokenizer();
  final HotScoreCalculator _hotScoreCalculator = const HotScoreCalculator();
  static const int _counterShardCount = 20;

  CollectionReference<JsonMap> get _postsRef => _firestore.collection('posts');

  CollectionReference<JsonMap> get _likesRef => _firestore.collection('likes');

  CollectionReference<JsonMap> get _boardsRef => _firestore.collection('boards');

  CollectionReference<JsonMap> get _searchSuggestionRef =>
      _firestore.collection('search_suggestions');

  CollectionReference<JsonMap> get _reportsRef => _firestore.collection('reports');

  DocumentReference<JsonMap> _postDoc(String postId) => _postsRef.doc(postId);

  CollectionReference<JsonMap> _commentsRef(String postId) =>
      _postDoc(postId).collection('comments');

  CollectionReference<JsonMap> _commentLikesRef(String postId) =>
      _postDoc(postId).collection('comment_likes');

  CollectionReference<JsonMap> _postCounterShard(String postId) => _firestore
      .collection('post_counters')
      .doc(postId)
      .collection('shards');

  CollectionReference<JsonMap> _bookmarksRef(String uid) =>
      _userDoc(uid).collection('bookmarks');

  DocumentReference<JsonMap> _userDoc(String uid) =>
      _firestore.collection('users').doc(uid);

  Future<Post> createPost({
    required PostType type,
    required String authorUid,
    required String authorNickname,
    required CareerTrack authorTrack,
    required String text,
    required PostAudience audience,
    required String serial,
    List<PostMedia> media = const <PostMedia>[],
    List<String> tags = const <String>[],
    String? boardId,
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
      'text': text,
      'media': media.map((PostMedia media) => media.toMap()).toList(growable: false),
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
        updates['media'] = media.map((PostMedia m) => m.toMap()).toList(growable: false);
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

  Future<void> deletePost({required String postId, required String authorUid}) async {
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
      final DocumentSnapshot<JsonMap> likeSnapshot =
          await _likesRef.doc('${postId}_$currentUid').get();
      liked = likeSnapshot.exists;
      final DocumentSnapshot<JsonMap> bookmarkSnapshot =
          await _bookmarksRef(currentUid).doc(postId).get();
      bookmarked = bookmarkSnapshot.exists;
    }

    return Post.fromSnapshot(snapshot, isLiked: liked, isBookmarked: bookmarked);
  }

  Future<PaginatedQueryResult<Post>> fetchChirpFeed({
    int limit = 20,
    QueryDocumentSnapshotJson? startAfter,
    String? currentUid,
  }) async {
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
  }

  Future<PaginatedQueryResult<Post>> fetchSerialFeed({
    required String serial,
    int limit = 20,
    QueryDocumentSnapshotJson? startAfter,
    String? currentUid,
  }) async {
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
  }

  Future<PaginatedQueryResult<Post>> fetchHotFeed({
    int limit = 20,
    QueryDocumentSnapshotJson? startAfter,
    String? currentUid,
  }) async {
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

  Future<PaginatedQueryResult<Post>> fetchBookmarkedPosts({
    required String uid,
    int limit = 20,
    QueryDocumentSnapshotJson? startAfter,
  }) async {
    Query<JsonMap> bookmarkQuery = _bookmarksRef(uid)
        .orderBy('createdAt', descending: true)
        .limit(limit);
    if (startAfter != null) {
      bookmarkQuery = bookmarkQuery.startAfterDocument(startAfter);
    }

    final QuerySnapshot<JsonMap> bookmarkSnapshot = await bookmarkQuery.get();
    final List<String> postIds = bookmarkSnapshot.docs
        .map((QueryDocumentSnapshot<JsonMap> doc) => doc.id)
        .toList(growable: false);

    final List<Post> posts = <Post>[];
    for (final String postId in postIds) {
      final Post? post = await fetchPostById(postId, currentUid: uid);
      if (post != null) {
        posts.add(post);
      }
    }

    final bool hasMore = bookmarkSnapshot.docs.length == limit;
    final QueryDocumentSnapshot<JsonMap>? last = bookmarkSnapshot.docs.isEmpty
        ? null
        : bookmarkSnapshot.docs.last;

    return PaginatedQueryResult<Post>(items: posts, hasMore: hasMore, lastDocument: last);
  }

  Future<PaginatedQueryResult<Comment>> fetchComments({
    required String postId,
    int limit = 50,
    QueryDocumentSnapshot<JsonMap>? startAfter,
    String? currentUid,
  }) async {
    Query<JsonMap> query = _commentsRef(postId)
        .orderBy('createdAt', descending: false)
        .limit(limit);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final QuerySnapshot<JsonMap> snapshot = await query.get();
    final Set<String> likedCommentIds = currentUid == null
        ? const <String>{}
        : await _fetchLikedCommentIds(postId: postId, uid: currentUid, commentIds: snapshot.docs.map((doc) => doc.id).toList(growable: false));

    final List<Comment> comments = snapshot.docs
        .map(
          (QueryDocumentSnapshot<JsonMap> doc) =>
              Comment.fromSnapshot(doc, postId: postId, isLiked: likedCommentIds.contains(doc.id)),
        )
        .toList(growable: false);

    final bool hasMore = snapshot.docs.length == limit;
    final QueryDocumentSnapshot<JsonMap>? last = snapshot.docs.isEmpty ? null : snapshot.docs.last;
    return PaginatedQueryResult<Comment>(items: comments, lastDocument: last, hasMore: hasMore);
  }

  Future<Comment> createComment({
    required String postId,
    required String authorUid,
    required String authorNickname,
    required String text,
    String? parentCommentId,
  }) async {
    final CollectionReference<JsonMap> comments = _commentsRef(postId);
    final DocumentReference<JsonMap> commentDoc = comments.doc();
    final DateTime now = DateTime.now();

    await _firestore.runTransaction<void>((Transaction transaction) async {
      transaction.set(commentDoc, <String, Object?>{
        'authorUid': authorUid,
        'authorNickname': authorNickname,
        'text': text,
        'likeCount': 0,
        'createdAt': Timestamp.fromDate(now),
        'parentCommentId': parentCommentId,
        'deleted': false,
      });

      final DocumentReference<JsonMap> postRef = _postDoc(postId);
      transaction.update(postRef, <String, Object?>{
        'commentCount': FieldValue.increment(1),
        'updatedAt': Timestamp.fromDate(now),
      });

      final DocumentReference<JsonMap> shardRef = _counterShardRef(postId);
      transaction.set(
        shardRef,
        <String, Object?>{'comments': FieldValue.increment(1)},
        SetOptions(merge: true),
      );
    });

    return Comment(
      id: commentDoc.id,
      postId: postId,
      authorUid: authorUid,
      authorNickname: authorNickname,
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
    final DocumentReference<JsonMap> commentDoc = _commentsRef(postId).doc(commentId);
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
      transaction.set(
        shardRef,
        <String, Object?>{'comments': FieldValue.increment(-1)},
        SetOptions(merge: true),
      );
    });
  }

  Future<bool> togglePostLike({required String postId, required String uid}) async {
    final DocumentReference<JsonMap> likeDoc = _likesRef.doc('${postId}_$uid');
    final DocumentReference<JsonMap> postDoc = _postDoc(postId);
    final DocumentReference<JsonMap> shardDoc = _counterShardRef(postId);

    return _firestore.runTransaction<bool>((Transaction transaction) async {
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
        <String, Object?>{'likes': FieldValue.increment(willLike ? 1 : -1)},
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
  }

  Future<bool> toggleCommentLike({
    required String postId,
    required String commentId,
    required String uid,
  }) async {
    final CollectionReference<JsonMap> commentLikes = _commentLikesRef(postId);
    final DocumentReference<JsonMap> likeDoc = commentLikes.doc('${commentId}_$uid');
    final DocumentReference<JsonMap> commentDoc = _commentsRef(postId).doc(commentId);
    return _firestore.runTransaction<bool>((Transaction transaction) async {
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
  }

  Future<void> incrementViewCount(String postId) async {
    await _postDoc(postId).update(<String, Object?>{
      'viewCount': FieldValue.increment(1),
    });
    await _counterShardRef(postId).set(
      <String, Object?>{'views': FieldValue.increment(1)},
      SetOptions(merge: true),
    );
  }

  Future<Board?> fetchBoardById(String boardId, {bool includeHidden = false}) async {
    final DocumentSnapshot<JsonMap> snapshot = await _boardsRef.doc(boardId).get();
    if (!snapshot.exists) {
      return null;
    }
    final Board board = Board.fromSnapshot(snapshot);
    if (!includeHidden && board.visibility != BoardVisibility.public) {
      return null;
    }
    return board;
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

  Future<void> toggleBookmark({required String uid, required String postId}) async {
    final DocumentReference<JsonMap> bookmarkDoc = _bookmarksRef(uid).doc(postId);
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
    return snapshot.docs.map((QueryDocumentSnapshot<JsonMap> doc) => doc.id).toSet();
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
      final List<DocumentSnapshot<JsonMap>> results = await Future.wait(futures);
      for (int index = 0; index < results.length; index += 1) {
        if (results[index].exists) {
          bookmarked.add(chunk[index]);
        }
      }
    }

    return bookmarked;
  }

  Future<List<Post>> searchPosts({
    required String prefix,
    int limit = 20,
    String? currentUid,
  }) async {
    final String token = prefix.trim().toLowerCase();
    if (token.isEmpty) {
      return const <Post>[];
    }

    Query<JsonMap> query = _postsRef
        .where('keywords', arrayContains: token)
        .where('visibility', isEqualTo: PostVisibility.public.name)
        .orderBy('hotScore', descending: true)
        .limit(limit);

    final QuerySnapshot<JsonMap> snapshot = await query.get();
    final PaginatedQueryResult<Post> page =
        await _buildPostPage(snapshot, currentUid: currentUid, limit: limit);

    unawaited(_searchSuggestionRef.doc(token).set(<String, Object?>{
      'count': FieldValue.increment(1),
      'updatedAt': Timestamp.now(),
    }, SetOptions(merge: true)));

    return page.items;
  }

  Future<List<String>> fetchAutocompleteTokens({
    required String prefix,
    int limit = 10,
  }) async {
    final String token = prefix.trim().toLowerCase();
    if (token.isEmpty) {
      return const <String>[];
    }

    Query<JsonMap> query = _searchSuggestionRef
        .orderBy(FieldPath.documentId)
        .startAt(<String>[token])
        .endAt(<String>['$token\uf8ff'])
        .limit(limit);

    final QuerySnapshot<JsonMap> snapshot = await query.get();
    return snapshot.docs.map((QueryDocumentSnapshot<JsonMap> doc) => doc.id).toList(growable: false);
  }

  Future<List<SearchSuggestion>> topSearchSuggestions({int limit = 10}) async {
    final QuerySnapshot<JsonMap> snapshot = await _searchSuggestionRef
        .orderBy('count', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs.map(SearchSuggestion.fromSnapshot).toList(growable: false);
  }

  Future<void> submitReport({
    required ReportTargetType targetType,
    required String targetId,
    required String reason,
    required String reporterUid,
    Map<String, Object?> metadata = const <String, Object?>{},
  }) async {
    await _reportsRef.add(ContentReport(
      id: '',
      targetType: targetType,
      targetId: targetId,
      reason: reason,
      reporterUid: reporterUid,
      createdAt: DateTime.now(),
      metadata: metadata,
    ).toMap());
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
    final Reference fileRef =
        _storage.ref('post_images/$uid/$postId/$fileName');
    await fileRef.putData(bytes, SettableMetadata(contentType: contentType));
    final String url = await fileRef.getDownloadURL();

    String? thumbnailUrl;
    if (thumbnailBytes != null) {
      final Reference thumbRef = _storage.ref('post_images/$uid/$postId/thumb_$fileName');
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

  Future<PaginatedQueryResult<Post>> _buildPostPage(
    QuerySnapshot<JsonMap> snapshot, {
    String? currentUid,
    required int limit,
  }) async {
    final List<QueryDocumentSnapshot<JsonMap>> docs = snapshot.docs;
    Set<String> likedIds = const <String>{};
    Set<String> bookmarkedIds = const <String>{};

    if (currentUid != null && docs.isNotEmpty) {
      final List<String> postIds =
          docs.map((QueryDocumentSnapshot<JsonMap> doc) => doc.id).toList(growable: false);
      likedIds = await _fetchLikedPostIds(uid: currentUid, postIds: postIds);
      bookmarkedIds = await _fetchBookmarkedIds(uid: currentUid, postIds: postIds);
    }

    final List<Post> posts = docs
        .map(
          (QueryDocumentSnapshot<JsonMap> doc) => Post.fromSnapshot(
            doc,
            isLiked: likedIds.contains(doc.id),
            isBookmarked: bookmarkedIds.contains(doc.id),
          ),
        )
        .toList(growable: false);

    final bool hasMore = docs.length == limit;
    final QueryDocumentSnapshot<JsonMap>? last = docs.isEmpty ? null : docs.last;
    return PaginatedQueryResult<Post>(items: posts, hasMore: hasMore, lastDocument: last);
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
      likedIds.addAll(snapshot.docs.map((QueryDocumentSnapshot<JsonMap> doc) => doc['postId'] as String));
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
      final QuerySnapshot<JsonMap> snapshot = await _commentLikesRef(postId)
          .where('uid', isEqualTo: uid)
          .where('commentId', whereIn: chunk)
          .get();
      likedIds.addAll(snapshot.docs.map((QueryDocumentSnapshot<JsonMap> doc) => doc['commentId'] as String));
    }
    return likedIds;
  }

  DocumentReference<JsonMap> _counterShardRef(String postId) {
    final Random random = Random();
    final int shardIndex = random.nextInt(_counterShardCount);
    return _postCounterShard(postId).doc('shard_$shardIndex');
  }

  Iterable<List<T>> _chunk<T>(List<T> items, {int size = 10}) sync* {
    for (int i = 0; i < items.length; i += size) {
      yield items.sublist(i, i + size > items.length ? items.length : i + size);
    }
  }
}
