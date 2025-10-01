import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../../../core/firebase/paginated_query.dart';
import '../../../core/utils/result.dart';
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
import 'repositories/post_repository.dart';
import 'repositories/comment_repository.dart';
import 'repositories/interaction_repository.dart';
import 'repositories/search_repository.dart';
import 'repositories/lounge_repository.dart';

typedef JsonMap = Map<String, Object?>;
typedef QueryJson = Query<JsonMap>;
typedef DocSnapshotJson = DocumentSnapshot<JsonMap>;

/// Community Repository - Main facade for community features
///
/// Responsibilities:
/// - Coordinate between specialized repositories
/// - Provide unified API for community operations
/// - Handle reports and moderation
/// - Enrich data with user-specific information (likes, bookmarks, top comments)
///
/// This repository acts as a facade pattern, delegating to:
/// - PostRepository: Post CRUD and feeds
/// - CommentRepository: Comment operations
/// - InteractionRepository: Likes and bookmarks
/// - SearchRepository: Search and suggestions
/// - LoungeRepository: Lounge feeds and boards
///
/// Dependencies: All specialized repositories, UserSession
class CommunityRepository {
  CommunityRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    required UserSession userSession,
    required UserProfileRepository userProfileRepository,
    required NotificationRepository notificationRepository,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _userSession = userSession,
        _userProfileRepository = userProfileRepository,
        _notificationRepository = notificationRepository {
    // Initialize specialized repositories
    _postRepository = PostRepository(
      firestore: _firestore,
      storage: _storage,
      userProfileRepository: _userProfileRepository,
    );
    _commentRepository = CommentRepository(
      firestore: _firestore,
      userProfileRepository: _userProfileRepository,
      notificationRepository: _notificationRepository,
    );
    _interactionRepository = InteractionRepository(
      firestore: _firestore,
      userProfileRepository: _userProfileRepository,
    );
    _searchRepository = SearchRepository(firestore: _firestore);
    _loungeRepository = LoungeRepository(firestore: _firestore);
  }

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final UserSession _userSession;
  final UserProfileRepository _userProfileRepository;
  final NotificationRepository _notificationRepository;

  late final PostRepository _postRepository;
  late final CommentRepository _commentRepository;
  late final InteractionRepository _interactionRepository;
  late final SearchRepository _searchRepository;
  late final LoungeRepository _loungeRepository;

  String get currentUserId => _userSession.userId;

  Future<String> get currentUserNickname async {
    final profile = await _userProfileRepository.fetchProfile(currentUserId);
    return profile?.nickname ?? 'Unknown User';
  }

  CollectionReference<JsonMap> get _reportsRef =>
      _firestore.collection('reports');

  DocumentReference<JsonMap> _userDoc(String uid) =>
      _firestore.collection('users').doc(uid);

