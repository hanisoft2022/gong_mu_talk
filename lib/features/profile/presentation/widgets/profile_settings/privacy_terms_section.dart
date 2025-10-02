/// Privacy and Terms Section Widget
///
/// Provides links to privacy policy and terms of service.
///
/// **Purpose**:
/// - Provide access to privacy policy
/// - Provide access to terms of service
/// - Open documents in external browser
///
/// **Features**:
/// - External link icons
/// - Opens in external browser for better reading experience
/// - Error handling for URL launch failures
/// - User feedback on errors
///
/// **Links**:
/// - Privacy Policy: https://www.hanisoft.kr/privacy
/// - Terms of Service: https://www.hanisoft.kr/terms

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'settings_section.dart';

/// Privacy and terms section with external links
class PrivacyTermsSection extends StatelessWidget {
  const PrivacyTermsSection({
    super.key,
    required this.showMessage,
  });

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
          trailing: const Icon(Icons.open_in_new),
          onTap: () => _launchUrl(
            context,
            'https://www.hanisoft.kr/privacy',
          ),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.description_outlined),
          title: const Text('서비스 이용약관'),
          trailing: const Icon(Icons.open_in_new),
          onTap: () => _launchUrl(
            context,
            'https://www.hanisoft.kr/terms',
          ),
        ),
      ],
    );
  }

  /// Launches URL in external browser
  Future<void> _launchUrl(BuildContext context, String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          showMessage(context, 'URL을 열 수 없습니다: $url');
        }
      }
    } catch (error) {
      if (context.mounted) {
        showMessage(context, 'URL을 여는 중 오류가 발생했습니다: $error');
      }
    }
  }
}
