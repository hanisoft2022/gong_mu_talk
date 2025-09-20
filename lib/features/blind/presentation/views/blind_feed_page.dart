import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../../core/ads/ad_banner.dart';
import '../../domain/entities/blind_post.dart';
import '../cubit/blind_feed_cubit.dart';

class BlindFeedPage extends StatefulWidget {
  const BlindFeedPage({super.key});

  @override
  State<BlindFeedPage> createState() => _BlindFeedPageState();
}

class _BlindFeedPageState extends State<BlindFeedPage> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    context.read<BlindFeedCubit>().loadInitial();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BlindFeedCubit, BlindFeedState>(
      builder: (context, state) {
        switch (state.status) {
          case BlindFeedStatus.initial:
          case BlindFeedStatus.loading:
            return const Center(child: CircularProgressIndicator());
          case BlindFeedStatus.error:
            return _BlindErrorView(
              onRetry: () => context.read<BlindFeedCubit>().loadInitial(),
            );
          case BlindFeedStatus.loaded:
            return RefreshIndicator(
              onRefresh: () => context.read<BlindFeedCubit>().refresh(),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                itemCount: state.posts.length + 2,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _FiltersSection(
                      controller: _searchController,
                      state: state,
                    );
                  }
                  if (index == state.posts.length + 1) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: GongMuBannerAd(),
                    );
                  }
                  final BlindPost post = state.posts[index - 1];
                  return _BlindPostTile(post: post);
                },
              ),
            );
        }
      },
    );
  }
}

class _FiltersSection extends StatelessWidget {
  const _FiltersSection({required this.controller, required this.state});

  final TextEditingController controller;
  final BlindFeedState state;

  @override
  Widget build(BuildContext context) {
    final BlindFeedCubit cubit = context.read<BlindFeedCubit>();
    if (controller.text != state.query) {
      controller.text = state.query;
      controller.selection = TextSelection.collapsed(
        offset: controller.text.length,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: '키워드로 게시글 검색',
            border: OutlineInputBorder(),
          ),
          onChanged: cubit.updateQuery,
        ),
        const Gap(12),
        if (state.departments.isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('전체'),
                  selected: state.selectedDepartment == null,
                  onSelected: (_) => cubit.selectDepartment(null),
                ),
                const Gap(8),
                ...state.departments.map(
                  (dept) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(dept),
                      selected: state.selectedDepartment == dept,
                      onSelected: (selected) =>
                          cubit.selectDepartment(selected ? dept : null),
                    ),
                  ),
                ),
              ],
            ),
          ),
        const Gap(16),
      ],
    );
  }
}

class _BlindPostTile extends StatelessWidget {
  const _BlindPostTile({required this.post});

  final BlindPost post;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String timestamp = DateFormat('M월 d일 HH:mm').format(post.createdAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Gap(6),
                Text(
                  post.content,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const Gap(12),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: theme.colorScheme.primary.withValues(
                        alpha: 0.1,
                      ),
                      foregroundColor: theme.colorScheme.primary,
                      child: Text(post.initial),
                    ),
                    const Gap(8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '@${post.department}',
                            style: theme.textTheme.bodySmall,
                          ),
                          Text(
                            timestamp,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.hintColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _BlindMeta(
                      icon: Icons.recommend_outlined,
                      label: '${post.likes}',
                    ),
                    const Gap(12),
                    _BlindMeta(
                      icon: Icons.chat_bubble_outline,
                      label: '${post.comments}',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BlindMeta extends StatelessWidget {
  const _BlindMeta({required this.icon, required this.label});

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

class _BlindErrorView extends StatelessWidget {
  const _BlindErrorView({required this.onRetry});

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
                const Icon(Icons.wifi_off_outlined, size: 56),
                const Gap(12),
                Text(
                  '피드를 불러오지 못했어요.',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Gap(12),
                FilledButton.icon(
                  onPressed: () => onRetry(),
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
