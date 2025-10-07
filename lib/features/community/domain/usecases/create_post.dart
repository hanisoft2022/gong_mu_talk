import '../../../../core/utils/result.dart';
import '../models/feed_filters.dart';
import '../models/post.dart';
import '../repositories/i_community_repository.dart';

class CreatePost {
  const CreatePost(this._repository);

  final ICommunityRepository _repository;

  Future<AppResult<Post>> call({
    required String text,
    required List<String> tags,
    required PostType type,
    required LoungeScope scope,
    List<String> imageUrls = const [],
    String? boardId,
  }) async {
    if (text.trim().isEmpty) {
      return AppResultHelpers.failure(const ValidationError('게시글 내용을 입력해주세요.'));
    }

    if (tags.length > 5) {
      return AppResultHelpers.failure(
        const ValidationError('태그는 최대 5개까지 입력할 수 있습니다.'),
      );
    }

    return _repository.createPost(
      text: text.trim(),
      tags: tags,
      type: type,
      scope: scope,
      imageUrls: imageUrls,
    );
  }
}
