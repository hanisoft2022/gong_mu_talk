import 'package:flutter/material.dart';

/// A circular avatar widget displaying the first character of the user's nickname.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.nickname,
    this.radius = 32,
  });

  final String nickname;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return CircleAvatar(
      radius: radius,
      backgroundColor: theme.colorScheme.primaryContainer,
      child: Text(
        nickname.characters.firstOrNull ?? '공',
        style: TextStyle(
          fontSize: radius * 0.6,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}
