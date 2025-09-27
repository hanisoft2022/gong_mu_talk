import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

class ImageProcessor {
  const ImageProcessor();

  static const int maxImageSize = 1920;
  static const int thumbnailSize = 300;
  static const int jpegQuality = 85;
  static const int thumbnailQuality = 70;

  Future<ImageProcessResult> processImage(Uint8List imageBytes) async {
    try {
      final img.Image? originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) {
        throw Exception('이미지를 처리할 수 없습니다.');
      }

      final int originalWidth = originalImage.width;
      final int originalHeight = originalImage.height;

      // Resize main image if too large
      img.Image processedImage = originalImage;
      if (originalWidth > maxImageSize || originalHeight > maxImageSize) {
        final double aspectRatio = originalWidth / originalHeight;
        int newWidth, newHeight;

        if (originalWidth > originalHeight) {
          newWidth = maxImageSize;
          newHeight = (maxImageSize / aspectRatio).round();
        } else {
          newHeight = maxImageSize;
          newWidth = (maxImageSize * aspectRatio).round();
        }

        processedImage = img.copyResize(
          originalImage,
          width: newWidth,
          height: newHeight,
          interpolation: img.Interpolation.cubic,
        );
      }

      // Create thumbnail
      final int thumbSize = thumbnailSize;
      final img.Image thumbnail = img.copyResize(
        originalImage,
        width: thumbSize,
        height: thumbSize,
        interpolation: img.Interpolation.cubic,
      );

      // Encode images
      final Uint8List processedBytes = Uint8List.fromList(
        img.encodeJpg(processedImage, quality: jpegQuality),
      );

      final Uint8List thumbnailBytes = Uint8List.fromList(
        img.encodeJpg(thumbnail, quality: thumbnailQuality),
      );

      return ImageProcessResult(
        processedImage: processedBytes,
        thumbnail: thumbnailBytes,
        originalWidth: originalWidth,
        originalHeight: originalHeight,
        processedWidth: processedImage.width,
        processedHeight: processedImage.height,
      );
    } catch (e) {
      throw Exception('이미지 처리 중 오류가 발생했습니다: $e');
    }
  }

  Future<Size> getImageDimensions(Uint8List imageBytes) async {
    final img.Image? image = img.decodeImage(imageBytes);
    if (image == null) {
      throw Exception('이미지 크기를 확인할 수 없습니다.');
    }
    return Size(image.width.toDouble(), image.height.toDouble());
  }

  bool isValidImageFormat(Uint8List bytes) {
    try {
      final img.Image? image = img.decodeImage(bytes);
      return image != null;
    } catch (e) {
      return false;
    }
  }

  String getImageMimeType(String filename) {
    final String extension = filename.toLowerCase().split('.').last;
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }
}

class ImageProcessResult {
  const ImageProcessResult({
    required this.processedImage,
    required this.thumbnail,
    required this.originalWidth,
    required this.originalHeight,
    required this.processedWidth,
    required this.processedHeight,
  });

  final Uint8List processedImage;
  final Uint8List thumbnail;
  final int originalWidth;
  final int originalHeight;
  final int processedWidth;
  final int processedHeight;

  double get compressionRatio {
    final int originalSize = originalWidth * originalHeight;
    final int processedSize = processedWidth * processedHeight;
    return originalSize == 0 ? 1.0 : processedSize / originalSize;
  }

  Size get originalSize =>
      Size(originalWidth.toDouble(), originalHeight.toDouble());
  Size get processedSize =>
      Size(processedWidth.toDouble(), processedHeight.toDouble());
}
