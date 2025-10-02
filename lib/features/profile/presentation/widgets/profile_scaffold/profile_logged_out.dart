/**
 * Profile Logged Out Widget
 *
 * Displays login prompt when user is not authenticated.
 * Shows lock icon and login button.
 *
 * Phase 4 - Extracted from profile_page.dart
 */
library;

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../utils/profile_auth_utils.dart';

class ProfileLoggedOut extends StatelessWidget {
  const ProfileLoggedOut({super.key, required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 56, color: theme.colorScheme.primary),
            const Gap(12),
            Text(
              '로그인이 필요합니다',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Gap(8),
            Text(
              '프로필을 관리하려면 먼저 로그인해주세요.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const Gap(16),
            FilledButton(
              onPressed: () => showAuthDialog(context),
              child: const Text('로그인 / 회원가입'),
            ),
          ],
        ),
      ),
    );
  }
}
