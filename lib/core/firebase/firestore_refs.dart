import 'package:cloud_firestore/cloud_firestore.dart';

typedef JsonMap = Map<String, Object?>;

class Fs {
  Fs._();

  static FirebaseFirestore get db => FirebaseFirestore.instance;

  // Paths
  static const String users = 'users';
  static const String handles = 'handles';
  static const String posts = 'posts';
  static const String comments = 'comments';
  static const String likes = 'likes';
  static const String boards = 'boards';
  static const String suggestions = 'search_suggestions';
  static const String postCounters = 'post_counters';
  static const String shards = 'shards';

  // Collections
  static CollectionReference<JsonMap> usersCol() => db.collection(users);
  static DocumentReference<JsonMap> userDoc(String uid) => usersCol().doc(uid);
  static CollectionReference<JsonMap> userBookmarksCol(String uid) => userDoc(uid).collection('bookmarks');

  static CollectionReference<JsonMap> handlesCol() => db.collection(handles);
  static DocumentReference<JsonMap> handleDoc(String handle) => handlesCol().doc(handle);

  static CollectionReference<JsonMap> postsCol() => db.collection(posts);
  static DocumentReference<JsonMap> postDoc(String postId) => postsCol().doc(postId);
  static CollectionReference<JsonMap> postCommentsCol(String postId) => postDoc(postId).collection(comments);
  static DocumentReference<JsonMap> postCommentDoc(String postId, String commentId) => postCommentsCol(postId).doc(commentId);
  static CollectionReference<JsonMap> postCommentLikesCol(String postId) => postDoc(postId).collection('comment_likes');

  static CollectionReference<JsonMap> likesCol() => db.collection(likes);
  static DocumentReference<JsonMap> likeDoc(String postId, String uid) => likesCol().doc('${postId}_$uid');

  static CollectionReference<JsonMap> boardsCol() => db.collection(boards);
  static DocumentReference<JsonMap> boardDoc(String boardId) => boardsCol().doc(boardId);

  static CollectionReference<JsonMap> suggestionsCol() => db.collection(suggestions);
  static DocumentReference<JsonMap> suggestionDoc(String token) => suggestionsCol().doc(token);

  static CollectionReference<JsonMap> postCountersCol(String postId) => db.collection(postCounters).doc(postId).collection(shards);
  static DocumentReference<JsonMap> postCounterShardDoc(String postId, String shardId) => postCountersCol(postId).doc(shardId);
}


