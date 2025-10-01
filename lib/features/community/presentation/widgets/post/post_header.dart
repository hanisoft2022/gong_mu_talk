/// Post header widget displaying author information and menu
///
/// Responsibilities:
/// - Display author avatar and name with career track
/// - Show timestamp
/// - Handle author menu tap
/// - Different display modes for serial vs public lounges
///
/// Used by: PostCard

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../domain/models/feed_filters.dart';
import '../../../domain/models/post.dart';
import '../../../../profile/domain/career_track.dart';
import '../../../../../core/utils/string_extensions.dart';
import '../comment_utils.dart';

class PostHeader extends StatelessWidget {
  const PostHeader({
    super.key,
    required this.post,
    required this.timestamp,
    required this.scope,
    required this.authorButtonKey,
    required this.onAuthorMenuTap,
  });

  final Post post;
  final String timestamp;
  final LoungeScope scope;
  final GlobalKey authorButtonKey;
  final VoidCallback onAuthorMenuTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          fit: FlexFit.loose,
          child: Align(
            alignment: Alignment.centerLeft,
            child: _buildAuthorMenu(context),
          ),
        ),
      ],
    );
  }

  Widget _buildAuthorMenu(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle timestampStyle =
        theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant) ??
        TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 11);

    final Widget timestampLabel = Text(timestamp, style: timestampStyle);
    final Widget identityButton = Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        key: authorButtonKey,
        borderRadius: BorderRadius.circular(12),
        onTap: onAuthorMenuTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: AuthorInfoHeader(post: post, scope: scope),
        ),
      ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        IntrinsicWidth(child: identityButton),
        const Spacer(),
        timestampLabel,
      ],
    );
  }
}

/// Author information header with avatar, name, and track
class AuthorInfoHeader extends StatelessWidget {
  const AuthorInfoHeader({
    super.key,
    required this.post,
    required this.scope,
  });

  final Post post;
  final LoungeScope scope;

  bool get _isSerialScope => scope == LoungeScope.serial;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: _isSerialScope ? _buildSerialHeader(theme) : _buildPublicHeader(theme),
    );
  }

  /// Serial lounge header with avatar
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
                      post.authorNickname,
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
                  serialLabel(post.authorTrack, post.authorSerialVisible, includeEmoji: true),
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

  /// Public lounge header with track tag
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
                child: Text(_maskedUid(), style: nameStyle, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build career track tag
  Widget _buildTrackTag(ThemeData theme) {
    final bool hasTrack = post.authorSerialVisible && post.authorTrack != CareerTrack.none;
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
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(color: foreground, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget? _buildSupporterBadge(ThemeData theme) {
    return null;
  }

  String _maskedUid() {
    final String fallback = post.authorNickname.isNotEmpty ? post.authorNickname : post.authorUid;
    return fallback.masked;
  }

  String _avatarInitial() {
    final String normalized = post.authorNickname.trim();
    if (normalized.isEmpty) {
      return '공';
    }
    return String.fromCharCode(normalized.runes.first).toUpperCase();
  }
}
