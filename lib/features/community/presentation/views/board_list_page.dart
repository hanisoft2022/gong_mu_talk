import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../di/di.dart';
import '../../domain/models/board.dart';
import '../cubit/board_catalog_cubit.dart';

class BoardListPage extends StatefulWidget {
  const BoardListPage({super.key});

  @override
  State<BoardListPage> createState() => _BoardListPageState();
}

class _BoardListPageState extends State<BoardListPage> {
  @override
  void initState() {
    super.initState();
    // load triggered when cubit is created in build.
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BoardCatalogCubit>(
      create: (_) => getIt<BoardCatalogCubit>()..loadBoards(),
      child: Scaffold(
        appBar: AppBar(title: const Text('게시판 선택')),
        body: BlocBuilder<BoardCatalogCubit, BoardCatalogState>(
          builder: (context, state) {
            switch (state.status) {
              case BoardCatalogStatus.initial:
              case BoardCatalogStatus.loading:
                return const Center(child: CircularProgressIndicator());
              case BoardCatalogStatus.error:
                return _BoardErrorView(
                  message: state.errorMessage ?? '게시판 목록을 불러오지 못했습니다.',
                  onRetry: () => context.read<BoardCatalogCubit>().loadBoards(),
                );
              case BoardCatalogStatus.loaded:
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final Board board = state.boards[index];
                    return ListTile(
                      title: Text(
                        board.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: board.description != null
                          ? Text(board.description!)
                          : null,
                      trailing: board.requireRealname
                          ? const Chip(label: Text('실명 필수'))
                          : const SizedBox.shrink(),
                      onTap: () => context.push(
                        '/community/boards/${board.id}',
                        extra: board,
                      ),
                    );
                  },
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemCount: state.boards.length,
                );
            }
          },
        ),
      ),
    );
  }
}

class _BoardErrorView extends StatelessWidget {
  const _BoardErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48),
          const Gap(12),
          Text(message, textAlign: TextAlign.center),
          const Gap(12),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }
}
