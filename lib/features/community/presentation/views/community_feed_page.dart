import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:gong_mu_talk/routing/app_router.dart';

import '../../../profile/domain/career_track.dart';
import '../../domain/models/post.dart';
import '../cubit/community_feed_cubit.dart';
import '../widgets/post_card.dart';

class CommunityFeedPage extends StatefulWidget {
  const CommunityFeedPage({super.key});

  @override
  State<CommunityFeedPage> createState() => _CommunityFeedPageState();
}

class _CommunityFeedPageState extends State<CommunityFeedPage> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    context.read<CommunityFeedCubit>().loadInitial();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final CommunityFeedCubit cubit = context.read<CommunityFeedCubit>();
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      cubit.fetchMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              const Gap(8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child:
                          BlocBuilder<CommunityFeedCubit, CommunityFeedState>(
                            builder: (context, state) {
                              return SegmentedButton<CommunityFeedTab>(
                                segments: const [
                                  ButtonSegment<CommunityFeedTab>(
                                    value: CommunityFeedTab.all,
                                    label: Text('전체'),
                                    icon: Icon(Icons.public_outlined),
                                  ),
                                  ButtonSegment<CommunityFeedTab>(
                                    value: CommunityFeedTab.serial,
                                    label: Text('직렬별'),
                                    icon: Icon(Icons.group_outlined),
                                  ),
                                  ButtonSegment<CommunityFeedTab>(
                                    value: CommunityFeedTab.hot,
                                    label: Text('인기'),
                                    icon: Icon(
                                      Icons.local_fire_department_outlined,
                                    ),
                                  ),
                                ],
                                selected: <CommunityFeedTab>{state.tab},
                                onSelectionChanged: (selection) {
                                  context.read<CommunityFeedCubit>().changeTab(
                                    selection.first,
                                  );
                                },
                              );
                            },
                          ),
                    ),
                    const Gap(12),
                    IconButton(
                      tooltip: '검색',
                      onPressed: () => context.push(CommunityRoute.searchPath),
                      icon: const Icon(Icons.search),
                    ),
                    const Gap(8),
                    IconButton(
                      tooltip: '게시판 보기',
                      onPressed: () => _openBoardList(context),
                      icon: const Icon(Icons.view_list_outlined),
                    ),
                  ],
                ),
              ),
              const Gap(8),
              Expanded(
                child: BlocBuilder<CommunityFeedCubit, CommunityFeedState>(
                  builder: (context, state) {
                    switch (state.status) {
                      case CommunityFeedStatus.initial:
                      case CommunityFeedStatus.loading:
                        return const Center(child: CircularProgressIndicator());
                      case CommunityFeedStatus.error:
                        return _CommunityErrorView(
                          message: state.errorMessage,
                          onRetry: () =>
                              context.read<CommunityFeedCubit>().loadInitial(),
                        );
                      case CommunityFeedStatus.loaded:
                      case CommunityFeedStatus.refreshing:
                        if (state.tab == CommunityFeedTab.serial &&
                            (state.careerTrack == CareerTrack.none ||
                                state.serial == 'unknown')) {
                          return _EmptyStateView(
                            icon: Icons.group_add_outlined,
                            title: '직렬 정보를 등록하면 전용 피드를 볼 수 있어요.',
                            message: '마이페이지에서 직렬과 소속 정보를 설정해주세요.',
                            onRefresh: () =>
                                context.read<CommunityFeedCubit>().refresh(),
                          );
                        }

                        if (state.posts.isEmpty) {
                          return _EmptyStateView(
                            icon: Icons.chat_bubble_outline,
                            title: '아직 게시물이 없습니다.',
                            message: '첫 번째 글을 올려 동료 공무원과 이야기를 시작해보세요!',
                            onRefresh: () =>
                                context.read<CommunityFeedCubit>().refresh(),
                          );
                        }

                        return RefreshIndicator(
                          onRefresh: () =>
                              context.read<CommunityFeedCubit>().refresh(),
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            itemCount:
                                state.posts.length + (state.hasMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index >= state.posts.length) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              final Post post = state.posts[index];
                              return PostCard(
                                post: post,
                                onToggleLike: () => context
                                    .read<CommunityFeedCubit>()
                                    .toggleLike(post),
                                onToggleBookmark: () => context
                                    .read<CommunityFeedCubit>()
                                    .toggleBookmark(post),
                              );
                            },
                          ),
                        );
                    }
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
          Positioned(
            bottom: 24,
            right: 16,
            child: FloatingActionButton.extended(
              heroTag: "community_fab",
              onPressed: () => _openComposer(context),
              icon: const Icon(Icons.edit_square),
              label: const Text('글 작성'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openComposer(BuildContext context) async {
    final bool? published = await context.push<bool>('/community/write');
    if (published == true && context.mounted) {
      await context.read<CommunityFeedCubit>().refresh();
    }
  }

  void _openBoardList(BuildContext context) {
    context.push('/community/boards');
  }
}

class _CommunityErrorView extends StatelessWidget {
  const _CommunityErrorView({required this.onRetry, this.message});

  final Future<void> Function() onRetry;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRetry,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                const Icon(Icons.inbox_outlined, size: 72),
                const Gap(16),
                Text(
                  message ?? '피드를 불러오지 못했어요.',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const Gap(12),
                FilledButton.icon(
                  onPressed: () {
                    onRetry();
                  },
                  icon: const Icon(Icons.refresh_outlined),
                  label: const Text('다시 시도'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyStateView extends StatelessWidget {
  const _EmptyStateView({
    required this.icon,
    required this.title,
    required this.message,
    required this.onRefresh,
  });

  final IconData icon;
  final String title;
  final String message;
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
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, size: 56, color: theme.colorScheme.primary),
              const Gap(12),
              Text(
                title,
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const Gap(8),
              Text(
                message,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const Gap(16),
              FilledButton.icon(
                onPressed: () =>
                    context.read<CommunityFeedCubit>().seedDummyChirps(),
                icon: const Icon(Icons.auto_awesome),
                label: const Text('더미 데이터 채우기'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
