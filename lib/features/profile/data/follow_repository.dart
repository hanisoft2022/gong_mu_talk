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
      // ⚠️ Firestore transaction rule: All reads must happen before any writes
      // Step 1: Perform ALL reads first
      final DocumentReference<JsonMap> followerDoc = _followersRef(
        targetUid,
      ).doc(followerUid);
      final DocumentReference<JsonMap> followingDoc = _followingRef(
        followerUid,
      ).doc(targetUid);
      final DocumentReference<JsonMap> targetUserDoc = _userDoc(targetUid);
      final DocumentReference<JsonMap> followerUserDoc = _userDoc(followerUid);

      final DocumentSnapshot<JsonMap> followerSnapshot = await transaction.get(followerDoc);
      if (followerSnapshot.exists) {
        return; // Already following
      }

      final DocumentSnapshot<JsonMap> targetUserSnapshot = await transaction.get(targetUserDoc);
      final DocumentSnapshot<JsonMap> followerUserSnapshot = await transaction.get(followerUserDoc);

      // Step 2: Perform ALL writes
      final DateTime now = DateTime.now();

      transaction.set(followerDoc, <String, Object?>{
        'followedAt': Timestamp.fromDate(now),
      });
      transaction.set(followingDoc, <String, Object?>{
        'followedAt': Timestamp.fromDate(now),
      });

      // Initialize followerCount/followingCount fields if they don't exist (for legacy users)
      if (targetUserSnapshot.exists) {
        final Map<String, dynamic>? targetData = targetUserSnapshot.data();
        if (targetData != null && !targetData.containsKey('followerCount')) {
          transaction.set(
            targetUserDoc,
            <String, Object?>{'followerCount': 0, 'followingCount': 0},
            SetOptions(merge: true),
          );
        }
      }

      if (followerUserSnapshot.exists) {
        final Map<String, dynamic>? followerData = followerUserSnapshot.data();
        if (followerData != null && !followerData.containsKey('followingCount')) {
          transaction.set(
            followerUserDoc,
            <String, Object?>{'followerCount': 0, 'followingCount': 0},
            SetOptions(merge: true),
          );
        }
      }

      transaction.update(targetUserDoc, <String, Object?>{
        'followerCount': FieldValue.increment(1),
        'updatedAt': Timestamp.fromDate(now),
      });
      transaction.update(followerUserDoc, <String, Object?>{
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
      // ⚠️ Firestore transaction rule: All reads must happen before any writes
      // Step 1: Perform ALL reads first
      final DocumentReference<JsonMap> followerDoc = _followersRef(
        targetUid,
      ).doc(followerUid);
      final DocumentReference<JsonMap> followingDoc = _followingRef(
        followerUid,
      ).doc(targetUid);
      final DocumentReference<JsonMap> targetUserDoc = _userDoc(targetUid);
      final DocumentReference<JsonMap> followerUserDoc = _userDoc(followerUid);

      final DocumentSnapshot<JsonMap> followerSnapshot = await transaction.get(followerDoc);
      if (!followerSnapshot.exists) {
        return; // Not following
      }

      final DocumentSnapshot<JsonMap> targetUserSnapshot = await transaction.get(targetUserDoc);
      final DocumentSnapshot<JsonMap> followerUserSnapshot = await transaction.get(followerUserDoc);

      // Step 2: Perform ALL writes
      final DateTime now = DateTime.now();

      transaction.delete(followerDoc);
      transaction.delete(followingDoc);

      // Initialize followerCount/followingCount fields if they don't exist (for legacy users)
      if (targetUserSnapshot.exists) {
        final Map<String, dynamic>? targetData = targetUserSnapshot.data();
        if (targetData != null && !targetData.containsKey('followerCount')) {
          transaction.set(
            targetUserDoc,
            <String, Object?>{'followerCount': 0, 'followingCount': 0},
            SetOptions(merge: true),
          );
        }
      }

      if (followerUserSnapshot.exists) {
        final Map<String, dynamic>? followerData = followerUserSnapshot.data();
        if (followerData != null && !followerData.containsKey('followingCount')) {
          transaction.set(
            followerUserDoc,
            <String, Object?>{'followerCount': 0, 'followingCount': 0},
            SetOptions(merge: true),
          );
        }
      }

      transaction.update(targetUserDoc, <String, Object?>{
        'followerCount': FieldValue.increment(-1),
        'updatedAt': Timestamp.fromDate(now),
      });
      transaction.update(followerUserDoc, <String, Object?>{
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
