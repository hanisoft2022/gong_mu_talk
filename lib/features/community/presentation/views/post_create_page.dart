import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import '../../../../di/di.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../domain/models/board.dart';
import '../../domain/models/post.dart';
import '../cubit/post_composer_cubit.dart';

class PostCreatePage extends StatefulWidget {
  const PostCreatePage({super.key, this.postType, this.postId});

  final PostType? postType;
  final String? postId;

  @override
  State<PostCreatePage> createState() => _PostCreatePageState();
}

class _PostCreatePageState extends State<PostCreatePage> {
  late PostType _postType;

  @override
  void initState() {
    super.initState();
    _postType = widget.postType ?? PostType.chirp;
  }
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PostComposerCubit>(
      create: (_) {
        final cubit = PostComposerCubit(communityRepository: getIt(), authCubit: getIt<AuthCubit>());
        if (widget.postId != null) {
          cubit.loadPostForEditing(widget.postId!);
        }
        return cubit;
      },
      child: BlocConsumer<PostComposerCubit, PostComposerState>(
        listenWhen: (previous, current) =>
            previous.submissionSuccess != current.submissionSuccess || previous.errorMessage != current.errorMessage,
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
          } else if (state.submissionSuccess) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(const SnackBar(content: Text('게시글이 등록되었습니다.')));
            Navigator.of(context).pop(true);
          }
        },
        builder: (context, state) {
          final PostComposerCubit cubit = context.read<PostComposerCubit>();
          final ThemeData theme = Theme.of(context);

          if (_textController.text != state.text) {
            _textController.value = TextEditingValue(
              text: state.text,
              selection: TextSelection.collapsed(offset: state.text.length),
            );
          }
          final String joinedTags = state.tags.join(', ');
          if (_tagController.text != joinedTags) {
            _tagController.value = TextEditingValue(
              text: joinedTags,
              selection: TextSelection.collapsed(offset: joinedTags.length),
            );
          }

          return Scaffold(
            appBar: AppBar(
              title: const Text('새 글 작성'),
              actions: [
                TextButton(
                  onPressed: state.isSubmitting
                      ? null
                      : () {
                          if (_postType == PostType.chirp) {
                            cubit.submitChirp();
                          } else {
                            cubit.submitBoardPost();
                          }
                        },
                  child: state.isSubmitting
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('등록'),
                ),
              ],
            ),
            body: SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (widget.postType == null)
                    SegmentedButton<PostType>(
                      segments: const [
                        ButtonSegment<PostType>(
                          value: PostType.chirp,
                          label: Text('라운지'),
                          icon: Icon(Icons.bubble_chart_outlined),
                        ),
                        ButtonSegment<PostType>(
                          value: PostType.board,
                          label: Text('게시판'),
                          icon: Icon(Icons.article_outlined),
                        ),
                      ],
                      selected: <PostType>{_postType},
                      onSelectionChanged: (selection) {
                        setState(() {
                          _postType = selection.first;
                        });
                      },
                    ),
                  const Gap(16),
                  if (_postType == PostType.chirp) _ChirpOptions(state: state, cubit: cubit),
                  if (_postType == PostType.board) _BoardSelector(state: state, cubit: cubit),
                  const Gap(16),
                  TextField(
                    controller: _textController,
                    minLines: 6,
                    maxLines: 12,
                    onChanged: cubit.updateText,
                    decoration: const InputDecoration(
                      labelText: '내용',
                      hintText: '동료 공무원들과 나누고 싶은 이야기를 작성해주세요.',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const Gap(16),
                  TextField(
                    controller: _tagController,
                    onChanged: cubit.updateTags,
                    decoration: const InputDecoration(
                      labelText: '태그',
                      hintText: '# 없이 쉼표 또는 공백으로 구분해 입력하세요',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const Gap(20),
                  Text('이미지 첨부', style: theme.textTheme.titleMedium),
                  const Gap(8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final PostMediaDraft draft in state.attachments)
                        Stack(
                          alignment: Alignment.topRight,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(draft.bytes, width: 96, height: 96, fit: BoxFit.cover),
                            ),
                            Positioned(
                              right: 4,
                              top: 4,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black45,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minHeight: 28, minWidth: 28),
                                  icon: const Icon(Icons.close, size: 18, color: Colors.white),
                                  onPressed: () => cubit.removeAttachment(draft),
                                ),
                              ),
                            ),
                          ],
                        ),
                      GestureDetector(
                        onTap: state.isSubmitting
                            ? null
                            : () async {
                                await _showAttachmentPicker(context, cubit);
                              },
                        child: Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.add_a_photo_outlined, color: theme.colorScheme.primary),
                        ),
                      ),
                    ],
                  ),
                  const Gap(24),
                  if (state.isSubmitting) const LinearProgressIndicator(minHeight: 3),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showAttachmentPicker(BuildContext context, PostComposerCubit cubit) async {
    final ThemeData theme = Theme.of(context);
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('갤러리에서 선택'),
              onTap: () async {
                Navigator.of(context).pop();
                await cubit.addAttachmentFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('카메라 촬영'),
              onTap: () async {
                Navigator.of(context).pop();
                await cubit.addAttachmentFromCamera();
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(Icons.close, color: theme.colorScheme.error),
              title: Text('취소', style: TextStyle(color: theme.colorScheme.error)),
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChirpOptions extends StatelessWidget {
  const _ChirpOptions({required this.state, required this.cubit});

  final PostComposerState state;
  final PostComposerCubit cubit;

  @override
  Widget build(BuildContext context) {
    final PostAudience audience = state.audience;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('공개 범위', style: TextStyle(fontWeight: FontWeight.w600)),
        const Gap(8),
        SegmentedButton<PostAudience>(
          segments: const [
            ButtonSegment<PostAudience>(
              value: PostAudience.all,
              label: Text('전체 공개'),
              icon: Icon(Icons.public_outlined),
            ),
            ButtonSegment<PostAudience>(
              value: PostAudience.serial,
              label: Text('직렬 전용'),
              icon: Icon(Icons.group_outlined),
            ),
          ],
          selected: <PostAudience>{audience},
          onSelectionChanged: (selection) => cubit.selectAudience(selection.first),
        ),
      ],
    );
  }
}

class _BoardSelector extends StatelessWidget {
  const _BoardSelector({required this.state, required this.cubit});

  final PostComposerState state;
  final PostComposerCubit cubit;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    if (state.boards.isEmpty) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('게시판 선택', style: TextStyle(fontWeight: FontWeight.w600)),
          Gap(8),
          Text('게시판 목록을 불러오는 중입니다...'),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('게시판 선택', style: TextStyle(fontWeight: FontWeight.w600)),
        const Gap(8),
        DropdownButtonFormField<String>(
          initialValue: state.selectedBoardId,
          items: state.boards
              .map(
                (Board board) => DropdownMenuItem<String>(
                  value: board.id,
                  child: Row(
                    children: [
                      Text(board.name),
                      if (board.requireRealname)
                        const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Chip(label: Text('실명'), visualDensity: VisualDensity.compact),
                        ),
                    ],
                  ),
                ),
              )
              .toList(growable: false),
          onChanged: (value) {
            cubit.selectBoard(value);
            if (value != null) {
              final Board selected = state.boards.firstWhere((Board board) => board.id == value);
              cubit.toggleAnonymous(!selected.requireRealname);
            }
          },
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        const Gap(8),
        Row(
          children: [
            Switch.adaptive(value: state.isAnonymous, onChanged: (value) => cubit.toggleAnonymous(value)),
            const Gap(6),
            Text(state.isAnonymous ? '닉네임으로 게시' : '실명으로 게시', style: theme.textTheme.bodyMedium),
          ],
        ),
      ],
    );
  }
}
