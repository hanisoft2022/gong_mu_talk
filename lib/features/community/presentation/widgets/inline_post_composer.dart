import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import '../../../../di/di.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../profile/domain/career_track.dart';
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


class _InlinePostComposerState extends State<InlinePostComposer> {
  late final TextEditingController _controller;
  late LoungeScope _lastScope;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _lastScope = widget.scope;
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
        initialAudience: widget.scope == LoungeScope.serial
            ? PostAudience.serial
            : PostAudience.all,
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
          final String? serialDisplayName = hasSerial
              ? _serialDisplayName(authState)
              : null;

          if (_lastScope != widget.scope) {
            final PostAudience desiredAudience = _audienceForScope(
              scope: widget.scope,
              hasSerial: hasSerial,
            );
            if (state.audience != desiredAudience) {
              cubit.selectAudience(desiredAudience);
            }
            _lastScope = widget.scope;
          }

          if (!hasSerial && state.audience == PostAudience.serial) {
            cubit.selectAudience(PostAudience.all);
          }

          final bool canSubmit =
              state.text.trim().isNotEmpty &&
              !state.isSubmitting &&
              authState.isLoggedIn &&
              (state.audience != PostAudience.serial || hasSerial);

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
                        _getTitleForScope(widget.scope, serialDisplayName),
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
                          ? '나누고 싶은 이야기를 적어보세요.'
                          : '로그인 후 글을 작성할 수 있어요.',
                      hintStyle: theme.textTheme.bodyMedium,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      filled: true,
                    ),
                  ),
                  if (state.attachments.isNotEmpty) ...[
                    const Gap(10),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: state.attachments
                          .map(
                            (PostMediaDraft draft) => _AttachmentPreview(
                              draft: draft,
                              onRemove: () => cubit.removeAttachment(draft),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ],
                  const Gap(10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      IconButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          minimumSize: const Size(0, 32),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          textStyle: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: state.isSubmitting
                            ? null
                            : () async {
                                await cubit.addAttachmentFromGallery();
                              },
                        icon: const Icon(
                          Icons.photo_library_outlined,
                          size: 18,
                        ),
                      ),
                      const Spacer(),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          minimumSize: const Size(0, 32),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          textStyle: theme.textTheme.labelMedium?.copyWith(
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
                  if (!authState.isLoggedIn) ...[
                    const Gap(6),
                    Text(
                      '로그인 후 글을 등록할 수 있습니다.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ] else if (!hasSerial &&
                      state.audience == PostAudience.serial) ...[
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

  PostAudience _audienceForScope({
    required LoungeScope scope,
    required bool hasSerial,
  }) {
    if (scope == LoungeScope.serial && hasSerial) {
      return PostAudience.serial;
    }
    return PostAudience.all;
  }

  String _getTitleForScope(LoungeScope scope, String? serialDisplayName) {
    if (scope == LoungeScope.serial && serialDisplayName != null) {
      return '$serialDisplayName 라운지에 글 남기기';
    }
    return '전체 라운지에 글 남기기';
  }

  String? _serialDisplayName(AuthState authState) {
    final CareerTrack track = authState.careerTrack;
    if (track != CareerTrack.none) {
      return track.displayName;
    }

    final String serial = authState.serial;
    final String normalized = serial.trim().toLowerCase();
    for (final CareerTrack candidate in CareerTrack.values) {
      if (candidate == CareerTrack.none) {
        continue;
      }
      if (normalized.contains(candidate.name.toLowerCase())) {
        return candidate.displayName;
      }
    }

    return null;
  }
}

class _AttachmentPreview extends StatelessWidget {
  const _AttachmentPreview({required this.draft, required this.onRemove});

  final PostMediaDraft draft;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topRight,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            draft.bytes,
            width: 72,
            height: 72,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          right: 4,
          top: 4,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minHeight: 24, minWidth: 24),
              icon: const Icon(Icons.close, size: 16, color: Colors.white),
              onPressed: onRemove,
            ),
          ),
        ),
      ],
    );
  }
}
