import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../../../core/firebase/paginated_query.dart';
import '../../../core/utils/hot_score.dart';
import '../../../core/utils/prefix_tokenizer.dart';
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
import '../../auth/presentation/cubit/auth_cubit.dart';
import '../../profile/data/user_profile_repository.dart';

typedef JsonMap = Map<String, Object?>;

typedef QueryJson = Query<JsonMap>;

typedef DocSnapshotJson = DocumentSnapshot<JsonMap>;

class _DummyCommentSeed {
  const _DummyCommentSeed({
    required this.author,
    required this.text,
    required this.likes,
    required this.track,
    this.supporterLevel = 0,
  });

  final String author;
  final String text;
  final int likes;
  final CareerTrack track;
  final int supporterLevel;

  bool get isSupporter => supporterLevel > 0;
}

class CommunityRepository {
  CommunityRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    required AuthCubit authCubit,
    required UserProfileRepository userProfileRepository,
    required NotificationRepository notificationRepository,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance,
       _authCubit = authCubit,
       _userProfileRepository = userProfileRepository,
       _notificationRepository = notificationRepository;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final AuthCubit _authCubit;
  final UserProfileRepository _userProfileRepository;
  final NotificationRepository _notificationRepository;
  final Random _random = Random();
  final PrefixTokenizer _tokenizer = const PrefixTokenizer();
  final HotScoreCalculator _hotScoreCalculator = const HotScoreCalculator();
  static const int _counterShardCount = 20;
  static const List<String> _commentNicknames = <String>[
    '행정초보',
    '공공데이터덕후',
    '정책메이커',
    '민원인턴',
    '보고서마스터',
    '세종라이프',
    '스마트행정러',
    '조직문화연구소',
    '현장소통담당',
    '기록요정',
    '행복청',
    '예산지킴이',
    '디지털전환팀',
    '업무혁신가',
    '연수복습러',
  ];

  static const List<String> _commentPhrases = <String>[
    '저희도 같은 고민이라서 다음 주에 워크숍 잡았습니다. 자료 공유드릴게요.',
    '현장 의견을 먼저 수집하고 초안을 돌리면 반발이 확 줄더라고요.',
    '도입 초반에는 챗봇 Q&A를 붙여두니 문의량이 줄었습니다.',
    '직무교육 때 받은 템플릿이 있는데 필요하시면 메일로 드릴게요.',
    '관련 규정이 자주 바뀌니 월간 업데이트 노트를 꼭 챙기세요.',
    '팀별로 업무 다이어리를 쓰도록 했더니 공유 속도가 좋아졌어요.',
    '실무자 간 소규모 스터디를 먼저 열어보는 것도 추천합니다.',
    '의견 조율이 어려우면 중간 성과를 가시화해서 보여주니 협조가 잘 됐어요.',
    '직접 써본 체크리스트를 내부 위키에 올려 두었습니다.',
    '예산팀과 미리 일정을 맞춰두면 승인 절차가 훨씬 수월합니다.',
    '현장 담당자와 주간 10분 자리라도 꾸준히 잡는 게 핵심이었어요.',
    '관련 매뉴얼을 카드뉴스로 만들었더니 신규 직원들이 빠르게 익히네요.',
    '성과지표를 간단히 정리해서 공유하면 협업할 때 설득이 쉽습니다.',
    '실패 사례도 같이 공유해주시면 다른 부서에서도 참고하기 좋아요.',
    '자료를 번역해서 쓰는 경우가 많아 용어집을 따로 만들었습니다.',
  ];

  static const int _maxSyntheticComments = 10;

  String get currentUserId => _authCubit.state.userId ?? 'anonymous';

  Future<String> get currentUserNickname async {
    final profile = await _userProfileRepository.fetchProfile(currentUserId);
    return profile?.nickname ?? 'Unknown User';
  }

  CollectionReference<JsonMap> get _postsRef => _firestore.collection('posts');

  CollectionReference<JsonMap> get _likesRef => _firestore.collection('likes');

  CollectionReference<JsonMap> get _boardsRef =>
      _firestore.collection('boards');

  CollectionReference<JsonMap> get _searchSuggestionRef =>
      _firestore.collection('search_suggestions');

  CollectionReference<JsonMap> get _reportsRef =>
      _firestore.collection('reports');

  DocumentReference<JsonMap> _postDoc(String postId) => _postsRef.doc(postId);

  CollectionReference<JsonMap> _commentsRef(String postId) =>
      _postDoc(postId).collection('comments');

  CollectionReference<JsonMap> _commentLikesRef(String postId) =>
      _postDoc(postId).collection('comment_likes');

