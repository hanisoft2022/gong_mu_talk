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
/// - Obscured password input with toggle
/// - Real-time password strength indicator
/// - Form validation before submission
/// - Loading state during password change
/// - Success/error feedback via SnackBar
/// - Auto-clear fields after successful change
///
/// **Validation**:
/// - All fields must be filled
/// - Minimum 8 characters required
/// - New password and confirmation must match
/// - Current password must be correct (validated by backend)
/// - Password strength: weak/medium/strong
///
/// **Security**:
/// - Password fields are obscured (toggle-able)
/// - Current password required for verification
/// - Secure password update via AuthCubit

library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:gong_mu_talk/core/constants/app_colors.dart';

import '../../../../auth/presentation/cubit/auth_cubit.dart';
import 'settings_section.dart';

/// Password strength level
enum PasswordStrength {
  weak,
  medium,
  strong;

  String get label {
    switch (this) {
      case PasswordStrength.weak:
        return '약함';
      case PasswordStrength.medium:
        return '보통';
      case PasswordStrength.strong:
        return '강함';
    }
  }

  Color getColor(BuildContext context) {
    switch (this) {
      case PasswordStrength.weak:
        return AppColors.error;
      case PasswordStrength.medium:
        return AppColors.warning;
      case PasswordStrength.strong:
        return AppColors.success;
    }
  }
}

/// Password change section with form validation and submission
class PasswordChangeSection extends StatefulWidget {
  const PasswordChangeSection({super.key, required this.showMessage});

  final void Function(BuildContext context, String message) showMessage;

  @override
  State<PasswordChangeSection> createState() => _PasswordChangeSectionState();
}

class _PasswordChangeSectionState extends State<PasswordChangeSection> {
  late final TextEditingController _currentPasswordController;
  late final TextEditingController _newPasswordController;
  late final TextEditingController _confirmPasswordController;

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  PasswordStrength? _passwordStrength;

  @override
  void initState() {
    super.initState();
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();

    // Listen to new password changes for strength calculation
    _newPasswordController.addListener(_updatePasswordStrength);
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Updates password strength based on new password input
  void _updatePasswordStrength() {
    final password = _newPasswordController.text;
    if (password.isEmpty) {
      setState(() => _passwordStrength = null);
      return;
    }

    setState(() {
      _passwordStrength = _calculatePasswordStrength(password);
    });
  }

  /// Calculates password strength
  PasswordStrength _calculatePasswordStrength(String password) {
    if (password.length < 8) {
      return PasswordStrength.weak;
    }

    final bool hasDigits = password.contains(RegExp(r'\d'));
    final bool hasSpecialChars = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    final bool hasUpperCase = password.contains(RegExp(r'[A-Z]'));
    final bool hasLowerCase = password.contains(RegExp(r'[a-z]'));

    int strengthScore = 0;
    if (hasDigits) strengthScore++;
    if (hasSpecialChars) strengthScore++;
    if (hasUpperCase) strengthScore++;
    if (hasLowerCase) strengthScore++;

    if (strengthScore >= 3) {
      return PasswordStrength.strong;
    } else if (strengthScore >= 2) {
      return PasswordStrength.medium;
    } else {
      return PasswordStrength.weak;
    }
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

    if (newPassword.length < 8) {
      widget.showMessage(context, '새 비밀번호는 8자 이상이어야 합니다.');
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
      setState(() => _passwordStrength = null);
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
              obscureText: _obscureCurrentPassword,
              enabled: !isProcessing,
              decoration: InputDecoration(
                labelText: '현재 비밀번호',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureCurrentPassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureCurrentPassword = !_obscureCurrentPassword;
                    });
                  },
                ),
              ),
            ),
            const Gap(12),

            // 새 비밀번호
            TextField(
              controller: _newPasswordController,
              obscureText: _obscureNewPassword,
              enabled: !isProcessing,
              decoration: InputDecoration(
                labelText: '새 비밀번호 (최소 8자)',
                helperText: '영문, 숫자, 특수문자 조합을 권장합니다',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureNewPassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureNewPassword = !_obscureNewPassword;
                    });
                  },
                ),
              ),
            ),

            // Password strength indicator
            if (_passwordStrength != null) ...[
              const Gap(8),
              Row(
                children: [
                  Text(
                    '비밀번호 강도: ',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _passwordStrength!.getColor(context).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _passwordStrength!.label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _passwordStrength!.getColor(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const Gap(12),

            // 새 비밀번호 확인
            TextField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              enabled: !isProcessing,
              decoration: InputDecoration(
                labelText: '새 비밀번호 확인',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
              ),
            ),
            const Gap(12),

            // 비밀번호 변경 버튼
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: isProcessing
                    ? null
                    : () => _handlePasswordChange(context, isProcessing),
                child: const Text('비밀번호 변경'),
              ),
            ),
          ],
        );
      },
    );
  }
}
