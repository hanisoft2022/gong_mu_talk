import 'package:flutter/foundation.dart';

/// Interaction Cache Manager
///
/// Responsibilities:
/// - Cache like/scrap states for posts
/// - Cache liked comments
/// - Cache top comments
/// - Track cache hit/miss statistics
/// - Optimize Firestore read costs
///
/// Cache TTL: 10 minutes
/// Cache statistics logged every 100 requests
class InteractionCacheManager {
  // Like/Scrap 캐시 (비용 최적화)
  final Map<String, Set<String>> _likedPostsCache = {};
  final Map<String, Set<String>> _scrappedPostsCache = {};
  DateTime? _lastCacheUpdate;

  // Comment Like 캐시 (추가 최적화)
  final Map<String, Map<String, Set<String>>> _likedCommentsCache = {}; // uid -> postId -> commentIds

  // Top Comment 캐시 (추가 최적화)
  final Map<String, dynamic> _topCommentsCache = {}; // postId -> CachedComment?

  // 캐시 히트율 추적 (성능 모니터링)
  int _cacheHitCount = 0;
  int _cacheMissCount = 0;

  static const Duration _cacheTTL = Duration(minutes: 10);

  /// Check if cache needs refresh
  bool shouldRefreshCache() {
    if (_lastCacheUpdate == null) return true;
    return DateTime.now().difference(_lastCacheUpdate!) > _cacheTTL;
  }

  /// Update like/scrap cache
  void updateCache({
    required String uid,
    required Set<String> likedIds,
    required Set<String> scrappedIds,
  }) {
    // 캐시 업데이트 (병합 방식)
    _likedPostsCache[uid] = {
      ...(_likedPostsCache[uid] ?? {}),
      ...likedIds,
    };
    _scrappedPostsCache[uid] = {
      ...(_scrappedPostsCache[uid] ?? {}),
      ...scrappedIds,
    };
    _lastCacheUpdate = DateTime.now();

    // 캐시 미스 기록
    _cacheMissCount++;
    debugPrint('🔄 Like/Scrap 캐시 갱신 - ${likedIds.length} likes, ${scrappedIds.length} scraps');
    _logCacheStats();
  }

  /// Get liked post IDs from cache
  Set<String>? getLikedPostIds(String uid, List<String> postIds) {
    if (!_likedPostsCache.containsKey(uid)) return null;
    
    final cached = _likedPostsCache[uid]!
        .where((id) => postIds.contains(id))
        .toSet();
    
    // 캐시 히트 기록
    _cacheHitCount++;
    debugPrint('✅ Like/Scrap 캐시 사용 - Firestore 호출 없음');
    _logCacheStats();
    
    return cached;
  }

  /// Get scrapped post IDs from cache
  Set<String>? getScrappedPostIds(String uid, List<String> postIds) {
    if (!_scrappedPostsCache.containsKey(uid)) return null;
    
    return _scrappedPostsCache[uid]!
        .where((id) => postIds.contains(id))
        .toSet();
  }

  /// Check if liked posts cache exists for user
  bool hasLikedCache(String uid) => _likedPostsCache.containsKey(uid);

  /// Update top comment cache
  void updateTopCommentCache(String postId, dynamic topComment) {
    _topCommentsCache[postId] = topComment;
    debugPrint('🔄 Top Comment 캐시 갱신 - postId: $postId');
  }

  /// Get top comment from cache
  dynamic getTopComment(String postId) {
    if (_topCommentsCache.containsKey(postId)) {
      debugPrint('✅ Top Comment 캐시 사용 - postId: $postId');
      return _topCommentsCache[postId];
    }
    return null;
  }

  /// Like/Scrap 캐시 초기화 (로그아웃 시 호출)
  void clearInteractionCache({String? uid}) {
    if (uid != null) {
      _likedPostsCache.remove(uid);
      _scrappedPostsCache.remove(uid);
      _likedCommentsCache.remove(uid);
      debugPrint('🗑️  Like/Scrap/Comment 캐시 삭제 - uid: $uid');
    } else {
      _likedPostsCache.clear();
      _scrappedPostsCache.clear();
      _likedCommentsCache.clear();
      _topCommentsCache.clear();
      _lastCacheUpdate = null;
      debugPrint('🗑️  모든 캐시 삭제 (Like/Scrap/Comment/TopComment)');
    }
  }

  /// 특정 사용자의 캐시 강제 갱신
  void forceUpdateCache({
    required String uid,
    required Set<String> likedIds,
    required Set<String> scrappedIds,
  }) {
    _likedPostsCache[uid] = likedIds;
    _scrappedPostsCache[uid] = scrappedIds;
    _lastCacheUpdate = DateTime.now();

    debugPrint('🔄 Like/Scrap 캐시 강제 갱신 - ${likedIds.length} likes, ${scrappedIds.length} scraps');
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
      debugPrint('   - 절감 비용: ${calculateSavedCost()} Firestore reads');
    }
  }

  /// 캐시로 절감한 Firestore read 횟수 계산
  int calculateSavedCost() {
    // 각 캐시 히트는 2번의 Firestore read를 절약 (likes + scraps)
    return _cacheHitCount * 2;
  }

  /// 캐시 통계 초기화 (테스트용)
  void resetCacheStats() {
    _cacheHitCount = 0;
    _cacheMissCount = 0;
    debugPrint('📊 캐시 통계 초기화');
  }

  /// Get cache statistics
  Map<String, int> getCacheStats() {
    return {
      'hitCount': _cacheHitCount,
      'missCount': _cacheMissCount,
      'savedCost': calculateSavedCost(),
    };
  }
}
