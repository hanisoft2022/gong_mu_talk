/// ProfileImageSection
///
/// 프로필 이미지 편집 섹션 위젯
///
/// Phase 2 - Extracted from profile_page.dart
///
/// Features:
/// - 프로필 이미지 표시 (아바타)
/// - 프로필 사진 변경 버튼
/// - 이미지 선택 모달 (앨범 선택, 기본 이미지로 변경)
/// - 이미지 업로드 처리
///
/// File Size: ~140 lines (Green Zone ✅)
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import '../../../../auth/presentation/cubit/auth_cubit.dart';

class ProfileImageSection extends StatelessWidget {
  const ProfileImageSection({
    super.key,
    required this.photoUrl,
    required this.nickname,
    required this.isProcessing,
  });

  final String? photoUrl;
  final String nickname;
  final bool isProcessing;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      children: [
        _ProfileAvatar(photoUrl: photoUrl, nickname: nickname),
        const Gap(12),
        TextButton.icon(
          onPressed: isProcessing ? null : () => _showImagePicker(context),
          icon: Icon(
            Icons.camera_alt_outlined,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          label: Text(
            '프로필 사진 변경',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showImagePicker(BuildContext context) async {
    final ThemeData theme = Theme.of(context);
    final bool hasProfileImage = (photoUrl != null && photoUrl!.isNotEmpty);

    await showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('앨범에서 선택'),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  await _pickImageFromGallery(context);
                },
              ),
              if (hasProfileImage)
                ListTile(
                  leading: Icon(
                    Icons.delete_outline,
                    color: theme.colorScheme.error,
                  ),
                  title: Text(
                    '기본 이미지로 변경',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    await context.read<AuthCubit>().removeProfileImage();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImageFromGallery(BuildContext context) async {
    final AuthCubit authCubit = context.read<AuthCubit>();
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result == null) return;

      final PlatformFile file = result.files.single;
      final Uint8List? bytes = file.bytes;
      if (bytes == null) {
        throw PlatformException(
          code: 'bytes-unavailable',
          message: '선택한 파일 데이터를 불러오지 못했습니다.',
        );
      }

      final String extension = (file.extension ?? '').toLowerCase();
      final String contentType = extension.isNotEmpty
          ? 'image/$extension'
          : 'image/jpeg';

      await authCubit.updateProfileImage(
        bytes: bytes,
        fileName: file.name,
        contentType: contentType,
      );
    } on PlatformException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('이미지를 불러오지 못했습니다: ${error.message}'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.photoUrl, required this.nickname});

  final String? photoUrl;
  final String nickname;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return CircleAvatar(
      radius: 32,
      backgroundColor: photoUrl != null && photoUrl!.isNotEmpty
          ? Colors.transparent
          : theme.colorScheme.primaryContainer,
      backgroundImage: photoUrl != null && photoUrl!.isNotEmpty
          ? CachedNetworkImageProvider(photoUrl!)
          : null,
      child: photoUrl == null || photoUrl!.isEmpty
          ? Text(
              nickname.isEmpty ? '?' : nickname.characters.first,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            )
          : null,
    );
  }
}
