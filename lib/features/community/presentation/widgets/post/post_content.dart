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
          _buildTextWithInlineMore(post.text, theme.textTheme.bodyLarge!, theme.colorScheme.primary)
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
                  (String tag) => Chip(label: Text('#$tag'), visualDensity: VisualDensity.compact),
                )
                .toList(growable: false),
          ),
        ],

        // Media preview
        if (post.media.isNotEmpty) ...[
          const Gap(12),
          RepaintBoundary(
            child: PostMediaPreview(mediaList: post.media),
          ),
        ],
      ],
    );
  }

  /// Build text with inline "더보기" button
  Widget _buildTextWithInlineMore(String text, TextStyle textStyle, Color primaryColor) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(text, style: textStyle, maxLines: 5, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: onExpand,
              child: Text(
                '더보기',
                style: textStyle.copyWith(color: primaryColor, fontWeight: FontWeight.w500),
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
  const PostMediaPreview({
    super.key,
    required this.mediaList,
  });

  final List<PostMedia> mediaList;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    if (mediaList.length == 1) {
      final PostMedia media = mediaList.first;
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: RepaintBoundary(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
            imageUrl: media.thumbnailUrl ?? media.url,
            placeholder: (context, url) => Container(
              color: theme.colorScheme.surfaceContainerHighest,
              child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            errorWidget: (context, url, error) => const Icon(Icons.broken_image_outlined, size: 48),
            fit: BoxFit.cover,
          ),
        ),
        ),
      );
    }

    // Multiple images - show max 3 with "+N" badge if more
    final int displayCount = mediaList.length > 3 ? 3 : mediaList.length;
    final int remainingCount = mediaList.length - 3;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: displayCount,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          childAspectRatio: 1.0,  // Square grid items
        ),
        itemBuilder: (context, index) {
          final PostMedia media = mediaList[index];
          final bool showBadge = index == 2 && remainingCount > 0;

          return RepaintBoundary(
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: media.thumbnailUrl ?? media.url,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  errorWidget: (context, url, error) => const Icon(Icons.broken_image_outlined),
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
          );
        },
      ),
    );
  }
}

/// Helper function to check if text should show "더보기" button
bool shouldShowMore(String text, BuildContext context) {
  final textStyle = Theme.of(context).textTheme.bodyLarge!;
  final textSpan = TextSpan(text: text, style: textStyle);
  final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr, maxLines: 5);

  // Get the available width (approximate card content width)
  final screenWidth = MediaQuery.of(context).size.width;
  final cardPadding = 32.0; // Card padding (16 * 2)
  final cardMargin = 24.0; // Card margin
  final availableWidth = screenWidth - cardPadding - cardMargin;

  textPainter.layout(maxWidth: availableWidth);
  return textPainter.didExceedMaxLines;
}
