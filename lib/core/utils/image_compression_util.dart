import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as path;

enum ImageCompressionType {
  post,
  comment,
}

class ImageCompressionUtil {
  static const int _maxFileSizeBytes = 10 * 1024 * 1024; // 10MB

  /// 이미지를 압축합니다.
  static Future<XFile?> compressImage(
    XFile originalFile,
    ImageCompressionType type,
  ) async {
    try {
      // 파일 크기 체크
      final File file = File(originalFile.path);
      final int fileSize = await file.length();

      if (fileSize > _maxFileSizeBytes) {
        throw const ImageCompressionException('파일 크기가 10MB를 초과합니다.');
      }

      // 파일 타입 검증
      if (!_isValidImageType(originalFile.path)) {
        throw const ImageCompressionException('지원하지 않는 이미지 형식입니다.\nJPEG, PNG, WebP, HEIC, GIF만 지원됩니다.');
      }

      // 임시적으로 압축 없이 원본 파일 반환 (플러그인 오류 해결 전까지)
      return originalFile;
    } catch (e) {
      if (e is ImageCompressionException) {
        rethrow;
      }
      throw ImageCompressionException('이미지 처리 중 오류가 발생했습니다: ${e.toString()}');
    }
  }


  /// 여러 이미지를 압축합니다.
  static Future<List<XFile>> compressImages(
    List<XFile> originalFiles,
    ImageCompressionType type, {
    Function(int current, int total)? onProgress,
  }) async {
    final List<XFile> compressedFiles = [];

    for (int i = 0; i < originalFiles.length; i++) {
      onProgress?.call(i + 1, originalFiles.length);

      final XFile? compressed = await compressImage(originalFiles[i], type);
      if (compressed != null) {
        compressedFiles.add(compressed);
      }
    }

    return compressedFiles;
  }

  /// 이미지 파일 타입 검증
  static bool _isValidImageType(String filePath) {
    final String extension = path.extension(filePath).toLowerCase();
    return ['.jpg', '.jpeg', '.png', '.webp', '.heic', '.heif', '.gif'].contains(extension);
  }

  /// 압축된 임시 파일들을 정리합니다.
  /// 현재는 임시적으로 비활성화 상태
  static Future<void> cleanupTempFiles() async {
    // 압축 기능이 비활성화된 상태이므로 정리할 임시 파일이 없음
  }

  /// 이미지 압축률 계산
  static Future<CompressionInfo> getCompressionInfo(
    XFile originalFile,
    XFile compressedFile,
  ) async {
    final int originalSize = await File(originalFile.path).length();
    final int compressedSize = await File(compressedFile.path).length();
    final double compressionRatio = (originalSize - compressedSize) / originalSize;

    return CompressionInfo(
      originalSizeBytes: originalSize,
      compressedSizeBytes: compressedSize,
      compressionRatio: compressionRatio,
      savedBytes: originalSize - compressedSize,
    );
  }
}

/// 이미지 압축 정보
class CompressionInfo {
  const CompressionInfo({
    required this.originalSizeBytes,
    required this.compressedSizeBytes,
    required this.compressionRatio,
    required this.savedBytes,
  });

  final int originalSizeBytes;
  final int compressedSizeBytes;
  final double compressionRatio;
  final int savedBytes;

  String get originalSizeFormatted => _formatBytes(originalSizeBytes);
  String get compressedSizeFormatted => _formatBytes(compressedSizeBytes);
  String get savedSizeFormatted => _formatBytes(savedBytes);
  String get compressionPercentage => '${(compressionRatio * 100).toStringAsFixed(1)}%';

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// 이미지 압축 예외
class ImageCompressionException implements Exception {
  const ImageCompressionException(this.message);

  final String message;

  @override
  String toString() => 'ImageCompressionException: $message';
}