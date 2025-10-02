import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// A circular avatar widget displaying a user's profile photo.
///
/// If [photoUrl] is provided and valid, displays the network image.
/// Otherwise, shows the first character of [nickname] as a fallback.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.photoUrl,
    required this.nickname,
    this.radius = 32,
  });

  final String? photoUrl;
  final String nickname;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return CircleAvatar(
      radius: radius,
      backgroundColor: photoUrl != null && photoUrl!.isNotEmpty
          ? Colors.transparent
          : theme.colorScheme.primaryContainer,
      backgroundImage: photoUrl != null && photoUrl!.isNotEmpty
          ? CachedNetworkImageProvider(photoUrl!)
          : null,
      child: photoUrl == null || photoUrl!.isEmpty
          ? Text(
              nickname.isEmpty ? '?' : nickname.characters.first,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            )
          : null,
    );
  }
}
