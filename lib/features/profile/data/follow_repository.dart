import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firebase/paginated_query.dart';
import '../domain/user_profile.dart';
import 'user_profile_repository.dart';

typedef JsonMap = Map<String, Object?>;

typedef QueryJson = Query<JsonMap>;

typedef QueryDocumentSnapshotJson = QueryDocumentSnapshot<JsonMap>;

class FollowRepository {
  FollowRepository({
    FirebaseFirestore? firestore,
    required UserProfileRepository userProfileRepository,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _userProfileRepository = userProfileRepository;

  final FirebaseFirestore _firestore;
  final UserProfileRepository _userProfileRepository;

  DocumentReference<JsonMap> _userDoc(String uid) =>
      _firestore.collection('users').doc(uid);

  CollectionReference<JsonMap> _followersRef(String uid) =>
      _userDoc(uid).collection('followers');

  CollectionReference<JsonMap> _followingRef(String uid) =>
      _userDoc(uid).collection('following');

  Future<void> follow({
    required String followerUid,
    required String targetUid,
  }) async {
    if (followerUid.isEmpty || targetUid.isEmpty || followerUid == targetUid) {
      return;
    }

    await _firestore.runTransaction((Transaction transaction) async {
      final DocumentReference<JsonMap> followerDoc = _followersRef(
        targetUid,
      ).doc(followerUid);
      final DocumentSnapshot<JsonMap> followerSnapshot = await transaction.get(
        followerDoc,
      );
      if (followerSnapshot.exists) {
        return;
      }

      final DocumentReference<JsonMap> followingDoc = _followingRef(
        followerUid,
      ).doc(targetUid);
      final DateTime now = DateTime.now();

      transaction.set(followerDoc, <String, Object?>{
        'followedAt': Timestamp.fromDate(now),
      });
      transaction.set(followingDoc, <String, Object?>{
        'followedAt': Timestamp.fromDate(now),
      });

      transaction.update(_userDoc(targetUid), <String, Object?>{
        'followerCount': FieldValue.increment(1),
        'updatedAt': Timestamp.fromDate(now),
      });
      transaction.update(_userDoc(followerUid), <String, Object?>{
        'followingCount': FieldValue.increment(1),
        'updatedAt': Timestamp.fromDate(now),
      });
    });
  }

  Future<void> unfollow({
    required String followerUid,
    required String targetUid,
  }) async {
    if (followerUid.isEmpty || targetUid.isEmpty || followerUid == targetUid) {
      return;
    }

    await _firestore.runTransaction((Transaction transaction) async {
      final DocumentReference<JsonMap> followerDoc = _followersRef(
        targetUid,
      ).doc(followerUid);
      final DocumentSnapshot<JsonMap> followerSnapshot = await transaction.get(
        followerDoc,
      );
      if (!followerSnapshot.exists) {
        return;
      }

      final DocumentReference<JsonMap> followingDoc = _followingRef(
        followerUid,
      ).doc(targetUid);
      final DateTime now = DateTime.now();

      transaction.delete(followerDoc);
      transaction.delete(followingDoc);

      transaction.update(_userDoc(targetUid), <String, Object?>{
        'followerCount': FieldValue.increment(-1),
        'updatedAt': Timestamp.fromDate(now),
      });
      transaction.update(_userDoc(followerUid), <String, Object?>{
        'followingCount': FieldValue.increment(-1),
        'updatedAt': Timestamp.fromDate(now),
      });
    });
  }

  Stream<bool> watchIsFollowing({
    required String followerUid,
    required String targetUid,
  }) {
    if (followerUid.isEmpty || targetUid.isEmpty || followerUid == targetUid) {
      return const Stream<bool>.empty();
    }
    return _followersRef(targetUid)
        .doc(followerUid)
        .snapshots()
        .map((DocumentSnapshot<JsonMap> snapshot) => snapshot.exists);
  }

  Future<PaginatedQueryResult<UserProfile>> fetchFollowers({
    required String uid,
    int limit = 20,
    QueryDocumentSnapshotJson? startAfter,
  }) async {
    QueryJson query = _followersRef(
      uid,
    ).orderBy('followedAt', descending: true).limit(limit);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final QuerySnapshot<JsonMap> snapshot = await query.get();
    final List<String> followerIds = snapshot.docs
        .map((QueryDocumentSnapshotJson doc) => doc.id)
        .toList(growable: false);
    final List<UserProfile> profiles = await _userProfileRepository
        .fetchProfilesByIds(followerIds);

    final bool hasMore = snapshot.docs.length == limit;
    final QueryDocumentSnapshotJson? last = snapshot.docs.isEmpty
        ? null
        : snapshot.docs.last;
    return PaginatedQueryResult<UserProfile>(
      items: profiles,
      hasMore: hasMore,
      lastDocument: last,
    );
  }

  Future<PaginatedQueryResult<UserProfile>> fetchFollowing({
    required String uid,
    int limit = 20,
    QueryDocumentSnapshotJson? startAfter,
  }) async {
    QueryJson query = _followingRef(
      uid,
    ).orderBy('followedAt', descending: true).limit(limit);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final QuerySnapshot<JsonMap> snapshot = await query.get();
    final List<String> followingIds = snapshot.docs
        .map((QueryDocumentSnapshotJson doc) => doc.id)
        .toList(growable: false);
    final List<UserProfile> profiles = await _userProfileRepository
        .fetchProfilesByIds(followingIds);

    final bool hasMore = snapshot.docs.length == limit;
    final QueryDocumentSnapshotJson? last = snapshot.docs.isEmpty
        ? null
        : snapshot.docs.last;
    return PaginatedQueryResult<UserProfile>(
      items: profiles,
      hasMore: hasMore,
      lastDocument: last,
    );
  }
}
