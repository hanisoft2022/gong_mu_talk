import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';

import '../widgets/auth_content.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key, required this.redirectPath});

  final String redirectPath;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('공무톡')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    child: Image.asset(
                      'assets/images/app_logo.png',
                      height: 72,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),

                  const Gap(32),
                  AuthContent(
                    onAuthenticated: (contentContext, state) {
                      contentContext.go(redirectPath);
                    },
                  ),
                  const Gap(48),
                  Align(
                    child: Text(
                      'Powered by HANISOFT',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
