import 'package:flutter/material.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/allowance.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/position.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/teacher_profile.dart';

/// 빠른 입력 Bottom Sheet
class QuickInputBottomSheet extends StatefulWidget {
  final TeacherProfile? initialProfile;
  final void Function(TeacherProfile profile) onSubmit;

  const QuickInputBottomSheet({
    super.key,
    this.initialProfile,
    required this.onSubmit,
  });

  @override
  State<QuickInputBottomSheet> createState() => _QuickInputBottomSheetState();
}

class _QuickInputBottomSheetState extends State<QuickInputBottomSheet> {
  late int _currentGrade;
  late Position _position;
  late DateTime _employmentStartDate;
  late int _retirementAge;

  // 수당 정보
  int _homeroomAllowance = 0;
  int _headTeacherAllowance = 0;
  int _familyAllowance = 0;
  int _veteranAllowance = 0;

  @override
  void initState() {
    super.initState();
    _currentGrade = widget.initialProfile?.currentGrade ?? 35;
    _position = widget.initialProfile?.position ?? Position.teacher;
    _employmentStartDate = widget.initialProfile?.employmentStartDate ??
        DateTime.now().subtract(const Duration(days: 365 * 20));
    _retirementAge = widget.initialProfile?.retirementAge ?? 65;

    if (widget.initialProfile != null) {
      _homeroomAllowance = widget.initialProfile!.allowances.homeroom;
      _headTeacherAllowance = widget.initialProfile!.allowances.headTeacher;
      _familyAllowance = widget.initialProfile!.allowances.family;
      _veteranAllowance = widget.initialProfile!.allowances.veteran;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // 핸들
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // 제목
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.rocket_launch, color: Colors.blue),
                    const SizedBox(width: 12),
                    Text(
                      '빠른 계산 (3초 완성!)',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),

              const Divider(),

              // 입력 폼
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // 현재 호봉
                    _buildSectionTitle('📍 현재 호봉'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: _currentGrade,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      items: List.generate(40, (index) => index + 1)
                          .map((grade) => DropdownMenuItem(
                                value: grade,
                                child: Text('$grade호봉'),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _currentGrade = value);
                        }
                      },
                    ),

                    const SizedBox(height: 24),

                    // 직급
                    _buildSectionTitle('📍 직급'),
                    const SizedBox(height: 8),
                    SegmentedButton<Position>(
                      segments: const [
                        ButtonSegment(
                          value: Position.teacher,
                          label: Text('교사'),
                        ),
                        ButtonSegment(
                          value: Position.vicePrincipal,
                          label: Text('교감'),
                        ),
                        ButtonSegment(
                          value: Position.principal,
                          label: Text('교장'),
                        ),
                      ],
                      selected: {_position},
                      onSelectionChanged: (Set<Position> newSelection) {
                        setState(() => _position = newSelection.first);
                      },
                    ),

                    const SizedBox(height: 24),

                    // 재직 시작일
                    _buildSectionTitle('📍 재직 시작일'),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _employmentStartDate,
                          firstDate: DateTime(1980),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() => _employmentStartDate = picked);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          '${_employmentStartDate.year}년 ${_employmentStartDate.month}월 ${_employmentStartDate.day}일',
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 퇴직 예정 연령
                    _buildSectionTitle('📍 퇴직 예정 연령'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: _retirementAge,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      items: List.generate(11, (index) => 60 + index)
                          .map((age) => DropdownMenuItem(
                                value: age,
                                child: Text('$age세'),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _retirementAge = value);
                        }
                      },
                    ),

                    const SizedBox(height: 32),

                    // 선택 입력 (접을 수 있는 섹션)
                    ExpansionTile(
                      title: const Text('⚙️ 더 정확하게 계산하기 (선택)'),
                      children: [
                        const SizedBox(height: 16),
                        _buildAllowanceInput(
                          '담임수당',
                          _homeroomAllowance,
                          (value) => setState(() => _homeroomAllowance = value),
                        ),
                        const SizedBox(height: 16),
                        _buildAllowanceInput(
                          '부장수당',
                          _headTeacherAllowance,
                          (value) =>
                              setState(() => _headTeacherAllowance = value),
                        ),
                        const SizedBox(height: 16),
                        _buildAllowanceInput(
                          '가족수당',
                          _familyAllowance,
                          (value) => setState(() => _familyAllowance = value),
                        ),
                        const SizedBox(height: 16),
                        _buildAllowanceInput(
                          '원로수당',
                          _veteranAllowance,
                          (value) => setState(() => _veteranAllowance = value),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // 계산 버튼
                    ElevatedButton(
                      onPressed: _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: const Text('📊 바로 계산하기'),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildAllowanceInput(
    String label,
    int value,
    void Function(int) onChanged,
  ) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(label),
        ),
        Expanded(
          flex: 3,
          child: TextFormField(
            initialValue: value == 0 ? '' : value.toString(),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              suffixText: '원',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              hintText: '0',
            ),
            onChanged: (text) {
              onChanged(int.tryParse(text) ?? 0);
            },
          ),
        ),
      ],
    );
  }

  void _handleSubmit() {
    final profile = TeacherProfile(
      currentGrade: _currentGrade,
      position: _position,
      employmentStartDate: _employmentStartDate,
      retirementAge: _retirementAge,
      allowances: Allowance(
        homeroom: _homeroomAllowance,
        headTeacher: _headTeacherAllowance,
        family: _familyAllowance,
        veteran: _veteranAllowance,
      ),
    );

    widget.onSubmit(profile);
    Navigator.pop(context);
  }
}
