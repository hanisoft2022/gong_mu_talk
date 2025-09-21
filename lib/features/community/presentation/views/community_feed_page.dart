import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:rive/rive.dart';

import '../../../../core/ads/ad_banner.dart';
import '../../../profile/domain/career_track.dart';
import '../../domain/entities/community_post.dart';
import '../cubit/community_feed_cubit.dart';

class CommunityFeedPage extends StatefulWidget {
  const CommunityFeedPage({super.key});

  @override
  State<CommunityFeedPage> createState() => _CommunityFeedPageState();
}

class _CommunityFeedPageState extends State<CommunityFeedPage> {
  @override
  void initState() {
    super.initState();
    context.read<CommunityFeedCubit>().loadInitial();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      children: [
        const Gap(8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: BlocBuilder<CommunityFeedCubit, CommunityFeedState>(
            builder: (context, state) {
              return SegmentedButton<CommunityFeedScope>(
                segments: const [
                  ButtonSegment<CommunityFeedScope>(
                    value: CommunityFeedScope.all,
                    label: Text('전체 피드'),
                    icon: Icon(Icons.public_outlined),
                  ),
                  ButtonSegment<CommunityFeedScope>(
                    value: CommunityFeedScope.myTrack,
                    label: Text('내 직렬'),
                    icon: Icon(Icons.group_outlined),
                  ),
                ],
                selected: <CommunityFeedScope>{state.scope},
                onSelectionChanged: (selection) {
                  context.read<CommunityFeedCubit>().changeScope(
                    selection.first,
                  );
                },
              );
            },
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
                    onRetry: () =>
                        context.read<CommunityFeedCubit>().loadInitial(),
                  );
                case CommunityFeedStatus.loaded:
                  return _CommunityFeedList(state: state, theme: theme);
              }
            },
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: GongMuBannerAd(),
        ),
      ],
    );
  }
}

class _CommunityFeedList extends StatelessWidget {
  const _CommunityFeedList({required this.state, required this.theme});

  final CommunityFeedState state;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final CommunityFeedCubit cubit = context.read<CommunityFeedCubit>();
    final bool isMyTrack = state.scope == CommunityFeedScope.myTrack;
    final CareerTrack track = state.currentTrack;

    if (isMyTrack && track == CareerTrack.none) {
      return const _EmptyStateView(
        icon: Icons.group_add_outlined,
        title: '직렬을 선택하면 전용 커뮤니티가 열립니다.',
        message: '마이페이지에서 직렬을 설정한 뒤 다시 확인해주세요.',
      );
    }

    if (state.posts.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => cubit.refresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: const [
            _EmptyStateView(
              icon: Icons.chat_bubble_outline,
              title: '아직 게시물이 없습니다.',
              message: '첫 번째 글을 올려 동료 공무원과 이야기를 시작해보세요!',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => cubit.refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: state.posts.length,
        itemBuilder: (context, index) {
          final CommunityPost post = state.posts[index];
          return _CommunityPostCard(post: post, theme: theme);
        },
      ),
    );
  }
}

class _CommunityPostCard extends StatelessWidget {
  const _CommunityPostCard({required this.post, required this.theme});

  final CommunityPost post;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final String timestamp = DateFormat('M월 d일 HH:mm').format(post.createdAt);
    final String scopeLabel = post.isGlobal
        ? '전체 공개'
        : '${post.targetTrack?.emoji ?? ''} ${post.targetTrack?.displayName ?? ''} 전용';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primary.withValues(
                    alpha: 0.12,
                  ),
                  foregroundColor: theme.colorScheme.primary,
                  child: Text(post.authorName.substring(0, 1)),
                ),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.authorName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${post.authorTrack.emoji} ${post.authorTrack.displayName} · $timestamp',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: Text(scopeLabel, style: theme.textTheme.labelSmall),
                ),
              ],
            ),
            const Gap(14),
            Text(post.content, style: theme.textTheme.bodyLarge),
            const Gap(16),
            Row(
              children: [
                _PostMeta(icon: Icons.favorite_border, label: '${post.likes}'),
                const Gap(16),
                _PostMeta(
                  icon: Icons.mode_comment_outlined,
                  label: '${post.comments}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PostMeta extends StatelessWidget {
  const _PostMeta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
        const Gap(6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _CommunityErrorView extends StatelessWidget {
  const _CommunityErrorView({required this.onRetry});

  final Future<void> Function() onRetry;

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
                const SizedBox(
                  height: 160,
                  width: 160,
                  child: RiveAnimation.asset(
                    'assets/animations/empty_state.riv',
                    fit: BoxFit.contain,
                  ),
                ),
                const Gap(16),
                Text(
                  '피드를 불러오지 못했어요.',
                  style: Theme.of(context).textTheme.titleMedium,
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
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 56, color: theme.colorScheme.primary),
        const Gap(12),
        Text(title, style: theme.textTheme.titleMedium),
        const Gap(8),
        Text(
          message,
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
