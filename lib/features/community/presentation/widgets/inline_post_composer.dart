import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import '../../../../di/di.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../domain/models/post.dart';
import '../cubit/community_feed_cubit.dart';
import '../cubit/post_composer_cubit.dart';

class InlinePostComposer extends StatefulWidget {
  const InlinePostComposer({super.key});

  @override
  State<InlinePostComposer> createState() => _InlinePostComposerState();
}

class _InlinePostComposerState extends State<InlinePostComposer> {
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
    return BlocProvider<PostComposerCubit>(
      create: (_) => PostComposerCubit(
        communityRepository: getIt(),
        authCubit: getIt<AuthCubit>(),
      ),
      child: BlocConsumer<PostComposerCubit, PostComposerState>(
        listenWhen: (previous, current) =>
            previous.submissionSuccess != current.submissionSuccess ||
            previous.errorMessage != current.errorMessage,
        listener: (context, state) async {
          final messenger = ScaffoldMessenger.of(context);
          if (state.errorMessage != null) {
            messenger
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
            return;
          }

          if (state.submissionSuccess) {
            _controller.clear();
            if (context.mounted) {
              messenger
                ..hideCurrentSnackBar()
                ..showSnackBar(const SnackBar(content: Text('글이 등록되었어요.')));
              await context.read<CommunityFeedCubit>().refresh();
            }
          }
        },
        builder: (context, state) {
          final PostComposerCubit cubit = context.read<PostComposerCubit>();
          if (_controller.text != state.text) {
            _controller.value = TextEditingValue(
              text: state.text,
              selection: TextSelection.collapsed(offset: state.text.length),
            );
          }

          final ThemeData theme = Theme.of(context);
          final AuthState authState = context.watch<AuthCubit>().state;
          final bool hasSerial =
              authState.serial.isNotEmpty && authState.serial != 'unknown';
          final bool canSubmit = state.text.trim().isNotEmpty &&
              !state.isSubmitting && authState.isLoggedIn;

          return Card(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '라운지에 글 남기기',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (state.isSubmitting) ...[
                        const Gap(8),
                        const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ],
                      const Spacer(),
                      FilledButton(
                        onPressed: canSubmit
                            ? () async {
                                FocusScope.of(context).unfocus();
                                await cubit.submitChirp();
                              }
                            : null,
                        child: const Text('등록'),
                      ),
                    ],
                  ),
                  const Gap(12),
                  TextField(
                    controller: _controller,
                    minLines: 3,
                    maxLines: 6,
                    enabled: !state.isSubmitting,
                    onChanged: cubit.updateText,
                    decoration: InputDecoration(
                      hintText: authState.isLoggedIn
                          ? '동료 공무원들과 나누고 싶은 이야기를 적어보세요.'
                          : '로그인 후 글을 작성할 수 있어요.',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                    ),
                  ),
                  const Gap(12),
                  Row(
                    children: [
                      SegmentedButton<PostAudience>(
                        segments: [
                          const ButtonSegment<PostAudience>(
                            value: PostAudience.all,
                            label: Text('전체 공개'),
                            icon: Icon(Icons.public_outlined),
                          ),
                          ButtonSegment<PostAudience>(
                            value: PostAudience.serial,
                            label: const Text('내 직렬'),
                            icon: const Icon(Icons.badge_outlined),
                            enabled: hasSerial,
                          ),
                        ],
                        selected: <PostAudience>{state.audience},
                        onSelectionChanged: (selection) {
                          cubit.selectAudience(selection.first);
                        },
                      ),
                    ],
                  ),
                  if (!authState.isLoggedIn) ...[
                    const Gap(8),
                    Text(
                      '로그인 후 글을 등록할 수 있습니다.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ] else if (!hasSerial && state.audience == PostAudience.serial) ...[
                    const Gap(8),
                    Text(
                      '마이페이지에서 직렬 정보를 등록하면 직렬 전용으로 공유할 수 있어요.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
