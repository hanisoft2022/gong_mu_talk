/// ProfileLoggedOutPage
///
/// 로그인하지 않은 사용자를 위한 프로필 페이지
///
/// Phase 2 - Extracted from profile_page.dart
///
/// Features:
/// - 로그인 필요 메시지 표시
/// - 로그인/회원가입 버튼
/// - 인증 다이얼로그 연동
///
/// File Size: ~60 lines (Green Zone ✅)
library;

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../auth/presentation/widgets/auth_dialog.dart';

class ProfileLoggedOutPage extends StatelessWidget {
  const ProfileLoggedOutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline,
              size: 56,
              color: theme.colorScheme.primary,
            ),
            const Gap(12),
            Text(
              '로그인이 필요합니다',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(8),
            Text(
              '프로필을 관리하려면 먼저 로그인해주세요.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const Gap(16),
            FilledButton(
              onPressed: () => _showAuthDialog(context),
              child: const Text('로그인 / 회원가입'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAuthDialog(BuildContext context) {
    showDialog<void>(context: context, builder: (_) => const AuthDialog());
  }
}