  CollectionReference<JsonMap> _postCounterShard(String postId) =>
      _firestore.collection('post_counters').doc(postId).collection('shards');

  CollectionReference<JsonMap> _bookmarksRef(String uid) =>
      _userDoc(uid).collection('bookmarks');

  DocumentReference<JsonMap> _userDoc(String uid) =>
      _firestore.collection('users').doc(uid);

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
    } catch (_) {
      final List<Post> items = _generateDummyPosts(count: limit);
      return PaginatedQueryResult<Post>(
        items: items,
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
    } catch (_) {
      final List<Post> items = _generateDummyPosts(
        count: limit,
        forceSerial: scope == LoungeScope.serial ? serial : null,
      );

      switch (sort) {
        case LoungeSort.latest:
          items.sort((Post a, Post b) => b.createdAt.compareTo(a.createdAt));
          break;
        case LoungeSort.popular:
          items.sort((Post a, Post b) => b.hotScore.compareTo(a.hotScore));
          break;
        case LoungeSort.likes:
          items.sort((Post a, Post b) => b.likeCount.compareTo(a.likeCount));
          break;
      }

      return PaginatedQueryResult<Post>(
        items: items,
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
    } catch (_) {
      final List<Post> items = _generateDummyPosts(
        count: limit,
        forceSerial: serial,
      );
      return PaginatedQueryResult<Post>(
        items: items,
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
        return query
            .orderBy('hotScore', descending: true)
            .orderBy('createdAt', descending: true);
      case LoungeSort.likes:
        return query
            .orderBy('likeCount', descending: true)
            .orderBy('createdAt', descending: true);
    }
  }

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
    } catch (_) {
      final List<Post> items = _generateDummyPosts(count: limit)
        ..sort((a, b) => b.hotScore.compareTo(a.hotScore));
      return PaginatedQueryResult<Post>(
        items: items,
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
          commentId: commentDoc.id,
          parentCommentId: parentCommentId,
          authorUid: authorUid,
          authorNickname: authorNickname,
          text: text,
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
          (QueryDocumentSnapshot<JsonMap> doc) => Comment.fromSnapshot(
            doc,
            isLiked: likedIds.contains(doc.id),
          ),
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
          (QueryDocumentSnapshot<JsonMap> doc) => Comment.fromSnapshot(
            doc,
            isLiked: likedIds.contains(doc.id),
          ),
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
  }) async {
    final nickname = await currentUserNickname;
    final CareerTrack track = _authCubit.state.careerTrack;
    final int supporterLevel = _authCubit.state.supporterLevel;
    final bool serialVisible = _authCubit.state.serialVisible;
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

  CareerTrack _randomCareerTrack() {
    final List<CareerTrack> pool = CareerTrack.values
        .where((CareerTrack track) => track != CareerTrack.none)
        .toList(growable: false);
    return pool[_random.nextInt(pool.length)];
  }

  CareerTrack _resolveSeedTrack(Object? raw) {
    final CareerTrack resolved = _careerTrackFromRaw(raw);
    if (resolved != CareerTrack.none) {
      return resolved;
    }
    return _randomCareerTrack();
  }

  List<Post> _generateDummyPosts({int count = 10, String? forceSerial}) {
    final List<String> samples = <String>[
      '출장 다녀온 뒤 정산 보고서를 어떻게 작성하시는지 궁금합니다. 예산과 실제 비용이 다를 때 어떤 식으로 설명을 덧붙이는지 사례가 있다면 공유 부탁드려요. 저는 각 항목마다 증빙 사유를 붙이고 있지만, 과장님이 더 보기 쉬운 양식이 있을 거라고 하시네요.',
      '이번 분기 목표를 세우면서 팀 내 협업 방식을 조금 바꿔보려고 합니다. 슬랙 채널을 세분화하는 방안, 주간 회의제 폐지 등 여러 의견이 나왔는데 실제로 개선에 성공한 팀이 있다면 어떤 절차를 거쳤는지 알려주실 수 있나요? 반대 의견을 설득하는 과정도 궁금합니다.',
      '새로 발령받은 부서에서 첫 번째 대형 프로젝트를 맡게 됐습니다. 기한은 빠듯하고 관련 지침은 예전 케이스라 그대로 적용하기가 어렵네요. 비슷한 경험 있으신 분들께서 어떤 식으로 현행 규정을 정리하고 이해관계자 협의를 진행하셨는지 경험담 나눠주시면 큰 도움이 될 것 같아요.',
      '최근에 민원 응대 매뉴얼을 개정해야 한다는 의견이 나왔는데, 현장에서 바로 적용 가능한 사례가 필요합니다. 특히 전화 상담과 방문 상담을 분리해서 대응한 경험이 있으신 분들의 노하우가 궁금합니다. 말투나 응대 시간 관리 팁도 환영합니다.',
      '업무 자동화를 위해 간단한 엑셀 매크로나 구글 앱스 스크립트를 도입해 보신 분 계신가요? 반복 입력 작업은 줄었지만 예외 상황에서 오류가 꽤 자주 발생합니다. 어떤 식으로 예외 처리를 설계했고, 사용자 교육은 어떻게 진행했는지 사례를 듣고 싶습니다.',
      '청사 근처 점심 선택지가 한정돼 있다 보니 팀원들과 도시락 시스템을 도입해 보려고 합니다. 단체 주문, 냉장 보관, 배분까지 운영 노하우가 있다면 공유 부탁드립니다. 특히 비용 정산과 위생 관리 측면에서 체크해야 할 포인트가 궁금합니다.',
      '주간 업무보고를 준비할 때 다들 어느 정도 분량으로 작성하시나요? 저는 핵심 업무를 표로 정리하고 부연 설명을 덧붙이고 있는데, 팀장님께서는 한눈에 진척도가 보였으면 좋겠다고 하셨습니다. 효과적인 시각화나 템플릿 추천 부탁드려요.',
      '최근 교육 연수에서 들은 내용 중 실무에 바로 적용 가능한 부분이 많았는데, 팀 단위 공유 방법을 고민 중입니다. 여러분은 연수나 세미나 내용을 사내에 전파할 때 어떤 자료와 채널을 활용하시나요? 영상 요약이나 카드뉴스 형태로 제작해 보신 분 계시면 조언 부탁드립니다.',
      '새로 도입된 협업 툴을 정착시키기 위해 온보딩 자료를 만들고 있습니다. 기본 기능 소개 외에 실제 업무 흐름을 케이스로 풀어냈을 때 이해도가 확 올라가더군요. 더 효과적인 온보딩 방식을 고민 중인데, 타 부서 성공 사례가 있다면 듣고 싶습니다.',
      '민관 협력 프로젝트를 진행하다 보니 보안과 공유 범위를 어디까지 설정해야 할지 고민이 많습니다. 협약서 작성 시 조항에 반영했던 내용이나, 클라우드 문서 공유 시 유의해야 할 점이 있다면 알려주세요. 실수로 정보가 노출되는 일이 없도록 대비하고 싶네요.',
      '사내 위키를 새롭게 꾸미려고 합니다. 문서 체계를 어떻게 설계하면 신규 구성원이 헤매지 않을까요? 템플릿 구조나 태그 전략, 검색 키워드 관리 팁이 있다면 공유 부탁드립니다.',
      '회의록을 작성할 때 자동 요약 도구를 활용해 보신 분 있으신가요? 음성 인식과 연결해 쓰려는데 보안 이슈나 정제 과정에서 주의해야 할 부분이 궁금합니다.',
      '정책 홍보 영상 제작을 맡게 되었는데, 대내외 이해관계자 모두 공감할 수 있는 메시지를 어떻게 추렸는지 사례를 듣고 싶어요. 제작 일정과 검토 프로세스도 공유해 주시면 감사하겠습니다.',
    ];

    final List<List<Map<String, Object?>>> commentSamples =
        <List<Map<String, Object?>>>[
          <Map<String, Object?>>[
            <String, Object?>{
              'author': '행정고시 63기',
              'text': '증빙 사유를 엑셀 메모로 넣고 PDF로 출력하면 깔끔하게 정리됩니다.',
              'likes': 18,
            },
            <String, Object?>{
              'author': '충북교육청',
              'text': '금액 차이가 크지 않다면 사유 한 줄과 영수증만으로 통과했습니다.',
              'likes': 9,
            },
            <String, Object?>{
              'author': '지원반 ooo',
              'text': '지출 항목별로 담당자 확인 싸인을 받는 것도 추천드려요.',
              'likes': 6,
            },
            <String, Object?>{
              'author': '재무회계팀',
              'text': '지출결의서에 첨부 서류 미리 붙이면 승인 속도가 빨라집니다.',
              'likes': 3,
            },
            <String, Object?>{
              'author': '세종청 회계담당',
              'text': '증빙사진은 클라우드 링크 대신 PDF로 묶는 게 검토하기 편하더라구요.',
              'likes': 2,
            },
          ],
          <Map<String, Object?>>[
            <String, Object?>{
              'author': '기획재정부',
              'text': '분기별 OKR 정리하면서 자연스럽게 협업 방식도 정리했습니다.',
              'likes': 21,
            },
            <String, Object?>{
              'author': '정책연구원',
              'text': '반대 의견이 있으면 파일럿으로 2주만 운영해보자고 설득했어요.',
              'likes': 15,
            },
            <String, Object?>{
              'author': '서울시 정책실',
              'text': '협업 지침을 문서로만 만들지 말고 킥오프 워크숍을 꼭 해보세요.',
              'likes': 12,
            },
            <String, Object?>{
              'author': '부산경제국',
              'text': '팀별 파트너 지정 제도를 도입했더니 커뮤니케이션 불편이 줄었습니다.',
              'likes': 6,
            },
          ],
          <Map<String, Object?>>[
            <String, Object?>{
              'author': '세종청사 4동',
              'text': '관련 규정 비교표를 먼저 만들고 이해관계자 워크숍을 진행했어요.',
              'likes': 11,
            },
            <String, Object?>{
              'author': '서울시청',
              'text': '초기에는 참고할 선례를 많이 찾아 공유하면 신뢰가 생깁니다.',
              'likes': 7,
            },
            <String, Object?>{
              'author': '행정사',
              'text': '법무팀 검토 일정을 반드시 여유 있게 잡으세요.',
              'likes': 5,
            },
            <String, Object?>{
              'author': '도시계획과',
              'text': '유사 사업 사례를 간략 리포트로 정리해서 도면과 같이 보여주면 좋아요.',
              'likes': 4,
            },
          ],
          <Map<String, Object?>>[
            <String, Object?>{
              'author': '콜센터 TF',
              'text': '전화/방문 시나리오를 따로 만들고 공통 FAQ만 묶어서 관리했습니다.',
              'likes': 24,
            },
            <String, Object?>{
              'author': '민원24 운영',
              'text': '응대 톤앤매너 동영상 찍어서 교육했더니 큰 도움이 됐어요.',
              'likes': 13,
            },
            <String, Object?>{
              'author': '경기도 콜센터',
              'text': '상황별 스크립트에 대응 키워드를 같이 적어두면 신규 직원이 빨리 익혀요.',
              'likes': 8,
            },
          ],
          <Map<String, Object?>>[
            <String, Object?>{
              'author': '데이터혁신과',
              'text': '예외 처리는 오류 로그를 슬랙으로 자동 전송하게 만들었어요.',
              'likes': 16,
            },
            <String, Object?>{
              'author': '인사혁신처',
              'text': '사용자 교육은 짧게 녹화한 스크린캐스트로 대체했습니다.',
              'likes': 10,
            },
            <String, Object?>{
              'author': 'IT지원실',
              'text': '매뉴얼 페이지에 주요 오류 FAQ 섹션을 추가하니 혼선이 줄었어요.',
              'likes': 5,
            },
            <String, Object?>{
              'author': '스마트행정팀',
              'text': '감사 대비 로그 정책도 같이 세팅하면 나중에 편합니다.',
              'likes': 4,
            },
          ],
          <Map<String, Object?>>[
            <String, Object?>{
              'author': '정부세종청사',
              'text': '냉장고 정리 담당자를 주별로 정해두면 위생 문제가 줄어요.',
              'likes': 8,
            },
            <String, Object?>{
              'author': '광주세무서',
              'text': '단체 주문할 땐 최소 주문 인원을 정해 놓는 게 좋아요.',
              'likes': 6,
            },
            <String, Object?>{
              'author': '영양사 김주무관',
              'text': '냉장고 안 일정표를 붙여두면 누구 차례인지 헷갈리지 않아요.',
              'likes': 5,
            },
          ],
          <Map<String, Object?>>[
            <String, Object?>{
              'author': '보고왕김주임',
              'text': '표 + 한 줄 요약, 그리고 리스크/이슈 칸을 넣으면 끝납니다.',
              'likes': 27,
            },
            <String, Object?>{
              'author': '대전교육청',
              'text': '슬라이드 3장으로 요약하고 상세는 별첨으로 빼고 있어요.',
              'likes': 12,
            },
            <String, Object?>{
              'author': '정책기획관실',
              'text': '리마인더 메일에 지난 주에 정한 액션 아이템을 적어두면 피드백 빨라요.',
              'likes': 6,
            },
          ],
          <Map<String, Object?>>[
            <String, Object?>{
              'author': '연수원 2기',
              'text': '수료 후 24시간 안에 요약 노트를 올리면 기억이 선명합니다.',
              'likes': 14,
            },
            <String, Object?>{
              'author': '홍보담당',
              'text': '카드뉴스 템플릿 공유해 드릴게요. 내부망에 올리면 반응 좋아요.',
              'likes': 9,
            },
            <String, Object?>{
              'author': '세미나디자인팀',
              'text': '요약자료는 PDF와 슬랙 아카이브 둘 다 남기는 게 공유가 잘 됩니다.',
              'likes': 4,
            },
          ],
          <Map<String, Object?>>[
            <String, Object?>{
              'author': '디지털과',
              'text': '첫 주는 1:1 멘토링, 이후 주간 Q&A 세션을 열었습니다.',
              'likes': 17,
            },
            <String, Object?>{
              'author': '혁신기획팀',
              'text': '케이스 기반 튜토리얼을 PDF와 영상 두 가지로 제공했어요.',
              'likes': 11,
            },
            <String, Object?>{
              'author': 'DX센터',
              'text': '신규 기능 릴리즈 노트를 주간 브리핑에 붙이니 정착이 빨랐습니다.',
              'likes': 8,
            },
          ],
          <Map<String, Object?>>[
            <String, Object?>{
              'author': '정보보호팀',
              'text': '공유 범위는 프로젝트 단계별로 나눠서 접근 권한을 다르게 줬습니다.',
              'likes': 20,
            },
            <String, Object?>{
              'author': '국무조정실',
              'text': '보안 교육을 워크숍 시작 전에 별도로 진행해야 사고가 줄어요.',
              'likes': 12,
            },
            <String, Object?>{
              'author': '법무담당',
              'text': '외부와 협력할 땐 비밀유지조항 외에 데이터 파기 절차도 명시하세요.',
              'likes': 7,
            },
          ],
        ];

    final List<String> nicknames = <String>[
      'gongmu_talker',
      '행정러버',
      '정책러너',
      '공무원탐험가',
      '세종시러',
    ];

    final List<Post> posts = <Post>[];
    for (int i = 0; i < count; i += 1) {
      final String id =
          'dummy_${DateTime.now().millisecondsSinceEpoch}_${i}_${_random.nextInt(9999)}';
      final DateTime createdAt = DateTime.now().subtract(
        Duration(minutes: _random.nextInt(240)),
      );
      final int likeCount = 18 + _random.nextInt(40);
      final List<Map<String, Object?>> baseComments =
          List<Map<String, Object?>>.from(
            commentSamples[_random.nextInt(commentSamples.length)],
          );

      final int additionalComments = 1 + _random.nextInt(7);
      final List<Map<String, Object?>> commentTemplate = <Map<String, Object?>>[
        ...baseComments,
        ...List<Map<String, Object?>>.generate(additionalComments, (int index) {
          final int likeSeed = baseComments.isEmpty
              ? 5 + _random.nextInt(10)
              : ((baseComments.first['likes'] as int?) ?? 5) - index * 2;
          return <String, Object?>{
            'author': _syntheticNickname(),
            'text': _syntheticCommentText(samples),
            'likes': likeSeed.clamp(1, 18),
          };
        }),
      ];

      final List<_DummyCommentSeed> seeds = commentTemplate
          .map(
            (Map<String, Object?> comment) => _DummyCommentSeed(
              author: (comment['author'] as String?) ?? '익명',
              text: (comment['text'] as String?) ?? '',
              likes: (comment['likes'] as num?)?.toInt() ?? 0,
              track: _resolveSeedTrack(comment['track']),
              supporterLevel:
                  (comment['supporterLevel'] as num?)?.toInt() ??
                  (_random.nextInt(12) == 0 ? 1 : 0),
            ),
          )
          .toList(growable: false);

      final List<_DummyCommentSeed> timelineSeeds = seeds
          .take(min(_maxSyntheticComments, seeds.length))
          .toList(growable: false);

      final List<_DummyCommentSeed> sortedByLikes =
          List<_DummyCommentSeed>.from(timelineSeeds)..sort(
            (_DummyCommentSeed a, _DummyCommentSeed b) =>
                b.likes.compareTo(a.likes),
          );

      final Map<_DummyCommentSeed, CachedComment> seedMap =
          <_DummyCommentSeed, CachedComment>{};
      final List<CachedComment> previewComments = <CachedComment>[];
      for (int index = 0; index < timelineSeeds.length; index += 1) {
        final _DummyCommentSeed seed = timelineSeeds[index];
        final CachedComment cached = CachedComment(
          id: 'dummy_comment_${id}_$index',
          text: seed.text,
          likeCount: seed.likes,
          authorNickname: seed.author,
          authorTrack: seed.track,
          authorSerialVisible: true,
          authorSupporterLevel: seed.supporterLevel,
          authorIsSupporter: seed.isSupporter,
        );
        seedMap[seed] = cached;
        previewComments.add(cached);
      }

      final CachedComment? topComment = sortedByLikes.isEmpty
          ? null
          : seedMap[sortedByLikes.first];

      final int resolvedCommentCount = previewComments.length;
      final int viewCount = likeCount * 8 + _random.nextInt(300);
      final bool hasForcedSerial =
          forceSerial != null &&
          forceSerial.isNotEmpty &&
          forceSerial != 'unknown';
      CareerTrack postTrack = hasForcedSerial
          ? _careerTrackFromRaw(forceSerial)
          : _randomCareerTrack();
      if (postTrack == CareerTrack.none) {
        postTrack = _randomCareerTrack();
      }
      final String serial = hasForcedSerial ? forceSerial : postTrack.name;
      final String text = samples[_random.nextInt(samples.length)];
      final double hot = _hotScoreCalculator.calculate(
        likeCount: likeCount,
        commentCount: resolvedCommentCount,
        viewCount: viewCount,
        createdAt: createdAt,
      );
      final int supporterLevel = _random.nextInt(6) == 0 ? 1 : 0;

      posts.add(
        Post(
          id: id,
          type: PostType.chirp,
          audience: forceSerial == null
              ? PostAudience.all
              : PostAudience.serial,
          serial: serial,
          boardId: null,
          authorUid: 'dummy_user',
          authorNickname: nicknames[_random.nextInt(nicknames.length)],
          authorTrack: postTrack,
          authorSerialVisible: true,
          authorSupporterLevel: supporterLevel,
          authorIsSupporter: supporterLevel > 0,
          text: text,
          media: const <PostMedia>[],
          tags: const <String>[],
          keywords: _tokenizer.buildPrefixes(title: '더미유저', body: text),
          likeCount: likeCount,
          commentCount: resolvedCommentCount,
          viewCount: viewCount,
          hotScore: hot,
          createdAt: createdAt,
          updatedAt: createdAt,
          visibility: PostVisibility.public,
          topComment: topComment,
          previewComments: previewComments,
          isLiked: false,
          isBookmarked: false,
        ),
      );
    }

    posts.sort((Post a, Post b) => b.createdAt.compareTo(a.createdAt));
    return posts;
  }

  Future<List<Post>> _attachTopComments(List<Post> posts) async {
    final List<Post> needsTopComment = posts
        .where((Post post) => post.topComment == null && post.commentCount > 0)
        .take(5)
        .toList(growable: false);

    if (needsTopComment.isEmpty) {
      return posts;
    }

    final List<MapEntry<String, CachedComment?>> fetched = await Future.wait(
      needsTopComment.map((Post post) async {
        try {
          final CachedComment? top = await _loadTopComment(post.id);
          return MapEntry<String, CachedComment?>(post.id, top);
        } catch (_) {
          return MapEntry<String, CachedComment?>(post.id, null);
        }
      }),
    );

    final Map<String, CachedComment?> lookup = <String, CachedComment?>{
      for (final MapEntry<String, CachedComment?> entry in fetched)
        entry.key: entry.value,
    };

    return posts
        .map(
          (Post post) => lookup.containsKey(post.id) && lookup[post.id] != null
              ? post.copyWith(topComment: lookup[post.id])
              : post,
        )
        .toList(growable: false);
  }

  Future<CachedComment?> _loadTopComment(String postId) async {
    final QuerySnapshot<JsonMap> snapshot = await _commentsRef(postId)
        .where('deleted', isEqualTo: false)
        .orderBy('likeCount', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    final QueryDocumentSnapshot<JsonMap> doc = snapshot.docs.first;
    final Map<String, Object?> data = doc.data();

    final String? text = data['text'] as String?;
    final String? author = data['authorNickname'] as String?;
    if (text == null || text.isEmpty || author == null || author.isEmpty) {
      return null;
    }

    final int likeCount = (data['likeCount'] as num?)?.toInt() ?? 0;
    final String? trackRaw = data['authorTrack'] as String?;
    final CareerTrack track = trackRaw != null
        ? CareerTrack.values.firstWhere(
            (CareerTrack value) => value.name == trackRaw,
            orElse: () => CareerTrack.none,
          )
        : CareerTrack.none;
    final int supporterLevel =
        (data['authorSupporterLevel'] as num?)?.toInt() ?? 0;
    final bool isSupporter =
        data['authorIsSupporter'] as bool? ?? supporterLevel > 0;
    final bool serialVisible = data['authorSerialVisible'] as bool? ?? true;

    return CachedComment(
      id: doc.id,
      text: text,
      likeCount: likeCount,
      authorNickname: author,
      authorTrack: track,
      authorSerialVisible: serialVisible,
      authorSupporterLevel: supporterLevel,
      authorIsSupporter: isSupporter,
    );
  }

  Future<List<String>> autocompleteSearchTokens({
    required String prefix,
    int limit = 6,
  }) async {
    final String token = prefix.trim().toLowerCase();
    if (token.isEmpty) {
      return const <String>[];
    }

    final String endToken = '$token${String.fromCharCode(0xF8FF)}';
    final QuerySnapshot<JsonMap> snapshot = await _searchSuggestionRef
        .orderBy(FieldPath.documentId)
        .startAt(<String>[token])
        .endAt(<String>[endToken])
        .limit(limit)
        .get();

    return snapshot.docs
        .map((QueryDocumentSnapshot<JsonMap> doc) => doc.id)
        .toList(growable: false);
  }

  Future<void> seedSamplePosts({
    required String uid,
    required String nickname,
    required CareerTrack track,
    required String serial,
    int count = 12,
  }) async {
    final List<String> samples = <String>[
      '오늘 업무 중 느낀 점을 공유해요. 같은 경험 있으신가요?',
      '부서 내 협업을 더 잘하려면 무엇이 필요할까요?',
      '점심 추천 부탁드립니다! 정부청사 근처 맛집 아시나요?',
      '업무 자동화 아이디어를 모아봅시다.',
      '정책 자료 정리 노하우 공유합니다.',
      '회의가 많은 날엔 집중 시간이 부족하네요.',
      '새로 발령받은 부서에 적응 중입니다.',
      '문서 양식 표준화에 대한 의견이 궁금해요.',
      '업무용 장비 교체 일정이 잡혔다고 합니다.',
      '팀 내 코드 리뷰 문화를 만들어볼까 해요.',
      '공유할만한 유용한 템플릿이 있으신가요?',
      '이번 주간 보고 양식을 바꿔보려 합니다.',
    ];
    final List<String> commentSamples = <String>[
      '저도 같은 고민 중이라 반갑네요.',
      '최근에 이런 비슷한 사례가 있었어요.',
      '팀과 공유해보고 싶은 아이디어입니다.',
      '현장에서 느낀 점을 덧붙여볼게요.',
      '선배께 들은 팁인데 도움이 되길 바랍니다.',
      '이 부분은 규정상 이렇게 처리해야 해요.',
    ];
    final List<String> replySamples = <String>[
      '좋은 정보 감사합니다!',
      '추가 질문 드려도 될까요?',
      '말씀 덕분에 방향이 잡히네요.',
      '곧 적용해서 공유드릴게요.',
    ];
    final List<String> commentAuthors = <String>['행정요정', '현장달인', '조용한고수', '친절한선배'];
    final List<CareerTrack> availableTracks = CareerTrack.values
        .where((CareerTrack value) => value != CareerTrack.none)
        .toList(growable: false);

    final Random random = Random();

    for (int i = 0; i < count; i += 1) {
      final String text = samples[random.nextInt(samples.length)];
      final List<String> tags = <String>[
        '업무',
        '협업',
        '문서',
        '정책',
      ].where((_) => random.nextBool()).take(2).toList(growable: false);

      final Post post = await createPost(
        type: PostType.chirp,
        authorUid: uid,
        authorNickname: nickname.isEmpty ? '시드봇' : nickname,
        authorTrack: track,
        text: text,
        audience: random.nextBool() ? PostAudience.all : PostAudience.serial,
        serial: serial.isEmpty
            ? (track == CareerTrack.none ? 'all' : track.name)
            : serial,
        tags: tags,
        awardPoints: false,
      );

      final int commentCount = max(1, random.nextInt(3));
      final List<Comment> createdComments = <Comment>[];
      for (int c = 0; c < commentCount; c += 1) {
        final String authorName = commentAuthors[random.nextInt(commentAuthors.length)];
        final CareerTrack authorTrack = availableTracks.isEmpty
            ? CareerTrack.none
            : availableTracks[random.nextInt(availableTracks.length)];
        final Comment comment = await createComment(
          postId: post.id,
          authorUid: '${authorName.toLowerCase()}-${post.id}-$c',
          authorNickname: authorName,
          text: commentSamples[random.nextInt(commentSamples.length)],
          authorTrack: authorTrack,
          authorSerialVisible: random.nextBool(),
          authorSupporterLevel: 0,
          authorIsSupporter: false,
          awardPoints: false,
        );
        createdComments.add(comment);
      }

      if (createdComments.isNotEmpty && random.nextBool()) {
        final Comment parent = createdComments.first;
        final String replyAuthor =
            commentAuthors[random.nextInt(commentAuthors.length)];
        await createComment(
          postId: post.id,
          authorUid: '${replyAuthor.toLowerCase()}-${post.id}-reply',
          authorNickname: replyAuthor,
          text: replySamples[random.nextInt(replySamples.length)],
          parentCommentId: parent.id,
          authorTrack: parent.authorTrack,
          authorSerialVisible: random.nextBool(),
          authorSupporterLevel: 0,
          authorIsSupporter: false,
          awardPoints: false,
        );
      }
    }
  }

  Future<void> _dispatchCommentNotifications({
    required String postId,
    required String commentId,
    required String? parentCommentId,
    required String authorUid,
    required String authorNickname,
    required String text,
  }) async {
    final List<Future<void>> tasks = <Future<void>>[];
    final String excerpt = _buildExcerpt(text);

    if (parentCommentId != null && parentCommentId.isNotEmpty) {
      tasks.add(
        _notifyParentCommentAuthor(
          postId: postId,
          commentId: commentId,
          parentCommentId: parentCommentId,
          authorUid: authorUid,
          authorNickname: authorNickname,
          excerpt: excerpt,
        ),
      );
    }

    tasks.add(
      _notifyBookmarkSubscribers(
        postId: postId,
        authorUid: authorUid,
        authorNickname: authorNickname,
        excerpt: excerpt,
      ),
    );

    await Future.wait(tasks);
  }

  Future<void> _notifyParentCommentAuthor({
    required String postId,
    required String commentId,
    required String parentCommentId,
    required String authorUid,
    required String authorNickname,
    required String excerpt,
  }) async {
    try {
      final DocumentSnapshot<JsonMap> parentSnapshot = await _commentsRef(
        postId,
      ).doc(parentCommentId).get();
      if (!parentSnapshot.exists) {
        return;
      }
      final Map<String, Object?> parentData = parentSnapshot.data()!;
      final String? targetUid = parentData['authorUid'] as String?;
      if (targetUid == null || targetUid.isEmpty || targetUid == authorUid) {
        return;
      }

      await _notificationRepository.notifyCommentReply(
        targetUid: targetUid,
        postId: postId,
        commentId: commentId,
        parentCommentId: parentCommentId,
        replierNickname: authorNickname,
        excerpt: excerpt,
      );
    } catch (error, stackTrace) {
      debugPrint(
        'Failed to queue comment reply notification: $error\n$stackTrace',
      );
    }
  }

  Future<void> _notifyBookmarkSubscribers({
    required String postId,
    required String authorUid,
    required String authorNickname,
    required String excerpt,
  }) async {
    try {
      final QuerySnapshot<JsonMap> snapshot = await _firestore
          .collectionGroup('bookmarks')
          .where('postId', isEqualTo: postId)
          .get();

      if (snapshot.docs.isEmpty) {
        return;
      }

      final Set<String> targets = <String>{};
      for (final QueryDocumentSnapshot<JsonMap> doc in snapshot.docs) {
        final String? targetUid = doc.reference.parent.parent?.id;
        if (targetUid == null || targetUid.isEmpty || targetUid == authorUid) {
          continue;
        }
        targets.add(targetUid);
      }

      if (targets.isEmpty) {
        return;
      }

      await Future.wait(
        targets.map(
          (String targetUid) =>
              _notificationRepository.notifyBookmarkedPostComment(
                targetUid: targetUid,
                postId: postId,
                commenterNickname: authorNickname,
                excerpt: excerpt,
              ),
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to notify bookmarked users: $error\n$stackTrace');
    }
  }

  String _buildExcerpt(String text, {int maxLength = 40}) {
    final String normalized = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.isEmpty) {
      return '내용 없음';
    }
    if (normalized.length <= maxLength) {
      return normalized;
    }
    return '${normalized.substring(0, maxLength)}...';
  }

  String _syntheticNickname() {
    return _commentNicknames[_random.nextInt(_commentNicknames.length)];
  }

  String _syntheticCommentText(List<String> samples) {
    if (_commentPhrases.isNotEmpty && _random.nextBool()) {
      return _commentPhrases[_random.nextInt(_commentPhrases.length)];
    }
    final String sample = samples[_random.nextInt(samples.length)];
    final List<String> sentences = sample.split(' ');
    final int take = min(12, sentences.length);
    return sentences.take(take).join(' ');
  }
}
