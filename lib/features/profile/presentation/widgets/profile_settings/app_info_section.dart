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

library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gong_mu_talk/common/widgets/info_dialog.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../../routing/app_router.dart';
import 'settings_section.dart';

/// App information section with version, developer, and licenses
class AppInfoSection extends StatefulWidget {
  const AppInfoSection({super.key});

  @override
  State<AppInfoSection> createState() => _AppInfoSectionState();
}

class _AppInfoSectionState extends State<AppInfoSection> {
  PackageInfo? _cachedPackageInfo;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  /// Loads and caches package info
  Future<void> _loadPackageInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _cachedPackageInfo = packageInfo;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: '앱 정보',
      children: [
        // 버전 정보
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.info_outline),
          title: const Text('버전 정보'),
          subtitle: Text(
            _cachedPackageInfo != null
                ? '${_cachedPackageInfo!.version} (빌드 ${_cachedPackageInfo!.buildNumber})'
                : '1.0.0 (빌드 1)',
          ),
          onTap: () => _showVersionInfo(context),
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
    final packageInfo = _cachedPackageInfo;

    InfoDialog.showList(
      context,
      title: '버전 정보',
      icon: Icons.info_outline,
      iconColor: Colors.teal.shade600,
      description: '최신 버전을 사용 중입니다.',
      items: [
        InfoListItem(
          title: '앱 이름',
          subtitle: packageInfo?.appName ?? '공무톡',
          icon: Icons.apps,
        ),
        InfoListItem(
          title: '앱 버전',
          subtitle: packageInfo?.version ?? '1.0.0',
          icon: Icons.update,
        ),
        InfoListItem(
          title: '빌드 번호',
          subtitle: packageInfo?.buildNumber ?? '1',
          icon: Icons.numbers,
        ),
        InfoListItem(
          title: '패키지명',
          subtitle: packageInfo?.packageName ?? 'kr.hanisoft.gong_mu_talk',
          icon: Icons.code,
        ),
      ],
    );
  }

  /// Shows developer info dialog
  void _showDeveloperInfo(BuildContext context) {
    InfoDialog.showList(
      context,
      title: '개발자 정보',
      icon: Icons.code_outlined,
      iconColor: Colors.teal.shade600,
      description: '공무톡은 공무원을 위한 종합 서비스 플랫폼입니다.',
      items: const [
        InfoListItem(
          title: '개발사',
          subtitle: 'HANISOFT',
          icon: Icons.business,
        ),
        InfoListItem(
          title: '이메일',
          subtitle: 'hanisoft2022@gmail.com',
          icon: Icons.email,
        ),
      ],
    );
  }

  /// Shows custom license page
  void _showLicenses(BuildContext context) {
    context.pushNamed(LicensesRoute.name);
  }
}
