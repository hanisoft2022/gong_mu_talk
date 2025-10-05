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
  late int? _birthYear;
  late int? _birthMonth;
  late int _currentGrade;
  late Position _position;
  late DateTime _employmentStartDate;
  late int _retirementAge;

  // 새로운 입력 방식
  bool _isHomeroom = false;
  bool _hasPosition = false;
  bool _hasSpouse = false;
  int _numberOfChildren = 0;
  bool _retirementExtension = false;
  bool _includeMealAllowance = false;

  @override
  void initState() {
    super.initState();
    _birthYear = widget.initialProfile?.birthYear;
    _birthMonth = widget.initialProfile?.birthMonth;
    _currentGrade = widget.initialProfile?.currentGrade ?? 20;
    _position = widget.initialProfile?.position ?? Position.teacher;
    _employmentStartDate = widget.initialProfile?.employmentStartDate ??
        DateTime.now().subtract(const Duration(days: 365 * 10));
    _retirementAge = widget.initialProfile?.retirementAge ?? 62;

    // 기존 allowances가 있으면 추정
    if (widget.initialProfile != null) {
      _isHomeroom = widget.initialProfile!.allowances.homeroom > 0;
      _hasPosition = widget.initialProfile!.allowances.headTeacher > 0;
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
                    // 생년월
                    _buildSectionTitle('📍 출생년월'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: _birthYear,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: '출생 년도',
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            items: List.generate(60, (index) => 1960 + index)
                                .map((year) => DropdownMenuItem(
                                      value: year,
                                      child: Text('$year년'),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() => _birthYear = value);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: _birthMonth,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: '출생 월',
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            items: List.generate(12, (index) => index + 1)
                                .map((month) => DropdownMenuItem(
                                      value: month,
                                      child: Text('$month월'),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() => _birthMonth = value);
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // 현재 호봉
                    _buildSectionTitle('📍 현재 호봉'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      initialValue: _currentGrade,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      items: List.generate(35, (index) => index + 6)
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
                      initialValue: _retirementAge,
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
                        // 담임 여부
                        SwitchListTile(
                          title: const Text('담임 여부'),
                          subtitle: const Text('담임일 경우 월 20만원 지급'),
                          value: _isHomeroom,
                          onChanged: (val) => setState(() => _isHomeroom = val),
                        ),
                        
                        // 보직교사 여부
                        SwitchListTile(
                          title: const Text('보직교사 (부장 등)'),
                          subtitle: const Text('보직교사일 경우 월 15만원 지급'),
                          value: _hasPosition,
                          onChanged: (val) => setState(() => _hasPosition = val),
                        ),
                        
                        const Divider(),
                        
                        // 가족수당
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '가족수당',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              SwitchListTile(
                                title: const Text('배우자'),
                                subtitle: const Text('월 4만원'),
                                value: _hasSpouse,
                                onChanged: (val) =>
                                    setState(() => _hasSpouse = val),
                                contentPadding: EdgeInsets.zero,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Text('자녀 수'),
                                  const SizedBox(width: 8),
                                  const Spacer(),
                                  DropdownButton<int>(
                                    value: _numberOfChildren,
                                    items: List.generate(6, (i) => i)
                                        .map((n) => DropdownMenuItem(
                                              value: n,
                                              child: Text('$n명'),
                                            ))
                                        .toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(
                                          () => _numberOfChildren = val,
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '첫째 5만원, 둘째 8만원, 셋째 이상 각 12만원',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const Divider(height: 32),
                        
                        // 정년 연장 시나리오
                        SwitchListTile(
                          title: const Text('정년 연장 적용 (62세 → 65세)'),
                          subtitle: Text(
                            _retirementExtension
                                ? '정년: 65세'
                                : '정년: 62세 (2027년 이후 연금 공백 가능)',
                            style: TextStyle(
                              color: _retirementExtension
                                  ? Colors.blue
                                  : Colors.orange,
                            ),
                          ),
                          value: _retirementExtension,
                          onChanged: (val) {
                            setState(() {
                              _retirementExtension = val;
                              _retirementAge = val ? 65 : 62;
                            });
                          },
                        ),
                        
                        // 정액급식비 포함 여부
                        SwitchListTile(
                          title: const Text('정액급식비 포함'),
                          subtitle: const Text('월 14만원'),
                          value: _includeMealAllowance,
                          onChanged: (val) =>
                              setState(() => _includeMealAllowance = val),
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

  void _handleSubmit() {
    // 생년월 필수 입력 검증
    if (_birthYear == null || _birthMonth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('출생년월을 선택해주세요.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // 새로운 방식: Allowance는 기본값으로 설정
    // 실제 수당 계산은 SalaryCalculationService에서 처리
    final profile = TeacherProfile(
      birthYear: _birthYear!,
      birthMonth: _birthMonth!,
      currentGrade: _currentGrade,
      position: _position,
      employmentStartDate: _employmentStartDate,
      retirementAge: _retirementAge,
      allowances: Allowance(
        homeroom: _isHomeroom ? 200000 : 0,
        headTeacher: _hasPosition ? 150000 : 0,
        family: 0, // SalaryCalculationService.calculateFamilyAllowance 사용
        veteran: 0, // SalaryCalculationService.calculateVeteranAllowance 사용
      ),
      hasSpouse: _hasSpouse,
      numberOfChildren: _numberOfChildren,
      isHomeroom: _isHomeroom,
      hasPosition: _hasPosition,
    );

    widget.onSubmit(profile);
    Navigator.pop(context);
  }
}
