import 'dart:io';

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

  /// Pick and compress a single image for comment
  Future<XFile?> pickAndCompressImage(
    BuildContext context, {
    List<XFile> currentImages = const [],
    VoidCallback? onStart,
    VoidCallback? onComplete,
  }) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) return null;

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
        final String year = now.year.toString();
        final String month = now.month.toString().padLeft(2, '0');
        final String fileName =
            'comments/$year/$month/$postId/${userId}_${now.millisecondsSinceEpoch}.jpg';

        final Reference ref = FirebaseStorage.instance.ref().child(fileName);
        final UploadTask uploadTask = ref.putFile(File(image.path));

        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final double progress = snapshot.bytesTransferred / snapshot.totalBytes;
          final double totalProgress = (i + progress) / images.length;
          onProgress(totalProgress);
        });

        final TaskSnapshot snapshot = await uploadTask;
        final String downloadUrl = await snapshot.ref.getDownloadURL();

        imageUrls.add(downloadUrl);
      }

      return imageUrls;
    } catch (e) {
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('이미지 업로드 중 오류가 발생했습니다'),
              behavior: SnackBarBehavior.floating,
            ),
          );
      }
      return [];
    }
  }
}
