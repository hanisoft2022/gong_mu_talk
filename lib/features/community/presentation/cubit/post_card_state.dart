import 'package:equatable/equatable.dart';
import '../../domain/models/comment.dart';

/// State for PostCard widget
///
/// Manages:
/// - Comment loading and display
/// - Comment submission
/// - View tracking
/// - Error states
class PostCardState extends Equatable {
  const PostCardState({
    required this.commentCount,
    required this.isLoadingComments,
    required this.commentsLoaded,
    required this.featuredComments,
    required this.timelineComments,
    required this.isSubmittingComment,
    required this.hasTrackedView,
    this.error,
  });

  /// Initial state factory
  factory PostCardState.initial({required int commentCount}) {
    return PostCardState(
      commentCount: commentCount,
      isLoadingComments: false,
      commentsLoaded: false,
      featuredComments: const [],
      timelineComments: const [],
      isSubmittingComment: false,
      hasTrackedView: false,
    );
  }

  final int commentCount;
  final bool isLoadingComments;
  final bool commentsLoaded;
  final List<Comment> featuredComments;
  final List<Comment> timelineComments;
  final bool isSubmittingComment;
  final bool hasTrackedView;
  final String? error;

  PostCardState copyWith({
    int? commentCount,
    bool? isLoadingComments,
    bool? commentsLoaded,
    List<Comment>? featuredComments,
    List<Comment>? timelineComments,
    bool? isSubmittingComment,
    bool? hasTrackedView,
    String? error,
    bool clearError = false,
  }) {
    return PostCardState(
      commentCount: commentCount ?? this.commentCount,
      isLoadingComments: isLoadingComments ?? this.isLoadingComments,
      commentsLoaded: commentsLoaded ?? this.commentsLoaded,
      featuredComments: featuredComments ?? this.featuredComments,
      timelineComments: timelineComments ?? this.timelineComments,
      isSubmittingComment: isSubmittingComment ?? this.isSubmittingComment,
      hasTrackedView: hasTrackedView ?? this.hasTrackedView,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [
    commentCount,
    isLoadingComments,
    commentsLoaded,
    featuredComments,
    timelineComments,
    isSubmittingComment,
    hasTrackedView,
    error,
  ];
}
