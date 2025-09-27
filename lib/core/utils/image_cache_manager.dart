import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// 이미지 로딩 성능 최적화 유틸리티
class ImageCacheManager {
  /// 이미지 프리로드 - 다음 페이지 이미지들을 미리 캐시
  static Future<void> preloadImages(List<String> imageUrls) async {
    for (final url in imageUrls.take(3)) {
      // 최대 3개만 미리 로드
      try {
        await precacheImage(
          CachedNetworkImageProvider(url),
          navigatorKey.currentContext!,
        );
      } catch (e) {
        // 프리로드 실패는 무시
      }
    }
  }

  /// NavigatorKey - 프리로드를 위해 필요
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
}

/// 최적화된 CachedNetworkImage 위젯
class OptimizedCachedNetworkImage extends StatelessWidget {
  const OptimizedCachedNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.fadeInDuration = const Duration(milliseconds: 300),
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget Function(BuildContext, String)? placeholder;
  final Widget Function(BuildContext, String, dynamic)? errorWidget;
  final Duration fadeInDuration;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      fadeInDuration: fadeInDuration,
      memCacheWidth: width?.toInt(),
      memCacheHeight: height?.toInt(),
      maxWidthDiskCache: 1000, // 디스크 캐시 최대 너비
      maxHeightDiskCache: 1000, // 디스크 캐시 최대 높이
      placeholder:
          placeholder ??
          (context, url) => Container(
            width: width,
            height: height,
            color: theme.colorScheme.surfaceContainerHighest,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
      errorWidget:
          errorWidget ??
          (context, url, error) => Container(
            width: width,
            height: height,
            color: theme.colorScheme.surfaceContainerHighest,
            child: Icon(
              Icons.broken_image_outlined,
              size: (width != null && height != null)
                  ? (width! + height!) / 4
                  : 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
    );
  }
}
