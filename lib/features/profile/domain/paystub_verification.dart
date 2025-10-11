import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import 'career_track.dart';

enum PaystubVerificationStatus { none, processing, verified, failed }

class PaystubVerification extends Equatable {
  const PaystubVerification({
    required this.status,
    this.detectedTrack,
    this.detectedKeywords = const <String>[],
    this.errorMessage,
    this.updatedAt,
    this.failureCount = 0,
    this.lastFailedAt,
  });

  final PaystubVerificationStatus status;
  final CareerTrack? detectedTrack;
  final List<String> detectedKeywords;
  final String? errorMessage;
  final DateTime? updatedAt;
  final int failureCount;
  final DateTime? lastFailedAt;

  bool get isVerified => status == PaystubVerificationStatus.verified;

  PaystubVerification copyWith({
    PaystubVerificationStatus? status,
    CareerTrack? detectedTrack,
    List<String>? detectedKeywords,
    String? errorMessage,
    DateTime? updatedAt,
    int? failureCount,
    DateTime? lastFailedAt,
  }) {
    return PaystubVerification(
      status: status ?? this.status,
      detectedTrack: detectedTrack ?? this.detectedTrack,
      detectedKeywords: detectedKeywords ?? this.detectedKeywords,
      errorMessage: errorMessage ?? this.errorMessage,
      updatedAt: updatedAt ?? this.updatedAt,
      failureCount: failureCount ?? this.failureCount,
      lastFailedAt: lastFailedAt ?? this.lastFailedAt,
    );
  }

  static PaystubVerification fromSnapshot(
    DocumentSnapshot<Map<String, Object?>> snapshot,
  ) {
    final Map<String, Object?> data = snapshot.data() ?? <String, Object?>{};
    final String statusRaw = (data['status'] as String?) ?? 'none';
    final PaystubVerificationStatus status = PaystubVerificationStatus.values
        .firstWhere(
          (PaystubVerificationStatus element) => element.name == statusRaw,
          orElse: () => PaystubVerificationStatus.none,
        );

    final String? detectedTrackRaw = data['detectedTrack'] as String?;
    CareerTrack? track;
    if (detectedTrackRaw != null && detectedTrackRaw.isNotEmpty) {
      final CareerTrack resolved = CareerTrack.values.firstWhere(
        (CareerTrack value) => value.name == detectedTrackRaw,
        orElse: () => CareerTrack.none,
      );
      track = resolved == CareerTrack.none ? null : resolved;
    }

    final List<String> keywords =
        (data['detectedKeywords'] as List?)?.whereType<String>().toList(
          growable: false,
        ) ??
        const <String>[];

    final Timestamp? updatedAtRaw = data['updatedAt'] as Timestamp?;
    final String? error = data['errorMessage'] as String?;
    final int failureCount = (data['failureCount'] as int?) ?? 0;
    final Timestamp? lastFailedAtRaw = data['lastFailedAt'] as Timestamp?;

    return PaystubVerification(
      status: status,
      detectedTrack: track,
      detectedKeywords: keywords,
      errorMessage: error,
      updatedAt: updatedAtRaw?.toDate(),
      failureCount: failureCount,
      lastFailedAt: lastFailedAtRaw?.toDate(),
    );
  }

  static const PaystubVerification none = PaystubVerification(
    status: PaystubVerificationStatus.none,
  );

  @override
  List<Object?> get props => <Object?>[
    status,
    detectedTrack,
    detectedKeywords,
    errorMessage,
    updatedAt,
    failureCount,
    lastFailedAt,
  ];
}
