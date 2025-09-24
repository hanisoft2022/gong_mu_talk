import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../auth/presentation/cubit/auth_cubit.dart';
// Removed unused import
import '../../data/community_repository.dart';
import '../../domain/models/board.dart';
import '../../domain/models/post.dart';

class PostMediaDraft extends Equatable {
  const PostMediaDraft({
    required this.file,
    required this.bytes,
    required this.contentType,
    this.width,
    this.height,
  });

  final XFile file;
  final Uint8List bytes;
  final String contentType;
  final int? width;
  final int? height;

  String get fileName => file.name;

  @override
  List<Object?> get props => <Object?>[file.path, contentType, width, height, bytes];
}

class PostComposerState extends Equatable {
  const PostComposerState({
    this.text = '',
    this.tags = const <String>[],
    this.audience = PostAudience.all,
    this.isSubmitting = false,
    this.isAnonymous = true,
    this.attachments = const <PostMediaDraft>[],
    this.boards = const <Board>[],
    this.selectedBoardId,
    this.errorMessage,
    this.submissionSuccess = false,
    this.editingPost,
    this.isLoading = false,
  });

  final String text;
  final List<String> tags;
  final PostAudience audience;
  final bool isSubmitting;
  final bool isAnonymous;
  final List<PostMediaDraft> attachments;
  final List<Board> boards;
  final String? selectedBoardId;
  final String? errorMessage;
  final bool submissionSuccess;
  final Post? editingPost;
  final bool isLoading;

  PostComposerState copyWith({
    String? text,
    List<String>? tags,
    PostAudience? audience,
    bool? isSubmitting,
    bool? isAnonymous,
    List<PostMediaDraft>? attachments,
    List<Board>? boards,
    String? selectedBoardId,
    String? errorMessage,
    bool? submissionSuccess,
    Post? editingPost,
    bool? isLoading,
  }) {
    return PostComposerState(
      text: text ?? this.text,
      tags: tags ?? this.tags,
      audience: audience ?? this.audience,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      attachments: attachments ?? this.attachments,
      boards: boards ?? this.boards,
      selectedBoardId: selectedBoardId ?? this.selectedBoardId,
      errorMessage: errorMessage,
      submissionSuccess: submissionSuccess ?? this.submissionSuccess,
      editingPost: editingPost ?? this.editingPost,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    text,
    tags,
    audience,
    isSubmitting,
    isAnonymous,
    attachments,
    boards,
    selectedBoardId,
    errorMessage,
    submissionSuccess,
    editingPost,
    isLoading,
  ];
}

class PostComposerCubit extends Cubit<PostComposerState> {
  PostComposerCubit({
    required CommunityRepository communityRepository,
    required AuthCubit authCubit,
  }) : _repository = communityRepository,
       _authCubit = authCubit,
       super(const PostComposerState()) {
    unawaited(_loadBoards());
  }

  final CommunityRepository _repository;
  final AuthCubit _authCubit;
  final ImagePicker _picker = ImagePicker();

  void updateText(String value) {
    emit(state.copyWith(text: value, errorMessage: null, submissionSuccess: false));
  }

  void updateTags(String raw) {
    final List<String> parsed = raw
        .split(RegExp(r'[#,\s]+'))
        .where((String tag) => tag.trim().isNotEmpty)
        .map((String tag) => tag.trim())
        .toSet()
        .toList(growable: false);
    emit(state.copyWith(tags: parsed, submissionSuccess: false));
  }

  void selectAudience(PostAudience audience) {
    emit(state.copyWith(audience: audience, submissionSuccess: false));
  }

  void toggleAnonymous(bool value) {
    emit(state.copyWith(isAnonymous: value, submissionSuccess: false));
  }

  void selectBoard(String? boardId) {
    emit(state.copyWith(selectedBoardId: boardId, submissionSuccess: false));
  }

  Future<void> addAttachmentFromGallery() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2048,
      imageQuality: 85,
    );
    if (file == null) {
      return;
    }

