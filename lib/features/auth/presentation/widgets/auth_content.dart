import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import '../cubit/auth_cubit.dart';

enum _SignUpFlow { email, google }

class AuthContent extends StatefulWidget {
  const AuthContent({super.key, this.onAuthenticated});

  final void Function(BuildContext context, AuthState state)? onAuthenticated;

  @override
  State<AuthContent> createState() => _AuthContentState();
}

class _AuthContentState extends State<AuthContent> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmController =
      TextEditingController();

  bool _isSignUpMode = false;
  bool _passwordVisible = false;
  _SignUpFlow _signUpFlow = _SignUpFlow.email;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return BlocConsumer<AuthCubit, AuthState>(
      listenWhen: (previous, current) =>
          previous.isLoggedIn != current.isLoggedIn,
      listener: (context, state) {
        if (state.isLoggedIn) {
          widget.onAuthenticated?.call(context, state);
        }
      },
      builder: (context, state) {
        final bool isLoading = state.isAuthenticating;
        final bool isSignUp = _isSignUpMode;
        final bool isGoogleFlow = isSignUp && _signUpFlow == _SignUpFlow.google;
        final bool showEmailFields = !isGoogleFlow;
        final bool showPasswordConfirmation =
            isSignUp && _signUpFlow == _SignUpFlow.email;
        final String actionLabel = isSignUp ? '회원가입' : '로그인';
        final String toggleLabel = isSignUp
            ? '이미 계정이 있으신가요? 로그인'
            : '처음이신가요? 회원가입';

        return Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                actionLabel,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Gap(8),
              Text(
                '공직자 메일 또는 자주 사용하는 이메일로 '
                '${_isSignUpMode ? '새 계정을 만들어보세요.' : '로그인하세요.'}',
                style: theme.textTheme.bodyMedium,
              ),
              const Gap(16),
              if (isSignUp) ...[
                Text('가입 방법 선택', style: theme.textTheme.titleMedium),
                const Gap(8),
                SegmentedButton<_SignUpFlow>(
                  segments: const [
                    ButtonSegment<_SignUpFlow>(
                      value: _SignUpFlow.email,
                      label: Text('이메일 주소로 가입'),
                      icon: Icon(Icons.alternate_email_outlined),
                    ),
                    ButtonSegment<_SignUpFlow>(
                      value: _SignUpFlow.google,
                      label: Text('Google 이메일로 가입'),
                      icon: Icon(Icons.account_circle_outlined),
                    ),
                  ],
                  selected: <_SignUpFlow>{_signUpFlow},
                  onSelectionChanged: (selection) {
                    if (selection.isEmpty) {
                      return;
                    }
                    setState(() {
                      _signUpFlow = selection.first;
                    });
                  },
                ),
                const Gap(12),
                _SignUpGuidance(theme: theme),
                const Gap(12),
              ],
              if (showEmailFields) ...[
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: '이메일',
                    hintText: 'example@korea.kr',
                  ),
                  validator: _validateEmail,
                ),
                const Gap(16),
                TextFormField(
                  controller: _passwordController,
                  autofillHints: const [AutofillHints.password],
                  textInputAction: TextInputAction.done,
                  obscureText: !_passwordVisible,
                  decoration: InputDecoration(
                    labelText: '비밀번호',
                    helperText: isSignUp
                        ? '8자 이상, 대·소문자·숫자·특수문자를 포함해주세요.'
                        : null,
                    suffixIcon: IconButton(
                      tooltip: _passwordVisible ? '비밀번호 숨기기' : '비밀번호 보기',
                      onPressed: () => setState(() {
                        _passwordVisible = !_passwordVisible;
                      }),
                      icon: Icon(
                        _passwordVisible
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                    ),
                  ),
                  onFieldSubmitted: (_) => _submit(),
                  validator: _validatePassword,
                ),
                const Gap(12),
                if (showPasswordConfirmation)
                  TextFormField(
                    controller: _passwordConfirmController,
                    textInputAction: TextInputAction.done,
                    obscureText: !_passwordVisible,
                    decoration: InputDecoration(
                      labelText: '비밀번호 확인',
                      helperText: '입력한 비밀번호와 동일하게 입력해주세요.',
                      suffixIcon: IconButton(
                        tooltip: _passwordVisible ? '비밀번호 숨기기' : '비밀번호 보기',
                        onPressed: () => setState(() {
                          _passwordVisible = !_passwordVisible;
                        }),
                        icon: Icon(
                          _passwordVisible
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),
                    ),
                    onFieldSubmitted: (_) => _submit(),
                    validator: _validatePasswordConfirmation,
                  ),
                if (showPasswordConfirmation) const Gap(12),
              ],
              if (state.authError != null)
                Text(
                  state.authError!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              const Gap(20),
              if (showEmailFields) ...[
                FilledButton(
                  onPressed: isLoading ? null : _submit,
                  child: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(actionLabel),
                ),
              ],
              if (!showEmailFields) ...[
                FilledButton.icon(
                  onPressed: isLoading ? null : _handleGoogleAuth,
                  icon: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.account_circle_outlined),
                  label: const Text('Google 계정으로 가입'),
                ),
              ],
              if (!isSignUp && showEmailFields) ...[
                const Gap(12),
                OutlinedButton.icon(
                  onPressed: isLoading ? null : _handleGoogleAuth,
                  icon: const Icon(Icons.account_circle_outlined),
                  label: const Text('Google 계정으로 로그인'),
                ),
              ],
              const Gap(12),
              const Gap(8),
              TextButton(
                onPressed: isLoading
                    ? null
                    : () => setState(() {
                        _isSignUpMode = !_isSignUpMode;
                        _signUpFlow = _SignUpFlow.email;
                      }),
                child: Text(toggleLabel),
              ),
            ],
          ),
        );
      },
    );
  }

  void _submit() {
    final AuthCubit authCubit = context.read<AuthCubit>();
    if (authCubit.state.isAuthenticating) {
      return;
    }

    final FormState? form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    if (_isSignUpMode) {
      authCubit.signUp(email: email, password: password);
    } else {
      authCubit.signIn(email: email, password: password);
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '이메일을 입력해주세요.';
    }

    final String email = value.trim();
    final List<String> segments = email.split('@');
    if (segments.length != 2 || segments.first.isEmpty) {
      return '올바른 이메일 주소를 입력해주세요.';
    }

    if (!segments[1].contains('.')) {
      return '올바른 이메일 주소를 입력해주세요.';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return '비밀번호를 입력해주세요.';
    }

    if (value.length < 8) {
      return '비밀번호는 최소 8자 이상이어야 합니다.';
    }

    final RegExp hasLower = RegExp(r'[a-z]');
    final RegExp hasUpper = RegExp(r'[A-Z]');
    final RegExp hasNumber = RegExp(r'[0-9]');
    final RegExp hasSpecial = RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-\[\]\\/()]');

    if (!hasLower.hasMatch(value)) {
      return '비밀번호에 소문자를 포함해주세요.';
    }

    if (!hasUpper.hasMatch(value)) {
      return '비밀번호에 대문자를 포함해주세요.';
    }

    if (!hasNumber.hasMatch(value)) {
      return '비밀번호에 숫자를 포함해주세요.';
    }

    if (!hasSpecial.hasMatch(value)) {
      return '비밀번호에 특수문자를 포함해주세요.';
    }

    return null;
  }

  String? _validatePasswordConfirmation(String? value) {
    if (!_isSignUpMode || _signUpFlow != _SignUpFlow.email) {
      return null;
    }

    if (value == null || value.isEmpty) {
      return '비밀번호 확인을 입력해주세요.';
    }

    if (value != _passwordController.text) {
      return '비밀번호가 일치하지 않습니다.';
    }

    return null;
  }

  void _handleGoogleAuth() {
    final AuthCubit authCubit = context.read<AuthCubit>();
    if (authCubit.state.isAuthenticating) {
      return;
    }

    FocusScope.of(context).unfocus();
    authCubit.signInWithGoogle();
  }
}

class _SignUpGuidance extends StatelessWidget {
  const _SignUpGuidance({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _GuidelineRow(
              icon: Icons.verified_user_outlined,
              message:
                  '공직자 메일(@korea.kr 등)로 가입하면 추후 추가 인증 없이 바로 서비스를 이용할 수 있습니다.',
            ),
            SizedBox(height: 12),
            _GuidelineRow(
              icon: Icons.badge_outlined,
              message:
                  '개인 이메일 또는 Google 계정으로 가입할 경우 커뮤니티·매칭 등 확장 기능 사용 전 공직자 메일 인증이 필요합니다.',
            ),
          ],
        ),
      ),
    );
  }
}

class _GuidelineRow extends StatelessWidget {
  const _GuidelineRow({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(message, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    );
  }
}
