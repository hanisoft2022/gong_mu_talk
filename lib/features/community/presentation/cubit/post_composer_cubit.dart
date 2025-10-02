import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../../core/utils/image_compression_util.dart';
// Removed unused import
import '../../data/community_repository.dart';
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
    this.selectedLoungeId,
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
  final String? selectedLoungeId;
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
    String? selectedLoungeId,
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
      selectedLoungeId: selectedLoungeId ?? this.selectedLoungeId,
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
    selectedLoungeId,
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
    PostAudience initialAudience = PostAudience.all,
    String? initialLoungeId,
  }) : _repository = communityRepository,
       _authCubit = authCubit,
       super(PostComposerState(audience: initialAudience, selectedLoungeId: initialLoungeId));

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

void setLoungeId(String? loungeId) {
    emit(state.copyWith(selectedLoungeId: loungeId, submissionSuccess: false));
  }

  Future<void> addAttachmentFromGallery() async {
    // 최대 5개 이미지 제한
    if (state.attachments.length >= 5) {
      emit(state.copyWith(errorMessage: '최대 5개의 이미지만 첨부할 수 있습니다.'));
      return;
    }

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

  void removeAttachment(PostMediaDraft draft) {
    final List<PostMediaDraft> updated = List<PostMediaDraft>.from(state.attachments)
      ..remove(draft);
    emit(state.copyWith(attachments: updated, submissionSuccess: false));
  }

  Future<void> submitChirp() async {
    await _submitPost(type: PostType.chirp);
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

emit(state.copyWith(isSubmitting: true, errorMessage: null, submissionSuccess: false));

    try {
      final int supporterLevel = 0;
      final String serialValue = state.selectedLoungeId ?? authState.serial;

      debugPrint('🔍 [PostComposer] Creating post with:');
      debugPrint('   selectedLoungeId: ${state.selectedLoungeId}');
      debugPrint('   authState.serial: ${authState.serial}');
      debugPrint('   final serial: $serialValue');

      final Post post = await _repository.createPost(
        type: type,
        authorUid: uid,
        authorNickname: authState.nickname,
        authorTrack: authState.careerTrack,
        authorSerialVisible: authState.serialVisible,
        authorSupporterLevel: supporterLevel,
        authorIsSupporter: supporterLevel > 0,
        text: text,
        audience: type == PostType.chirp ? state.audience : PostAudience.all,
        serial: serialValue,
        media: const <PostMedia>[],
        tags: state.tags,
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

        await _repository.updatePost(postId: post.id, authorUid: uid, media: uploaded);
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
      emit(state.copyWith(isSubmitting: false, errorMessage: '게시글 등록 중 오류가 발생했습니다. 다시 시도해주세요.'));
    }
  }

  Future<void> _addAttachment(XFile file) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      // 이미지 압축 처리
      final XFile? compressedFile = await ImageCompressionUtil.compressImage(
        file,
        ImageCompressionType.post,
      );

      if (compressedFile == null) {
        throw const ImageCompressionException('이미지 압축에 실패했습니다.');
      }

      final Uint8List bytes = await compressedFile.readAsBytes();
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

      final String contentType =
          compressedFile.mimeType ?? _contentTypeFromExtension(compressedFile.name);
      final PostMediaDraft draft = PostMediaDraft(
        file: compressedFile,
        bytes: bytes,
        contentType: contentType,
        width: width,
        height: height,
      );

      final List<PostMediaDraft> updated = List<PostMediaDraft>.from(state.attachments)..add(draft);

      emit(state.copyWith(attachments: updated, submissionSuccess: false, isLoading: false));
    } on ImageCompressionException catch (e) {
      emit(state.copyWith(errorMessage: e.message, isLoading: false));
    } catch (e) {
      emit(state.copyWith(errorMessage: '이미지 처리 중 오류가 발생했습니다.', isLoading: false));
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
        emit(state.copyWith(isLoading: false, errorMessage: '게시글을 찾을 수 없습니다.'));
        return;
      }

      emit(
        state.copyWith(
          text: post.text,
          tags: post.tags,
          audience: post.audience,
          editingPost: post,
          isLoading: false,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: '게시글을 불러올 수 없습니다: $e'));
    }
  }
}
