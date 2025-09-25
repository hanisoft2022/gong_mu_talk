class EngagementPoints {
  const EngagementPoints._();

  /// Points awarded when a user publishes a new lounge post.
  static const int postCreation = 15;

  /// Points awarded when a user leaves a comment in the lounge.
  static const int commentCreation = 5;

  /// Points awarded to the content author when their post or comment receives a like.
  static const int contentReceivedLike = 2;
}
