import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:gong_mu_talk/routing/app_router.dart';

import '../../../profile/domain/career_track.dart';
import '../../domain/models/feed_filters.dart';
import '../../domain/models/post.dart';
import '../cubit/community_feed_cubit.dart';
import '../widgets/inline_post_composer.dart';
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
      body: BlocBuilder<CommunityFeedCubit, CommunityFeedState>(
        builder: (context, state) {
          if ((state.status == CommunityFeedStatus.initial ||
                  state.status == CommunityFeedStatus.loading) &&
              state.posts.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == CommunityFeedStatus.error &&
              state.posts.isEmpty) {
            return _CommunityErrorView(
              message: state.errorMessage,
              onRetry: () => context.read<CommunityFeedCubit>().loadInitial(),
            );
          }

          return RefreshIndicator(
            onRefresh: () => context.read<CommunityFeedCubit>().refresh(),
            child: ListView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              children: _buildFeedChildren(context, state),
            ),
          );
        },
      ),
    );
  }

  void _openBoardList(BuildContext context) {
    context.push('/community/boards');
  }

  List<Widget> _buildFeedChildren(
    BuildContext context,
    CommunityFeedState state,
  ) {
    final CommunityFeedCubit cubit = context.read<CommunityFeedCubit>();
    final bool hasSerialAccess =
        state.careerTrack != CareerTrack.none && state.serial != 'unknown';
    final bool showSerialGuide =
        state.scope == LoungeScope.serial && !hasSerialAccess;
    final bool showEmptyPosts = state.posts.isEmpty && !showSerialGuide;

    final List<Widget> children = <Widget>[
      _FeedHeader(
        scope: state.scope,
        sort: state.sort,
        hasSerialAccess: hasSerialAccess,
        onScopeChanged: cubit.changeScope,
        onSortSelected: cubit.changeSort,
        onSearchTap: () => context.push(CommunityRoute.searchPath),
        onBoardTap: () => _openBoardList(context),
      ),
      const Gap(12),
      const InlinePostComposer(),
      const Gap(16),
    ];

    if (showSerialGuide) {
      children.add(
        _EmptyStateView(
          icon: Icons.group_add_outlined,
          title: '직렬 정보를 등록하면 전용 피드를 볼 수 있어요.',
          message: '마이페이지에서 직렬과 소속 정보를 설정해주세요.',
          onRefresh: () => cubit.refresh(),
        ),
      );
    } else if (showEmptyPosts) {
      children.add(
        _EmptyStateView(
          icon: Icons.chat_bubble_outline,
          title: '아직 게시물이 없습니다.',
          message: '첫 번째 글을 올려 동료 공무원과 이야기를 시작해보세요!',
          onRefresh: () => cubit.refresh(),
        ),
      );
    } else {
      for (final Post post in state.posts) {
        children.add(
          PostCard(
            post: post,
            onToggleLike: () => cubit.toggleLike(post),
            onToggleBookmark: () => cubit.toggleBookmark(post),
          ),
        );
      }
    }

    if (state.isLoadingMore) {
      children.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return children;
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

class _FeedHeader extends StatelessWidget {
  const _FeedHeader({
    required this.scope,
    required this.sort,
    required this.hasSerialAccess,
    required this.onScopeChanged,
    required this.onSortSelected,
    required this.onSearchTap,
    required this.onBoardTap,
  });

  final LoungeScope scope;
  final LoungeSort sort;
  final bool hasSerialAccess;
  final ValueChanged<LoungeScope> onScopeChanged;
  final ValueChanged<LoungeSort> onSortSelected;
  final VoidCallback onSearchTap;
  final VoidCallback onBoardTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: SegmentedButton<LoungeScope>(
                segments: [
                  const ButtonSegment<LoungeScope>(
                    value: LoungeScope.all,
                    label: Text('전체'),
                    icon: Icon(Icons.public_outlined),
                  ),
                  ButtonSegment<LoungeScope>(
                    value: LoungeScope.serial,
                    label: const Text('내 직렬'),
                    icon: const Icon(Icons.group_outlined),
                    enabled: hasSerialAccess,
                  ),
                ],
                selected: <LoungeScope>{scope},
                onSelectionChanged: (selection) {
                  onScopeChanged(selection.first);
                },
              ),
            ),
            const Gap(12),
            IconButton(
              tooltip: '검색',
              onPressed: onSearchTap,
              icon: const Icon(Icons.search),
            ),
            const Gap(8),
            IconButton(
              tooltip: '게시판 보기',
              onPressed: onBoardTap,
              icon: const Icon(Icons.view_list_outlined),
            ),
          ],
        ),
        const Gap(12),
        Align(
          alignment: Alignment.centerRight,
          child: PopupMenuButton<LoungeSort>(
            tooltip: '정렬 방법',
            initialValue: sort,
            onSelected: onSortSelected,
            itemBuilder: (context) {
              return LoungeSort.values.map((LoungeSort option) {
                final bool isSelected = option == sort;
                return PopupMenuItem<LoungeSort>(
                  value: option,
                  child: Row(
                    children: [
                      if (isSelected)
                        Icon(Icons.check, size: 18, color: theme.colorScheme.primary)
                      else
                        const SizedBox(width: 18),
                      const Gap(8),
                      Text(option.label),
                    ],
                  ),
                );
              }).toList(growable: false);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.tune, size: 18),
                  const Gap(6),
                  Text(sort.label, style: theme.textTheme.labelLarge),
                  const Gap(2),
                  const Icon(Icons.arrow_drop_down, size: 20),
                ],
              ),
            ),
          ),
        ),
      ],
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
