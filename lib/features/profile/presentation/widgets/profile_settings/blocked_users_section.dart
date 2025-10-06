import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../routing/app_router.dart';
import 'settings_section.dart';

/// Blocked Users Section
///
/// Provides navigation to blocked users management page
class BlockedUsersSection extends StatelessWidget {
  const BlockedUsersSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: '차단 관리',
      children: [
        ListTile(
          leading: const Icon(Icons.block_outlined),
          title: const Text('차단한 사용자'),
          subtitle: const Text('차단한 사용자 목록 보기 및 관리'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.pushNamed(BlockedUsersRoute.name),
        ),
      ],
    );
  }
}
