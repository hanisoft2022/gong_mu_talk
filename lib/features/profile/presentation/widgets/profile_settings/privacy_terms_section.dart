/// Privacy and Terms Section Widget
///
/// Provides links to privacy policy and terms of service.
///
/// **Purpose**:
/// - Provide access to privacy policy
/// - Provide access to terms of service
/// - Display documents within the app
///
/// **Features**:
/// - In-app pages for privacy policy and terms
/// - No external browser required
/// - Consistent with app navigation
/// - GDPR and legal compliance
///
/// **Pages**:
/// - Privacy Policy: /profile/privacy
/// - Terms of Service: /profile/terms

library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../routing/app_router.dart';
import 'settings_section.dart';

/// Privacy and terms section with in-app pages
class PrivacyTermsSection extends StatelessWidget {
  const PrivacyTermsSection({super.key, required this.showMessage});

  final void Function(BuildContext context, String message) showMessage;

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: '개인정보 및 약관',
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.privacy_tip_outlined),
          title: const Text('개인정보 처리방침'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.pushNamed(PrivacyPolicyRoute.name),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.description_outlined),
          title: const Text('서비스 이용약관'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.pushNamed(TermsOfServiceRoute.name),
        ),
      ],
    );
  }
}
