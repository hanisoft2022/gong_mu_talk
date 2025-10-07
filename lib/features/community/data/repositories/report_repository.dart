import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/report.dart';

typedef JsonMap = Map<String, Object?>;

/// Report Repository
///
/// Responsibilities:
/// - Submit content reports (posts, comments, users)
/// - Block/unblock users
/// - Manage user moderation settings
///
/// Dependencies: FirebaseFirestore
class ReportRepository {
  ReportRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<JsonMap> get _reportsRef =>
      _firestore.collection('reports');

  DocumentReference<JsonMap> _userDoc(String uid) =>
      _firestore.collection('users').doc(uid);

  /// Submit a content report
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

  /// Report a post
  Future<void> reportPost({
    required String postId,
    required String reason,
    required String reporterUid,
  }) async {
    await submitReport(
      targetType: ReportTargetType.post,
      targetId: postId,
      reason: reason,
      reporterUid: reporterUid,
    );
  }

  /// Report a comment
  Future<void> reportComment({
    required String commentId,
    required String reason,
    required String reporterUid,
  }) async {
    await submitReport(
      targetType: ReportTargetType.comment,
      targetId: commentId,
      reason: reason,
      reporterUid: reporterUid,
    );
  }

  /// Report a user
  Future<void> reportUser({
    required String userId,
    required String reason,
    required String reporterUid,
  }) async {
    await submitReport(
      targetType: ReportTargetType.user,
      targetId: userId,
      reason: reason,
      reporterUid: reporterUid,
    );
  }

  /// Block a user
  Future<void> blockUser({
    required String userId,
    required String blockerUid,
  }) async {
    await _userDoc(blockerUid).collection('blocked_users').doc(userId).set({
      'blockedAt': Timestamp.now(),
    });
  }

  /// Unblock a user
  Future<void> unblockUser({
    required String userId,
    required String blockerUid,
  }) async {
    await _userDoc(blockerUid).collection('blocked_users').doc(userId).delete();
  }

  /// Get blocked user IDs
  Future<Set<String>> getBlockedUserIds(String uid) async {
    final snapshot = await _userDoc(uid).collection('blocked_users').get();
    return snapshot.docs.map((doc) => doc.id).toSet();
  }

  /// Check if user is blocked
  Future<bool> isUserBlocked({
    required String userId,
    required String blockerUid,
  }) async {
    final doc = await _userDoc(
      blockerUid,
    ).collection('blocked_users').doc(userId).get();
    return doc.exists;
  }
}
