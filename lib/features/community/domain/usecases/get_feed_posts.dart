import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/firebase/paginated_query.dart';
import '../../../../core/utils/result.dart';
import '../models/feed_filters.dart';
import '../models/post.dart';
import '../repositories/i_community_repository.dart';

enum FeedType {
  chirp,
  lounge,
  serial,
  hot,
  author,
  bookmarks,
}

class GetFeedPosts {
  const GetFeedPosts(this._repository);

  final ICommunityRepository _repository;

  Future<AppResult<PaginatedQueryResult<Post>>> call({
    required FeedType feedType,
    int limit = 20,
    DocumentSnapshot? startAfter,
    String? currentUid,
    LoungeScope scope = LoungeScope.all,
    String? authorUid,
    String? serial,
  }) async {
    switch (feedType) {
      case FeedType.chirp:
        return _repository.fetchChirpFeed(
          limit: limit,
          startAfter: startAfter,
          currentUid: currentUid,
        );
      case FeedType.lounge:
        return _repository.fetchLoungeFeed(
          limit: limit,
          startAfter: startAfter,
          currentUid: currentUid,
          scope: scope,
        );
      case FeedType.serial:
        if (serial == null) {
          return AppResultHelpers.failure(const ValidationError('기수를 선택해주세요.'));
        }
        return _repository.fetchSerialFeed(
          serial: serial,
          limit: limit,
          startAfter: startAfter,
          currentUid: currentUid,
        );
      case FeedType.hot:
        return _repository.fetchHotFeed(
          limit: limit,
          currentUid: currentUid,
        );
      case FeedType.author:
        if (authorUid == null) {
          return AppResultHelpers.failure(const ValidationError('작성자를 선택해주세요.'));
        }
        return _repository.fetchPostsByAuthor(
          authorUid: authorUid,
          limit: limit,
          startAfter: startAfter,
          currentUid: currentUid,
        );
      case FeedType.bookmarks:
        if (currentUid == null) {
          return AppResultHelpers.failure(const ValidationError('로그인이 필요합니다.'));
        }
        return _repository.fetchBookmarkedPosts(
          uid: currentUid,
          limit: limit,
          startAfter: startAfter,
        );
    }
  }
}