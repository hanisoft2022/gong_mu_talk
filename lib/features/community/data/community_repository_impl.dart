import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/firebase/paginated_query.dart';
import '../../../core/utils/result.dart';
import '../../profile/domain/career_track.dart';
import '../domain/models/comment.dart';
import '../domain/models/feed_filters.dart';
import '../domain/models/post.dart';
import '../domain/models/search_result.dart';
import '../domain/models/search_suggestion.dart';
import '../domain/repositories/i_community_repository.dart';
import 'community_repository.dart';

class CommunityRepositoryImpl implements ICommunityRepository {
  const CommunityRepositoryImpl(this._repository);

  final CommunityRepository _repository;

  @override
  String? get currentUserId => _repository.currentUserId;

  @override
  Future<String> get currentUserNickname => _repository.currentUserNickname;

  @override
  Future<AppResult<Post>> createPost({
    required String text,
    required List<String> tags,
    required PostType type,
    required LoungeScope scope,
    List<String> imageUrls = const [],
  }) async {
    return AppResultHelpers.tryCallAsync(() async {
      return _repository.createPost(
        text: text,
        tags: tags,
        type: type,
        audience: scope == LoungeScope.serial ? PostAudience.serial : PostAudience.all,
        authorUid: currentUserId ?? '',
        authorNickname: await currentUserNickname,
        authorTrack: CareerTrack.none, // Default value, should be passed properly
        serial: '', // Should be determined from context
      );
    });
  }

  @override
  Future<AppResult<void>> updatePost({
    required String postId,
    required String text,
    required List<String> tags,
  }) async {
    return AppResultHelpers.tryCallAsync(() async {
      return _repository.updatePost(
        postId: postId,
        text: text,
        tags: tags,
        authorUid: currentUserId ?? '',
      );
    });
  }

  @override
  Future<AppResult<void>> deletePost({
    required String postId,
    required String currentUid,
  }) async {
    return AppResultHelpers.tryCallAsync(() async {
      return _repository.deletePost(
        postId: postId,
        authorUid: currentUid,
      );
    });
  }

  @override
  Future<AppResult<Post?>> fetchPostById(String postId, {String? currentUid}) async {
    return AppResultHelpers.tryCallAsync(() async {
      return _repository.fetchPostById(postId, currentUid: currentUid);
    });
  }

  @override
  Future<AppResult<PaginatedQueryResult<Post>>> fetchChirpFeed({
    int limit = 20,
    DocumentSnapshot? startAfter,
    String? currentUid,
  }) async {
    return AppResultHelpers.tryCallAsync(() async {
      return _repository.fetchChirpFeed(
        limit: limit,
        startAfter: startAfter as QueryDocumentSnapshot<Map<String, Object?>>?,
        currentUid: currentUid,
      );
    });
  }

  @override
  Future<AppResult<PaginatedQueryResult<Post>>> fetchLoungeFeed({
    int limit = 20,
    DocumentSnapshot? startAfter,
    String? currentUid,
    LoungeScope scope = LoungeScope.all,
  }) async {
    return AppResultHelpers.tryCallAsync(() async {
      return _repository.fetchLoungeFeed(
        limit: limit,
        startAfter: startAfter as QueryDocumentSnapshot<Map<String, Object?>>?,
        currentUid: currentUid,
        scope: scope,
        sort: LoungeSort.latest,
      );
    });
  }

  @override
  Future<AppResult<PaginatedQueryResult<Post>>> fetchSerialFeed({
    required String serial,
    int limit = 20,
    DocumentSnapshot? startAfter,
    String? currentUid,
  }) async {
    return AppResultHelpers.tryCallAsync(() async {
      return _repository.fetchSerialFeed(
        serial: serial,
        limit: limit,
        startAfter: startAfter as QueryDocumentSnapshot<Map<String, Object?>>?,
        currentUid: currentUid,
      );
    });
  }

  @override
  Future<AppResult<PaginatedQueryResult<Post>>> fetchHotFeed({
    int limit = 20,
    String? currentUid,
  }) async {
    return AppResultHelpers.tryCallAsync(() async {
      return _repository.fetchHotFeed(
        limit: limit,
        currentUid: currentUid,
      );
    });
  }

  

  @override
  Future<AppResult<PaginatedQueryResult<Post>>> fetchPostsByAuthor({
    required String authorUid,
    int limit = 20,
    DocumentSnapshot? startAfter,
    String? currentUid,
  }) async {
    return AppResultHelpers.tryCallAsync(() async {
      return _repository.fetchPostsByAuthor(
        authorUid: authorUid,
        limit: limit,
        startAfter: startAfter as QueryDocumentSnapshot<Map<String, Object?>>?,
        currentUid: currentUid,
      );
    });
  }

