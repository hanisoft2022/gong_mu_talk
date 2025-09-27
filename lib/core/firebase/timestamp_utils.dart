import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? parseTimestamp(Object? raw) {
  if (raw == null) {
    return null;
  }
  if (raw is Timestamp) {
    return raw.toDate();
  }
  if (raw is DateTime) {
    return raw;
  }
  if (raw is String) {
    return DateTime.tryParse(raw);
  }
  if (raw is num) {
    return DateTime.fromMillisecondsSinceEpoch(raw.toInt());
  }
  return null;
}

Object? toFirestoreTimestamp(DateTime? value) {
  if (value == null) {
    return null;
  }
  return Timestamp.fromDate(value);
}
