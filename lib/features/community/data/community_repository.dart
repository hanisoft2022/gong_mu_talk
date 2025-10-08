import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../../../core/firebase/paginated_query.dart';
import '../../../core/utils/result.dart';
import '../../profile/domain/career_track.dart';
import '../domain/models/comment.dart';
import '../domain/models/comment_with_post.dart';
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
import 'repositories/report_repository.dart';
import 'services/interaction_cache_manager.dart';
import 'services/post_enrichment_service.dart';

typedef JsonMap = Map<String, Object?>;
typedef QueryJson = Query<JsonMap>;
typedef DocSnapshotJson = DocumentSnapshot<JsonMap>;

/// Community Repository - Main facade for community features
///
/// Responsibilities:
/// - Coordinate between specialized repositories
/// - Provide unified API for community operations
/// - Handle reports and moderation
/// - Enrich data with user-specific information (likes, scraps, top comments)
///
/// This repository acts as a facade pattern, delegating to:
/// - PostRepository: Post CRUD and feeds
/// - CommentRepository: Comment operations
/// - InteractionRepository: Likes and scraps
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
    required AuthCubit authCubit,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance,
       _userSession = userSession,
       _userProfileRepository = userProfileRepository,
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
    );
    _interactionRepository = InteractionRepository(
      firestore: _firestore,
      userProfileRepository: _userProfileRepository,
    );
    _searchRepository = SearchRepository(firestore: _firestore);
    _loungeRepository = LoungeRepository(firestore: _firestore);
    _reportRepository = ReportRepository(firestore: _firestore);

    // Initialize cache and enrichment services
    _cacheManager = InteractionCacheManager();
    _enrichmentService = PostEnrichmentService(
      interactionRepository: _interactionRepository,
      commentRepository: _commentRepository,
      postRepository: _postRepository,
      cacheManager: _cacheManager,
    );

    // AuthCubit 상태 변화 구독 (로그아웃 시 캐시 클리어)
    _authSubscription = _authCubit.stream.listen(_handleAuthStateChanged);
  }

  StreamSubscription<AuthState>? _authSubscription;

  void _handleAuthStateChanged(AuthState state) {
    // 로그아웃 감지 (userId가 null이 됨)
    if (state.userId == null) {
      _cacheManager.clearInteractionCache();
      _cacheManager.resetCacheStats();
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
  final AuthCubit _authCubit;

  // 검색 Rate Limiting (비용 최적화)
  DateTime? _lastSearchTime;
  static const Duration _searchCooldown = Duration(seconds: 2);

  // Specialized repositories and services
  late final PostRepository _postRepository;
  late final CommentRepository _commentRepository;
  late final InteractionRepository _interactionRepository;
  late final SearchRepository _searchRepository;
  late final LoungeRepository _loungeRepository;
  late final ReportRepository _reportRepository;

  // Cache and enrichment services
  late final InteractionCacheManager _cacheManager;
  late final PostEnrichmentService _enrichmentService;

  // Legacy cache variables (TODO: migrate to services)
  final Map<String, Map<String, Set<String>>> _likedCommentsCache = {};
  final Map<String, List<Comment>> _topCommentsCache = {};

  String get currentUserId => _userSession.userId;

  Future<String> get currentUserNickname async {
    final profile = await _userProfileRepository.fetchProfile(currentUserId);
    return profile?.nickname ?? 'Unknown User';
  }

  // Removed - delegated to ReportRepository

  // ============================================================================
  // POST OPERATIONS - Delegate to PostRepository
  // ============================================================================

  Future<Post> createPost({
    String? postId,
    required PostType type,
    required String authorUid,
    required String authorNickname,
    required CareerTrack authorTrack,
    String? authorSpecificCareer,
    bool authorSerialVisible = true,
    int authorSupporterLevel = 0,
    bool authorIsSupporter = false,
    required String text,
    required PostAudience audience,
    required String serial,
    List<PostMedia> media = const <PostMedia>[],
    List<String> tags = const <String>[],
    bool awardPoints = true,
  }) {
    return _postRepository.createPost(
      postId: postId,
      type: type,
      authorUid: authorUid,
      authorNickname: authorNickname,
      authorTrack: authorTrack,
      authorSpecificCareer: authorSpecificCareer,
      authorSerialVisible: authorSerialVisible,
      authorSupporterLevel: authorSupporterLevel,
      authorIsSupporter: authorIsSupporter,
      text: text,
      audience: audience,
      serial: serial,
      media: media,
      tags: tags,
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

  Future<void> deletePost({required String postId, required String authorUid}) {
    return _postRepository.deletePost(postId: postId, authorUid: authorUid);
  }

  Future<Post?> fetchPostById(String postId, {String? currentUid}) async {
    final Post? post = await _postRepository.fetchPostById(postId);
    if (post == null) return null;

    return _enrichmentService.enrichPost(post, currentUid: currentUid);
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
    return _enrichmentService.enrichPostPage(result, currentUid: currentUid);
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
    return _enrichmentService.enrichPostPage(result, currentUid: currentUid);
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
    return _enrichmentService.enrichPostPage(result, currentUid: currentUid);
  }

  Future<PostMedia> uploadPostImage({
    required String uid,
    required String postId,
    required String fileName,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
    int? width,
    int? height,
  }) {
    return _postRepository.uploadPostImage(
      uid: uid,
      postId: postId,
      fileName: fileName,
      bytes: bytes,
      contentType: contentType,
      width: width,
      height: height,
    );
  }

  /// Generate a new post ID without creating the document
  String generatePostId() {
    return _postRepository.generatePostId();
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
    return _enrichmentService.enrichPostPage(result, currentUid: currentUid);
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
    return _enrichmentService.enrichPostPage(result, currentUid: currentUid);
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
      debugPrint(
        '🔄 Comment Like 캐시 갱신 - postId: $postId, ${likedIds.length} likes',
      );
    }

    final enrichedComments = result.items
        .map(
          (comment) => comment.copyWith(isLiked: likedIds.contains(comment.id)),
        )
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
    String? authorSpecificCareer,
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
      authorSpecificCareer: authorSpecificCareer,
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

  /// Undo comment deletion (restore)
  Future<void> undoDeleteComment({
    required String postId,
    required String commentId,
    required String requesterUid,
    required String originalText,
  }) async {
    await _commentRepository.undoDeleteComment(
      postId: postId,
      commentId: commentId,
      requesterUid: requesterUid,
      originalText: originalText,
    );

    // Top Comment 캐시 무효화 (복구된 댓글이 top이 될 수 있음)
    _topCommentsCache.remove(postId);
    debugPrint('🔄 Top Comment 캐시 무효화 - postId: $postId (댓글 복구)');
  }

  Future<List<Comment>> getComments(String postId) async {
    final comments = await _commentRepository.getComments(postId);
    final Set<String> likedIds = await _interactionRepository
        .fetchLikedCommentIds(
          postId: postId,
          uid: currentUserId,
          commentIds: comments.map((c) => c.id).toList(),
        );

    return comments
        .map((c) => c.copyWith(isLiked: likedIds.contains(c.id)))
        .toList();
  }

  Future<List<Comment>> getTopComments(String postId, {int limit = 3}) async {
    final comments = await _commentRepository.getTopComments(
      postId,
      limit: limit,
    );
    final Set<String> likedIds = await _interactionRepository
        .fetchLikedCommentIds(
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
    final String? specificCareer = _userSession.specificCareer;
    final int supporterLevel = _userSession.supporterLevel;
    final bool serialVisible = _userSession.serialVisible;
    await createComment(
      postId: postId,
      authorUid: currentUserId,
      authorNickname: nickname,
      text: text,
      parentCommentId: parentCommentId,
      authorTrack: track,
      authorSpecificCareer: specificCareer,
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
    final liked = await _interactionRepository.togglePostLike(
      postId: postId,
      uid: uid,
    );

    // Update InteractionCacheManager (used by PostEnrichmentService)
    _cacheManager.toggleLikeInCache(uid: uid, postId: postId);
    debugPrint('💾 InteractionCacheManager Like 업데이트 - postId: $postId, liked: $liked');

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
      debugPrint(
        '💾 Comment Like 캐시 업데이트 - commentId: $commentId, liked: $liked',
      );
    }

    return liked;
  }

  Future<void> toggleScrap({
    required String uid,
    required String postId,
  }) async {
    await _interactionRepository.toggleScrap(uid: uid, postId: postId);

    // Update cache using InteractionCacheManager
    _cacheManager.toggleScrapInCache(uid: uid, postId: postId);
  }

  Future<Set<String>> fetchScrappedPostIds(String uid) {
    return _interactionRepository.fetchScrappedPostIds(uid);
  }

  Future<PaginatedQueryResult<Post>> fetchScrappedPosts({
    required String uid,
    int limit = 20,
    QueryDocumentSnapshotJson? startAfter,
  }) async {
    final scrapPage = await _interactionRepository.fetchScrappedPostIdsPage(
      uid: uid,
      limit: limit,
      startAfter: startAfter,
    );

    if (scrapPage.items.isEmpty) {
      return PaginatedQueryResult<Post>(
        items: const <Post>[],
        hasMore: scrapPage.hasMore,
        lastDocument: scrapPage.lastDocument,
      );
    }

    final Map<String, Post> postMap = await _postRepository.fetchPostsByIds(
      scrapPage.items,
    );

    final List<Post> posts = scrapPage.items
        .map((id) => postMap[id])
        .whereType<Post>()
        .toList();

    final enrichedPosts = await _enrichmentService.enrichPosts(
      posts,
      currentUid: uid,
    );

    return PaginatedQueryResult<Post>(
      items: enrichedPosts,
      hasMore: scrapPage.hasMore,
      lastDocument: scrapPage.lastDocument,
    );
  }

  Future<PaginatedQueryResult<Post>> fetchLikedPosts({
    required String uid,
    int limit = 20,
    QueryDocumentSnapshotJson? startAfter,
  }) async {
    final likePage = await _interactionRepository.fetchLikedPostIdsPage(
      uid: uid,
      limit: limit,
      startAfter: startAfter,
    );

    if (likePage.items.isEmpty) {
      return PaginatedQueryResult<Post>(
        items: const <Post>[],
        hasMore: likePage.hasMore,
        lastDocument: likePage.lastDocument,
      );
    }

    final Map<String, Post> postMap = await _postRepository.fetchPostsByIds(
      likePage.items,
    );

    final List<Post> posts = likePage.items
        .map((id) => postMap[id])
        .whereType<Post>()
        .toList();

    final enrichedPosts = await _enrichmentService.enrichPosts(
      posts,
      currentUid: uid,
    );

    return PaginatedQueryResult<Post>(
      items: enrichedPosts,
      hasMore: likePage.hasMore,
      lastDocument: likePage.lastDocument,
    );
  }

  Future<PaginatedQueryResult<CommentWithPost>> fetchUserComments({
    required String authorUid,
    int limit = 20,
    QueryDocumentSnapshot<JsonMap>? startAfter,
  }) async {
    final commentPage = await _commentRepository.fetchCommentsByAuthor(
      authorUid: authorUid,
      limit: limit,
      startAfter: startAfter,
    );

    if (commentPage.items.isEmpty) {
      return PaginatedQueryResult<CommentWithPost>(
        items: const <CommentWithPost>[],
        hasMore: commentPage.hasMore,
        lastDocument: commentPage.lastDocument,
      );
    }

    // Extract unique postIds from comments
    final Set<String> postIds = commentPage.items
        .map((comment) => comment.postId)
        .toSet();

    // Fetch posts by IDs
    final Map<String, Post> postMap = await _postRepository.fetchPostsByIds(
      postIds.toList(),
    );

    // Map comments to CommentWithPost objects
    final List<CommentWithPost> commentsWithPosts = commentPage.items
        .map((comment) {
          final post = postMap[comment.postId];
          if (post == null) {
            // Post might be deleted, skip this comment
            return null;
          }

          return CommentWithPost(
            comment: comment,
            postId: post.id,
            postText: post.text,
            postAuthorNickname: post.authorNickname,
          );
        })
        .whereType<CommentWithPost>()
        .toList();

    return PaginatedQueryResult<CommentWithPost>(
      items: commentsWithPosts,
      hasMore: commentPage.hasMore,
      lastDocument: commentPage.lastDocument,
    );
  }

  Future<void> toggleLike(String postId) async {
    await togglePostLike(postId: postId, uid: currentUserId);
  }

  Future<void> togglePostScrap(String postId) async {
    await toggleScrap(uid: currentUserId, postId: postId);
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
    int userLimit = 20,
    String? currentUid,
  }) async {
    // Rate Limiting: 2초 이내 재검색 방지
    final now = DateTime.now();
    if (_lastSearchTime != null &&
        now.difference(_lastSearchTime!) < _searchCooldown) {
      debugPrint('⚠️  검색 Rate Limit - ${_searchCooldown.inSeconds}초 대기 필요');
      return const CommunitySearchResults();
    }
    _lastSearchTime = now;
    final results = await _searchRepository.searchCommunity(
      query: query,
      scope: scope,
      postLimit: postLimit,
      commentLimit: commentLimit,
      userLimit: userLimit,
    );

    // Enrich posts with user data
    final enrichedPosts = currentUid != null
        ? await _enrichmentService.enrichPosts(
            results.posts,
            currentUid: currentUid,
          )
        : results.posts;

    // Enrich comments with post data
    final commentResults = await _enrichmentService.enrichCommentSearchResults(
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
  }) {
    return _reportRepository.submitReport(
      targetType: targetType,
      targetId: targetId,
      reason: reason,
      reporterUid: reporterUid,
      metadata: metadata,
    );
  }

  Future<void> reportPost(String postId, String reason) {
    return _reportRepository.reportPost(
      postId: postId,
      reason: reason,
      reporterUid: currentUserId,
    );
  }

  Future<void> blockUser(String userId) {
    return _reportRepository.blockUser(
      userId: userId,
      blockerUid: currentUserId,
    );
  }

  Future<void> unblockUser(String userId) {
    return _reportRepository.unblockUser(
      userId: userId,
      blockerUid: currentUserId,
    );
  }

  Future<Set<String>> getBlockedUserIds(String uid) {
    return _reportRepository.getBlockedUserIds(uid);
  }

  // ============================================================================
  // CACHE MANAGEMENT - Delegate to services
  // ============================================================================

  /// Clear interaction cache (called on logout)
  void clearInteractionCache({String? uid}) {
    _cacheManager.clearInteractionCache(uid: uid);
  }

  /// Refresh interaction cache for user
  Future<void> refreshInteractionCache(String uid, List<String> postIds) {
    return _enrichmentService.refreshCache(uid, postIds);
  }

  /// Reset cache statistics
  void resetCacheStats() {
    _cacheManager.resetCacheStats();
  }

  /// Get cache statistics
  Map<String, int> getCacheStats() {
    return _cacheManager.getCacheStats();
  }

  /// Get scrapped post IDs from cache (no network call)
  Set<String>? getCachedScrappedIds(String uid, List<String> postIds) {
    return _cacheManager.getScrappedPostIds(uid, postIds);
  }

  /// Get liked post IDs from cache (no network call)
  Set<String>? getCachedLikedIds(String uid, List<String> postIds) {
    return _cacheManager.getLikedPostIds(uid, postIds);
  }
}
