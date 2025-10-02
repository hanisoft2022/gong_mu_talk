import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/firebase/paginated_query.dart';
import '../../../../core/firebase/firestore_refs.dart';
import '../../domain/models/feed_filters.dart';
import '../../domain/models/post.dart';

typedef JsonMap = Map<String, Object?>;
typedef QueryJson = Query<JsonMap>;

/// Lounge Repository - Manages lounge feeds and boards
///
/// Responsibilities:
/// - Fetch lounge feeds with scope and sort filtering
/// - Fetch serial-specific feeds
/// - Apply lounge sorting (latest, popular, likes)
/// - Manage board data (fetch, watch)
///
/// Dependencies: FirebaseFirestore
class LoungeRepository {
  LoungeRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const Duration _dailyLookback = Duration(hours: 24);
  static const Duration _weeklyLookback = Duration(days: 7);

  CollectionReference<JsonMap> get _postsRef => _firestore.collection(Fs.posts);

  Future<PaginatedQueryResult<Post>> fetchLoungeFeed({
    required LoungeScope scope,
    required LoungeSort sort,
    int limit = 20,
    QueryDocumentSnapshotJson? startAfter,
    String? serial,
  }) async {
    try {
      QueryJson query = _postsRef
          .where('type', isEqualTo: PostType.chirp.name)
          .where('visibility', isEqualTo: PostVisibility.public.name);

      // 라운지별 필터링 (동적 라운지 시스템)
      // 전체 라운지(all)도 serial == 'all'인 글만 표시
      query = query.where('serial', isEqualTo: scope.loungeId);

      query = _applyLoungeSort(query, sort);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final QuerySnapshot<JsonMap> snapshot = await query.limit(limit).get();
      return _buildPostPage(snapshot, limit: limit);
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
      return _buildPostPage(snapshot, limit: limit);
    } catch (e) {
      debugPrint('Error fetching serial feed: $e');
      return const PaginatedQueryResult<Post>(
        items: <Post>[],
        hasMore: false,
        lastDocument: null,
      );
    }
  }

  

  

  QueryJson _applyLoungeSort(QueryJson query, LoungeSort sort) {
    switch (sort) {
      case LoungeSort.latest:
        return query.orderBy('createdAt', descending: true);
      case LoungeSort.dailyPopular:
        final Timestamp dailySince = _dailyPopularCutoffTimestamp();
        return query
            .where('createdAt', isGreaterThanOrEqualTo: dailySince)
            .orderBy('hotScore', descending: true);
      case LoungeSort.weeklyPopular:
        final Timestamp weeklySince = _weeklyPopularCutoffTimestamp();
        return query
            .where('createdAt', isGreaterThanOrEqualTo: weeklySince)
            .orderBy('hotScore', descending: true);
    }
  }

  Timestamp _dailyPopularCutoffTimestamp() => Timestamp.fromDate(_dailyPopularCutoff());
  DateTime _dailyPopularCutoff() => DateTime.now().subtract(_dailyLookback);

  Timestamp _weeklyPopularCutoffTimestamp() => Timestamp.fromDate(_weeklyPopularCutoff());
  DateTime _weeklyPopularCutoff() => DateTime.now().subtract(_weeklyLookback);

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