    await _addAttachment(file);
  }

  Future<void> addAttachmentFromCamera() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 2048,
      imageQuality: 85,
    );
    if (file == null) {
      return;
    }

    await _addAttachment(file);
  }

  void removeAttachment(PostMediaDraft draft) {
    final List<PostMediaDraft> updated = List<PostMediaDraft>.from(state.attachments)
      ..remove(draft);
    emit(state.copyWith(attachments: updated, submissionSuccess: false));
  }

  Future<void> submitChirp() async {
    await _submitPost(type: PostType.chirp);
  }

  Future<void> submitBoardPost() async {
    await _submitPost(type: PostType.board);
  }

  Future<void> _submitPost({required PostType type}) async {
    final AuthState authState = _authCubit.state;
    final String? uid = authState.userId;
    if (uid == null) {
      emit(state.copyWith(errorMessage: '로그인 후 글을 작성할 수 있습니다.'));
      return;
    }

    final String text = state.text.trim();
    if (text.isEmpty) {
      emit(state.copyWith(errorMessage: '본문을 입력해주세요.'));
      return;
    }

    if (type == PostType.board && (state.selectedBoardId == null || state.selectedBoardId!.isEmpty)) {
      emit(state.copyWith(errorMessage: '게시판을 선택해주세요.'));
      return;
    }

    emit(state.copyWith(isSubmitting: true, errorMessage: null, submissionSuccess: false));

    try {
      final Post post = await _repository.createPost(
        type: type,
        authorUid: uid,
        authorNickname: authState.nickname,
        authorTrack: authState.careerTrack,
        text: text,
        audience: type == PostType.chirp ? state.audience : PostAudience.all,
        serial: authState.serial,
        media: const <PostMedia>[],
        tags: state.tags,
        boardId: type == PostType.board ? state.selectedBoardId : null,
      );

      if (state.attachments.isNotEmpty) {
        final List<PostMedia> uploaded = <PostMedia>[];
        for (final PostMediaDraft draft in state.attachments) {
          final PostMedia media = await _repository.uploadPostImage(
            uid: uid,
            postId: post.id,
            fileName: draft.fileName,
            bytes: draft.bytes,
            contentType: draft.contentType,
            width: draft.width,
            height: draft.height,
          );
          uploaded.add(media);
        }

        await _repository.updatePost(
          postId: post.id,
          authorUid: uid,
          media: uploaded,
        );
      }

      emit(
        state.copyWith(
          isSubmitting: false,
          submissionSuccess: true,
          text: '',
          tags: const <String>[],
          attachments: const <PostMediaDraft>[],
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: '게시글 등록 중 오류가 발생했습니다. 다시 시도해주세요.',
        ),
      );
    }
  }

  Future<void> _addAttachment(XFile file) async {
    final Uint8List bytes = await file.readAsBytes();
    int? width;
    int? height;
    try {
      final Completer<ui.Image> completer = Completer<ui.Image>();
      ui.decodeImageFromList(bytes, (ui.Image img) => completer.complete(img));
      final ui.Image decoded = await completer.future;
      width = decoded.width;
      height = decoded.height;
    } catch (_) {
      width = null;
      height = null;
    }

    final String contentType = file.mimeType ?? _contentTypeFromExtension(file.name);
    final PostMediaDraft draft = PostMediaDraft(
      file: file,
      bytes: bytes,
      contentType: contentType,
      width: width,
      height: height,
    );

    final List<PostMediaDraft> updated = List<PostMediaDraft>.from(state.attachments)
      ..add(draft);
    emit(state.copyWith(attachments: updated, submissionSuccess: false));
  }

  Future<void> _loadBoards() async {
    try {
      final List<Board> boards = await _repository.fetchBoards();
      emit(state.copyWith(boards: boards));
    } catch (_) {
      // Silently ignore board load failures to avoid showing a global snackbar
      // when the composer opens in '라운지' mode. The board selector UI will
      // handle empty lists gracefully.
      emit(state.copyWith(boards: const <Board>[], errorMessage: null));
    }
  }

  String _contentTypeFromExtension(String fileName) {
    final String lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) {
      return 'image/png';
    }
    if (lower.endsWith('.gif')) {
      return 'image/gif';
    }
    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }
    return 'image/jpeg';
  }

  Future<void> loadPostForEditing(String postId) async {
    try {
      emit(state.copyWith(isLoading: true, errorMessage: null));
      final Post? post = await _repository.getPost(postId);

      if (post == null) {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: '게시글을 찾을 수 없습니다.',
        ));
        return;
      }

      emit(state.copyWith(
        text: post.text,
        tags: post.tags,
        audience: post.audience,
        selectedBoardId: post.boardId,
        editingPost: post,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: '게시글을 불러올 수 없습니다: $e',
      ));
    }
  }
}
