import 'package:cloud_firestore/cloud_firestore.dart';

typedef JsonMap = Map<String, Object?>;

typedef DocumentSnapshotJson = DocumentSnapshot<JsonMap>;

typedef QueryDocumentSnapshotJson = QueryDocumentSnapshot<JsonMap>;

typedef QueryJson = Query<JsonMap>;

typedef CollectionReferenceJson = CollectionReference<JsonMap>;

class PaginatedQueryResult<T> {
  const PaginatedQueryResult({
    required this.items,
    this.lastDocument,
    required this.hasMore,
  });

  final List<T> items;
  final QueryDocumentSnapshotJson? lastDocument;
  final bool hasMore;
}
