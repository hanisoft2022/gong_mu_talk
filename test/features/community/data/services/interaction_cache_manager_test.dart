import 'package:flutter_test/flutter_test.dart';
import 'package:gong_mu_talk/features/community/data/services/interaction_cache_manager.dart';

void main() {
  group('InteractionCacheManager', () {
    late InteractionCacheManager cacheManager;

    setUp(() {
      cacheManager = InteractionCacheManager();
    });

    group('Cache TTL and Refresh', () {
      test('should require refresh when cache is empty', () {
        expect(cacheManager.shouldRefreshCache(), isTrue);
      });

      test('should not require refresh immediately after update', () {
        cacheManager.updateCache(
          uid: 'user1',
          likedIds: {'post1', 'post2'},
          scrappedIds: {'post3'},
        );

        expect(cacheManager.shouldRefreshCache(), isFalse);
      });

      test('should have liked cache after update', () {
        cacheManager.updateCache(
          uid: 'user1',
          likedIds: {'post1', 'post2'},
          scrappedIds: {'post3'},
        );

        expect(cacheManager.hasLikedCache('user1'), isTrue);
        expect(cacheManager.hasLikedCache('user2'), isFalse);
      });
    });

    group('Liked Posts Cache', () {
      test('should return null when no cache exists', () {
        final result = cacheManager.getLikedPostIds('user1', ['post1', 'post2']);
        expect(result, isNull);
      });

      test('should return cached liked post IDs', () {
        cacheManager.updateCache(
          uid: 'user1',
          likedIds: {'post1', 'post2', 'post3'},
          scrappedIds: {},
        );

        final result = cacheManager.getLikedPostIds('user1', ['post1', 'post2', 'post4']);
        expect(result, {'post1', 'post2'});
      });

      test('should merge liked IDs when updating cache', () {
        cacheManager.updateCache(
          uid: 'user1',
          likedIds: {'post1', 'post2'},
          scrappedIds: {},
        );

        cacheManager.updateCache(
          uid: 'user1',
          likedIds: {'post3', 'post4'},
          scrappedIds: {},
        );

        final result = cacheManager.getLikedPostIds('user1', ['post1', 'post2', 'post3', 'post4']);
        expect(result, {'post1', 'post2', 'post3', 'post4'});
      });
    });

    group('Scrapped Posts Cache', () {
      test('should return null when no cache exists', () {
        final result = cacheManager.getScrappedPostIds('user1', ['post1']);
        expect(result, isNull);
      });

      test('should return cached scrapped post IDs', () {
        cacheManager.updateCache(
          uid: 'user1',
          likedIds: {},
          scrappedIds: {'post1', 'post3'},
        );

        final result = cacheManager.getScrappedPostIds('user1', ['post1', 'post2', 'post3']);
        expect(result, {'post1', 'post3'});
      });
    });

    group('Top Comment Cache', () {
      test('should return null when no top comment cached', () {
        final result = cacheManager.getTopComment('post1');
        expect(result, isNull);
      });

      test('should cache and retrieve top comment', () {
        final mockComment = {'id': 'comment1', 'text': 'Great post!'};
        
        cacheManager.updateTopCommentCache('post1', mockComment);
        
        final result = cacheManager.getTopComment('post1');
        expect(result, mockComment);
      });

      test('should handle null top comment', () {
        cacheManager.updateTopCommentCache('post1', null);
        
        final result = cacheManager.getTopComment('post1');
        expect(result, isNull);
      });
    });

    group('Cache Statistics', () {
      test('should track cache hit and miss', () {
        // First access - cache miss
        cacheManager.updateCache(
          uid: 'user1',
          likedIds: {'post1'},
          scrappedIds: {},
        );

        // Second access - cache hit
        cacheManager.getLikedPostIds('user1', ['post1']);

        final stats = cacheManager.getCacheStats();
        expect(stats['hitCount'], 1);
        expect(stats['missCount'], 1);
      });

      test('should calculate saved cost correctly', () {
        // 1 cache hit = 2 Firestore reads saved
        cacheManager.updateCache(uid: 'user1', likedIds: {}, scrappedIds: {});
        cacheManager.getLikedPostIds('user1', []);
        cacheManager.getLikedPostIds('user1', []);

        final stats = cacheManager.getCacheStats();
        expect(stats['savedCost'], 4); // 2 hits * 2 reads each
      });

      test('should reset statistics', () {
        cacheManager.updateCache(uid: 'user1', likedIds: {}, scrappedIds: {});
        cacheManager.getLikedPostIds('user1', []);

        cacheManager.resetCacheStats();

        final stats = cacheManager.getCacheStats();
        expect(stats['hitCount'], 0);
        expect(stats['missCount'], 0);
        expect(stats['savedCost'], 0);
      });
    });

    group('Cache Clearing', () {
      test('should clear cache for specific user', () {
        cacheManager.updateCache(
          uid: 'user1',
          likedIds: {'post1'},
          scrappedIds: {'post2'},
        );
        cacheManager.updateCache(
          uid: 'user2',
          likedIds: {'post3'},
          scrappedIds: {'post4'},
        );

        cacheManager.clearInteractionCache(uid: 'user1');

        expect(cacheManager.hasLikedCache('user1'), isFalse);
        expect(cacheManager.hasLikedCache('user2'), isTrue);
      });

      test('should clear all caches when uid is null', () {
        cacheManager.updateCache(
          uid: 'user1',
          likedIds: {'post1'},
          scrappedIds: {},
        );
        cacheManager.updateTopCommentCache('post1', {'id': 'comment1'});

        cacheManager.clearInteractionCache();

        expect(cacheManager.hasLikedCache('user1'), isFalse);
        expect(cacheManager.getTopComment('post1'), isNull);
      });
    });

    group('Force Update Cache', () {
      test('should replace existing cache', () {
        cacheManager.updateCache(
          uid: 'user1',
          likedIds: {'post1', 'post2'},
          scrappedIds: {'post3'},
        );

        cacheManager.forceUpdateCache(
          uid: 'user1',
          likedIds: {'post4'},
          scrappedIds: {'post5'},
        );

        final liked = cacheManager.getLikedPostIds('user1', ['post1', 'post2', 'post4']);
        final scrapped = cacheManager.getScrappedPostIds('user1', ['post3', 'post5']);

        expect(liked, {'post4'});
        expect(scrapped, {'post5'});
      });
    });
  });
}
