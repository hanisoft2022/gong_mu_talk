/// Password Change Section Widget
///
/// Provides UI for changing user password.
///
/// **Purpose**:
/// - Allow users to securely change their password
/// - Validate password requirements
/// - Provide feedback on password change attempts
///
/// **Features**:
/// - Three-field form (current, new, confirm password)
/// - Obscured password input
/// - Form validation before submission
/// - Loading state during password change
/// - Success/error feedback via SnackBar
/// - Auto-clear fields after successful change
///
/// **Validation**:
/// - All fields must be filled
/// - New password and confirmation must match
/// - Current password must be correct (validated by backend)
///
/// **Security**:
/// - Password fields are obscured
/// - Current password required for verification
/// - Secure password update via AuthCubit

library;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import '../../../../auth/presentation/cubit/auth_cubit.dart';
import 'settings_section.dart';

/// Password change section with form validation and submission
class PasswordChangeSection extends StatefulWidget {
  const PasswordChangeSection({
    super.key,
    required this.showMessage,
  });

  final void Function(BuildContext context, String message) showMessage;

  @override
  State<PasswordChangeSection> createState() => _PasswordChangeSectionState();
}

class _PasswordChangeSectionState extends State<PasswordChangeSection> {
  late final TextEditingController _currentPasswordController;
  late final TextEditingController _newPasswordController;
  late final TextEditingController _confirmPasswordController;

  @override
  void initState() {
    super.initState();
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Validates and submits password change request
  Future<void> _handlePasswordChange(
    BuildContext context,
    bool isProcessing,
  ) async {
    final String currentPassword = _currentPasswordController.text.trim();
    final String newPassword = _newPasswordController.text.trim();
    final String confirmPassword = _confirmPasswordController.text.trim();

    // Validation
    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      widget.showMessage(context, '비밀번호를 모두 입력해주세요.');
      return;
    }

    if (newPassword != confirmPassword) {
      widget.showMessage(context, '새 비밀번호가 일치하지 않습니다.');
      return;
    }

    // Submit password change
    await context.read<AuthCubit>().changePassword(
          currentPassword: currentPassword,
          newPassword: newPassword,
        );

    // Clear fields on success
    if (mounted) {
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (BuildContext context, AuthState state) {
        final bool isProcessing = state.isProcessing;

        return SettingsSection(
          title: '비밀번호 변경',
          children: [
            // 현재 비밀번호
            TextField(
              controller: _currentPasswordController,
              obscureText: true,
              enabled: !isProcessing,
              decoration: const InputDecoration(
                labelText: '현재 비밀번호',
              ),
            ),
            const Gap(12),

            // 새 비밀번호
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              enabled: !isProcessing,
              decoration: const InputDecoration(
                labelText: '새 비밀번호',
              ),
            ),
            const Gap(12),

            // 새 비밀번호 확인
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              enabled: !isProcessing,
              decoration: const InputDecoration(
                labelText: '새 비밀번호 확인',
              ),
            ),
            const Gap(12),

            // 비밀번호 변경 버튼
            FilledButton(
              onPressed:
                  isProcessing ? null : () => _handlePasswordChange(context, isProcessing),
              child: const Text('비밀번호 변경'),
            ),
          ],
        );
      },
    );
  }
}
