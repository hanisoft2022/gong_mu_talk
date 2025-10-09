/// Post content widget displaying text, tags, and media
///
/// Responsibilities:
/// - Display post text with expand/collapse logic
/// - Show "더보기" button for long text
/// - Display hashtags
/// - Show media preview (images)
///
/// Used by: PostCard

library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../domain/models/post.dart';

class PostContent extends StatelessWidget {
  const PostContent({
    super.key,
    required this.post,
    required this.isExpanded,
    required this.showMoreButton,
    required this.onExpand,
  });

  final Post post;
  final bool isExpanded;
  final bool showMoreButton;
  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Text content with expand/collapse
        if (isExpanded)
          Text(post.text, style: theme.textTheme.bodyLarge)
        else if (showMoreButton)
          _buildTextWithInlineMore(
            post.text,
            theme.textTheme.bodyLarge!,
            theme.colorScheme.primary,
          )
        else
          Text(
            post.text,
            style: theme.textTheme.bodyLarge,
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
          ),

        // Hashtags
        if (post.tags.isNotEmpty) ...[
          const Gap(10),
          Wrap(
            spacing: 6,
            runSpacing: -8,
            children: post.tags
                .map(
                  (String tag) => Chip(
                    label: Text('#$tag'),
                    visualDensity: VisualDensity.compact,
                  ),
                )
                .toList(growable: false),
          ),
        ],

        // Media preview
        if (post.media.isNotEmpty) ...[
          const Gap(8),
          RepaintBoundary(child: PostMediaPreview(mediaList: post.media)),
        ],
      ],
    );
  }

  /// Build text with inline "더보기" button
  Widget _buildTextWithInlineMore(
    String text,
    TextStyle textStyle,
    Color primaryColor,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: textStyle,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: onExpand,
              child: Text(
                '더보기',
                style: textStyle.copyWith(
                  color: primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Media preview widget for post images
class PostMediaPreview extends StatelessWidget {
  const PostMediaPreview({super.key, required this.mediaList});

  final List<PostMedia> mediaList;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    if (mediaList.length == 1) {
      final PostMedia media = mediaList.first;
      return GestureDetector(
        onTap: () => _showImageViewer(context, mediaList, 0),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: RepaintBoundary(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _SafePostImage(
                media: media,
                fit: BoxFit.cover,
                theme: theme,
              ),
            ),
          ),
        ),
      );
    }

    // Multiple images - show max 3 with "+N" badge if more
    final int displayCount = mediaList.length > 3 ? 3 : mediaList.length;
    final int remainingCount = mediaList.length - 3;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: displayCount,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        childAspectRatio: 1.0, // Square grid items
      ),
      itemBuilder: (context, index) {
        final PostMedia media = mediaList[index];
        final bool showBadge = index == 2 && remainingCount > 0;

        return GestureDetector(
          onTap: () => _showImageViewer(context, mediaList, index),
          child: RepaintBoundary(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _SafePostImage(
                    media: media,
                    fit: BoxFit.cover,
                    theme: theme,
                    showSmallSpinner: true,
                  ),
                  if (showBadge)
                    Container(
                      color: Colors.black.withValues(alpha: 0.6),
                      alignment: Alignment.center,
                      child: Text(
                        '+$remainingCount',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Show full-screen image viewer
void _showImageViewer(
  BuildContext context,
  List<PostMedia> mediaList,
  int initialIndex,
) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (context) =>
          _ImageViewerPage(mediaList: mediaList, initialIndex: initialIndex),
    ),
  );
}

/// Full-screen image viewer with zoom and swipe
class _ImageViewerPage extends StatefulWidget {
  const _ImageViewerPage({required this.mediaList, required this.initialIndex});

  final List<PostMedia> mediaList;
  final int initialIndex;

  @override
  State<_ImageViewerPage> createState() => _ImageViewerPageState();
}

class _ImageViewerPageState extends State<_ImageViewerPage> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Image viewer with swipe
          PageView.builder(
            controller: _pageController,
            itemCount: widget.mediaList.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final media = widget.mediaList[index];
              return InteractiveViewer(
                minScale: 1.0,
                maxScale: 4.0,
                child: Center(
                  child: CachedNetworkImage(
                    imageUrl: media.url,
                    fit: BoxFit.contain,
                    placeholder: (context, url) =>
                        const Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) => const Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        size: 64,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Top bar with close button and counter
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Close button
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.5),
                    ),
                  ),

                  // Image counter
                  if (widget.mediaList.length > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${_currentIndex + 1} / ${widget.mediaList.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper function to check if text should show "더보기" button
bool shouldShowMore(String text, BuildContext context) {
  final textStyle = Theme.of(context).textTheme.bodyLarge!;
  final textSpan = TextSpan(text: text, style: textStyle);
  final textPainter = TextPainter(
    text: textSpan,
    textDirection: TextDirection.ltr,
    maxLines: 5,
  );

  // Get the available width (approximate card content width)
  final screenWidth = MediaQuery.of(context).size.width;
  final cardPadding = 32.0; // Card padding (16 * 2)
  final cardMargin = 24.0; // Card margin
  final availableWidth = screenWidth - cardPadding - cardMargin;

  textPainter.layout(maxWidth: availableWidth);
  return textPainter.didExceedMaxLines;
}

/// Safe image widget that falls back to original URL if thumbnail fails
///
/// Handles cases where:
/// - thumbnailUrl is empty string (not null)
/// - thumbnailUrl points to non-existent file
/// - Thumbnail generation is still in progress
class _SafePostImage extends StatefulWidget {
  const _SafePostImage({
    required this.media,
    required this.fit,
    required this.theme,
    this.showSmallSpinner = false,
  });

  final PostMedia media;
  final BoxFit fit;
  final ThemeData theme;
  final bool showSmallSpinner;

  @override
  State<_SafePostImage> createState() => _SafePostImageState();
}

class _SafePostImageState extends State<_SafePostImage> {
  bool _useFallback = false;

  String? get _imageUrl {
    if (_useFallback) {
      // Use original URL on fallback
      final url = widget.media.url.trim();
      return url.isEmpty ? null : url;
    }

    // Use thumbnail if available and not empty
    final thumbnail = widget.media.thumbnailUrl;
    if (thumbnail != null && thumbnail.trim().isNotEmpty) {
      return thumbnail;
    }

    // Fall back to original URL
    final url = widget.media.url.trim();
    return url.isEmpty ? null : url;
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _imageUrl;

    // If no valid URL, show error immediately
    if (imageUrl == null) {
      return Container(
        color: widget.theme.colorScheme.surfaceContainerHighest,
        child: Icon(
          Icons.broken_image_outlined,
          size: widget.showSmallSpinner ? 32 : 48,
          color: widget.theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: widget.fit,
      placeholder: (context, url) => Container(
        color: widget.theme.colorScheme.surfaceContainerHighest,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: widget.showSmallSpinner ? 2 : 2,
          ),
        ),
      ),
      errorWidget: (context, url, error) {
        // If not already using fallback, try original URL
        if (!_useFallback && widget.media.thumbnailUrl != null) {
          // Schedule fallback attempt on next frame
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _useFallback = true;
              });
            }
          });
          // Show loading while switching to fallback
          return Container(
            color: widget.theme.colorScheme.surfaceContainerHighest,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        // If fallback also failed, show error icon
        return Container(
          color: widget.theme.colorScheme.surfaceContainerHighest,
          child: Icon(
            Icons.broken_image_outlined,
            size: widget.showSmallSpinner ? 32 : 48,
            color: widget.theme.colorScheme.onSurfaceVariant,
          ),
        );
      },
    );
  }
}
