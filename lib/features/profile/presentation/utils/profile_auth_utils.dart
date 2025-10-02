/**
 * Profile Authentication Utilities
 *
 * Helper functions for authentication-related UI actions.
 *
 * Phase 4 - Extracted from profile_page.dart
 */
library;

import 'package:flutter/material.dart';

import '../../../auth/presentation/widgets/auth_dialog.dart';

/// Shows the authentication dialog for login/signup
void showAuthDialog(BuildContext context) {
  showDialog<void>(context: context, builder: (_) => const AuthDialog());
}
