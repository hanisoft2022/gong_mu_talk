import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class SearchSuggestion extends Equatable {
  const SearchSuggestion({required this.token, required this.count});

  final String token;
  final int count;

  Map<String, Object?> toMap() {
    return <String, Object?>{'count': count, 'updatedAt': Timestamp.now()};
  }

  static SearchSuggestion fromSnapshot(
    DocumentSnapshot<Map<String, Object?>> snapshot,
  ) {
    final Map<String, Object?>? data = snapshot.data();
    if (data == null) {
      throw StateError('Search suggestion ${snapshot.id} has no data');
    }

    return SearchSuggestion(
      token: snapshot.id,
      count: (data['count'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => <Object?>[token, count];
}
