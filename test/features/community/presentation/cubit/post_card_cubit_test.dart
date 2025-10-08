import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gong_mu_talk/features/community/data/community_repository.dart';
import 'package:gong_mu_talk/features/community/domain/models/comment.dart';
import 'package:gong_mu_talk/features/community/presentation/cubit/post_card_cubit.dart';
import 'package:gong_mu_talk/features/community/presentation/cubit/post_card_state.dart';
import 'package:gong_mu_talk/features/profile/domain/career_track.dart';

class MockCommunityRepository extends Mock implements CommunityRepository {}

void main() {
  group('PostCardCubit', () {
    late MockCommunityRepository mockRepository;
    late PostCardCubit cubit;

    const String testPostId = 'post123';
    const String testUid = 'user123';

    setUp(() {
      mockRepository = MockCommunityRepository();
      cubit = PostCardCubit(
        repository: mockRepository,
        postId: testPostId,
        initialCommentCount: 5,
      );
    });

    tearDown(() {
      cubit.close();
    });

    group('Initial State', () {
      test('should have correct initial state', () {
        expect(cubit.state, equals(PostCardState.initial(commentCount: 5)));
      });

      test('initial state should have empty comments', () {
        expect(cubit.state.featuredComments, isEmpty);
        expect(cubit.state.timelineComments, isEmpty);
      });

      test('initial state should not be loading', () {
        expect(cubit.state.isLoadingComments, isFalse);
        expect(cubit.state.isSubmittingComment, isFalse);
      });
    });

    group('loadComments', () {
      final featuredComment = Comment(
        id: 'comment1',
        postId: testPostId,
        authorUid: 'author1',
        authorNickname: 'Author1',
        authorTrack: CareerTrack.teacher,
        authorSerialVisible: true,
        text: 'Featured comment',
        likeCount: 10,
        createdAt: DateTime(2025, 1, 1),
      );

      final timelineComments = <Comment>[
        Comment(
          id: 'comment1',
          postId: testPostId,
          authorUid: 'author1',
          authorNickname: 'Author1',
          authorTrack: CareerTrack.teacher,
          authorSerialVisible: true,
          text: 'Featured comment',
          likeCount: 10,
          createdAt: DateTime(2025, 1, 1),
        ),
        Comment(
          id: 'comment2',
          postId: testPostId,
          authorUid: 'author2',
          authorNickname: 'Author2',
          authorTrack: CareerTrack.teacher,
          authorSerialVisible: true,
          text: 'Regular comment',
          likeCount: 2,
          createdAt: DateTime(2025, 1, 2),
        ),
        Comment(
          id: 'comment3',
          postId: testPostId,
          authorUid: 'author3',
          authorNickname: 'Author3',
          authorTrack: CareerTrack.teacher,
          authorSerialVisible: true,
          text: 'Another comment',
          likeCount: 1,
          createdAt: DateTime(2025, 1, 3),
        ),
      ];

      blocTest<PostCardCubit, PostCardState>(
        'emits loading then loaded state when comments load successfully',
        build: () {
          when(
            () => mockRepository.getTopComments(testPostId, limit: 1),
          ).thenAnswer((_) async => [featuredComment]);
          when(
            () => mockRepository.getComments(testPostId),
          ).thenAnswer((_) async => timelineComments);
          return cubit;
        },
        act: (cubit) => cubit.loadComments(),
        expect: () => [
          const PostCardState(
            commentCount: 5,
            isLoadingComments: true,
            commentsLoaded: false,
            featuredComments: [],
            timelineComments: [],
            isSubmittingComment: false,
            hasTrackedView: false,
          ),
          PostCardState(
            commentCount: 5,
            isLoadingComments: false,
            commentsLoaded: true,
            featuredComments: [featuredComment],
            timelineComments: timelineComments,
            isSubmittingComment: false,
            hasTrackedView: false,
          ),
        ],
        verify: (_) {
          verify(
            () => mockRepository.getTopComments(testPostId, limit: 1),
          ).called(1);
          verify(() => mockRepository.getComments(testPostId)).called(1);
        },
      );

      blocTest<PostCardCubit, PostCardState>(
        'does not show featured comment if total comments < 3',
        build: () {
          when(
            () => mockRepository.getTopComments(testPostId, limit: 1),
          ).thenAnswer((_) async => [featuredComment]);
          when(
            () => mockRepository.getComments(testPostId),
          ).thenAnswer((_) async => timelineComments.take(2).toList());
          return cubit;
        },
        act: (cubit) => cubit.loadComments(),
        expect: () => [
          predicate<PostCardState>((state) => state.isLoadingComments == true),
          predicate<PostCardState>(
            (state) =>
                state.featuredComments.isEmpty && // No featured if < 3 comments
                state.timelineComments.length == 2,
          ),
        ],
      );

      blocTest<PostCardCubit, PostCardState>(
        'does not show featured comment if likeCount < 3',
        build: () {
          final lowLikeComment = featuredComment.copyWith(likeCount: 2);
          when(
            () => mockRepository.getTopComments(testPostId, limit: 1),
          ).thenAnswer((_) async => [lowLikeComment]);
          when(
            () => mockRepository.getComments(testPostId),
          ).thenAnswer((_) async => timelineComments);
          return cubit;
        },
        act: (cubit) => cubit.loadComments(),
        expect: () => [
          predicate<PostCardState>((state) => state.isLoadingComments == true),
          predicate<PostCardState>(
            (state) =>
                state
                    .featuredComments
                    .isEmpty && // No featured if likeCount < 3
                state.timelineComments.length == 3,
          ),
        ],
      );

      blocTest<PostCardCubit, PostCardState>(
        'emits error state when comment loading fails',
        build: () {
          when(
            () => mockRepository.getTopComments(testPostId, limit: 1),
          ).thenThrow(Exception('Failed to load comments'));
          when(
            () => mockRepository.getComments(testPostId),
          ).thenThrow(Exception('Failed to load comments'));
          return cubit;
        },
        act: (cubit) => cubit.loadComments(),
        expect: () => [
          predicate<PostCardState>((state) => state.isLoadingComments == true),
          predicate<PostCardState>(
            (state) => state.isLoadingComments == false && state.error != null,
          ),
        ],
      );

      blocTest<PostCardCubit, PostCardState>(
        'force reload reloads even if already loaded',
        build: () {
          when(
            () => mockRepository.getTopComments(testPostId, limit: 1),
          ).thenAnswer((_) async => [featuredComment]);
          when(
            () => mockRepository.getComments(testPostId),
          ).thenAnswer((_) async => timelineComments);
          return cubit;
        },
        seed: () => const PostCardState(
          commentCount: 5,
          commentsLoaded: true,
          featuredComments: [],
          timelineComments: [],
          isLoadingComments: false,
          isSubmittingComment: false,
          hasTrackedView: false,
        ),
        act: (cubit) => cubit.loadComments(force: true),
        verify: (_) {
          verify(
            () => mockRepository.getTopComments(testPostId, limit: 1),
          ).called(1);
          verify(() => mockRepository.getComments(testPostId)).called(1);
        },
      );
    });

    group('submitComment', () {
      blocTest<PostCardCubit, PostCardState>(
        'submits comment successfully without images',
        build: () {
          when(
            () => mockRepository.addComment(
              testPostId,
              'Test comment',
              imageUrls: [],
            ),
          ).thenAnswer((_) async => {});
          when(
            () => mockRepository.getTopComments(testPostId, limit: 1),
          ).thenAnswer((_) async => []);
          when(
            () => mockRepository.getComments(testPostId),
          ).thenAnswer((_) async => []);
          return cubit;
        },
        act: (cubit) => cubit.submitComment('Test comment'),
        expect: () => [
          predicate<PostCardState>(
            (state) => state.isSubmittingComment == true,
          ),
          predicate<PostCardState>(
            (state) =>
                state.isSubmittingComment == false && state.commentCount == 6,
          ), // Incremented from initial 5
          predicate<PostCardState>(
            (state) => state.isLoadingComments == true,
          ), // loadComments starts
          predicate<PostCardState>(
            (state) =>
                state.isLoadingComments == false &&
                state.commentsLoaded == true,
          ), // loadComments completes
        ],
        verify: (_) {
          verify(
            () => mockRepository.addComment(
              testPostId,
              'Test comment',
              imageUrls: [],
            ),
          ).called(1);
          verify(
            () => mockRepository.getTopComments(testPostId, limit: 1),
          ).called(1);
          verify(() => mockRepository.getComments(testPostId)).called(1);
        },
      );

      blocTest<PostCardCubit, PostCardState>(
        'does not submit empty comment',
        build: () => cubit,
        act: (cubit) => cubit.submitComment(''),
        expect: () => [], // No state change
        verify: (_) {
          verifyNever(
            () => mockRepository.addComment(
              any(),
              any(),
              imageUrls: any(named: 'imageUrls'),
            ),
          );
        },
      );

      blocTest<PostCardCubit, PostCardState>(
        'does not submit whitespace-only comment',
        build: () => cubit,
        act: (cubit) => cubit.submitComment('   \n  '),
        expect: () => [],
        verify: (_) {
          verifyNever(
            () => mockRepository.addComment(
              any(),
              any(),
              imageUrls: any(named: 'imageUrls'),
            ),
          );
        },
      );

      blocTest<PostCardCubit, PostCardState>(
        'handles comment submission error',
        build: () {
          when(
            () => mockRepository.addComment(
              testPostId,
              'Test comment',
              imageUrls: [],
            ),
          ).thenThrow(Exception('Failed to submit'));
          return cubit;
        },
        act: (cubit) => cubit.submitComment('Test comment'),
        expect: () => [
          predicate<PostCardState>(
            (state) => state.isSubmittingComment == true,
          ),
          predicate<PostCardState>(
            (state) =>
                state.isSubmittingComment == false && state.error != null,
          ),
        ],
      );
    });

    group('toggleCommentLike', () {
      final comment = Comment(
        id: 'comment1',
        postId: testPostId,
        authorUid: 'author1',
        authorNickname: 'Author',
        authorTrack: CareerTrack.teacher,
        authorSerialVisible: true,
        text: 'Test comment',
        likeCount: 5,
        isLiked: false,
        createdAt: DateTime(2025, 1, 1),
      );

      blocTest<PostCardCubit, PostCardState>(
        'toggles like with optimistic update',
        build: () {
          when(
            () => mockRepository.toggleCommentLikeById(testPostId, comment.id),
          ).thenAnswer((_) async => {});
          return cubit;
        },
        seed: () => PostCardState(
          commentCount: 5,
          commentsLoaded: true,
          timelineComments: [comment],
          featuredComments: const [],
          isLoadingComments: false,
          isSubmittingComment: false,
          hasTrackedView: false,
        ),
        act: (cubit) => cubit.toggleCommentLike(comment),
        expect: () => [
          predicate<PostCardState>((state) {
            final updatedComment = state.timelineComments.first;
            return updatedComment.isLiked == true &&
                updatedComment.likeCount == 6; // Optimistic increment
          }),
        ],
        verify: (_) {
          verify(
            () => mockRepository.toggleCommentLikeById(testPostId, comment.id),
          ).called(1);
        },
      );

      blocTest<PostCardCubit, PostCardState>(
        'reverts optimistic update on failure',
        build: () {
          when(
            () => mockRepository.toggleCommentLikeById(testPostId, comment.id),
          ).thenThrow(Exception('Failed to toggle like'));
          return cubit;
        },
        seed: () => PostCardState(
          commentCount: 5,
          commentsLoaded: true,
          timelineComments: [comment],
          featuredComments: const [],
          isLoadingComments: false,
          isSubmittingComment: false,
          hasTrackedView: false,
        ),
        act: (cubit) => cubit.toggleCommentLike(comment),
        expect: () => [
          predicate<PostCardState>((state) {
            final updatedComment = state.timelineComments.first;
            return updatedComment.isLiked == true &&
                updatedComment.likeCount == 6;
          }),
          predicate<PostCardState>((state) {
            final revertedComment = state.timelineComments.first;
            return revertedComment.isLiked == false &&
                revertedComment.likeCount == 5; // Reverted
          }),
        ],
      );
    });

    group('reportPost', () {
      blocTest<PostCardCubit, PostCardState>(
        'reports post successfully',
        build: () {
          when(
            () => mockRepository.reportPost(testPostId, 'spam'),
          ).thenAnswer((_) async => {});
          return cubit;
        },
        act: (cubit) => cubit.reportPost('spam'),
        verify: (_) {
          verify(() => mockRepository.reportPost(testPostId, 'spam')).called(1);
        },
      );

      blocTest<PostCardCubit, PostCardState>(
        'handles report error',
        build: () {
          when(
            () => mockRepository.reportPost(testPostId, 'spam'),
          ).thenThrow(Exception('Failed to report'));
          return cubit;
        },
        act: (cubit) => cubit.reportPost('spam'),
        expect: () => [
          predicate<PostCardState>((state) => state.error != null),
        ],
      );
    });

    group('blockUser', () {
      blocTest<PostCardCubit, PostCardState>(
        'blocks user successfully',
        build: () {
          when(
            () => mockRepository.blockUser(testUid),
          ).thenAnswer((_) async => {});
          return cubit;
        },
        act: (cubit) => cubit.blockUser(testUid),
        verify: (_) {
          verify(() => mockRepository.blockUser(testUid)).called(1);
        },
      );

      blocTest<PostCardCubit, PostCardState>(
        'handles block error',
        build: () {
          when(
            () => mockRepository.blockUser(testUid),
          ).thenThrow(Exception('Failed to block'));
          return cubit;
        },
        act: (cubit) => cubit.blockUser(testUid),
        expect: () => [
          predicate<PostCardState>((state) => state.error != null),
        ],
      );
    });

    group('clearError', () {
      blocTest<PostCardCubit, PostCardState>(
        'clears error state',
        build: () => cubit,
        seed: () => const PostCardState(
          commentCount: 5,
          isLoadingComments: false,
          commentsLoaded: false,
          featuredComments: [],
          timelineComments: [],
          isSubmittingComment: false,
          hasTrackedView: false,
          error: 'Some error',
        ),
        act: (cubit) => cubit.clearError(),
        expect: () => [
          predicate<PostCardState>((state) => state.error == null),
        ],
      );
    });
  });
}
