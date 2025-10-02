/// App Info Section Widget
///
/// Displays application information and related links.
///
/// **Purpose**:
/// - Show app version and build number
/// - Provide developer information
/// - Show open source licenses
///
/// **Features**:
/// - Version info from PackageInfo
/// - Developer info dialog
/// - Custom license page
/// - Version info dialog with details
///
/// **Information Displayed**:
/// - App name, version, build number, package name
/// - Developer name and contact
/// - Open source licenses used in the app

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'settings_section.dart';
import 'custom_license_page.dart';

/// App information section with version, developer, and licenses
class AppInfoSection extends StatelessWidget {
  const AppInfoSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: '앱 정보',
      children: [
        // 버전 정보
        FutureBuilder<PackageInfo>(
          future: PackageInfo.fromPlatform(),
          builder: (context, snapshot) {
            final String versionText = snapshot.hasData
                ? '${snapshot.data!.version} (빌드 ${snapshot.data!.buildNumber})'
                : '1.0.0 (빌드 1)';
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.info_outline),
              title: const Text('버전 정보'),
              subtitle: Text(versionText),
              onTap: () => _showVersionInfo(context),
            );
          },
        ),

        // 개발자 정보
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.code_outlined),
          title: const Text('개발자 정보'),
          subtitle: const Text('HANISOFT'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showDeveloperInfo(context),
        ),

        // 오픈소스 라이선스
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.code),
          title: const Text('오픈소스 라이선스'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showLicenses(context),
        ),
      ],
    );
  }

  /// Shows version info dialog with detailed app information
  void _showVersionInfo(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return FutureBuilder<PackageInfo>(
          future: PackageInfo.fromPlatform(),
          builder: (context, snapshot) {
            final PackageInfo? packageInfo = snapshot.data;

            return AlertDialog(
              title: const Text('버전 정보'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('앱 이름: ${packageInfo?.appName ?? '공무톡'}'),
                  Text('앱 버전: ${packageInfo?.version ?? '1.0.0'}'),
                  Text('빌드 번호: ${packageInfo?.buildNumber ?? '1'}'),
                  Text(
                    '패키지명: ${packageInfo?.packageName ?? 'kr.hanisoft.gong_mu_talk'}',
                  ),
                  const SizedBox(height: 16),
                  const Text('최신 버전을 사용 중입니다.'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('확인'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Shows developer info dialog
  void _showDeveloperInfo(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('개발자 정보'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('개발사: HANISOFT'),
              Text('이메일: contact@hanisoft.kr'),
              SizedBox(height: 16),
              Text('공무톡은 공무원을 위한 종합 서비스 플랫폼입니다.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }

  /// Shows custom license page
  void _showLicenses(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const CustomLicensePage(),
      ),
    );
  }
}
