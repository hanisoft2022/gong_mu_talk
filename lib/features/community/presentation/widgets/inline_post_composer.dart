import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../di/di.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../profile/domain/career_track.dart';
import '../../../profile/domain/lounge_info.dart';
import '../../../profile/presentation/widgets/profile_verification/government_email_verification_card.dart';
import '../../domain/models/feed_filters.dart';
import '../../domain/models/post.dart';
import '../cubit/community_feed_cubit.dart';
import '../cubit/post_composer_cubit.dart';

class InlinePostComposer extends StatefulWidget {
  const InlinePostComposer({
    super.key,
    required this.scope,
    this.selectedLoungeInfo,
  });

  final LoungeScope scope;
  final LoungeInfo? selectedLoungeInfo;

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
  void didUpdateWidget(InlinePostComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedLoungeInfo?.id != widget.selectedLoungeInfo?.id) {
      _lastScope = widget.scope;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PostComposerCubit>(
      create: (_) => PostComposerCubit(
        communityRepository: getIt(),
        authCubit: getIt<AuthCubit>(),
        initialAudience: PostAudience.all,
        initialLoungeId: widget.selectedLoungeInfo?.id ?? 'all',
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

          // 라운지 변경 감지 및 업데이트 (build 후 처리)
          final String currentLoungeId = widget.selectedLoungeInfo?.id ?? 'all';
          if (state.selectedLoungeId != currentLoungeId) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                context.read<PostComposerCubit>().setLoungeId(currentLoungeId);
              }
            });
          }

          if (_lastScope != widget.scope) {
            final PostAudience desiredAudience = _audienceForScope(
              scope: widget.scope,
              hasSerial: hasSerial,
            );
            if (state.audience != desiredAudience) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) {
                  context.read<PostComposerCubit>().selectAudience(
                    desiredAudience,
                  );
                }
              });
            }
            _lastScope = widget.scope;
          }

          if (!hasSerial && state.audience == PostAudience.serial) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                context.read<PostComposerCubit>().selectAudience(
                  PostAudience.all,
                );
              }
            });
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
                        _getTitleForScope(
                          widget.selectedLoungeInfo,
                          serialDisplayName,
                        ),
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
                  // 인증 안내 카드 (글쓰기 권한 없을 때)
                  if (!authState.hasLoungeWriteAccess) ...[
                    _buildVerificationPromptCard(context, authState),
                    const Gap(10),
                  ],
                  TextField(
                    controller: _controller,
                    minLines: 2,
                    maxLines: 4,
                    enabled:
                        !state.isSubmitting &&
                        authState.isGovernmentEmailVerified,
                    readOnly: !authState.isGovernmentEmailVerified,
                    onTap: authState.isGovernmentEmailVerified
                        ? null
                        : () => _showVerificationRequiredDialog(context),
                    onChanged: cubit.updateText,
                    decoration: InputDecoration(
                      hintText: authState.isGovernmentEmailVerified
                          ? '나누고 싶은 이야기를 적어보세요.'
                          : authState.isLoggedIn
                          ? '글 작성은 공직자 메일 인증 후 가능합니다'
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
    return PostAudience.all;
  }

  String _getTitleForScope(LoungeInfo? loungeInfo, String? serialDisplayName) {
    if (loungeInfo != null && loungeInfo.id != 'all') {
      return '${loungeInfo.name} 라운지에 글 남기기';
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

  void _showVerificationRequiredDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('공직자 메일 인증 필요'),
        content: const Text('글 작성은 공직자 메일 인증 후 가능합니다.\n지금 인증하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.push(GovernmentEmailVerificationCard.verificationRoute);
            },
            child: const Text('지금 인증하기'),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationPromptCard(BuildContext context, AuthState authState) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: InkWell(
        onTap: () => context.push(GovernmentEmailVerificationCard.verificationRoute),
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Icon(
              Icons.lock_outline,
              color: colorScheme.primary,
              size: 20,
            ),
            const Gap(10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '공직자 메일 인증이 필요합니다',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const Gap(2),
                  Text(
                    '지금 인증하고 라운지에 글을 남겨보세요',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
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
          right: 2,
          top: 2,
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minHeight: 18, minWidth: 18),
              icon: const Icon(Icons.close, size: 12, color: Colors.white),
              onPressed: onRemove,
            ),
          ),
        ),
      ],
    );
  }
}
