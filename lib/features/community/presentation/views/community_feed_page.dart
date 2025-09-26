import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import '../../../profile/domain/career_track.dart';
import '../../domain/models/feed_filters.dart';
import '../../domain/models/post.dart';
import '../cubit/community_feed_cubit.dart';
import '../widgets/inline_post_composer.dart';
import '../widgets/post_card.dart';
import '../widgets/lounge_ad_banner.dart';

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
      InlinePostComposer(scope: state.scope),
      const Gap(12),
      _SortMenu(currentSort: state.sort, onSelect: cubit.changeSort),
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
      const int adInterval = 10;
      int renderedCount = 0;
      final int totalPosts = state.posts.length;

      for (final Post post in state.posts) {
        children.add(
          PostCard(
            post: post,
            onToggleLike: () => cubit.toggleLike(post),
            onToggleBookmark: () => cubit.toggleBookmark(post),
          ),
        );
        renderedCount += 1;

        final bool shouldInsertAd =
            state.showAds &&
            renderedCount % adInterval == 0 &&
            renderedCount < totalPosts;

        if (shouldInsertAd) {
          children
            ..add(const Gap(12))
            ..add(const LoungeAdBanner())
            ..add(const Gap(12));
        }
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

class _SortMenu extends StatelessWidget {
  const _SortMenu({required this.currentSort, required this.onSelect});

  final LoungeSort currentSort;
  final ValueChanged<LoungeSort> onSelect;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerRight,
      child: PopupMenuButton<LoungeSort>(
        tooltip: '정렬 방법',
        initialValue: currentSort,
        onSelected: onSelect,
        itemBuilder: (context) {
          return LoungeSort.values
              .map((LoungeSort option) {
                final bool isSelected = option == currentSort;
                return PopupMenuItem<LoungeSort>(
                  value: option,
                  height: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      if (isSelected)
                        Icon(
                          Icons.check,
                          size: 18,
                          color: theme.colorScheme.primary,
                        )
                      else
                        const SizedBox(width: 18),
                      const Gap(8),
                      Text(option.label),
                    ],
                  ),
                );
              })
              .toList(growable: false);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.tune, size: 16),
              const Gap(4),
              Text(
                currentSort.label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Gap(2),
              const Icon(Icons.arrow_drop_down, size: 18),
            ],
          ),
        ),
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
