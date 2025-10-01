import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/firebase/paginated_query.dart';
import '../../../../core/utils/hot_score.dart';
import '../../../../core/utils/prefix_tokenizer.dart';
import '../../../../core/constants/engagement_points.dart';
import '../../../../core/firebase/firestore_refs.dart';
import '../../../profile/domain/career_track.dart';
import '../../../profile/data/user_profile_repository.dart';
import '../../domain/models/post.dart';

typedef JsonMap = Map<String, Object?>;
typedef QueryJson = Query<JsonMap>;
typedef DocSnapshotJson = DocumentSnapshot<JsonMap>;

/// Post Repository - Manages post CRUD operations and counters
///
/// Responsibilities:
/// - Create, read, update, delete posts
/// - Fetch various post feeds (chirp, hot, board, author)
/// - Handle post view counts and hot scores
/// - Upload and manage post media
/// - Post visibility (hide/restore)
///
/// Dependencies: UserProfileRepository, FirebaseFirestore, FirebaseStorage
class PostRepository {
  PostRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    required UserProfileRepository userProfileRepository,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _userProfileRepository = userProfileRepository;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final UserProfileRepository _userProfileRepository;
  final Random _random = Random();
  final PrefixTokenizer _tokenizer = const PrefixTokenizer();
  final HotScoreCalculator _hotScoreCalculator = const HotScoreCalculator();
  static const int _counterShardCount = 20;

  CollectionReference<JsonMap> get _postsRef => _firestore.collection(Fs.posts);

  DocumentReference<JsonMap> _postDoc(String postId) => _postsRef.doc(postId);

  CollectionReference<JsonMap> _postCounterShard(String postId) =>
      _firestore.collection(Fs.postCounters).doc(postId).collection(Fs.shards);

  DocumentReference<JsonMap> _counterShardRef(String postId) {
    final int shardIndex = _random.nextInt(_counterShardCount);
    return _postCounterShard(postId).doc('shard_$shardIndex');
  }

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

  Future<Post?> fetchPostById(String postId) async {
    final DocSnapshotJson snapshot = await _postDoc(postId).get();
    if (!snapshot.exists) {
      return null;
    }
    return Post.fromSnapshot(snapshot);
  }

  Future<PaginatedQueryResult<Post>> fetchChirpFeed({
    int limit = 20,
    QueryDocumentSnapshotJson? startAfter,
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
      return _buildPostPage(snapshot, limit: limit);
    } catch (e) {
      debugPrint('Error fetching chirp feed: $e');
      return const PaginatedQueryResult<Post>(
        items: <Post>[],
        hasMore: false,
        lastDocument: null,
      );
    }
  }

  Future<PaginatedQueryResult<Post>> fetchHotFeed({
    int limit = 20,
    QueryDocumentSnapshotJson? startAfter,
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
      return _buildPostPage(snapshot, limit: limit);
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
    return _buildPostPage(snapshot, limit: limit);
  }

  Future<PaginatedQueryResult<Post>> fetchPostsByAuthor({
    required String authorUid,
    int limit = 20,
    QueryDocumentSnapshotJson? startAfter,
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
      return _buildPostPage(snapshot, limit: limit);
    } catch (_) {
      return const PaginatedQueryResult<Post>(
        items: <Post>[],
        hasMore: false,
        lastDocument: null,
      );
    }
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

  Future<Map<String, Post>> fetchPostsByIds(
    Iterable<String> ids,
  ) async {
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

    return <String, Post>{
      for (final Post post in posts) post.id: post,
    };
  }

  PaginatedQueryResult<Post> _buildPostPage(
    QuerySnapshot<JsonMap> snapshot, {
    required int limit,
  }) {
    final List<QueryDocumentSnapshot<JsonMap>> docs = snapshot.docs;

    final List<Post> posts = docs
        .map((QueryDocumentSnapshot<JsonMap> doc) => Post.fromSnapshot(doc))
        .toList(growable: false);

    final bool hasMore = docs.length == limit;
    final QueryDocumentSnapshot<JsonMap>? last = docs.isEmpty ? null : docs.last;
    return PaginatedQueryResult<Post>(
      items: posts,
      hasMore: hasMore,
      lastDocument: last,
    );
  }
}