  // ============================================================================
  // POST OPERATIONS - Delegate to PostRepository
  // ============================================================================

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
  }) {
    return _postRepository.createPost(
      type: type,
      authorUid: authorUid,
      authorNickname: authorNickname,
      authorTrack: authorTrack,
      authorSerialVisible: authorSerialVisible,
      authorSupporterLevel: authorSupporterLevel,
      authorIsSupporter: authorIsSupporter,
      text: text,
      audience: audience,
      serial: serial,
      media: media,
      tags: tags,
      boardId: boardId,
      awardPoints: awardPoints,
    );
  }

  Future<void> updatePost({
    required String postId,
    required String authorUid,
    String? text,
    List<PostMedia>? media,
    List<String>? tags,
    PostVisibility? visibility,
  }) {
    return _postRepository.updatePost(
      postId: postId,
      authorUid: authorUid,
      text: text,
      media: media,
      tags: tags,
      visibility: visibility,
    );
  }

  Future<void> deletePost({
    required String postId,
    required String authorUid,
  }) {
    return _postRepository.deletePost(postId: postId, authorUid: authorUid);
  }

  Future<Post?> fetchPostById(String postId, {String? currentUid}) async {
    final Post? post = await _postRepository.fetchPostById(postId);
    if (post == null) return null;

    return _enrichPostWithUserData(post, currentUid: currentUid);
  }

  Future<PaginatedQueryResult<Post>> fetchChirpFeed({
    int limit = 20,
    QueryDocumentSnapshotJson? startAfter,
    String? currentUid,
  }) async {
    final result = await _postRepository.fetchChirpFeed(
      limit: limit,
      startAfter: startAfter,
    );
    return _enrichPostPageWithUserData(result, currentUid: currentUid);
  }

  Future<PaginatedQueryResult<Post>> fetchHotFeed({
    int limit = 20,
    QueryDocumentSnapshotJson? startAfter,
    String? currentUid,
  }) async {
    final result = await _postRepository.fetchHotFeed(
      limit: limit,
      startAfter: startAfter,
    );
    return _enrichPostPageWithUserData(result, currentUid: currentUid);
  }

  Future<PaginatedQueryResult<Post>> fetchBoardPosts({
    required String boardId,
    int limit = 20,
    QueryDocumentSnapshotJson? startAfter,
    String? currentUid,
  }) async {
    final result = await _postRepository.fetchBoardPosts(
      boardId: boardId,
      limit: limit,
      startAfter: startAfter,
    );
    return _enrichPostPageWithUserData(result, currentUid: currentUid);
  }

  Future<PaginatedQueryResult<Post>> fetchPostsByAuthor({
    required String authorUid,
    int limit = 20,
    QueryDocumentSnapshotJson? startAfter,
    String? currentUid,
  }) async {
    final result = await _postRepository.fetchPostsByAuthor(
      authorUid: authorUid,
      limit: limit,
      startAfter: startAfter,
    );
    return _enrichPostPageWithUserData(result, currentUid: currentUid);
  }

  Future<void> incrementViewCount(String postId) {
    return _postRepository.incrementViewCount(postId);
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
  }) {
    return _postRepository.uploadPostImage(
      uid: uid,
      postId: postId,
      fileName: fileName,
      bytes: bytes,
      contentType: contentType,
      thumbnailBytes: thumbnailBytes,
      thumbnailContentType: thumbnailContentType,
      width: width,
      height: height,
    );
  }

  Future<void> hidePost({required String postId}) {
    return _postRepository.hidePost(postId: postId);
  }

  Future<void> restorePost({required String postId}) {
    return _postRepository.restorePost(postId: postId);
  }

  Future<void> batchHidePosts(List<String> postIds) {
    return _postRepository.batchHidePosts(postIds);
  }

  Future<Post?> getPost(String postId) async {
    return fetchPostById(postId, currentUid: currentUserId);
  }

  Future<void> deletePostById(String postId) async {
    await deletePost(postId: postId, authorUid: currentUserId);
  }

  // ============================================================================
  // LOUNGE OPERATIONS - Delegate to LoungeRepository
  // ============================================================================

  Future<PaginatedQueryResult<Post>> fetchLoungeFeed({
    required LoungeScope scope,
    required LoungeSort sort,
    int limit = 20,
    QueryDocumentSnapshotJson? startAfter,
    String? serial,
    String? currentUid,
  }) async {
    final result = await _loungeRepository.fetchLoungeFeed(
      scope: scope,
      sort: sort,
      limit: limit,
      startAfter: startAfter,
      serial: serial,
    );
    return _enrichPostPageWithUserData(result, currentUid: currentUid);
  }

  Future<PaginatedQueryResult<Post>> fetchSerialFeed({
    required String serial,
    int limit = 20,
    QueryDocumentSnapshotJson? startAfter,
    String? currentUid,
  }) async {
    final result = await _loungeRepository.fetchSerialFeed(
      serial: serial,
      limit: limit,
      startAfter: startAfter,
    );
    return _enrichPostPageWithUserData(result, currentUid: currentUid);
  }

  Future<List<Board>> fetchBoards({bool includeHidden = false}) {
    return _loungeRepository.fetchBoards(includeHidden: includeHidden);
  }

  Stream<List<Board>> watchBoards({bool includeHidden = false}) {
    return _loungeRepository.watchBoards(includeHidden: includeHidden);
  }

  // ============================================================================
  // COMMENT OPERATIONS - Delegate to CommentRepository
  // ============================================================================

  Future<PaginatedQueryResult<Comment>> fetchComments({
    required String postId,
    int limit = 50,
    QueryDocumentSnapshot<JsonMap>? startAfter,
    String? currentUid,
  }) async {
    final result = await _commentRepository.fetchComments(
      postId: postId,
      limit: limit,
      startAfter: startAfter,
    );

    if (currentUid == null) return result;

    final Set<String> likedIds = await _interactionRepository.fetchLikedCommentIds(
      postId: postId,
      uid: currentUid,
      commentIds: result.items.map((c) => c.id).toList(),
    );

    final enrichedComments = result.items
        .map((comment) =>
            comment.copyWith(isLiked: likedIds.contains(comment.id)))
        .toList();

    return PaginatedQueryResult<Comment>(
      items: enrichedComments,
      lastDocument: result.lastDocument,
      hasMore: result.hasMore,
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
  }) {
    return _commentRepository.createComment(
      postId: postId,
      authorUid: authorUid,
      authorNickname: authorNickname,
      text: text,
      parentCommentId: parentCommentId,
      authorTrack: authorTrack,
      authorSerialVisible: authorSerialVisible,
      authorSupporterLevel: authorSupporterLevel,
      authorIsSupporter: authorIsSupporter,
      awardPoints: awardPoints,
      imageUrls: imageUrls,
    );
  }

  Future<void> deleteComment({
    required String postId,
    required String commentId,
    required String requesterUid,
  }) {
    return _commentRepository.deleteComment(
      postId: postId,
      commentId: commentId,
      requesterUid: requesterUid,
    );
  }

  Future<List<Comment>> getComments(String postId) async {
    final comments = await _commentRepository.getComments(postId);
    final Set<String> likedIds = await _interactionRepository.fetchLikedCommentIds(
      postId: postId,
      uid: currentUserId,
      commentIds: comments.map((c) => c.id).toList(),
    );

    return comments
        .map((c) => c.copyWith(isLiked: likedIds.contains(c.id)))
        .toList();
  }

  Future<List<Comment>> getTopComments(String postId, {int limit = 3}) async {
    final comments =
        await _commentRepository.getTopComments(postId, limit: limit);
    final Set<String> likedIds = await _interactionRepository.fetchLikedCommentIds(
      postId: postId,
      uid: currentUserId,
      commentIds: comments.map((c) => c.id).toList(),
    );

    return comments
        .map((c) => c.copyWith(isLiked: likedIds.contains(c.id)))
        .toList();
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

  // ============================================================================
  // INTERACTION OPERATIONS - Delegate to InteractionRepository
  // ============================================================================

  Future<bool> togglePostLike({
    required String postId,
    required String uid,
  }) {
    return _interactionRepository.togglePostLike(postId: postId, uid: uid);
  }

  Future<bool> toggleCommentLike({
    required String postId,
    required String commentId,
    required String uid,
  }) {
    return _interactionRepository.toggleCommentLike(
      postId: postId,
      commentId: commentId,
      uid: uid,
    );
  }

  Future<void> toggleBookmark({
    required String uid,
    required String postId,
  }) {
    return _interactionRepository.toggleBookmark(uid: uid, postId: postId);
  }

  Future<Set<String>> fetchBookmarkedPostIds(String uid) {
    return _interactionRepository.fetchBookmarkedPostIds(uid);
  }

  Future<PaginatedQueryResult<Post>> fetchBookmarkedPosts({
    required String uid,
    int limit = 20,
    QueryDocumentSnapshotJson? startAfter,
  }) async {
    final bookmarkPage =
        await _interactionRepository.fetchBookmarkedPostIdsPage(
      uid: uid,
      limit: limit,
      startAfter: startAfter,
    );

    if (bookmarkPage.items.isEmpty) {
      return PaginatedQueryResult<Post>(
        items: const <Post>[],
        hasMore: bookmarkPage.hasMore,
        lastDocument: bookmarkPage.lastDocument,
      );
    }

    final Map<String, Post> postMap =
        await _postRepository.fetchPostsByIds(bookmarkPage.items);

    final List<Post> posts = bookmarkPage.items
        .map((id) => postMap[id])
        .whereType<Post>()
        .toList();

    final enrichedPosts = await _enrichPostsWithUserData(posts, currentUid: uid);

    return PaginatedQueryResult<Post>(
      items: enrichedPosts,
      hasMore: bookmarkPage.hasMore,
      lastDocument: bookmarkPage.lastDocument,
    );
  }

  Future<void> toggleLike(String postId) async {
    await togglePostLike(postId: postId, uid: currentUserId);
  }

  Future<void> togglePostBookmark(String postId) async {
    await toggleBookmark(uid: currentUserId, postId: postId);
  }

  Future<void> toggleCommentLikeById(String postId, String commentId) async {
    await toggleCommentLike(
      postId: postId,
      commentId: commentId,
      uid: currentUserId,
    );
  }

  // ============================================================================
  // SEARCH OPERATIONS - Delegate to SearchRepository
  // ============================================================================

  Future<CommunitySearchResults> searchCommunity({
    required String query,
    required SearchScope scope,
    int postLimit = 20,
    int commentLimit = 20,
    String? currentUid,
  }) async {
    final results = await _searchRepository.searchCommunity(
      query: query,
      scope: scope,
      postLimit: postLimit,
      commentLimit: commentLimit,
    );

    // Enrich posts with user data
    final enrichedPosts = currentUid != null
        ? await _enrichPostsWithUserData(results.posts, currentUid: currentUid)
        : results.posts;

    // Enrich comments with post data
    final commentResults = await _enrichCommentSearchResults(
      results.comments,
      currentUid: currentUid,
    );

    return CommunitySearchResults(
      posts: enrichedPosts,
      comments: commentResults,
    );
  }

  Future<List<SearchSuggestion>> topSearchSuggestions({int limit = 10}) {
    return _searchRepository.topSearchSuggestions(limit: limit);
  }

  Future<AppResult<List<String>>> autocompleteSearchTokens({
    required String prefix,
    int limit = 10,
  }) {
    return _searchRepository.autocompleteSearchTokens(
      prefix: prefix,
      limit: limit,
    );
  }

  // ============================================================================
  // REPORT & MODERATION OPERATIONS
  // ============================================================================

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

  Future<void> reportPost(String postId, String reason) async {
    await submitReport(
      targetType: ReportTargetType.post,
      targetId: postId,
      reason: reason,
      reporterUid: currentUserId,
    );
  }

  Future<void> blockUser(String userId) async {
    await _userDoc(currentUserId)
        .collection('blocked_users')
        .doc(userId)
        .set({'blockedAt': Timestamp.now()});
  }

  // ============================================================================
  // HELPER METHODS - Data enrichment
  // ============================================================================

  Future<Post> _enrichPostWithUserData(
    Post post, {
    String? currentUid,
  }) async {
    if (currentUid == null) return post;

    final likedIds = await _interactionRepository.fetchLikedPostIds(
      uid: currentUid,
      postIds: [post.id],
    );
    final bookmarkedIds = await _interactionRepository.fetchBookmarkedIds(
      uid: currentUid,
      postIds: [post.id],
    );

    Post enriched = post.copyWith(
      isLiked: likedIds.contains(post.id),
      isBookmarked: bookmarkedIds.contains(post.id),
    );

    if (enriched.topComment == null && enriched.commentCount > 0) {
      final topComment = await _commentRepository.loadTopComment(post.id);
      if (topComment != null) {
        enriched = enriched.copyWith(topComment: topComment);
      }
    }

    return enriched;
  }

  Future<List<Post>> _enrichPostsWithUserData(
    List<Post> posts, {
    String? currentUid,
  }) async {
    if (posts.isEmpty) return posts;
    if (currentUid == null) return posts;

    final postIds = posts.map((p) => p.id).toList();
    final likedIds = await _interactionRepository.fetchLikedPostIds(
      uid: currentUid,
      postIds: postIds,
    );
    final bookmarkedIds = await _interactionRepository.fetchBookmarkedIds(
      uid: currentUid,
      postIds: postIds,
    );

    final enriched = <Post>[];
    for (final post in posts) {
      Post p = post.copyWith(
        isLiked: likedIds.contains(post.id),
        isBookmarked: bookmarkedIds.contains(post.id),
      );

      if (p.topComment == null && p.commentCount > 0) {
        final topComment = await _commentRepository.loadTopComment(post.id);
        if (topComment != null) {
          p = p.copyWith(topComment: topComment);
        }
      }
      enriched.add(p);
    }

    return enriched;
  }

  Future<PaginatedQueryResult<Post>> _enrichPostPageWithUserData(
    PaginatedQueryResult<Post> page, {
    String? currentUid,
  }) async {
    final enrichedPosts = await _enrichPostsWithUserData(
      page.items,
      currentUid: currentUid,
    );

    return PaginatedQueryResult<Post>(
      items: enrichedPosts,
      hasMore: page.hasMore,
      lastDocument: page.lastDocument,
    );
  }

  Future<List<CommentSearchResult>> _enrichCommentSearchResults(
    List<CommentSearchResult> results, {
    String? currentUid,
  }) async {
    if (results.isEmpty) return results;

    final postIds = results
        .map((r) => r.comment.postId)
        .where((id) => id.isNotEmpty)
        .toSet();

    final postMap = await _postRepository.fetchPostsByIds(postIds);

    final enriched = <CommentSearchResult>[];
    for (final result in results) {
      final comment = result.comment;
      Comment enrichedComment = comment;

      if (currentUid != null) {
        final likedIds = await _interactionRepository.fetchLikedCommentIds(
          postId: comment.postId,
          uid: currentUid,
          commentIds: [comment.id],
        );
        enrichedComment =
            comment.copyWith(isLiked: likedIds.contains(comment.id));
      }

      enriched.add(CommentSearchResult(
        comment: enrichedComment,
        post: postMap[comment.postId],
      ));
    }

    return enriched;
  }
}
