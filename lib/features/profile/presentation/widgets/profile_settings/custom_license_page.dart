/// Custom License Page Widget
///
/// Displays open source licenses used in the application.
///
/// **Purpose**:
/// - Show all open source licenses
/// - Provide detailed license information
/// - Comply with open source license requirements
///
/// **Features**:
/// - Loads licenses from Flutter LicenseRegistry
/// - App info header with branding
/// - License count information
/// - Searchable/scrollable license list
/// - Detailed license viewer dialog
///
/// **Display**:
/// - App name, version, copyright
/// - Total license count
/// - Individual license cards with preview
/// - Full license text in dialog

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

/// Custom license page showing all open source licenses
class CustomLicensePage extends StatefulWidget {
  const CustomLicensePage({super.key});

  @override
  State<CustomLicensePage> createState() => _CustomLicensePageState();
}

class _CustomLicensePageState extends State<CustomLicensePage> {
  late Future<List<LicenseEntry>> _licensesFuture;

  @override
  void initState() {
    super.initState();
    _licensesFuture = _loadLicenses();
  }

  /// Loads all licenses from Flutter's LicenseRegistry
  Future<List<LicenseEntry>> _loadLicenses() async {
    final List<LicenseEntry> licenses = <LicenseEntry>[];
    await for (final LicenseEntry license in LicenseRegistry.licenses) {
      licenses.add(license);
    }
    return licenses;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('오픈소스 라이선스'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
      ),
      body: FutureBuilder<List<LicenseEntry>>(
        future: _licensesFuture,
        builder: (
          BuildContext context,
          AsyncSnapshot<List<LicenseEntry>> snapshot,
        ) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: theme.colorScheme.error,
                  ),
                  const Gap(16),
                  Text(
                    '라이선스 정보를 불러올 수 없습니다.',
                    style: theme.textTheme.titleMedium,
                  ),
                  const Gap(8),
                  Text(
                    '${snapshot.error}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final List<LicenseEntry> licenses = snapshot.data ?? [];

          return CustomScrollView(
            slivers: [
              // 앱 정보 헤더
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '공무톡',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const Gap(8),
                      Text(
                        '버전 1.0.0',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const Gap(16),
                      Text(
                        '© 2025 HANISOFT. All rights reserved.\n\n'
                        '공무톡은 대한민국 공무원을 위한 종합 플랫폼입니다. '
                        '오픈소스 라이브러리의 기여에 감사드립니다.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              // 라이선스 개수 정보
              SliverToBoxAdapter(
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '오픈소스 라이브러리 정보',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const Gap(8),
                      Text(
                        '직접 사용: 약 50개의 주요 라이브러리',
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        '전체 포함: ${licenses.length}개 (의존성 포함)',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const Gap(4),
                      Text(
                        '※ 각 라이브러리의 하위 의존성까지 모두 포함된 수치입니다.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 라이선스 목록
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                    final LicenseEntry license = licenses[index];
                    return Card(
                      margin:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: theme.colorScheme.outlineVariant,
                          width: 1,
                        ),
                      ),
                      child: ListTile(
                        title: Text(
                          license.packages.join(', '),
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        subtitle: license.paragraphs.isNotEmpty
                            ? Text(
                                license.paragraphs.first.text,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall,
                              )
                            : null,
                        trailing: Icon(
                          Icons.chevron_right,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        onTap: () => _showLicenseDetail(context, license),
                      ),
                    );
                  },
                  childCount: licenses.length,
                ),
              ),

              // 하단 여백
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
            ],
          );
        },
      ),
    );
  }

  /// Shows detailed license text in a dialog
  void _showLicenseDetail(BuildContext context, LicenseEntry license) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        final ThemeData theme = Theme.of(context);
        return AlertDialog(
          title: Text(
            license.packages.join(', '),
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: license.paragraphs
                    .map((LicenseParagraph paragraph) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      paragraph.text,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        height: 1.4,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('닫기'),
            ),
          ],
        );
      },
    );
  }
}
