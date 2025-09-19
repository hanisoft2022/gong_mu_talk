import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import '../cubit/auth_cubit.dart';

class AuthDialog extends StatefulWidget {
  const AuthDialog({super.key});

  @override
  State<AuthDialog> createState() => _AuthDialogState();
}

class _AuthDialogState extends State<AuthDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isSignUpMode = false;
  bool _passwordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: BlocConsumer<AuthCubit, AuthState>(
            listenWhen: (previous, current) =>
                previous.isLoggedIn != current.isLoggedIn,
            listener: (context, state) {
              if (state.isLoggedIn) {
                Navigator.of(context).maybePop();
              }
            },
            builder: (context, state) {
              final bool isLoading = state.isAuthenticating;
              final String actionLabel = _isSignUpMode ? '회원가입' : '로그인';
              final String toggleLabel = _isSignUpMode
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
                    const Gap(20),
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
                        helperText: _isSignUpMode
                            ? '6자 이상, 영문/숫자 조합을 추천합니다.'
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
                    if (state.authError != null)
                      Text(
                        state.authError!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    const Gap(20),
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
                    const Gap(8),
                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () => setState(() {
                              _isSignUpMode = !_isSignUpMode;
                            }),
                      child: Text(toggleLabel),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
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

    if (value.length < 6) {
      return '비밀번호는 최소 6자 이상이어야 합니다.';
    }

    return null;
  }
}
