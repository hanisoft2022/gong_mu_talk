import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import '../../../../di/di.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../domain/models/feed_filters.dart';
import '../../domain/models/post.dart';
import '../cubit/community_feed_cubit.dart';
import '../cubit/post_composer_cubit.dart';

class InlinePostComposer extends StatefulWidget {
  const InlinePostComposer({super.key, required this.scope});

  final LoungeScope scope;

  @override
  State<InlinePostComposer> createState() => _InlinePostComposerState();
}

PostAudience _audienceForScope(LoungeScope scope) {
  return scope == LoungeScope.serial ? PostAudience.serial : PostAudience.all;
}

class _AudienceHint extends StatelessWidget {
  const _AudienceHint({required this.audience});

  final PostAudience audience;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isSerial = audience == PostAudience.serial;
    final IconData icon = isSerial
        ? Icons.badge_outlined
        : Icons.public_outlined;
    final String label = isSerial ? '내 직렬' : '전체 공개';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const Gap(6),
          Text(
            '$label로 게시됩니다.',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
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
        initialAudience: _audienceForScope(widget.scope),
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
          final PostAudience desiredAudience = _audienceForScope(widget.scope);

          if (state.audience != desiredAudience) {
            cubit.selectAudience(desiredAudience);
          }

          final bool canSubmit =
              state.text.trim().isNotEmpty &&
              !state.isSubmitting &&
              authState.isLoggedIn &&
              (desiredAudience != PostAudience.serial || hasSerial);

          return Card(
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
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
                        const Gap(6),
                        const SizedBox(
                          height: 14,
                          width: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ],
                      const Spacer(),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          textStyle: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
                  const Gap(10),
                  TextField(
                    controller: _controller,
                    minLines: 2,
                    maxLines: 4,
                    enabled: !state.isSubmitting,
                    onChanged: cubit.updateText,
                    decoration: InputDecoration(
                      hintText: authState.isLoggedIn
                          ? '동료 공무원들과 나누고 싶은 이야기를 적어보세요.'
                          : '로그인 후 글을 작성할 수 있어요.',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      filled: true,
                    ),
                  ),
                  const Gap(10),
                  _AudienceHint(audience: desiredAudience),
                  if (!authState.isLoggedIn) ...[
                    const Gap(6),
                    Text(
                      '로그인 후 글을 등록할 수 있습니다.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ] else if (!hasSerial &&
                      desiredAudience == PostAudience.serial) ...[
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
