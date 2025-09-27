import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum ReportTargetType { post, comment, user }

enum ReportStatus { pending, reviewed, actionTaken }

class ContentReport extends Equatable {
  const ContentReport({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.reason,
    required this.reporterUid,
    required this.createdAt,
    this.metadata = const <String, Object?>{},
    this.status = ReportStatus.pending,
    this.moderatorUid,
    this.reviewedAt,
    this.notes,
  });

  final String id;
  final ReportTargetType targetType;
  final String targetId;
  final String reason;
  final String reporterUid;
  final DateTime createdAt;
  final Map<String, Object?> metadata;
  final ReportStatus status;
  final String? moderatorUid;
  final DateTime? reviewedAt;
  final String? notes;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'targetType': targetType.name,
      'targetId': targetId,
      'reason': reason,
      'reporterUid': reporterUid,
      'createdAt': Timestamp.fromDate(createdAt),
      'metadata': metadata,
      'status': status.name,
      'moderatorUid': moderatorUid,
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'notes': notes,
    };
  }

  static ContentReport fromSnapshot(
    DocumentSnapshot<Map<String, Object?>> snapshot,
  ) {
    final Map<String, Object?>? data = snapshot.data();
    if (data == null) {
      throw StateError('Report document ${snapshot.id} has no data');
    }

    return ContentReport(
      id: snapshot.id,
      targetType: _parseTargetType(data['targetType']),
      targetId: (data['targetId'] as String?) ?? '',
      reason: (data['reason'] as String?) ?? '',
      reporterUid: (data['reporterUid'] as String?) ?? '',
      createdAt: _parseTimestamp(data['createdAt']) ?? DateTime.now(),
      metadata: _parseMetadata(data['metadata']),
      status: _parseStatus(data['status']),
      moderatorUid: data['moderatorUid'] as String?,
      reviewedAt: _parseTimestamp(data['reviewedAt']),
      notes: data['notes'] as String?,
    );
  }

  static ReportTargetType _parseTargetType(Object? raw) {
    if (raw is String) {
      return ReportTargetType.values.firstWhere(
        (ReportTargetType type) => type.name == raw,
        orElse: () => ReportTargetType.post,
      );
    }
    return ReportTargetType.post;
  }

  static ReportStatus _parseStatus(Object? raw) {
    if (raw is String) {
      return ReportStatus.values.firstWhere(
        (ReportStatus value) => value.name == raw,
        orElse: () => ReportStatus.pending,
      );
    }
    return ReportStatus.pending;
  }

  static DateTime? _parseTimestamp(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }
    return null;
  }

  static Map<String, Object?> _parseMetadata(Object? raw) {
    if (raw is Map) {
      return raw.map<String, Object?>(
        (key, value) => MapEntry(key.toString(), value),
      );
    }
    return const <String, Object?>{};
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    targetType,
    targetId,
    reason,
    reporterUid,
    createdAt,
    metadata,
    status,
    moderatorUid,
    reviewedAt,
    notes,
  ];
}
