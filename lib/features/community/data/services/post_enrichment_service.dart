import 'package:gong_mu_talk/core/firebase/paginated_query.dart';
import '../../domain/models/comment.dart';
import '../../domain/models/post.dart';
import '../../domain/models/search_result.dart';
import '../repositories/comment_repository.dart';
import '../repositories/interaction_repository.dart';
import '../repositories/post_repository.dart';
import 'interaction_cache_manager.dart';

/// Post Enrichment Service
///
/// Responsibilities:
/// - Enrich posts with user-specific data (likes, scraps)
/// - Add top comments to posts
/// - Enrich comment search results
/// - Coordinate with cache manager for performance
///
/// Dependencies:
/// - InteractionRepository: Fetch likes/scraps
/// - CommentRepository: Fetch top comments
/// - InteractionCacheManager: Cache management
class PostEnrichmentService {
  PostEnrichmentService({
    required InteractionRepository interactionRepository,
    required CommentRepository commentRepository,
    required PostRepository postRepository,
    required InteractionCacheManager cacheManager,
  })  : _interactionRepository = interactionRepository,
        _commentRepository = commentRepository,
        _postRepository = postRepository,
        _cacheManager = cacheManager;

  final InteractionRepository _interactionRepository;
  final CommentRepository _commentRepository;
  final PostRepository _postRepository;
  final InteractionCacheManager _cacheManager;

  /// Enrich a single post with user data
  Future<Post> enrichPost(
    Post post, {
    String? currentUid,
  }) async {
    if (currentUid == null) return post;

    final likedIds = await _interactionRepository.fetchLikedPostIds(
      uid: currentUid,
      postIds: [post.id],
    );
    final scrappedIds = await _interactionRepository.fetchScrappedIds(
      uid: currentUid,
      postIds: [post.id],
    );

    Post enriched = post.copyWith(
      isLiked: likedIds.contains(post.id),
      isScrapped: scrappedIds.contains(post.id),
    );

    if (enriched.topComment == null && enriched.commentCount > 0) {
      // Top Comment 캐시 사용
      CachedComment? topComment = _cacheManager.getTopComment(post.id);
      
      if (topComment == null) {
        topComment = await _commentRepository.loadTopComment(post.id);
        _cacheManager.updateTopCommentCache(post.id, topComment);
      }
      
      if (topComment != null) {
        enriched = enriched.copyWith(topComment: topComment);
      }
    }

    return enriched;
  }

  /// Enrich multiple posts with user data
  Future<List<Post>> enrichPosts(
    List<Post> posts, {
    String? currentUid,
  }) async {
    if (posts.isEmpty) return posts;
    if (currentUid == null) return posts;

    final postIds = posts.map((p) => p.id).toList();

    Set<String> likedIds;
    Set<String> scrappedIds;

    // 캐시 사용 (10분 유효 - 비용 최적화)
    if (_cacheManager.shouldRefreshCache() || 
        !_cacheManager.hasLikedCache(currentUid)) {
      // 캐시 갱신 필요
      likedIds = await _interactionRepository.fetchLikedPostIds(
        uid: currentUid,
        postIds: postIds,
      );
      scrappedIds = await _interactionRepository.fetchScrappedIds(
        uid: currentUid,
        postIds: postIds,
      );

      _cacheManager.updateCache(
        uid: currentUid,
        likedIds: likedIds,
        scrappedIds: scrappedIds,
      );
    } else {
      // 캐시에서 가져오기
      likedIds = _cacheManager.getLikedPostIds(currentUid, postIds) ?? {};
      scrappedIds = _cacheManager.getScrappedPostIds(currentUid, postIds) ?? {};
    }

    final enriched = <Post>[];
    for (final post in posts) {
      Post p = post.copyWith(
        isLiked: likedIds.contains(post.id),
        isScrapped: scrappedIds.contains(post.id),
      );

      if (p.topComment == null && p.commentCount > 0) {
        // Top Comment 캐시 사용
        CachedComment? topComment = _cacheManager.getTopComment(post.id);
        
        if (topComment == null) {
          topComment = await _commentRepository.loadTopComment(post.id);
          _cacheManager.updateTopCommentCache(post.id, topComment);
        }
        
        if (topComment != null) {
          p = p.copyWith(topComment: topComment);
        }
      }
      enriched.add(p);
    }

    return enriched;
  }

  /// Enrich paginated post result with user data
  Future<PaginatedQueryResult<Post>> enrichPostPage(
    PaginatedQueryResult<Post> page, {
    String? currentUid,
  }) async {
    final enrichedPosts = await enrichPosts(
      page.items,
      currentUid: currentUid,
    );

    return PaginatedQueryResult<Post>(
      items: enrichedPosts,
      hasMore: page.hasMore,
      lastDocument: page.lastDocument,
    );
  }

  /// Enrich comment search results
  Future<List<CommentSearchResult>> enrichCommentSearchResults(
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

  /// Refresh cache for specific user
  Future<void> refreshCache(String uid, List<String> postIds) async {
    if (postIds.isEmpty) return;

    final likedIds = await _interactionRepository.fetchLikedPostIds(
      uid: uid,
      postIds: postIds,
    );
    final scrappedIds = await _interactionRepository.fetchScrappedIds(
      uid: uid,
      postIds: postIds,
    );

    _cacheManager.forceUpdateCache(
      uid: uid,
      likedIds: likedIds,
      scrappedIds: scrappedIds,
    );
  }
}
