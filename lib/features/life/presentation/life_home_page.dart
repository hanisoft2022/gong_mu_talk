import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import '../../../di/di.dart';
import '../../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../community/data/mock_social_graph.dart';
import '../../matching/presentation/cubit/matching_cubit.dart';
import '../../matching/presentation/views/matching_page.dart';
import '../data/mock_life_repository.dart';
import '../domain/life_meeting.dart';
import '../domain/life_section.dart';
import 'cubit/life_section_cubit.dart';
import 'utils/life_scroll_coordinator.dart';

class LifeHomePage extends StatefulWidget {
  const LifeHomePage({super.key});

  @override
  State<LifeHomePage> createState() => _LifeHomePageState();
}

class _LifeHomePageState extends State<LifeHomePage> {
  late final MockLifeRepository _lifeRepository;
  late final MatchingCubit _matchingCubit;
  late final MockSocialGraph _socialGraph;
  late final ScrollController _scrollController;
  int _lastScrollRequestId = 0;

  @override
  void initState() {
    super.initState();
    _lifeRepository = getIt<MockLifeRepository>();
    _socialGraph = getIt<MockSocialGraph>();
    _matchingCubit = getIt<MatchingCubit>()..loadCandidates();
    getIt<AuthCubit>().refreshAuthStatus();
    _scrollController = ScrollController();
    _lastScrollRequestId = LifeScrollCoordinator.instance.lastRequestId;
    LifeScrollCoordinator.instance.addListener(_handleScrollRequest);
  }

  @override
  void dispose() {
    LifeScrollCoordinator.instance.removeListener(_handleScrollRequest);
    _scrollController.dispose();
    _matchingCubit.close();
    super.dispose();
  }

  void _handleScrollRequest() {
    final int requestId = LifeScrollCoordinator.instance.lastRequestId;
    if (requestId == _lastScrollRequestId) {
      return;
    }
    _lastScrollRequestId = requestId;
    if (!_scrollController.hasClients) {
      return;
    }
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final LifeSection section = context.watch<LifeSectionCubit>().state;
    return Scaffold(
      body: SafeArea(
        child: PrimaryScrollController(
          controller: _scrollController,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: section == LifeSection.meetings
                      ? _MeetingsView(repository: _lifeRepository, socialGraph: _socialGraph)
                      : BlocProvider<MatchingCubit>.value(
                          value: _matchingCubit,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: MatchingPage(),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MeetingsView extends StatelessWidget {
  const _MeetingsView({required this.repository, required this.socialGraph});

  final MockLifeRepository repository;
  final MockSocialGraph socialGraph;

  @override
  Widget build(BuildContext context) {
    final AuthState authState = context.watch<AuthCubit>().state;

    return StreamBuilder<List<LifeMeeting>>(
      stream: repository.watchMeetings(),
      builder: (context, snapshot) {
        final List<LifeMeeting> meetings = snapshot.data ?? const <LifeMeeting>[];

        return RefreshIndicator(
          onRefresh: () async {
            await Future<void>.delayed(const Duration(milliseconds: 300));
          },
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              _MeetingCreateCard(
                onCreate: () =>
                    _openCreateSheet(context, repository: repository, authState: authState),
              ),
              const Gap(20),
              if (meetings.isEmpty)
                _EmptyMeetingsView(
                  onCreate: () =>
                      _openCreateSheet(context, repository: repository, authState: authState),
                )
              else
                ...meetings.map(
                  (LifeMeeting meeting) =>
                      _MeetingTile(meeting: meeting, authState: authState, repository: repository),
                ),
            ],
          ),
        );
      },
    );
  }

  void _openCreateSheet(
    BuildContext context, {
    required MockLifeRepository repository,
    required AuthState authState,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => MeetingCreationSheet(repository: repository, authState: authState),
    );
  }
}

class _MeetingCreateCard extends StatelessWidget {
  const _MeetingCreateCard({required this.onCreate});

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

class _EmptyMeetingsView extends StatelessWidget {
  const _EmptyMeetingsView({required this.onCreate});

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

class _MeetingTile extends StatelessWidget {
  const _MeetingTile({required this.meeting, required this.authState, required this.repository});

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

class MeetingCreationSheet extends StatefulWidget {
  const MeetingCreationSheet({super.key, required this.repository, required this.authState});

  final MockLifeRepository repository;
  final AuthState authState;

  @override
  State<MeetingCreationSheet> createState() => _MeetingCreationSheetState();
}

class _MeetingCreationSheetState extends State<MeetingCreationSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController(text: '8');
  final TextEditingController _locationController = TextEditingController();
  MeetingCategory _category = MeetingCategory.fitness;
  DateTime? _schedule;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _capacityController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsets viewInsets = MediaQuery.of(context).viewInsets;
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '새 모임 만들기',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Gap(16),
              DropdownButtonFormField<MeetingCategory>(
                decoration: const InputDecoration(labelText: '모임 종류'),
                initialValue: _category,
                items: MeetingCategory.values
                    .map(
                      (MeetingCategory category) => DropdownMenuItem<MeetingCategory>(
                        value: category,
                        child: Text('${category.emoji} ${category.label}'),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (MeetingCategory? value) {
                  if (value != null) {
                    setState(() => _category = value);
                  }
                },
              ),
              const Gap(12),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: '모임 제목'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '모임 제목을 입력해주세요.';
                  }
                  return null;
                },
              ),
              const Gap(12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: '모임 소개'),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '모임 소개를 입력해주세요.';
                  }
                  return null;
                },
              ),
              const Gap(12),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: '장소 (선택)'),
              ),
              const Gap(12),
              TextFormField(
                controller: _capacityController,
                decoration: const InputDecoration(labelText: '모집 인원'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final int? parsed = int.tryParse(value ?? '');
                  if (parsed == null || parsed < 2) {
                    return '2명 이상 인원을 입력해주세요.';
                  }
                  return null;
                },
              ),
              const Gap(12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _schedule == null
                          ? '모임 일시를 선택해주세요 (선택)'
                          : '모임 일시: ${_schedule!.year}.${_schedule!.month.toString().padLeft(2, '0')}.${_schedule!.day.toString().padLeft(2, '0')} ${_schedule!.hour.toString().padLeft(2, '0')}:${_schedule!.minute.toString().padLeft(2, '0')}',
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _pickSchedule,
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: const Text('선택'),
                  ),
                ],
              ),
              const Gap(20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('모임 만들기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickSchedule() async {
    final DateTime now = DateTime.now();
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null) {
      return;
    }
    if (!mounted) {
      return;
    }
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 19, minute: 0),
    );
    if (time == null) {
      return;
    }
    setState(() {
      _schedule = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (widget.authState.userId == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('로그인 후 모임을 만들 수 있어요.')));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final MeetingMember host = MeetingMember(
        uid: widget.authState.userId!,
        nickname: widget.authState.nickname,
      );
      await widget.repository.createMeeting(
        category: _category,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        host: host,
        capacity: int.parse(_capacityController.text.trim()),
        location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        schedule: _schedule,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('새 모임이 생성되었습니다.')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('모임을 만들지 못했어요: $error')));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
