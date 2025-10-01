/// Extracted from life_home_page.dart for better file organization
/// This widget displays the meeting creation bottom sheet form

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../data/mock_life_repository.dart';
import '../../domain/life_meeting.dart';

class MeetingCreationSheet extends StatefulWidget {
  const MeetingCreationSheet({
    super.key,
    required this.repository,
    required this.authState,
  });

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
