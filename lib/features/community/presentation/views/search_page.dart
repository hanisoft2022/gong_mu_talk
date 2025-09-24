import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/post.dart';
import '../../domain/models/search_suggestion.dart';
import '../cubit/search_cubit.dart';
import '../widgets/post_card.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key, this.initialQuery});

  final String? initialQuery;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late final TextEditingController _searchController;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery ?? '');
    _scrollController = ScrollController()..addListener(_onScroll);

    if (widget.initialQuery?.isNotEmpty == true) {
      context.read<SearchCubit>().search(widget.initialQuery!);
    } else {
      context.read<SearchCubit>().loadSuggestions();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      context.read<SearchCubit>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: '게시글 검색...',
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          textInputAction: TextInputAction.search,
          onSubmitted: (query) => _performSearch(query.trim()),
          autofocus: widget.initialQuery?.isEmpty ?? true,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _performSearch(_searchController.text.trim()),
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _clearSearch,
          ),
        ],
      ),
      body: BlocBuilder<SearchCubit, SearchState>(
        builder: (context, state) {
          if (state.isLoading && state.results.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.query.isEmpty) {
            return _buildSuggestions(state.suggestions);
          }

          if (state.results.isEmpty && !state.isLoading) {
            return _buildEmptyResults(state.query);
          }

          return RefreshIndicator(
            onRefresh: () => context.read<SearchCubit>().refresh(),
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: state.results.length + (state.hasMore ? 1 : 0) + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildResultsHeader(state.query, state.results.length);
                }

                final int postIndex = index - 1;
                if (postIndex >= state.results.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final Post post = state.results[postIndex];
                return PostCard(
                  post: post,
                  onToggleLike: () => context.read<SearchCubit>().toggleLike(post),
                  onToggleBookmark: () => context.read<SearchCubit>().toggleBookmark(post),
                  onTap: () async {
                    final cubit = context.read<SearchCubit>();
                    final result = await context.push<bool>('/community/post/${post.id}');
                    if (result == true && mounted) {
                      cubit.refresh();
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildSuggestions(List<SearchSuggestion> suggestions) {
    if (suggestions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_outlined, size: 64),
            Gap(16),
            Text('검색어를 입력하세요'),
            Gap(8),
            Text('게시글 제목, 내용, 태그를 검색할 수 있습니다.'),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const Icon(Icons.trending_up_outlined),
            const Gap(8),
            Text(
              '인기 검색어',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const Gap(16),
        ...suggestions.map(
          (suggestion) => ListTile(
            leading: const Icon(Icons.search_outlined),
            title: Text(suggestion.token),
            subtitle: Text('${suggestion.count}회 검색'),
            onTap: () => _performSearch(suggestion.token),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyResults(String query) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_outlined, size: 64),
            const Gap(16),
            Text(
              "'$query'에 대한 검색 결과가 없습니다.",
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const Gap(8),
            const Text(
              '다른 검색어로 시도해보세요.',
              textAlign: TextAlign.center,
            ),
            const Gap(24),
            FilledButton.icon(
              onPressed: _clearSearch,
              icon: const Icon(Icons.refresh),
              label: const Text('새로 검색'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsHeader(String query, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.titleMedium,
                children: [
                  const TextSpan(text: "'"),
                  TextSpan(
                    text: query,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const TextSpan(text: "' 검색 결과 "),
                  TextSpan(
                    text: '$count개',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _performSearch(String query) {
    if (query.isEmpty) return;

    _searchController.text = query;
    context.read<SearchCubit>().search(query);
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<SearchCubit>().clearSearch();
  }
}