  @override
  Future<AppResult<PaginatedQueryResult<Post>>> fetchBookmarkedPosts({
    required String uid,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    return AppResultHelpers.tryCallAsync(() async {
      return _repository.fetchBookmarkedPosts(
        uid: uid,
        limit: limit,
        startAfter: startAfter as QueryDocumentSnapshot<Map<String, Object?>>?,
      );
    });
  }

  @override
  Future<AppResult<PaginatedQueryResult<Comment>>> fetchComments({
    required String postId,
    int limit = 100,
    DocumentSnapshot? startAfter,
  }) async {
    return AppResultHelpers.tryCallAsync(() async {
      return _repository.fetchComments(
        postId: postId,
        limit: limit,
        startAfter: startAfter as QueryDocumentSnapshot<Map<String, Object?>>?,
      );
    });
  }

  @override
  Future<AppResult<Comment>> createComment({
    required String postId,
    required String text,
    List<String> imageUrls = const [],
    String? parentCommentId,
  }) async {
    return AppResultHelpers.tryCallAsync(() async {
      return _repository.createComment(
        postId: postId,
        text: text,
        authorUid: currentUserId ?? '',
        authorNickname: await currentUserNickname,
        imageUrls: imageUrls,
        parentCommentId: parentCommentId,
      );
    });
  }

  @override
  Future<AppResult<void>> deleteComment({
    required String postId,
    required String commentId,
    required String currentUid,
  }) async {
    return AppResultHelpers.tryCallAsync(() async {
      return _repository.deleteComment(
        postId: postId,
        commentId: commentId,
        requesterUid: currentUid,
      );
    });
  }

  @override
  Future<AppResult<bool>> togglePostLike({
    required String postId,
    required String currentUid,
  }) async {
    return AppResultHelpers.tryCallAsync(() async {
      return _repository.togglePostLike(
        postId: postId,
        uid: currentUid,
      );
    });
  }

  @override
  Future<AppResult<bool>> toggleCommentLike({
    required String postId,
    required String commentId,
    required String currentUid,
  }) async {
    return AppResultHelpers.tryCallAsync(() async {
      return _repository.toggleCommentLike(
        postId: postId,
        commentId: commentId,
        uid: currentUid,
      );
    });
  }

  @override
  Future<AppResult<void>> togglePostBookmark(String postId) async {
    return AppResultHelpers.tryCallAsync(() async {
      return _repository.togglePostBookmark(postId);
    });
  }

  @override
  Future<AppResult<void>> incrementViewCount(String postId) async {
    return AppResultHelpers.tryCallAsync(() async {
      return _repository.incrementViewCount(postId);
    });
  }

  

  @override
  Future<AppResult<CommunitySearchResults>> searchCommunity({
    required String query,
    required SearchScope scope,
    int postLimit = 20,
    int commentLimit = 20,
    String? currentUid,
  }) async {
    return AppResultHelpers.tryCallAsync(() async {
      return _repository.searchCommunity(
        query: query,
        scope: scope,
        postLimit: postLimit,
        commentLimit: commentLimit,
        currentUid: currentUid,
      );
    });
  }

  @override
  Future<AppResult<List<String>>> autocompleteSearchTokens({
    required String prefix,
    int limit = 10,
  }) async {
    return _repository.autocompleteSearchTokens(
      prefix: prefix,
      limit: limit,
    );
  }

  @override
  Future<AppResult<List<SearchSuggestion>>> topSearchSuggestions({
    int limit = 10,
  }) async {
    return AppResultHelpers.tryCallAsync(() async {
      return _repository.topSearchSuggestions(limit: limit);
    });
  }

  // Legacy methods for compatibility
  @override
  Future<bool> toggleLike(String postId) async {
    final result = await togglePostLike(
      postId: postId,
      currentUid: currentUserId ?? '',
    );
    return result.fold((error) => false, (success) => success);
  }

  @override
  Future<void> addComment(String postId, String text, {
    List<String> imageUrls = const [],
    String? parentCommentId,
  }) async {
    await createComment(
      postId: postId,
      text: text,
      imageUrls: imageUrls,
      parentCommentId: parentCommentId,
    );
  }

  @override
  Future<List<Comment>> getComments(String postId) async {
    final result = await fetchComments(postId: postId);
    return result.fold((error) => [], (paginated) => paginated.items);
  }

  @override
  Future<List<Comment>> getTopComments(String postId, {int limit = 3}) async {
    final result = await fetchComments(postId: postId, limit: limit);
    return result.fold((error) => [], (paginated) => paginated.items);
  }

  @override
  Future<bool> toggleCommentLikeById(String postId, String commentId) async {
    final result = await toggleCommentLike(
      postId: postId,
      commentId: commentId,
      currentUid: currentUserId ?? '',
    );
    return result.fold((error) => false, (success) => success);
  }
}