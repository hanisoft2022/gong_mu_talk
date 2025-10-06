import 'package:equatable/equatable.dart';

import 'comment.dart';

/// CommentWithPost - Comment with its parent post information
///
/// Used for displaying user's comment history with context
class CommentWithPost extends Equatable {
  const CommentWithPost({
    required this.comment,
    required this.postId,
    required this.postText,
    required this.postAuthorNickname,
  });

  final Comment comment;
  final String postId;
  final String postText;
  final String postAuthorNickname;

  @override
  List<Object?> get props => [comment, postId, postText, postAuthorNickname];
}
