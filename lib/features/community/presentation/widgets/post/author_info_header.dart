import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../domain/models/feed_filters.dart';
import '../../../domain/models/post.dart';
import '../../../../profile/domain/career_track.dart';
import '../comment_utils.dart';

class AuthorInfoHeader extends StatelessWidget {
  const AuthorInfoHeader({super.key, required this.post, required this.scope});

  final Post post;
  final LoungeScope scope;

  bool get _isSerialScope => scope == LoungeScope.serial;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 12, top: 4, bottom: 4),
      child: _isSerialScope
          ? _buildSerialHeader(theme)
          : _buildPublicHeader(theme),
    );
  }

  Widget _buildSerialHeader(ThemeData theme) {
    final Widget? supporter = _buildSupporterBadge(theme);
    final TextStyle nameStyle =
        theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600) ??
        const TextStyle(fontSize: 15, fontWeight: FontWeight.w600);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
          foregroundColor: theme.colorScheme.primary,
          child: Text(_avatarInitial(), style: nameStyle),
        ),
        const Gap(10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (supporter != null) ...[supporter, const Gap(6)],
                  Expanded(
                    child: Text(
                      maskNickname(post.authorNickname.isNotEmpty ? post.authorNickname : post.authorUid),
                      style: nameStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (scope != LoungeScope.serial) ...[
                const Gap(2),
                Text(
                  serialLabel(
                    post.authorTrack,
                    post.authorSerialVisible,
                    includeEmoji: true,
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPublicHeader(ThemeData theme) {
    final Widget? supporter = _buildSupporterBadge(theme);
    final TextStyle nameStyle =
        theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600) ??
        const TextStyle(fontSize: 14, fontWeight: FontWeight.w600);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTrackTag(theme),
        const Gap(6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 220),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (supporter != null) ...[supporter, const Gap(6)],
              Flexible(
                child: Text(
                  _maskedUid(),
                  style: nameStyle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrackTag(ThemeData theme) {
    final bool hasTrack =
        post.authorSerialVisible && post.authorTrack != CareerTrack.none;
    final Color background = hasTrack
        ? theme.colorScheme.primary.withValues(alpha: 0.12)
        : theme.colorScheme.surfaceContainerHighest;
    final Color foreground = hasTrack
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;
    final String label = serialLabel(
      post.authorTrack,
      post.authorSerialVisible,
      includeEmoji: hasTrack,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget? _buildSupporterBadge(ThemeData theme) {
    if (!post.authorIsSupporter) {
      return null;
    }
    final int level = post.authorSupporterLevel;
    return Tooltip(
      message: level > 0 ? '후원자 레벨 $level' : '후원자',
      child: Icon(Icons.verified, size: 18, color: theme.colorScheme.primary),
    );
  }

  String _maskedUid() {
    final String fallback = post.authorNickname.isNotEmpty
        ? post.authorNickname
        : post.authorUid;
    return maskNickname(fallback);
  }

  String _avatarInitial() {
    final String normalized = post.authorNickname.trim();
    if (normalized.isEmpty) {
      return '공';
    }
    return String.fromCharCode(normalized.runes.first).toUpperCase();
  }
}
