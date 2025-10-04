/// Post header widget displaying author information and menu
///
/// Responsibilities:
/// - Display author avatar and name with career track
/// - Show timestamp
/// - Handle author menu tap
/// - Different display modes for serial vs public lounges
///
/// Used by: PostCard

library;
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../domain/models/feed_filters.dart';
import '../../../domain/models/post.dart';
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

    final String displayName = getDisplayName(
      nickname: post.authorNickname.isNotEmpty ? post.authorNickname : post.authorUid,
      track: post.authorTrack,
      serialVisible: post.authorSerialVisible,
    );

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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (supporter != null) ...[supporter, const Gap(6)],
              Expanded(
                child: Text(
                  displayName,
                  style: nameStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Public lounge header: "직렬 닉네임" 통합 표시
  Widget _buildPublicHeader(ThemeData theme) {
    final Widget? supporter = _buildSupporterBadge(theme);
    final TextStyle nameStyle =
        theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600) ??
        const TextStyle(fontSize: 14, fontWeight: FontWeight.w600);

    final String displayName = getDisplayName(
      nickname: post.authorNickname.isNotEmpty ? post.authorNickname : post.authorUid,
      track: post.authorTrack,
      serialVisible: post.authorSerialVisible,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (supporter != null) ...[supporter, const Gap(6)],
        Flexible(
          child: Text(displayName, style: nameStyle, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }



  Widget? _buildSupporterBadge(ThemeData theme) {
    return null;
  }

  String _avatarInitial() {
    final String normalized = post.authorNickname.trim();
    if (normalized.isEmpty) {
      return '공';
    }
    return String.fromCharCode(normalized.runes.first).toUpperCase();
  }
}
