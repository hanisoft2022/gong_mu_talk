import 'package:equatable/equatable.dart';

import 'comment.dart';
import 'post.dart';

enum SearchScope { all, posts, comments, author }

extension SearchScopeLabel on SearchScope {
  String get label {
    switch (this) {
      case SearchScope.all:
        return '글+댓글';
      case SearchScope.posts:
        return '글';
      case SearchScope.comments:
        return '댓글';
      case SearchScope.author:
        return '글 작성자';
    }
  }
}

class CommentSearchResult extends Equatable {
  const CommentSearchResult({
    required this.comment,
    this.post,
  });

  final Comment comment;
  final Post? post;

  @override
  List<Object?> get props => <Object?>[comment, post];
}

class CommunitySearchResults extends Equatable {
  const CommunitySearchResults({
    this.posts = const <Post>[],
    this.comments = const <CommentSearchResult>[],
  });

  final List<Post> posts;
  final List<CommentSearchResult> comments;

  CommunitySearchResults copyWith({
    List<Post>? posts,
    List<CommentSearchResult>? comments,
  }) {
    return CommunitySearchResults(
      posts: posts ?? this.posts,
      comments: comments ?? this.comments,
    );
  }

  @override
  List<Object?> get props => <Object?>[posts, comments];
}
