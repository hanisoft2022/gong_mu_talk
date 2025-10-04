import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../domain/models/feed_filters.dart';
import '../../../domain/models/post.dart';
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
    if (!post.authorIsSupporter) {
      return null;
    }
    final int level = post.authorSupporterLevel;
    return Tooltip(
      message: level > 0 ? '후원자 레벨 $level' : '후원자',
      child: Icon(Icons.verified, size: 18, color: theme.colorScheme.primary),
    );
  }

  String _avatarInitial() {
    final String normalized = post.authorNickname.trim();
    if (normalized.isEmpty) {
      return '공';
    }
    return String.fromCharCode(normalized.runes.first).toUpperCase();
  }
}
