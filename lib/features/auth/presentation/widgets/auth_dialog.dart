import 'package:flutter/material.dart';

import 'auth_content.dart';

class AuthDialog extends StatelessWidget {
  const AuthDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: AuthContent(
            onAuthenticated: (dialogContext, state) {
              Navigator.of(dialogContext).maybePop();
            },
          ),
        ),
      ),
    );
  }
}
