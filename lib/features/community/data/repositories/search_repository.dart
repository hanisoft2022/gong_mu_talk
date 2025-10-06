import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/utils/result.dart';
import '../../../../core/firebase/firestore_refs.dart';
import '../../../profile/data/user_profile_repository.dart';
import '../../../profile/domain/user_profile.dart';
import '../../domain/models/comment.dart';
import '../../domain/models/post.dart';
import '../../domain/models/search_result.dart';
import '../../domain/models/search_suggestion.dart';

typedef JsonMap = Map<String, Object?>;
typedef QueryJson = Query<JsonMap>;

/// Search Repository - Manages search operations and suggestions
///
/// Responsibilities:
/// - Search posts and comments by keywords
/// - Provide search autocomplete/suggestions
/// - Track popular search terms
/// - Record search token usage
///
/// Dependencies: FirebaseFirestore, UserProfileRepository
class SearchRepository {
  SearchRepository({
    FirebaseFirestore? firestore,
    UserProfileRepository? userProfileRepository,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _userProfileRepository = userProfileRepository ?? UserProfileRepository();

  final FirebaseFirestore _firestore;
  final UserProfileRepository _userProfileRepository;

  CollectionReference<JsonMap> get _postsRef => _firestore.collection(Fs.posts);
  CollectionReference<JsonMap> get _searchSuggestionRef =>
      _firestore.collection(Fs.suggestions);

  Future<List<Post>> searchPosts({
    required String token,
    int limit = 20,
    bool authorOnly = false,
  }) async {
    QueryJson query = _postsRef
        .where('keywords', arrayContains: token)
        .where('visibility', isEqualTo: PostVisibility.public.name)
        .orderBy('hotScore', descending: true)
        .limit(limit);

    final QuerySnapshot<JsonMap> snapshot = await query.get();
    List<Post> posts = snapshot.docs
        .map((doc) => Post.fromSnapshot(doc))
        .toList(growable: false);

    if (authorOnly) {
      posts = posts
          .where((Post post) => post.authorNickname.toLowerCase().contains(token))
          .toList(growable: false);
    }

    return posts;
  }

  Future<List<Comment>> searchComments({
    required String token,
    int limit = 20,
  }) async {
    final QuerySnapshot<JsonMap> snapshot = await _firestore
        .collectionGroup('comments')
        .where('deleted', isEqualTo: false)
        .where('keywords', arrayContains: token)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    if (snapshot.docs.isEmpty) {
      return const <Comment>[];
    }

    return snapshot.docs.map((doc) {
      final String postId = doc.reference.parent.parent?.id ?? '';
      return Comment.fromMap(id: doc.id, postId: postId, data: doc.data());
    }).toList(growable: false);
  }

  Future<CommunitySearchResults> searchCommunity({
    required String query,
    required SearchScope scope,
    int postLimit = 20,
    int commentLimit = 20,
    int userLimit = 20,
  }) async {
    final String token = query.trim().toLowerCase();
    if (token.isEmpty) {
      return const CommunitySearchResults();
    }

    final bool includePosts = scope != SearchScope.comments && scope != SearchScope.author;
    final bool authorOnly = scope == SearchScope.author;
    final bool includeComments =
        scope == SearchScope.comments || scope == SearchScope.all;

    List<Post> posts = const <Post>[];
    List<Comment> comments = const <Comment>[];
    List<UserProfile> users = const <UserProfile>[];

    // Search users by nickname when in author scope
    if (authorOnly && userLimit > 0) {
      users = await _userProfileRepository.searchUsersByNickname(
        query: token,
        limit: userLimit,
      );
    } else if (includePosts && postLimit > 0) {
      posts = await searchPosts(
        token: token,
        limit: postLimit,
        authorOnly: false,
      );
    }

    if (includeComments && commentLimit > 0) {
      comments = await searchComments(
        token: token,
        limit: commentLimit,
      );
    }

    recordSearchToken(token);

    return CommunitySearchResults(
      posts: posts,
      comments: comments.map((c) => CommentSearchResult(comment: c)).toList(),
      users: users,
    );
  }

  Future<List<SearchSuggestion>> topSearchSuggestions({int limit = 10}) async {
    final QuerySnapshot<JsonMap> snapshot = await _searchSuggestionRef
        .orderBy('count', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs
        .map(SearchSuggestion.fromSnapshot)
        .toList(growable: false);
  }

  Future<AppResult<List<String>>> autocompleteSearchTokens({
    required String prefix,
    int limit = 10,
  }) async {
    try {
      if (prefix.isEmpty) return AppResultHelpers.success([]);

      final String endPrefix = prefix.substring(0, prefix.length - 1) +
          String.fromCharCode(prefix.codeUnitAt(prefix.length - 1) + 1);

      final QuerySnapshot<JsonMap> snapshot = await _searchSuggestionRef
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: prefix)
          .where(FieldPath.documentId, isLessThan: endPrefix)
          .orderBy(FieldPath.documentId)
          .limit(limit)
          .get();

      final tokens = snapshot.docs.map((doc) => doc.id).toList(growable: false);
      return AppResultHelpers.success(tokens);
    } catch (e) {
      return AppResultHelpers.failure(
          UnknownError('검색어 자동완성 중 오류가 발생했습니다: $e'));
    }
  }

  void recordSearchToken(String token) {
    unawaited(
      _searchSuggestionRef.doc(token).set(<String, Object?>{
        'count': FieldValue.increment(1),
        'updatedAt': Timestamp.now(),
      }, SetOptions(merge: true)),
    );
  }
}
