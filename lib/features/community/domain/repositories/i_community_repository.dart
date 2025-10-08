import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/firebase/paginated_query.dart';
import '../../../../core/utils/result.dart';
import '../models/comment.dart';
import '../models/feed_filters.dart';
import '../models/post.dart';
import '../models/search_result.dart';
import '../models/search_suggestion.dart';

abstract class ICommunityRepository {
  // User properties
  String? get currentUserId;
  Future<String> get currentUserNickname;

  // Post operations
  Future<AppResult<Post>> createPost({
    required String text,
    required List<String> tags,
    required PostType type,
    required LoungeScope scope,
    List<String> imageUrls = const [],
  });

  Future<AppResult<void>> updatePost({
    required String postId,
    required String text,
    required List<String> tags,
  });

  Future<AppResult<void>> deletePost({
    required String postId,
    required String currentUid,
  });

  Future<AppResult<Post?>> fetchPostById(String postId, {String? currentUid});

  // Feed operations
  Future<AppResult<PaginatedQueryResult<Post>>> fetchChirpFeed({
    int limit = 20,
    DocumentSnapshot? startAfter,
    String? currentUid,
  });

  Future<AppResult<PaginatedQueryResult<Post>>> fetchLoungeFeed({
    int limit = 20,
    DocumentSnapshot? startAfter,
    String? currentUid,
    LoungeScope scope = LoungeScope.all,
  });

  Future<AppResult<PaginatedQueryResult<Post>>> fetchSerialFeed({
    required String serial,
    int limit = 20,
    DocumentSnapshot? startAfter,
    String? currentUid,
  });

  Future<AppResult<PaginatedQueryResult<Post>>> fetchHotFeed({
    int limit = 20,
    String? currentUid,
  });

  Future<AppResult<PaginatedQueryResult<Post>>> fetchPostsByAuthor({
    required String authorUid,
    int limit = 20,
    DocumentSnapshot? startAfter,
    String? currentUid,
  });

  Future<AppResult<PaginatedQueryResult<Post>>> fetchScrappedPosts({
    required String uid,
    int limit = 20,
    DocumentSnapshot? startAfter,
  });

  // Comment operations
  Future<AppResult<PaginatedQueryResult<Comment>>> fetchComments({
    required String postId,
    int limit = 100,
    DocumentSnapshot? startAfter,
  });

  Future<AppResult<Comment>> createComment({
    required String postId,
    required String text,
    List<String> imageUrls = const [],
    String? parentCommentId,
  });

  Future<AppResult<void>> deleteComment({
    required String postId,
    required String commentId,
    required String currentUid,
  });

  // Engagement operations
  Future<AppResult<bool>> togglePostLike({
    required String postId,
    required String currentUid,
  });

  Future<AppResult<bool>> toggleCommentLike({
    required String postId,
    required String commentId,
    required String currentUid,
  });

  Future<AppResult<void>> togglePostScrap(String postId);

  Future<AppResult<void>> incrementViewCount(String postId);

  // Search operations
  Future<AppResult<CommunitySearchResults>> searchCommunity({
    required String query,
    required SearchScope scope,
    int postLimit = 20,
    int commentLimit = 20,
    int userLimit = 20,
    String? currentUid,
  });

  Future<AppResult<List<String>>> autocompleteSearchTokens({
    required String prefix,
    int limit = 10,
  });

  Future<AppResult<List<SearchSuggestion>>> topSearchSuggestions({
    int limit = 10,
  });

  // Legacy methods for compatibility
  Future<bool> toggleLike(String postId);
  Future<void> addComment(
    String postId,
    String text, {
    List<String> imageUrls = const [],
    String? parentCommentId,
  });
  Future<List<Comment>> getComments(String postId);
  Future<List<Comment>> getTopComments(String postId, {int limit = 3});
  Future<bool> toggleCommentLikeById(String postId, String commentId);

  // Cache management
  void clearInteractionCache({String? uid});
}
