import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/firebase/paginated_query.dart';
import '../../../../core/firebase/firestore_refs.dart';
import '../../domain/models/board.dart';
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
  static const Duration _loungeLookback = Duration(hours: 24);

  CollectionReference<JsonMap> get _postsRef => _firestore.collection(Fs.posts);
  CollectionReference<JsonMap> get _boardsRef =>
      _firestore.collection(Fs.boards);

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

  QueryJson _applyLoungeSort(QueryJson query, LoungeSort sort) {
    switch (sort) {
      case LoungeSort.latest:
        return query.orderBy('createdAt', descending: true);
      case LoungeSort.popular:
        final Timestamp since = _popularCutoffTimestamp();
        return query
            .where('createdAt', isGreaterThanOrEqualTo: since)
            .orderBy('createdAt', descending: true)
            .orderBy('hotScore', descending: true);
      case LoungeSort.likes:
        final Timestamp since = _popularCutoffTimestamp();
        return query
            .where('createdAt', isGreaterThanOrEqualTo: since)
            .orderBy('createdAt', descending: true)
            .orderBy('likeCount', descending: true);
    }
  }

  Timestamp _popularCutoffTimestamp() => Timestamp.fromDate(_popularCutoff());

  DateTime _popularCutoff() => DateTime.now().subtract(_loungeLookback);

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
