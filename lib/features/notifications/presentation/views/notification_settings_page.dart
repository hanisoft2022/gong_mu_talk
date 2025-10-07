import 'package:flutter/material.dart';

import '../../../../core/utils/performance_optimizations.dart';
import 'package:gap/gap.dart';

import '../../../../di/di.dart';
import '../../data/notification_repository.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  late final NotificationRepository _repository;
  Map<String, bool> _settings = {};
  bool _isLoading = true;

  final Map<String, NotificationOption> _notificationOptions = {
    'comments': const NotificationOption(
      title: '댓글 알림',
      subtitle: '내 글에 댓글이 달렸을 때',
      icon: Icons.comment_outlined,
    ),
    'likes': const NotificationOption(
      title: '좋아요 알림',
      subtitle: '내 글이나 댓글에 좋아요를 받았을 때',
      icon: Icons.favorite_outline,
    ),
    'new_posts': const NotificationOption(
      title: '새 글 알림',
      subtitle: '관심 직렬에 새 글이 올라왔을 때',
      icon: Icons.article_outlined,
    ),
    'weekly_digest': const NotificationOption(
      title: '주간 요약',
      subtitle: '일주일간의 인기 글과 활동 요약',
      icon: Icons.summarize_outlined,
    ),
    'system': const NotificationOption(
      title: '시스템 알림',
      subtitle: '공지사항, 업데이트 등 중요한 알림',
      icon: Icons.notifications_outlined,
    ),
  };

  @override
  void initState() {
    super.initState();
    _repository = getIt<NotificationRepository>();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _repository.getNotificationSettings();
      setState(() {
        _settings = settings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('설정을 불러오는데 실패했습니다: $e')));
      }
    }
  }

  Future<void> _updateSetting(String key, bool value) async {
    setState(() {
      _settings[key] = value;
    });

    try {
      await _repository.setNotificationEnabled(key, value);
    } catch (e) {
      // 실패 시 되돌리기
      setState(() {
        _settings[key] = !value;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('설정 변경에 실패했습니다: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('알림 설정'),
        backgroundColor: theme.colorScheme.surface,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : OptimizedListView(
              itemCount: 9,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 20,
                                  color: theme.colorScheme.primary,
                                ),
                                const Gap(8),
                                Text(
                                  '알림 설정',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            const Gap(8),
                            Text(
                              '받고 싶은 알림 유형을 선택하세요. 언제든지 변경할 수 있습니다.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                } else if (index == 1) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Gap(16),
                  );
                } else if (index >= 2 && index <= 6) {
                  final entry = _notificationOptions.entries.elementAt(
                    index - 2,
                  );
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildNotificationTile(
                      context,
                      entry.key,
                      entry.value,
                    ),
                  );
                } else if (index == 7) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Gap(24),
                  );
                } else {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.settings_outlined,
                                  size: 20,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                const Gap(8),
                                Text(
                                  '기기 알림 설정',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const Gap(8),
                            Text(
                              '푸시 알림을 완전히 차단하려면 기기의 설정 > 알림에서 공무톡 앱의 알림을 비활성화하세요.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
              },
            ),
    );
  }

  Widget _buildNotificationTile(
    BuildContext context,
    String key,
    NotificationOption option,
  ) {
    final ThemeData theme = Theme.of(context);
    final bool isEnabled = _settings[key] ?? true;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        secondary: Icon(
          option.icon,
          color: isEnabled
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant,
        ),
        title: Text(
          option.title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: isEnabled
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
        subtitle: Text(
          option.subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        value: isEnabled,
        onChanged: (bool value) => _updateSetting(key, value),
        activeThumbColor: theme.colorScheme.primary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}

class NotificationOption {
  const NotificationOption({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;
}
