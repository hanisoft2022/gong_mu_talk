import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import '../../../../di/di.dart';
import '../cubit/community_search_cubit.dart';
import '../widgets/post_card.dart';

class CommunitySearchPage extends StatefulWidget {
  const CommunitySearchPage({super.key});

  @override
  State<CommunitySearchPage> createState() => _CommunitySearchPageState();
}

class _CommunitySearchPageState extends State<CommunitySearchPage> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CommunitySearchCubit>(
      create: (_) => getIt<CommunitySearchCubit>()..initialize(),
      child: BlocListener<CommunitySearchCubit, CommunitySearchState>(
        listenWhen: (previous, current) => previous.errorMessage != current.errorMessage,
        listener: (context, state) {
          final String? message = state.errorMessage;
          if (message != null && message.isNotEmpty) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(message)));
          }
        },
        child: Scaffold(
          appBar: AppBar(
            titleSpacing: 0,
            title: _SearchField(controller: _controller),
            actions: [
              IconButton(
                tooltip: '검색',
                onPressed: () =>
                    context.read<CommunitySearchCubit>().search(_controller.text),
                icon: const Icon(Icons.search),
              ),
            ],
          ),
          body: const _SearchBody(),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CommunitySearchCubit, CommunitySearchState>(
      buildWhen: (previous, current) => previous.query != current.query,
      builder: (context, state) {
        if (controller.text != state.query) {
          controller.value = TextEditingValue(
            text: state.query,
            selection: TextSelection.collapsed(offset: state.query.length),
          );
        }
        return TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '게시글, 태그, 키워드 검색',
            border: InputBorder.none,
          ),
          textInputAction: TextInputAction.search,
          onChanged: context.read<CommunitySearchCubit>().updateQuery,
          onSubmitted: context.read<CommunitySearchCubit>().search,
        );
      },
    );
  }
}

class _SearchBody extends StatelessWidget {
  const _SearchBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CommunitySearchCubit, CommunitySearchState>(
      builder: (context, state) {
        return Column(
          children: [
            if (state.isFetchingSuggestions)
              const LinearProgressIndicator(minHeight: 2),
            _SuggestionSection(state: state),
            const Divider(height: 1),
            Expanded(child: _SearchResults(state: state)),
          ],
        );
      },
    );
  }
}

class _SuggestionSection extends StatelessWidget {
  const _SuggestionSection({required this.state});

  final CommunitySearchState state;

  @override
  Widget build(BuildContext context) {
    if (state.query.isEmpty) {
      if (state.popularSuggestions.isEmpty) {
        return const SizedBox.shrink();
      }
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '인기 검색어',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Gap(8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: state.popularSuggestions
                  .map(
                    (String suggestion) => ActionChip(
                      label: Text(suggestion),
                      onPressed: () =>
                          context.read<CommunitySearchCubit>().selectSuggestion(suggestion),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ),
      );
    }

    if (state.autocompleteSuggestions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '“${state.query}” 검색',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    final int visibleCount =
        state.autocompleteSuggestions.length.clamp(1, 5).toInt();
    return SizedBox(
      height: visibleCount * 48.0,
      child: ListView.builder(
        itemCount: state.autocompleteSuggestions.length,
        itemBuilder: (context, index) {
          final String suggestion = state.autocompleteSuggestions[index];
          return ListTile(
            leading: const Icon(Icons.search),
            title: Text(suggestion),
            onTap: () => context.read<CommunitySearchCubit>().selectSuggestion(suggestion),
          );
        },
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({required this.state});

  final CommunitySearchState state;

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case CommunitySearchStatus.initial:
        if (state.query.isEmpty) {
          return _SearchPlaceholder(onClear: context.read<CommunitySearchCubit>().clear);
        }
        return const SizedBox.shrink();
      case CommunitySearchStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case CommunitySearchStatus.error:
        return _SearchErrorView(
          message: state.errorMessage ?? '검색 결과를 불러오지 못했습니다.',
          onRetry: () => context.read<CommunitySearchCubit>().search(state.query),
        );
      case CommunitySearchStatus.success:
        if (state.results.isEmpty) {
          return _EmptyResultsView(query: state.query);
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: state.results.length,
          itemBuilder: (context, index) {
            final post = state.results[index];
            return PostCard(
              post: post,
              onToggleLike: () => context.read<CommunitySearchCubit>().toggleLike(post),
              onToggleBookmark: () =>
                  context.read<CommunitySearchCubit>().toggleBookmark(post),
              onTap: () {
                context.read<CommunitySearchCubit>().recordView(post.id);
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    const SnackBar(content: Text('검색 상세 페이지는 준비 중입니다.')),
                  );
              },
            );
          },
        );
    }
  }
}

class _SearchPlaceholder extends StatelessWidget {
  const _SearchPlaceholder({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_outlined, size: 72, color: theme.colorScheme.primary),
            const Gap(16),
            Text(
              '찾고 싶은 내용을 검색해보세요.',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const Gap(8),
            Text(
              '태그, 직렬, 지역 등 다양한 키워드를 지원합니다.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const Gap(16),
            FilledButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.refresh_outlined),
              label: const Text('검색어 지우기'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyResultsView extends StatelessWidget {
  const _EmptyResultsView({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.manage_search_outlined, size: 64, color: theme.colorScheme.primary),
            const Gap(12),
            Text('“$query”에 대한 결과가 없습니다.', style: theme.textTheme.titleMedium),
            const Gap(8),
            Text(
              '철자나 띄어쓰기를 확인하거나 다른 키워드를 입력해보세요.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchErrorView extends StatelessWidget {
  const _SearchErrorView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64),
            const Gap(12),
            Text(message, textAlign: TextAlign.center),
            const Gap(16),
            FilledButton.icon(
              onPressed: () => onRetry(),
              icon: const Icon(Icons.refresh_outlined),
              label: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}
