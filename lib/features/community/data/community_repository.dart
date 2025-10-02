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
import '../../auth/presentation/cubit/auth_cubit.dart';
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
    required AuthCubit authCubit,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _userSession = userSession,
        _userProfileRepository = userProfileRepository,
        _notificationRepository = notificationRepository,
        _authCubit = authCubit {
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

    // AuthCubit 상태 변화 구독 (로그아웃 시 캐시 클리어)
    _authSubscription = _authCubit.stream.listen(_handleAuthStateChanged);
  }

  StreamSubscription<AuthState>? _authSubscription;

  void _handleAuthStateChanged(AuthState state) {
    // 로그아웃 감지 (userId가 null이 됨)
    if (state.userId == null) {
      clearInteractionCache();
      resetCacheStats();
      debugPrint('🔓 로그아웃 감지 - 모든 캐시 및 통계 삭제');
    }
  }

  void dispose() {
    _authSubscription?.cancel();
  }

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final UserSession _userSession;
  final UserProfileRepository _userProfileRepository;
  final NotificationRepository _notificationRepository;
  final AuthCubit _authCubit;

  // Like/Bookmark 캐시 (비용 최적화)
  final Map<String, Set<String>> _likedPostsCache = {};
  final Map<String, Set<String>> _bookmarkedPostsCache = {};
  DateTime? _lastCacheUpdate;

  // Comment Like 캐시 (추가 최적화)
  final Map<String, Map<String, Set<String>>> _likedCommentsCache = {}; // uid -> postId -> commentIds

  // Top Comment 캐시 (추가 최적화)
  final Map<String, CachedComment?> _topCommentsCache = {}; // postId -> topComment

  // 캐시 히트율 추적 (성능 모니터링)
  int _cacheHitCount = 0;
  int _cacheMissCount = 0;

  // 검색 Rate Limiting (비용 최적화)
  DateTime? _lastSearchTime;
  static const Duration _searchCooldown = Duration(seconds: 2);

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

    // Comment Like 캐시 사용
    final commentIds = result.items.map((c) => c.id).toList();
    Set<String> likedIds;

    // 캐시 확인
    if (_likedCommentsCache.containsKey(currentUid) &&
        _likedCommentsCache[currentUid]!.containsKey(postId)) {
      // 캐시에서 가져오기
      likedIds = _likedCommentsCache[currentUid]![postId]!
          .where((id) => commentIds.contains(id))
          .toSet();
      debugPrint('✅ Comment Like 캐시 사용 - postId: $postId');
    } else {
      // Firestore에서 조회
      likedIds = await _interactionRepository.fetchLikedCommentIds(
        postId: postId,
        uid: currentUid,
        commentIds: commentIds,
      );

      // 캐시 업데이트
      _likedCommentsCache.putIfAbsent(currentUid, () => {});
      _likedCommentsCache[currentUid]![postId] = likedIds;
      debugPrint('🔄 Comment Like 캐시 갱신 - postId: $postId, ${likedIds.length} likes');
    }

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
  }) async {
    final comment = await _commentRepository.createComment(
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
    
    // Top Comment 캐시 무효화 (새 댓글이 top이 될 수 있음)
    _topCommentsCache.remove(postId);
    debugPrint('🗑️  Top Comment 캐시 무효화 - postId: $postId (새 댓글 생성)');
    
    return comment;
  }

  Future<void> deleteComment({
    required String postId,
    required String commentId,
    required String requesterUid,
  }) async {
    await _commentRepository.deleteComment(
      postId: postId,
      commentId: commentId,
      requesterUid: requesterUid,
    );
    
    // Top Comment 캐시 무효화 (top comment가 삭제되었을 수 있음)
    _topCommentsCache.remove(postId);
    debugPrint('🗑️  Top Comment 캐시 무효화 - postId: $postId (댓글 삭제)');
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
  }) async {
    final liked = await _interactionRepository.togglePostLike(postId: postId, uid: uid);
    
    // 캐시 즉시 업데이트
    if (_likedPostsCache.containsKey(uid)) {
      if (liked) {
        _likedPostsCache[uid]!.add(postId);
      } else {
        _likedPostsCache[uid]!.remove(postId);
      }
      debugPrint('💾 Like 캐시 업데이트 - postId: $postId, liked: $liked');
    }
    
    return liked;
  }

  Future<bool> toggleCommentLike({
    required String postId,
    required String commentId,
    required String uid,
  }) async {
    final liked = await _interactionRepository.toggleCommentLike(
      postId: postId,
      commentId: commentId,
      uid: uid,
    );

    // Comment Like 캐시 즉시 업데이트
    if (_likedCommentsCache.containsKey(uid) &&
        _likedCommentsCache[uid]!.containsKey(postId)) {
      if (liked) {
        _likedCommentsCache[uid]![postId]!.add(commentId);
      } else {
        _likedCommentsCache[uid]![postId]!.remove(commentId);
      }
      debugPrint('💾 Comment Like 캐시 업데이트 - commentId: $commentId, liked: $liked');
    }

    return liked;
  }

  Future<void> toggleBookmark({
    required String uid,
    required String postId,
  }) async {
    await _interactionRepository.toggleBookmark(uid: uid, postId: postId);
    
    // 캐시 즉시 업데이트 (토글이므로 존재 여부 확인)
    if (_bookmarkedPostsCache.containsKey(uid)) {
      if (_bookmarkedPostsCache[uid]!.contains(postId)) {
        _bookmarkedPostsCache[uid]!.remove(postId);
        debugPrint('💾 Bookmark 캐시 업데이트 - postId: $postId, bookmarked: false');
      } else {
        _bookmarkedPostsCache[uid]!.add(postId);
        debugPrint('💾 Bookmark 캐시 업데이트 - postId: $postId, bookmarked: true');
      }
    }
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
  // CACHE MANAGEMENT - Performance optimization
  // ============================================================================

  /// Like/Bookmark 캐시 초기화 (로그아웃 시 호출)
  void clearInteractionCache({String? uid}) {
    if (uid != null) {
      _likedPostsCache.remove(uid);
      _bookmarkedPostsCache.remove(uid);
      _likedCommentsCache.remove(uid);
      debugPrint('🗑️  Like/Bookmark/Comment 캐시 삭제 - uid: $uid');
    } else {
      _likedPostsCache.clear();
      _bookmarkedPostsCache.clear();
      _likedCommentsCache.clear();
      _topCommentsCache.clear();
      _lastCacheUpdate = null;
      debugPrint('🗑️  모든 캐시 삭제 (Like/Bookmark/Comment/TopComment)');
    }
  }

  /// 특정 사용자의 캐시 강제 갱신
  Future<void> refreshInteractionCache(String uid, List<String> postIds) async {
    if (postIds.isEmpty) return;

    final likedIds = await _interactionRepository.fetchLikedPostIds(
      uid: uid,
      postIds: postIds,
    );
    final bookmarkedIds = await _interactionRepository.fetchBookmarkedIds(
      uid: uid,
      postIds: postIds,
    );

    _likedPostsCache[uid] = likedIds;
    _bookmarkedPostsCache[uid] = bookmarkedIds;
    _lastCacheUpdate = DateTime.now();

    debugPrint('🔄 Like/Bookmark 캐시 강제 갱신 - ${likedIds.length} likes, ${bookmarkedIds.length} bookmarks');
  }

  /// 캐시 히트율 통계 로깅
  void _logCacheStats() {
    final totalRequests = _cacheHitCount + _cacheMissCount;
    if (totalRequests == 0) return;

    final hitRate = (_cacheHitCount / totalRequests * 100).toStringAsFixed(1);
    debugPrint('📊 캐시 히트율: $hitRate% (히트: $_cacheHitCount, 미스: $_cacheMissCount)');

    // 100회마다 상세 통계 출력
    if (totalRequests % 100 == 0) {
      debugPrint('📈 누적 통계 ($totalRequests 요청)');
      debugPrint('   - 캐시 히트: $_cacheHitCount회');
      debugPrint('   - 캐시 미스: $_cacheMissCount회');
      debugPrint('   - 절감 비용: ${_calculateSavedCost()} Firestore reads');
    }
  }

  /// 캐시로 절감한 Firestore read 횟수 계산
  int _calculateSavedCost() {
    // 각 캐시 히트는 2번의 Firestore read를 절약 (likes + bookmarks)
    return _cacheHitCount * 2;
  }

  /// 캐시 통계 초기화 (테스트용)
  void resetCacheStats() {
    _cacheHitCount = 0;
    _cacheMissCount = 0;
    debugPrint('📊 캐시 통계 초기화');
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
    // Rate Limiting: 2초 이내 재검색 방지
    final now = DateTime.now();
    if (_lastSearchTime != null && now.difference(_lastSearchTime!) < _searchCooldown) {
      debugPrint('⚠️  검색 Rate Limit - ${_searchCooldown.inSeconds}초 대기 필요');
      return const CommunitySearchResults();
    }
    _lastSearchTime = now;
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
      // Top Comment 캐시 사용
      CachedComment? topComment;
      
      if (_topCommentsCache.containsKey(post.id)) {
        topComment = _topCommentsCache[post.id];
        debugPrint('✅ Top Comment 캐시 사용 - postId: ${post.id}');
      } else {
        topComment = await _commentRepository.loadTopComment(post.id);
        _topCommentsCache[post.id] = topComment;
        debugPrint('🔄 Top Comment 캐시 갱신 - postId: ${post.id}');
      }
      
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

    // 캐시 사용 (10분 유효 - 비용 최적화)
    final now = DateTime.now();
    final shouldRefreshCache = _lastCacheUpdate == null ||
        now.difference(_lastCacheUpdate!) > const Duration(minutes: 10);

    Set<String> likedIds;
    Set<String> bookmarkedIds;

    if (shouldRefreshCache || !_likedPostsCache.containsKey(currentUid)) {
      // 캐시 갱신 필요
      likedIds = await _interactionRepository.fetchLikedPostIds(
        uid: currentUid,
        postIds: postIds,
      );
      bookmarkedIds = await _interactionRepository.fetchBookmarkedIds(
        uid: currentUid,
        postIds: postIds,
      );

      // 캐시 업데이트 (병합 방식)
      _likedPostsCache[currentUid] = {
        ...(_likedPostsCache[currentUid] ?? {}),
        ...likedIds,
      };
      _bookmarkedPostsCache[currentUid] = {
        ...(_bookmarkedPostsCache[currentUid] ?? {}),
        ...bookmarkedIds,
      };
      _lastCacheUpdate = now;

      // 캐시 미스 기록
      _cacheMissCount++;
      debugPrint('🔄 Like/Bookmark 캐시 갱신 - ${likedIds.length} likes, ${bookmarkedIds.length} bookmarks');
      _logCacheStats();
    } else {
      // 캐시에서 가져오기
      likedIds = _likedPostsCache[currentUid]!
          .where((id) => postIds.contains(id))
          .toSet();
      bookmarkedIds = _bookmarkedPostsCache[currentUid]!
          .where((id) => postIds.contains(id))
          .toSet();

      // 캐시 히트 기록
      _cacheHitCount++;
      debugPrint('✅ Like/Bookmark 캐시 사용 - Firestore 호출 없음');
      _logCacheStats();
    }

    final enriched = <Post>[];
    for (final post in posts) {
      Post p = post.copyWith(
        isLiked: likedIds.contains(post.id),
        isBookmarked: bookmarkedIds.contains(post.id),
      );

      if (p.topComment == null && p.commentCount > 0) {
        // Top Comment 캐시 사용
        CachedComment? topComment;
        
        if (_topCommentsCache.containsKey(post.id)) {
          topComment = _topCommentsCache[post.id];
        } else {
          topComment = await _commentRepository.loadTopComment(post.id);
          _topCommentsCache[post.id] = topComment;
        }
        
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
