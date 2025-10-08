import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/utils/image_compression_util.dart';

/// Comment Image Uploader
///
/// Responsibilities:
/// - Pick images from gallery
/// - Compress images for comments
/// - Upload to Firebase Storage with progress tracking
/// - Handle single image limitation for comments
///
/// Usage:
/// ```dart
/// final uploader = CommentImageUploader();
/// final result = await uploader.pickAndCompressImage(context);
/// if (result != null) {
///   final urls = await uploader.uploadImages([result], ...);
/// }
/// ```
class CommentImageUploader {
  final ImagePicker _imagePicker = ImagePicker();
  bool _isPickingImage = false; // ImagePicker 중복 호출 방지 플래그

  /// Pick and compress a single image for comment
  Future<XFile?> pickAndCompressImage(
    BuildContext context, {
    List<XFile> currentImages = const [],
    VoidCallback? onStart,
    VoidCallback? onComplete,
  }) async {
    // ImagePicker 중복 호출 방지
    if (_isPickingImage) {
      return null;
    }

    _isPickingImage = true;
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
        requestFullMetadata: false, // iOS HEIC → JPEG 자동 변환
      );

      if (image == null) {
        _isPickingImage = false;
        return null;
      }

      // Check if need to replace existing image
      if (currentImages.isNotEmpty && context.mounted) {
        final bool? replace = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('이미지 교체'),
            content: const Text('댓글에는 이미지를 1장만 첨부할 수 있습니다. 기존 이미지를 교체하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('교체'),
              ),
            ],
          ),
        );

        if (replace != true) return null;
      }

      onStart?.call();

      try {
        final XFile? compressedImage = await ImageCompressionUtil.compressImage(
          image,
          ImageCompressionType.comment,
        );

        onComplete?.call();

        if (compressedImage != null) {
          return compressedImage;
        } else {
          throw const ImageCompressionException('이미지 압축에 실패했습니다.');
        }
      } on ImageCompressionException catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(e.message),
                duration: const Duration(seconds: 3),
                behavior: SnackBarBehavior.floating,
              ),
            );
        }
        onComplete?.call();
        return null;
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(
                content: Text('이미지 처리 중 오류가 발생했습니다.'),
                duration: Duration(seconds: 3),
                behavior: SnackBarBehavior.floating,
              ),
            );
        }
        onComplete?.call();
        return null;
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('이미지를 선택하는 중 오류가 발생했습니다'),
              behavior: SnackBarBehavior.floating,
            ),
          );
      }
      return null;
    } finally {
      _isPickingImage = false;
    }
  }

  /// Upload images to Firebase Storage with progress tracking
  Future<List<String>> uploadImages({
    required List<XFile> images,
    required String userId,
    required String postId,
    required Function(double) onProgress,
    BuildContext? context,
  }) async {
    if (images.isEmpty) return [];

    try {
      final List<String> imageUrls = [];

      for (int i = 0; i < images.length; i++) {
        final XFile image = images[i];
        final DateTime now = DateTime.now();

        // 파일명 생성 (.webp 확장자)
        final String fileName = '${userId}_${now.millisecondsSinceEpoch}.webp';

        // 올바른 경로 사용: comment_images/{userId}/{postId}/{fileName}
        final String filePath = 'comment_images/$userId/$postId/$fileName';

        final Reference ref = FirebaseStorage.instance.ref().child(filePath);

        // 파일 데이터 읽기
        final Uint8List bytes = await image.readAsBytes();

        // CDN 캐싱 설정: 7일
        final UploadTask uploadTask = ref.putData(
          bytes,
          SettableMetadata(
            contentType: 'image/webp',
            cacheControl: 'public, max-age=604800', // 7 days
          ),
        );

        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final double progress =
              snapshot.bytesTransferred / snapshot.totalBytes;
          final double totalProgress = (i + progress) / images.length;
          onProgress(totalProgress);
        });

        final TaskSnapshot snapshot = await uploadTask;
        final String downloadUrl = await snapshot.ref.getDownloadURL();

        imageUrls.add(downloadUrl);
      }

      return imageUrls;
    } on FirebaseException catch (e) {

      String errorMessage = '이미지 업로드 중 오류가 발생했습니다';
      if (e.code == 'permission-denied' || e.code == 'unauthorized') {
        errorMessage = '이미지 업로드 권한이 없습니다.\n앱을 재시작하거나 다시 로그인해주세요.';
      } else if (e.code == 'quota-exceeded') {
        errorMessage = '저장 공간이 부족합니다. 잠시 후 다시 시도해주세요.';
      } else if (e.code == 'unauthenticated') {
        errorMessage = '인증이 만료되었습니다. 다시 로그인해주세요.';
      } else {
        // 개발 중에는 더 자세한 에러 메시지 표시
        errorMessage = '이미지 업로드 실패\n오류 코드: ${e.code}';
      }

      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: '다시 시도',
                onPressed: () {
                  // User can retry manually
                },
              ),
            ),
          );
      }
      return [];
    } catch (e) {
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('이미지 업로드 중 오류가 발생했습니다\n오류: ${e.toString()}'),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 5),
            ),
          );
      }
      return [];
    }
  }
}
