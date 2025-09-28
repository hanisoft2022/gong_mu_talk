import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

enum ImageCompressionType {
  post,
  comment,
}

class ImageCompressionUtil {
  static const int _postMaxWidth = 1200;
  static const int _postMaxHeight = 1200;
  static const int _postQuality = 80;

  static const int _commentMaxWidth = 800;
  static const int _commentMaxHeight = 800;
  static const int _commentQuality = 75;

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
        throw const ImageCompressionException('지원하지 않는 이미지 형식입니다. (JPEG, PNG, WebP만 지원)');
      }

      // 임시적으로 압축 없이 원본 파일 반환 (플러그인 오류 해결 전까지)
      // TODO: flutter_image_compress 플러그인 이슈 해결 후 압축 기능 활성화
      return originalFile;

      // 아래 코드는 플러그인 이슈 해결 후 활성화
      /*
      // 압축 설정
      final int maxWidth = type == ImageCompressionType.post ? _postMaxWidth : _commentMaxWidth;
      final int maxHeight = type == ImageCompressionType.post ? _postMaxHeight : _commentMaxHeight;
      final int quality = type == ImageCompressionType.post ? _postQuality : _commentQuality;

      // 임시 디렉토리 생성
      final Directory tempDir = await getTemporaryDirectory();
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_compressed.jpg';
      final String targetPath = path.join(tempDir.path, fileName);

      // 이미지 압축 실행
      final XFile? compressedFile = await FlutterImageCompress.compressAndGetFile(
        originalFile.path,
        targetPath,
        minWidth: maxWidth ~/ 2, // 최소 크기 설정
        minHeight: maxHeight ~/ 2,
        quality: quality,
        format: CompressFormat.jpeg, // 일관된 포맷 사용
        keepExif: false, // 메타데이터 제거로 보안 강화
        autoCorrectionAngle: true, // 자동 회전 보정
      );

      if (compressedFile == null) {
        throw const ImageCompressionException('이미지 압축에 실패했습니다.');
      }

      // 압축 후 파일 크기 재검증
      final File compressedFileObj = File(compressedFile.path);
      final int compressedSize = await compressedFileObj.length();

      if (compressedSize > _maxFileSizeBytes) {
        // 압축 후에도 크기가 클 경우 품질을 더 낮춰서 재압축
        await compressedFileObj.delete();
        return await _recompressWithLowerQuality(originalFile, type, quality - 20);
      }

      return compressedFile;
      */
    } catch (e) {
      if (e is ImageCompressionException) {
        rethrow;
      }
      throw ImageCompressionException('이미지 처리 중 오류가 발생했습니다: ${e.toString()}');
    }
  }

  /// 품질을 낮춰서 재압축
  static Future<XFile?> _recompressWithLowerQuality(
    XFile originalFile,
    ImageCompressionType type,
    int quality,
  ) async {
    if (quality < 30) {
      throw const ImageCompressionException('이미지 크기가 너무 큽니다. 다른 이미지를 선택해주세요.');
    }

    final int maxWidth = type == ImageCompressionType.post ? _postMaxWidth : _commentMaxWidth;
    final int maxHeight = type == ImageCompressionType.post ? _postMaxHeight : _commentMaxHeight;

    final Directory tempDir = await getTemporaryDirectory();
    final String fileName = '${DateTime.now().millisecondsSinceEpoch}_recompressed.jpg';
    final String targetPath = path.join(tempDir.path, fileName);

    final XFile? recompressedFile = await FlutterImageCompress.compressAndGetFile(
      originalFile.path,
      targetPath,
      minWidth: maxWidth ~/ 3,
      minHeight: maxHeight ~/ 3,
      quality: quality,
      format: CompressFormat.jpeg,
      keepExif: false,
      autoCorrectionAngle: true,
    );

    if (recompressedFile == null) {
      throw const ImageCompressionException('이미지 압축에 실패했습니다.');
    }

    final File recompressedFileObj = File(recompressedFile.path);
    final int recompressedSize = await recompressedFileObj.length();

    if (recompressedSize > _maxFileSizeBytes) {
      await recompressedFileObj.delete();
      return await _recompressWithLowerQuality(originalFile, type, quality - 20);
    }

    return recompressedFile;
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
    return ['.jpg', '.jpeg', '.png', '.webp'].contains(extension);
  }

  /// 압축된 임시 파일들을 정리합니다.
  static Future<void> cleanupTempFiles() async {
    try {
      final Directory tempDir = await getTemporaryDirectory();
      final List<FileSystemEntity> files = tempDir.listSync();

      for (final FileSystemEntity file in files) {
        if (file is File && file.path.contains('compressed')) {
          final DateTime now = DateTime.now();
          final FileStat stat = await file.stat();
          final Duration age = now.difference(stat.modified);

          // 1시간 이상 된 압축 파일들 삭제
          if (age.inHours >= 1) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      // 정리 실패는 무시 (중요하지 않음)
    }
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