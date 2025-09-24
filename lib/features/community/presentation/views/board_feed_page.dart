import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import '../../../../di/di.dart';
import '../../domain/models/board.dart';
import '../../domain/models/post.dart';
import '../cubit/board_feed_cubit.dart';
import '../widgets/post_card.dart';

class BoardFeedPage extends StatelessWidget {
  const BoardFeedPage({super.key, this.board, this.boardId});

  final Board? board;
  final String? boardId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BoardFeedCubit>(
      create: (_) {
        final BoardFeedCubit cubit = getIt<BoardFeedCubit>();
        if (board != null) {
          cubit.loadBoard(board!);
        } else if (boardId != null) {
          cubit.loadBoardById(boardId!);
        }
        return cubit;
      },
      child: _BoardFeedView(defaultBoard: board),
    );
  }
}

class _BoardFeedView extends StatefulWidget {
  const _BoardFeedView({required this.defaultBoard});

  final Board? defaultBoard;

  @override
  State<_BoardFeedView> createState() => _BoardFeedViewState();
}

class _BoardFeedViewState extends State<_BoardFeedView> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final BoardFeedCubit cubit = context.read<BoardFeedCubit>();
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      cubit.fetchMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<BoardFeedCubit, BoardFeedState>(
          builder: (context, state) {
            final String title =
                state.board?.name ?? widget.defaultBoard?.name ?? '게시판';
            return Text(title);
          },
        ),
      ),
      body: BlocBuilder<BoardFeedCubit, BoardFeedState>(
        builder: (context, state) {
          switch (state.status) {
            case BoardFeedStatus.initial:
            case BoardFeedStatus.loading:
              return const Center(child: CircularProgressIndicator());
            case BoardFeedStatus.error:
              return _BoardFeedErrorView(
                message: state.errorMessage ?? '게시판 글을 불러오지 못했습니다.',
                onRetry: () => context.read<BoardFeedCubit>().refresh(),
              );
            case BoardFeedStatus.loaded:
              if (state.posts.isEmpty) {
                return _BoardFeedEmptyView(
                  boardName: state.board?.name ?? '게시판',
                  onRefresh: () => context.read<BoardFeedCubit>().refresh(),
                );
              }

              return RefreshIndicator(
                onRefresh: () => context.read<BoardFeedCubit>().refresh(),
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                  itemCount: state.posts.length + (state.hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= state.posts.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final Post post = state.posts[index];
                    return PostCard(
                      post: post,
                      onToggleLike: () =>
                          context.read<BoardFeedCubit>().toggleLike(post),
                      onToggleBookmark: () =>
                          context.read<BoardFeedCubit>().toggleBookmark(post),
                    );
                  },
                ),
              );
          }
        },
      ),
    );
  }
}

class _BoardFeedErrorView extends StatelessWidget {
  const _BoardFeedErrorView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRetry,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 56),
              const Gap(12),
              Text(message, textAlign: TextAlign.center),
              const Gap(12),
              FilledButton.icon(
                onPressed: () => onRetry(),
                icon: const Icon(Icons.refresh_outlined),
                label: const Text('다시 시도'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BoardFeedEmptyView extends StatelessWidget {
  const _BoardFeedEmptyView({required this.boardName, required this.onRefresh});

  final String boardName;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.chat_outlined,
                size: 56,
                color: theme.colorScheme.primary,
              ),
              const Gap(12),
              Text(
                '$boardName 게시판이 아직 조용해요!',
                style: theme.textTheme.titleMedium,
              ),
              const Gap(8),
              Text(
                '첫 번째 글을 작성해 동료들과 이야기를 시작해보세요.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
