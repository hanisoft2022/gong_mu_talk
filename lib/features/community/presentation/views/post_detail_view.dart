import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../di/di.dart';
import '../../data/community_repository.dart';
import '../../domain/models/post.dart';
import '../widgets/post_card.dart';

/// Post Detail View
///
/// Displays a single post when accessed via deep link.
/// Used for sharing posts with other users.
class PostDetailView extends StatefulWidget {
  const PostDetailView({required this.postId, super.key});

  final String postId;

  @override
  State<PostDetailView> createState() => _PostDetailViewState();
}

class _PostDetailViewState extends State<PostDetailView> {
  late final CommunityRepository _repository;
  Post? _post;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _repository = getIt<CommunityRepository>();
    _loadPost();
  }

  Future<void> _loadPost() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final post = await _repository.fetchPostById(widget.postId);

      if (mounted) {
        if (post == null) {
          setState(() {
            _errorMessage = '게시물을 찾을 수 없습니다';
            _isLoading = false;
          });
        } else {
          setState(() {
            _post = post;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '게시물을 불러오는 중 오류가 발생했습니다';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('게시물'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 64),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _loadPost,
                icon: const Icon(Icons.refresh),
                label: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    }

    if (_post == null) {
      return const Center(
        child: Text('게시물을 찾을 수 없습니다'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: RepositoryProvider<CommunityRepository>.value(
        value: _repository,
        child: PostCard(
          post: _post!,
          onToggleLike: () async {
            // Optimistic update
            setState(() {
              _post = _post!.copyWith(
                isLiked: !_post!.isLiked,
                likeCount: _post!.isLiked
                    ? _post!.likeCount - 1
                    : _post!.likeCount + 1,
              );
            });

            try {
              await _repository.toggleLike(_post!.id);
            } catch (e) {
              // Revert on failure
              if (mounted) {
                setState(() {
                  _post = _post!.copyWith(
                    isLiked: !_post!.isLiked,
                    likeCount: _post!.isLiked
                        ? _post!.likeCount + 1
                        : _post!.likeCount - 1,
                  );
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('좋아요 처리 중 오류가 발생했습니다')),
                );
              }
            }
          },
          onToggleScrap: () async {
            // Optimistic update
            setState(() {
              _post = _post!.copyWith(
                isScrapped: !_post!.isScrapped,
              );
            });

            try {
              await _repository.togglePostScrap(_post!.id);
            } catch (e) {
              // Revert on failure
              if (mounted) {
                setState(() {
                  _post = _post!.copyWith(
                    isScrapped: !_post!.isScrapped,
                  );
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('스크랩 처리 중 오류가 발생했습니다')),
                );
              }
            }
          },
        ),
      ),
    );
  }
}
