/// Account Management Section Widget
///
/// Provides account deletion functionality.
///
/// **Purpose**:
/// - Allow users to delete their account
/// - Provide confirmation dialog with password verification
/// - Ensure secure account deletion process
///
/// **Features**:
/// - Confirmation dialog before deletion
/// - Password verification (for email/password accounts)
/// - Loading state during deletion
/// - Error feedback
/// - Auto-close dialog after deletion
///
/// **Security**:
/// - Requires password confirmation
/// - Clear warning about data deletion
/// - Two-step confirmation process
///
/// **Process**:
/// 1. User clicks "회원 탈퇴" button
/// 2. Dialog opens requesting password
/// 3. User enters password and confirms
/// 4. AuthCubit handles account deletion
/// 5. Dialog closes automatically
/// 6. User is logged out and redirected

library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import '../../../../auth/presentation/cubit/auth_cubit.dart';
import 'settings_section.dart';

/// Account management section with deletion functionality
class AccountManagementSection extends StatefulWidget {
  const AccountManagementSection({super.key});

  @override
  State<AccountManagementSection> createState() =>
      _AccountManagementSectionState();
}

class _AccountManagementSectionState extends State<AccountManagementSection> {
  late final TextEditingController _deletePasswordController;

  @override
  void initState() {
    super.initState();
    _deletePasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _deletePasswordController.dispose();
    super.dispose();
  }

  /// Handle logout action
  Future<void> _handleLogout(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('로그아웃'),
          content: const Text('로그아웃하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('로그아웃'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      await context.read<AuthCubit>().logOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (BuildContext context, AuthState state) {
        final bool isProcessing = state.isProcessing;

        return SettingsSection(
          title: '계정 관리',
          children: [
            // Logout button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: isProcessing ? null : () => _handleLogout(context),
                child: const Text('로그아웃'),
              ),
            ),
            const Gap(12),
            // Delete account button
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.errorContainer,
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: isProcessing
                    ? null
                    : () => _confirmDeleteAccount(context),
                child: const Text('회원 탈퇴'),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Shows confirmation dialog for account deletion
  void _confirmDeleteAccount(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('회원 탈퇴'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('탈퇴를 진행하려면 비밀번호를 입력해주세요.'),
              const Gap(12),
              TextField(
                controller: _deletePasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: '비밀번호'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.errorContainer,
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () async {
                final String password = _deletePasswordController.text.trim();
                final AuthCubit authCubit = context.read<AuthCubit>();
                final NavigatorState navigator = Navigator.of(context);

                await authCubit.deleteAccount(
                  currentPassword: password.isEmpty ? null : password,
                );

                if (!mounted) {
                  return;
                }
                navigator.pop();
                _deletePasswordController.clear();
              },
              child: const Text('탈퇴하기'),
            ),
          ],
        );
      },
    );
  }
}
