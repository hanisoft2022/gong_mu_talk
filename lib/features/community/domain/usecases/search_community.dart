import '../../../../core/utils/result.dart';
import '../models/search_result.dart';
import '../repositories/i_community_repository.dart';

class SearchCommunity {
  const SearchCommunity(this._repository);

  final ICommunityRepository _repository;

  Future<AppResult<CommunitySearchResults>> call({
    required String query,
    required SearchScope scope,
    int postLimit = 20,
    int commentLimit = 20,
    int userLimit = 20,
    String? currentUid,
  }) async {
    if (query.trim().isEmpty) {
      return AppResultHelpers.failure(const ValidationError('검색어를 입력해주세요.'));
    }

    if (query.trim().length < 2) {
      return AppResultHelpers.failure(
        const ValidationError('검색어는 2글자 이상 입력해주세요.'),
      );
    }

    return _repository.searchCommunity(
      query: query.trim().toLowerCase(),
      scope: scope,
      postLimit: postLimit,
      commentLimit: commentLimit,
      userLimit: userLimit,
      currentUid: currentUid,
    );
  }
}
