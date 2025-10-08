import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gong_mu_talk/common/widgets/cupertino_picker_modal.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/allowance.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/position.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/teacher_profile.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/teaching_allowance_bonus.dart';
import 'package:gong_mu_talk/features/calculator/presentation/widgets/teaching_allowance_selector_dialog.dart';

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
  late DateTime? _birthDate;
  late int? _currentGrade;
  late Position _position;
  late DateTime _employmentStartDate;
  late int _retirementAge;
  late int _gradePromotionMonth;

  // 새로운 입력 방식
  bool _isHomeroom = false;
  bool _hasSpouse = false;
  int _numberOfChildren = 0;
  int _numberOfParents = 0; // 60세 이상 직계존속
  Set<TeachingAllowanceBonus> _teachingAllowanceBonuses = {};

  @override
  void initState() {
    super.initState();
    // 출생일: 기존 프로필이 있으면 사용, 없으면 null
    if (widget.initialProfile != null) {
      _birthDate = DateTime(
        widget.initialProfile!.birthYear,
        widget.initialProfile!.birthMonth,
        1,
      );
    } else {
      _birthDate = null;
    }

    // 현재 호봉: 디폴트 없음 (필수 선택)
    _currentGrade = widget.initialProfile?.currentGrade;

    // 직급: 항상 교사로 고정
    _position = Position.teacher;

    // 임용일: 2025년 3월 1일 디폴트
    _employmentStartDate =
        widget.initialProfile?.employmentStartDate ?? DateTime(2025, 3, 1);

    _retirementAge = widget.initialProfile?.retirementAge ?? 62;

    // 호봉 승급월: 기본 3월
    _gradePromotionMonth = widget.initialProfile?.gradePromotionMonth ?? 3;

    // 기존 allowances가 있으면 추정
    if (widget.initialProfile != null) {
      _isHomeroom = widget.initialProfile!.allowances.homeroom > 0;
      _teachingAllowanceBonuses =
          widget.initialProfile!.teachingAllowanceBonuses;

      // 기존 allowances에 headTeacher가 있으면 teachingAllowanceBonuses에 추가
      if (widget.initialProfile!.allowances.headTeacher > 0 &&
          !_teachingAllowanceBonuses.contains(TeachingAllowanceBonus.headTeacher)) {
        _teachingAllowanceBonuses = {
          ..._teachingAllowanceBonuses,
          TeachingAllowanceBonus.headTeacher,
        };
      }
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.rocket_launch, color: Colors.blue),
                    const Gap(12),
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
                    _buildSectionTitle('📍 출생 연월'),
                    const Gap(8),
                    InkWell(
                      onTap: () async {
                        final initialDate = _birthDate ?? DateTime(1990, 1, 1);
                        int tempYear = initialDate.year;
                        int tempMonth = initialDate.month;

                        await showCupertinoModalPopup(
                          context: context,
                          builder: (BuildContext context) {
                            return DefaultTextStyle(
                              style: GoogleFonts.notoSansKr(
                                color: Colors.black87,
                              ),
                              child: Container(
                                height: 300,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(16),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    // Header
                                    Container(
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: Border(
                                          bottom: BorderSide(
                                            color: Colors.grey.shade300,
                                            width: 0.5,
                                          ),
                                        ),
                                        borderRadius:
                                            const BorderRadius.vertical(
                                              top: Radius.circular(16),
                                            ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          CupertinoButton(
                                            minimumSize: Size.zero,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                            ),
                                            child: Text(
                                              '취소',
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: 16,
                                              ),
                                            ),
                                            onPressed: () =>
                                                Navigator.pop(context),
                                          ),
                                          const Text(
                                            '출생 연월 선택',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          CupertinoButton(
                                            minimumSize: Size.zero,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                            ),
                                            child: Text(
                                              '완료',
                                              style: TextStyle(
                                                color: Theme.of(
                                                  context,
                                                ).primaryColor,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            onPressed: () {
                                              HapticFeedback.mediumImpact();
                                              setState(() {
                                                _birthDate = DateTime(
                                                  tempYear,
                                                  tempMonth,
                                                  1,
                                                );
                                              });
                                              Navigator.pop(context);
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Year and Month Pickers
                                    Expanded(
                                      child: CupertinoTheme(
                                        data: CupertinoThemeData(
                                          textTheme: CupertinoTextThemeData(
                                            pickerTextStyle:
                                                GoogleFonts.notoSansKr(
                                                  color: Colors.black87,
                                                  fontSize: 20,
                                                ),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            // Year Picker
                                            Expanded(
                                              child: CupertinoPicker(
                                                scrollController:
                                                    FixedExtentScrollController(
                                                  initialItem:
                                                      initialDate.year - 1960,
                                                ),
                                                itemExtent: 40,
                                                backgroundColor: Colors.white,
                                                diameterRatio: 1.5,
                                                squeeze: 1.2,
                                                magnification: 1.1,
                                                useMagnifier: true,
                                                selectionOverlay: Container(
                                                  decoration: BoxDecoration(
                                                    border: Border.symmetric(
                                                      horizontal: BorderSide(
                                                        color: Theme.of(context)
                                                            .primaryColor
                                                            .withValues(
                                                              alpha: 0.3,
                                                            ),
                                                        width: 1.5,
                                                      ),
                                                    ),
                                                    color: Theme.of(context)
                                                        .primaryColor
                                                        .withValues(alpha: 0.05),
                                                  ),
                                                ),
                                                onSelectedItemChanged: (index) {
                                                  HapticFeedback
                                                      .selectionClick();
                                                  tempYear = 1960 + index;
                                                },
                                                children: List.generate(
                                                  DateTime.now().year -
                                                      1960 +
                                                      1,
                                                  (index) {
                                                    final year = 1960 + index;
                                                    return Center(
                                                      child: Text('$year년'),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                            // Month Picker
                                            Expanded(
                                              child: CupertinoPicker(
                                                scrollController:
                                                    FixedExtentScrollController(
                                                  initialItem:
                                                      initialDate.month - 1,
                                                ),
                                                itemExtent: 40,
                                                backgroundColor: Colors.white,
                                                diameterRatio: 1.5,
                                                squeeze: 1.2,
                                                magnification: 1.1,
                                                useMagnifier: true,
                                                selectionOverlay: Container(
                                                  decoration: BoxDecoration(
                                                    border: Border.symmetric(
                                                      horizontal: BorderSide(
                                                        color: Theme.of(context)
                                                            .primaryColor
                                                            .withValues(
                                                              alpha: 0.3,
                                                            ),
                                                        width: 1.5,
                                                      ),
                                                    ),
                                                    color: Theme.of(context)
                                                        .primaryColor
                                                        .withValues(alpha: 0.05),
                                                  ),
                                                ),
                                                onSelectedItemChanged: (index) {
                                                  HapticFeedback
                                                      .selectionClick();
                                                  tempMonth = index + 1;
                                                },
                                                children: List.generate(12, (index) {
                                                  final month = index + 1;
                                                  return Center(
                                                    child: Text('$month월'),
                                                  );
                                                }),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: '출생 연도 및 월',
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          _birthDate != null
                              ? '${_birthDate!.year}년 ${_birthDate!.month}월'
                              : '선택해주세요',
                          style: TextStyle(
                            color: _birthDate != null ? null : Colors.grey,
                          ),
                        ),
                      ),
                    ),

                    const Gap(24),

                    // 현재 호봉
                    _buildSectionTitle('📍 현재 호봉'),
                    const Gap(8),
                    InkWell(
                      onTap: _showGradePicker,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: '호봉 선택 (필수)',
                          suffixIcon: Icon(Icons.school),
                        ),
                        child: Text(
                          _currentGrade != null
                              ? '$_currentGrade호봉'
                              : '호봉을 선택해주세요',
                          style: TextStyle(
                            color: _currentGrade != null ? null : Colors.grey,
                          ),
                        ),
                      ),
                    ),

                    const Gap(24),

                    // 임용일
                    _buildSectionTitle('📍 임용일'),
                    const Gap(8),
                    InkWell(
                      onTap: () async {
                        DateTime tempDate = _employmentStartDate;

                        await showCupertinoModalPopup(
                          context: context,
                          builder: (BuildContext context) {
                            return DefaultTextStyle(
                              style: GoogleFonts.notoSansKr(
                                color: Colors.black87,
                              ),
                              child: Container(
                                height: 300,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(16),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    // Header
                                    Container(
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: Border(
                                          bottom: BorderSide(
                                            color: Colors.grey.shade300,
                                            width: 0.5,
                                          ),
                                        ),
                                        borderRadius:
                                            const BorderRadius.vertical(
                                              top: Radius.circular(16),
                                            ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          CupertinoButton(
                                            minimumSize: Size.zero,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                            ),
                                            child: Text(
                                              '취소',
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: 16,
                                              ),
                                            ),
                                            onPressed: () =>
                                                Navigator.pop(context),
                                          ),
                                          const Text(
                                            '임용일 선택',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          CupertinoButton(
                                            minimumSize: Size.zero,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                            ),
                                            child: Text(
                                              '완료',
                                              style: TextStyle(
                                                color: Theme.of(
                                                  context,
                                                ).primaryColor,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            onPressed: () {
                                              HapticFeedback.mediumImpact(); // 완료 버튼 햅틱
                                              setState(() {
                                                _employmentStartDate = tempDate;
                                              });
                                              Navigator.pop(context);
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Date Picker
                                    Expanded(
                                      child: CupertinoTheme(
                                        data: CupertinoThemeData(
                                          textTheme: CupertinoTextThemeData(
                                            dateTimePickerTextStyle:
                                                GoogleFonts.notoSansKr(
                                                  color: Colors.black87,
                                                  fontSize: 20,
                                                ),
                                          ),
                                        ),
                                        child: CupertinoDatePicker(
                                          mode: CupertinoDatePickerMode.date,
                                          backgroundColor: Colors.white,
                                          initialDateTime: _employmentStartDate,
                                          minimumYear: 1980,
                                          maximumDate: DateTime.now(),
                                          onDateTimeChanged: (DateTime picked) {
                                            HapticFeedback.selectionClick(); // 날짜 변경 시 햅틱
                                            tempDate = picked;
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
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

                    const Gap(32),

                    // 선택 입력 (접을 수 있는 섹션)
                    ExpansionTile(
                      title: const Text('⚙️ 더 정확하게 계산하기 (선택)'),
                      children: [
                        // 호봉 승급월
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '호봉 승급월',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Gap(8),
                              InkWell(
                                onTap: _showGradePromotionMonthPicker,
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    suffixIcon: Icon(Icons.calendar_month),
                                  ),
                                  child: Text('$_gradePromotionMonth월'),
                                ),
                              ),
                              const Gap(4),
                              Text(
                                '호봉이 승급되는 월을 선택하세요 (일반적으로 3월)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Divider(),

                        // 교직 수당
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '교직 수당',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Gap(12),
                              SwitchListTile(
                                title: const Text('담임 수당 (가산금 4)'),
                                subtitle: const Text('담임일 경우 월 20만원 지급'),
                                value: _isHomeroom,
                                onChanged: (val) => setState(() => _isHomeroom = val),
                                contentPadding: EdgeInsets.zero,
                              ),
                              const Gap(8),
                              // 교직수당 가산금 선택 (보직교사 포함)
                              ListTile(
                                title: const Text('교직수당 가산금'),
                                subtitle: _teachingAllowanceBonuses.isEmpty
                                    ? const Text('보직교사, 특수교사 등 선택')
                                    : Text(
                                        _teachingAllowanceBonuses
                                            .map((b) => b.displayName)
                                            .join(', '),
                                      ),
                                trailing: const Icon(Icons.chevron_right),
                                contentPadding: EdgeInsets.zero,
                                onTap: _showTeachingAllowanceBonusesSelector,
                              ),
                            ],
                          ),
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
                              const Gap(12),
                              SwitchListTile(
                                title: const Text('배우자'),
                                subtitle: const Text('월 4만원'),
                                value: _hasSpouse,
                                onChanged: (val) =>
                                    setState(() => _hasSpouse = val),
                                contentPadding: EdgeInsets.zero,
                              ),
                              const Gap(8),
                              const Text(
                                '자녀 수',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Gap(8),
                              InkWell(
                                onTap: _showNumberOfChildrenPicker,
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    suffixIcon: Icon(Icons.family_restroom),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                  ),
                                  child: Text('$_numberOfChildren명'),
                                ),
                              ),
                              const Gap(4),
                              Text(
                                '첫째 5만원, 둘째 8만원, 셋째 이상 각 12만원',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const Gap(16),
                              const Text(
                                '60세 이상 부모님 (직계존속)',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Gap(8),
                              InkWell(
                                onTap: _showNumberOfParentsPicker,
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    suffixIcon: Icon(Icons.elderly),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                  ),
                                  child: Text('$_numberOfParents명'),
                                ),
                              ),
                              const Gap(4),
                              Text(
                                '1인당 2만원 (최대 4명)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Gap(16),

                        const Divider(),

                        // 퇴직 예정 연령
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    '퇴직 예정 연령',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const Gap(4),
                                  GestureDetector(
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('퇴직 예정 연령 안내'),
                                          content: const Text(
                                            '현재 법정 정년: 만 62세\n\n'
                                            '• 60세: 조기 퇴직 (연금 감액 가능)\n'
                                            '• 62세: 현행 법정 정년 (기본값)\n'
                                            '• 65세: 정년 연장 시나리오 (미확정)',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: const Text('확인'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    child: Icon(
                                      Icons.info_outline,
                                      size: 18,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              const Gap(8),
                              InkWell(
                                onTap: _showRetirementAgePicker,
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    suffixIcon: Icon(Icons.cake),
                                  ),
                                  child: Text('$_retirementAge세'),
                                ),
                              ),
                              const Gap(4),
                              _buildRetirementAgeDescription(),
                            ],
                          ),
                        ),

                        const Gap(16),
                      ],
                    ),

                    const Gap(32),

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

                    const Gap(24),
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
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    );
  }

  Widget _buildRetirementAgeDescription() {
    String description;
    Color color;

    switch (_retirementAge) {
      case 60:
        description = '조기 퇴직 (연금 감액 가능)';
        color = Colors.orange;
        break;
      case 62:
        description = '현행 법정 정년';
        color = Colors.green;
        break;
      case 65:
        description = '정년 연장 시나리오 (미확정)';
        color = Colors.blue;
        break;
      default:
        description = '';
        color = Colors.grey;
    }

    if (description.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        Icon(Icons.info_outline, size: 14, color: color),
        const Gap(4),
        Text(
          description,
          style: TextStyle(fontSize: 12, color: color),
        ),
      ],
    );
  }

  Future<void> _showGradePicker() async {
    final selectedGrade = await CupertinoPickerModal.show<int>(
      context: context,
      title: '호봉 선택',
      items: List.generate(35, (i) => i + 6), // 6-40호봉
      initialItem: _currentGrade ?? 15,
      itemBuilder: (grade) => '$grade호봉',
    );

    if (selectedGrade != null) {
      setState(() {
        _currentGrade = selectedGrade;
      });
    }
  }

  Future<void> _showRetirementAgePicker() async {
    final selectedAge = await CupertinoPickerModal.show<int>(
      context: context,
      title: '퇴직 예정 연령',
      items: List.generate(6, (i) => i + 60), // 60-65세
      initialItem: _retirementAge,
      itemBuilder: (age) => '$age세',
    );

    if (selectedAge != null) {
      setState(() {
        _retirementAge = selectedAge;
      });
    }
  }

  Future<void> _showGradePromotionMonthPicker() async {
    final selectedMonth = await CupertinoPickerModal.show<int>(
      context: context,
      title: '호봉 승급월',
      items: List.generate(12, (i) => i + 1), // 1-12월
      initialItem: _gradePromotionMonth,
      itemBuilder: (month) => '$month월',
    );

    if (selectedMonth != null) {
      setState(() {
        _gradePromotionMonth = selectedMonth;
      });
    }
  }

  Future<void> _showNumberOfChildrenPicker() async {
    final selectedChildren = await CupertinoPickerModal.show<int>(
      context: context,
      title: '자녀 수 선택',
      items: List.generate(6, (i) => i), // 0-5명
      initialItem: _numberOfChildren,
      itemBuilder: (count) => '$count명',
    );

    if (selectedChildren != null) {
      setState(() {
        _numberOfChildren = selectedChildren;
      });
    }
  }

  Future<void> _showNumberOfParentsPicker() async {
    final selectedParents = await CupertinoPickerModal.show<int>(
      context: context,
      title: '60세 이상 부모님',
      items: List.generate(5, (i) => i), // 0-4명
      initialItem: _numberOfParents,
      itemBuilder: (count) => '$count명',
    );
    if (selectedParents != null) {
      setState(() {
        _numberOfParents = selectedParents;
      });
    }
  }

  void _handleSubmit() {
    // 생년월 필수 입력 검증
    if (_birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('출생 연월을 선택해주세요.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // 호봉 필수 입력 검증
    if (_currentGrade == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('현재 호봉을 선택해주세요.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // 새로운 방식: Allowance는 기본값으로 설정
    // 실제 수당 계산은 SalaryCalculationService에서 처리

    // 보직교사 여부는 teachingAllowanceBonuses에서 판단
    final hasPosition = _teachingAllowanceBonuses.contains(
      TeachingAllowanceBonus.headTeacher,
    );

    final profile = TeacherProfile(
      birthYear: _birthDate!.year,
      birthMonth: _birthDate!.month,
      currentGrade: _currentGrade!,
      position: _position,
      employmentStartDate: _employmentStartDate,
      retirementAge: _retirementAge,
      gradePromotionMonth: _gradePromotionMonth,
      allowances: Allowance(
        homeroom: _isHomeroom ? 200000 : 0,
        headTeacher: hasPosition ? 150000 : 0,
        family: 0, // MonthlyBreakdownService._calculateFamilyAllowance 사용
        veteran: 0, // MonthlyBreakdownService._calculateVeteranAllowance 사용
      ),
      hasSpouse: _hasSpouse,
      numberOfChildren: _numberOfChildren,
      numberOfParents: _numberOfParents,
      isHomeroom: _isHomeroom,
      hasPosition: hasPosition,
      teachingAllowanceBonuses: _teachingAllowanceBonuses,
    );

    widget.onSubmit(profile);
    Navigator.pop(context);
  }

  Future<void> _showTeachingAllowanceBonusesSelector() async {
    final result = await TeachingAllowanceSelectorDialog.show(
      context,
      initialSelection: _teachingAllowanceBonuses,
    );

    if (result != null) {
      setState(() {
        _teachingAllowanceBonuses = result;
      });
    }
  }
}
