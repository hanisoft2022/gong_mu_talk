/// Extracted from life_home_page.dart for better file organization
/// This file contains meeting-related display widgets

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../data/mock_life_repository.dart';
import '../../domain/life_meeting.dart';

class MeetingCreateCard extends StatelessWidget {
  const MeetingCreateCard({required this.onCreate, super.key});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '새로운 모임 만들기',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const Gap(8),
            Text('함께 배우고 즐길 동료를 찾아보세요. 직접 모임을 만들 수도 있어요!', style: theme.textTheme.bodyMedium),
            const Gap(12),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('모임 만들기'),
            ),
          ],
        ),
      ),
    );
  }
}

class EmptyMeetingsView extends StatelessWidget {
  const EmptyMeetingsView({required this.onCreate, super.key});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.people_outline, size: 48, color: theme.colorScheme.primary),
            const Gap(12),
            Text('아직 등록된 모임이 없어요.', style: theme.textTheme.titleMedium),
            const Gap(8),
            Text('첫 번째 모임을 직접 만들어보세요!', style: theme.textTheme.bodyMedium),
            const Gap(12),
            FilledButton(onPressed: onCreate, child: const Text('모임 만들기')),
          ],
        ),
      ),
    );
  }
}

class MeetingTile extends StatelessWidget {
  const MeetingTile({
    required this.meeting,
    required this.authState,
    required this.repository,
    super.key,
  });

  final LifeMeeting meeting;
  final AuthState authState;
  final MockLifeRepository repository;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isJoined = meeting.members.any(
      (MeetingMember member) => member.uid == authState.userId,
    );
    final bool isHost = meeting.host.uid == authState.userId;
    final bool isFull = meeting.isFull && !isJoined;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Chip(label: Text('${meeting.category.emoji} ${meeting.category.label}')),
                const Spacer(),
                if (meeting.schedule != null)
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 16),
                      const Gap(4),
                      Text(_formatSchedule(meeting.schedule!), style: theme.textTheme.labelMedium),
                    ],
                  ),
              ],
            ),
            const Gap(12),
            Text(
              meeting.title,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const Gap(8),
            Text(meeting.description, style: theme.textTheme.bodyMedium),
            const Gap(12),
            Row(
              children: [
                CircleAvatar(radius: 16, child: Text(meeting.host.nickname.substring(0, 1))),
                const Gap(8),
                Expanded(
                  child: Text(
                    '${meeting.host.nickname} 주최 · ${meeting.members.length}/${meeting.capacity}명',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                if (!isHost)
                  FilledButton.icon(
                    onPressed: isFull ? null : () => _handleJoin(context, isJoined: isJoined),
                    icon: Icon(isJoined ? Icons.check : Icons.group_add_outlined),
                    label: Text(isJoined ? '참여 중' : '참여하기'),
                  ),
              ],
            ),
            if (meeting.location != null) ...[
              const Gap(12),
              Row(
                children: [
                  const Icon(Icons.place_outlined, size: 16),
                  const Gap(6),
                  Expanded(child: Text(meeting.location!, style: theme.textTheme.bodySmall)),
                ],
              ),
            ],
            if (meeting.tags.isNotEmpty) ...[
              const Gap(12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: meeting.tags
                    .map(
                      (String tag) =>
                          Chip(visualDensity: VisualDensity.compact, label: Text('#$tag')),
                    )
                    .toList(growable: false),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _handleJoin(BuildContext context, {required bool isJoined}) async {
    if (authState.userId == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('로그인이 필요합니다.')));
      return;
    }

    if (isJoined) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('이미 참여 중인 모임입니다.')));
      return;
    }

    try {
      await repository.joinMeeting(
        meetingId: meeting.id,
        member: MeetingMember(uid: authState.userId!, nickname: authState.nickname),
      );
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('모임에 참여했어요.')));
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.toString().replaceAll('StateError: ', ''))));
    }
  }

  String _formatSchedule(DateTime schedule) {
    final String month = schedule.month.toString().padLeft(2, '0');
    final String day = schedule.day.toString().padLeft(2, '0');
    final String hour = schedule.hour.toString().padLeft(2, '0');
    final String minute = schedule.minute.toString().padLeft(2, '0');
    return '$month/$day $hour:$minute';
  }
}
