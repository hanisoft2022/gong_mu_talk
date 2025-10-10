import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gong_mu_talk/common/widgets/cupertino_picker_modal.dart';
import 'package:gong_mu_talk/common/widgets/info_dialog.dart';
import 'package:gong_mu_talk/core/theme/app_color_extension.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/allowance.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/position.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/school_type.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/teacher_profile.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/teaching_allowance_bonus.dart';
import 'package:gong_mu_talk/features/calculator/presentation/widgets/teaching_allowance_selector_dialog.dart';

/// 빠른 입력 Bottom Sheet
class QuickInputBottomSheet extends StatefulWidget {
  final TeacherProfile? initialProfile;
  final void Function(TeacherProfile profile) onSubmit;

  const QuickInputBottomSheet({super.key, this.initialProfile, required this.onSubmit});

  @override
  State<QuickInputBottomSheet> createState() => _QuickInputBottomSheetState();
}

class _QuickInputBottomSheetState extends State<QuickInputBottomSheet> {
  late DateTime? _birthDate;
  late int? _currentGrade;
  late Position _position;
  late SchoolType _schoolType;
  late DateTime _employmentStartDate;
  late int _retirementAge;
  late int _gradePromotionMonth;

  // 새로운 입력 방식
  bool _hasSpouse = false;
  int _numberOfChildren = 0;
  int _numberOfParents = 0; // 60세 이상 직계존속
  List<DateTime?> _childrenBirthDates = []; // 자녀 생년월일 목록 (만 6세 이하 비과세용)
  Set<TeachingAllowanceBonus> _teachingAllowanceBonuses = {};

  // 교육경력 관련
  bool _hasFirstGradeCertificate = true; // 1급 정교사 (기본 true)
  int _additionalTeachingMonths = 0; // 추가 교육경력 (개월)
  int _excludedTeachingMonths = 0; // 제외 교육경력 (개월)

  // 공제 항목
  int _teacherAssociationFee = 0; // 교직원공제회비
  int _otherDeductions = 0; // 기타 공제

  // TextField Controllers
  late TextEditingController _teacherAssociationFeeController;
  late TextEditingController _otherDeductionsController;

  @override
  void initState() {
    super.initState();
    // 출생일: 기존 프로필이 있으면 사용, 없으면 null
    if (widget.initialProfile != null) {
      _birthDate = DateTime(widget.initialProfile!.birthYear, widget.initialProfile!.birthMonth, 1);
    } else {
      _birthDate = null;
    }

    // 현재 호봉: 디폴트 없음 (필수 선택)
    _currentGrade = widget.initialProfile?.currentGrade;

    // 직급: 기본값 교사
    _position = widget.initialProfile?.position ?? Position.teacher;

    // 학교급: 기본값 유·초등
    _schoolType = widget.initialProfile?.schoolType ?? SchoolType.elementary;

    // 임용일: 2025년 3월 1일 디폴트
    _employmentStartDate = widget.initialProfile?.employmentStartDate ?? DateTime(2025, 3, 1);

    _retirementAge = widget.initialProfile?.retirementAge ?? 62;

    // 호봉 승급월: 기본 3월
    _gradePromotionMonth = widget.initialProfile?.gradePromotionMonth ?? 3;

    // 기존 allowances가 있으면 추정
    if (widget.initialProfile != null) {
      _teachingAllowanceBonuses = widget.initialProfile!.teachingAllowanceBonuses;

      // 기존 allowances에 homeroom이 있으면 teachingAllowanceBonuses에 추가
      if (widget.initialProfile!.allowances.homeroom > 0 &&
          !_teachingAllowanceBonuses.contains(TeachingAllowanceBonus.homeroom)) {
        _teachingAllowanceBonuses = {..._teachingAllowanceBonuses, TeachingAllowanceBonus.homeroom};
      }

      // 기존 allowances에 headTeacher가 있으면 teachingAllowanceBonuses에 추가
      if (widget.initialProfile!.allowances.headTeacher > 0 &&
          !_teachingAllowanceBonuses.contains(TeachingAllowanceBonus.headTeacher)) {
        _teachingAllowanceBonuses = {
          ..._teachingAllowanceBonuses,
          TeachingAllowanceBonus.headTeacher,
        };
      }

      // 공제 항목 초기화
      _teacherAssociationFee = widget.initialProfile!.teacherAssociationFee;
      _otherDeductions = widget.initialProfile!.otherDeductions;
    }

    // 가족 수당 필드 초기화 (Bug Fix 1)
    _hasSpouse = widget.initialProfile?.hasSpouse ?? false;
    _numberOfChildren = widget.initialProfile?.numberOfChildren ?? 0;
    _numberOfParents = widget.initialProfile?.numberOfParents ?? 0;

    // 자녀 생년월일 초기화 (만 6세 이하 비과세용)
    if (widget.initialProfile != null) {
      _childrenBirthDates = List.from(widget.initialProfile!.youngChildrenBirthDates);
      // 자녀 수만큼 리스트 크기 조정 (부족한 경우 null로 채움)
      while (_childrenBirthDates.length < _numberOfChildren) {
        _childrenBirthDates.add(null);
      }
    } else {
      _childrenBirthDates = List.filled(_numberOfChildren, null);
    }

    // 교육경력 필드 초기화
    _hasFirstGradeCertificate = widget.initialProfile?.hasFirstGradeCertificate ?? true;
    _additionalTeachingMonths = widget.initialProfile?.additionalTeachingMonths ?? 0;
    _excludedTeachingMonths = widget.initialProfile?.excludedTeachingMonths ?? 0;

    // TextEditingController 초기화 (Bug Fix 2)
    _teacherAssociationFeeController = TextEditingController(
      text: _teacherAssociationFee > 0 ? _teacherAssociationFee.toString() : '',
    );
    _otherDeductionsController = TextEditingController(
      text: _otherDeductions > 0 ? _otherDeductions.toString() : '',
    );
  }

  @override
  void dispose() {
    _teacherAssociationFeeController.dispose();
    _otherDeductionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.8,
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
                  color: Theme.of(context).colorScheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // 제목
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.rocket_launch, color: context.appColors.info),
                    const Gap(12),
                    Text(
                      '빠른 계산 (3초 완성!)',
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
                              style: GoogleFonts.notoSansKr(color: Theme.of(context).colorScheme.onSurface),
                              child: Container(
                                height: 300,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                ),
                                child: Column(
                                  children: [
                                    // Header
                                    Container(
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.surface,
                                        border: Border(
                                          bottom: BorderSide(
                                            color: Theme.of(context).colorScheme.outline,
                                            width: 0.5,
                                          ),
                                        ),
                                        borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(16),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          CupertinoButton(
                                            minimumSize: Size.zero,
                                            padding: const EdgeInsets.symmetric(horizontal: 12),
                                            child: Text(
                                              '취소',
                                              style: TextStyle(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant,
                                                fontSize: 16,
                                              ),
                                            ),
                                            onPressed: () => Navigator.pop(context),
                                          ),
                                          Text(
                                            '출생 연월 선택',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                              color: Theme.of(context).colorScheme.onSurface,
                                            ),
                                          ),
                                          CupertinoButton(
                                            minimumSize: Size.zero,
                                            padding: const EdgeInsets.symmetric(horizontal: 12),
                                            child: Text(
                                              '완료',
                                              style: TextStyle(
                                                color: Theme.of(context).primaryColor,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            onPressed: () {
                                              HapticFeedback.mediumImpact();
                                              setState(() {
                                                _birthDate = DateTime(tempYear, tempMonth, 1);
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
                                            pickerTextStyle: GoogleFonts.notoSansKr(
                                              color: Theme.of(context).colorScheme.onSurface,
                                              fontSize: 20,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            // Year Picker
                                            Expanded(
                                              child: CupertinoPicker(
                                                scrollController: FixedExtentScrollController(
                                                  initialItem: initialDate.year - 1960,
                                                ),
                                                itemExtent: 40,
                                                backgroundColor: Theme.of(context).colorScheme.surface,
                                                diameterRatio: 1.5,
                                                squeeze: 1.2,
                                                magnification: 1.1,
                                                useMagnifier: true,
                                                selectionOverlay: Container(
                                                  decoration: BoxDecoration(
                                                    border: Border.symmetric(
                                                      horizontal: BorderSide(
                                                        color: Theme.of(
                                                          context,
                                                        ).primaryColor.withValues(alpha: 0.3),
                                                        width: 1.5,
                                                      ),
                                                    ),
                                                    color: Theme.of(
                                                      context,
                                                    ).primaryColor.withValues(alpha: 0.05),
                                                  ),
                                                ),
                                                onSelectedItemChanged: (index) {
                                                  HapticFeedback.selectionClick();
                                                  tempYear = 1960 + index;
                                                },
                                                children: List.generate(
                                                  DateTime.now().year - 1960 + 1,
                                                  (index) {
                                                    final year = 1960 + index;
                                                    return Center(child: Text('$year년'));
                                                  },
                                                ),
                                              ),
                                            ),
                                            // Month Picker
                                            Expanded(
                                              child: CupertinoPicker(
                                                scrollController: FixedExtentScrollController(
                                                  initialItem: initialDate.month - 1,
                                                ),
                                                itemExtent: 40,
                                                backgroundColor: Theme.of(context).colorScheme.surface,
                                                diameterRatio: 1.5,
                                                squeeze: 1.2,
                                                magnification: 1.1,
                                                useMagnifier: true,
                                                selectionOverlay: Container(
                                                  decoration: BoxDecoration(
                                                    border: Border.symmetric(
                                                      horizontal: BorderSide(
                                                        color: Theme.of(
                                                          context,
                                                        ).primaryColor.withValues(alpha: 0.3),
                                                        width: 1.5,
                                                      ),
                                                    ),
                                                    color: Theme.of(
                                                      context,
                                                    ).primaryColor.withValues(alpha: 0.05),
                                                  ),
                                                ),
                                                onSelectedItemChanged: (index) {
                                                  HapticFeedback.selectionClick();
                                                  tempMonth = index + 1;
                                                },
                                                children: List.generate(12, (index) {
                                                  final month = index + 1;
                                                  return Center(child: Text('$month월'));
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
                            color: _birthDate != null
                                ? null
                                : Theme.of(context).colorScheme.onSurfaceVariant,
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
                          _currentGrade != null ? '$_currentGrade호봉' : '호봉을 선택해주세요',
                          style: TextStyle(
                            color: _currentGrade != null
                                ? null
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),

                    const Gap(24),

                    // 직급 선택
                    _buildSectionTitle('📍 직급'),
                    const Gap(8),
                    InkWell(
                      onTap: _showPositionPicker,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: '직급 선택',
                          suffixIcon: Icon(Icons.badge),
                        ),
                        child: Text(_position.displayName),
                      ),
                    ),

                    // 학교급 선택 (교장/교감만 표시)
                    if (_position == Position.principal || _position == Position.vicePrincipal) ...[
                      const Gap(16),
                      _buildSectionTitle('📍 학교급'),
                      const Gap(8),
                      InkWell(
                        onTap: _showSchoolTypePicker,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: '학교급 선택',
                            suffixIcon: Icon(Icons.school),
                          ),
                          child: Text(_schoolType.displayName),
                        ),
                      ),
                      const Gap(4),
                      Text(
                        '교원연구비 계산에 사용됩니다 (교장/교감만)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],

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
                              style: GoogleFonts.notoSansKr(color: Theme.of(context).colorScheme.onSurface),
                              child: Container(
                                height: 300,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                ),
                                child: Column(
                                  children: [
                                    // Header
                                    Container(
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.surface,
                                        border: Border(
                                          bottom: BorderSide(
                                            color: Theme.of(context).colorScheme.outline,
                                            width: 0.5,
                                          ),
                                        ),
                                        borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(16),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          CupertinoButton(
                                            minimumSize: Size.zero,
                                            padding: const EdgeInsets.symmetric(horizontal: 12),
                                            child: Text(
                                              '취소',
                                              style: TextStyle(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant,
                                                fontSize: 16,
                                              ),
                                            ),
                                            onPressed: () => Navigator.pop(context),
                                          ),
                                          Text(
                                            '임용일 선택',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                              color: Theme.of(context).colorScheme.onSurface,
                                            ),
                                          ),
                                          CupertinoButton(
                                            minimumSize: Size.zero,
                                            padding: const EdgeInsets.symmetric(horizontal: 12),
                                            child: Text(
                                              '완료',
                                              style: TextStyle(
                                                color: Theme.of(context).primaryColor,
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
                                            dateTimePickerTextStyle: GoogleFonts.notoSansKr(
                                              color: Theme.of(context).colorScheme.onSurface,
                                              fontSize: 20,
                                            ),
                                          ),
                                        ),
                                        child: CupertinoDatePicker(
                                          mode: CupertinoDatePickerMode.date,
                                          backgroundColor: Theme.of(context).colorScheme.surface,
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
                      title: Text(
                        '🔎  정확한 계산 (선택 입력)',
                        style: Theme.of(
                          context,
                        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      children: [
                        // 호봉 승급월
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '호봉 승급월',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
                                '호봉이 승급되는 월을 선택하세요.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Divider(),

                        // 1급 정교사 & 재직연수 & 교육경력
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    '재직연수 & 교육경력',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                  ),
                                  const Gap(4),
                                  GestureDetector(
                                    onTap: () {
                                      InfoDialog.showList(
                                        context,
                                        title: '재직연수 & 교육경력 안내',
                                        icon: Icons.school_outlined,
                                        iconColor: context.appColors.info,
                                        description: '두 가지 경력 개념을 구분하여 정확한 수당 계산',
                                        items: [
                                          InfoListItem(
                                            title: '재직연수',
                                            subtitle: '정근수당 계산 기준, 군 경력 100% 반영',
                                            icon: Icons.event_available,
                                            iconColor: context.appColors.success,
                                          ),
                                          InfoListItem(
                                            title: '교육경력',
                                            subtitle: '교원연구비 계산 기준, 군 경력 미반영이므로 수기 입력 필요',
                                            icon: Icons.timeline,
                                            iconColor: Theme.of(context).colorScheme.primary,
                                          ),
                                          const InfoListItem(
                                            title: '호봉 기반 자동 계산',
                                            subtitle: '현재 호봉과 승급월을 기반으로 자동 계산됩니다',
                                            icon: Icons.calculate_outlined,
                                          ),
                                        ],
                                      );
                                    },
                                    child: Icon(
                                      Icons.info_outline,
                                      size: 18,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              const Gap(12),
                              // 1급 정교사 체크박스
                              SwitchListTile(
                                title: const Text('1급 정교사 자격증 소지'),
                                value: _hasFirstGradeCertificate,
                                onChanged: (val) => setState(() => _hasFirstGradeCertificate = val),
                                contentPadding: EdgeInsets.zero,
                              ),
                              const Gap(16),
                              // 재직연수 & 교육경력 카드 (나란히 배치)
                              Row(
                                children: [
                                  // 재직연수 카드 (왼쪽, 초록색)
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: context.appColors.successLight,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: context.appColors.success.withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.event_available,
                                                size: 18,
                                                color: context.appColors.success,
                                              ),
                                              const Gap(6),
                                              Expanded(
                                                child: Text(
                                                  '재직연수',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: context.appColors.successDark,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const Gap(8),
                                          Builder(
                                            builder: (context) {
                                              final service = _calculateServiceYears();
                                              return Text(
                                                '${service['years']}년\n${service['months']}개월',
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: context.appColors.successDark,
                                                  height: 1.2,
                                                ),
                                              );
                                            },
                                          ),
                                          const Gap(6),
                                          Text(
                                            '정근수당 기준',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: context.appColors.success,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const Gap(12),
                                  // 교육경력 카드 (오른쪽, 파란색)
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primaryContainer,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary.withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.timeline,
                                                size: 18,
                                                color: Theme.of(context).colorScheme.primary,
                                              ),
                                              const Gap(6),
                                              Expanded(
                                                child: Text(
                                                  '교육경력',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: Theme.of(context).colorScheme.primary,
                                                  ),
                                                ),
                                              ),
                                              GestureDetector(
                                                onTap: _showTeachingExperienceEditModal,
                                                child: Icon(
                                                  Icons.edit,
                                                  size: 16,
                                                  color: Theme.of(context).colorScheme.primary,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const Gap(8),
                                          Builder(
                                            builder: (context) {
                                              final exp = _calculateTeachingExperience();
                                              final isModified =
                                                  _additionalTeachingMonths > 0 ||
                                                  _excludedTeachingMonths > 0;
                                              return Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    '${exp['years']}년\n${exp['months']}개월',
                                                    style: TextStyle(
                                                      fontSize: 20,
                                                      fontWeight: FontWeight.bold,
                                                      color: Theme.of(context).colorScheme.primary,
                                                      height: 1.2,
                                                    ),
                                                  ),
                                                  if (isModified)
                                                    Container(
                                                      margin: const EdgeInsets.only(top: 2),
                                                      padding: const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: context.appColors.highlightLight,
                                                        borderRadius: BorderRadius.circular(3),
                                                      ),
                                                      child: Text(
                                                        '수정됨',
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.w600,
                                                          color: context.appColors.highlightDark,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              );
                                            },
                                          ),
                                          const Gap(6),
                                          Text(
                                            '교원연구비 기준',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Theme.of(context).colorScheme.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const Divider(),

                        // 교직수당
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '교직수당 가산금',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                              const Gap(12),
                              // 교직수당 가산금 선택 (담임, 보직교사 포함)
                              ListTile(
                                title: const Text('교직수당 가산금'),
                                subtitle: _teachingAllowanceBonuses.isEmpty
                                    ? const Text('담임교사, 보직교사, 특수교사 등 선택')
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
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                              const Gap(12),
                              SwitchListTile(
                                title: const Text('배우자'),
                                subtitle: const Text('월 4만원'),
                                value: _hasSpouse,
                                onChanged: (val) => setState(() => _hasSpouse = val),
                                contentPadding: EdgeInsets.zero,
                              ),
                              const Gap(8),
                              const Text(
                                '자녀 수',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
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
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              // 자녀 생년월일 입력 버튼 (조건부 표시)
                              if (_numberOfChildren >= 1) ...[
                                const Gap(12),
                                OutlinedButton.icon(
                                  onPressed: _showChildrenBirthDatesDialog,
                                  icon: const Icon(Icons.child_care, size: 18),
                                  label: const Text('만 6세 이하 자녀 정보 입력 (비과세 혜택)'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                                const Gap(4),
                                Text(
                                  '생년월일 입력 시 월 20만원 한도 내 비과세 적용',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ],
                              const Gap(16),
                              const Text(
                                '부양 가족 수',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
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
                                '만 60세 이상 직계존속 부모님, 1인당 2만원 (최대 2명)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                  ),
                                  const Gap(4),
                                  GestureDetector(
                                    onTap: () {
                                      InfoDialog.showList(
                                        context,
                                        title: '퇴직 예정 연령 안내',
                                        icon: Icons.cake_outlined,
                                        iconColor: context.appColors.info,
                                        description: '재직 20년 이상부터 퇴직 가능',
                                        items: [
                                          InfoListItem(
                                            title: '명예퇴직 (재직 20년 이상)',
                                            subtitle: '법정 정년 전 퇴직',
                                            icon: Icons.star_outline,
                                            iconColor: context.appColors.warning,
                                          ),
                                          InfoListItem(
                                            title: '법정 정년 (62세)',
                                            subtitle: '현행 법정 정년',
                                            icon: Icons.check_circle_outline,
                                            iconColor: context.appColors.info,
                                          ),
                                          InfoListItem(
                                            title: '정년 연장 (63~65세)',
                                            subtitle: '정년 연장 시나리오 (정부 논의 단계, 법 개정 전)',
                                            icon: Icons.trending_up,
                                            iconColor: Theme.of(context).colorScheme.primary,
                                          ),
                                        ],
                                      );
                                    },
                                    child: Icon(
                                      Icons.info_outline,
                                      size: 18,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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

                        const Divider(),

                        // 공제 항목 (선택)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    '공제 항목 (선택)',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                  ),
                                  const Gap(4),
                                  GestureDetector(
                                    onTap: () {
                                      InfoDialog.showList(
                                        context,
                                        title: '공제 항목 안내',
                                        icon: Icons.account_balance_outlined,
                                        iconColor: context.appColors.info,
                                        description: '매월 급여에서 공제되는 항목을 입력할 수 있습니다.',
                                        items: const [
                                          InfoListItem(
                                            title: '교직원공제회비',
                                            subtitle: '교직원공제회 회원인 경우',
                                            icon: Icons.groups_outlined,
                                          ),
                                          InfoListItem(
                                            title: '기타 공제',
                                            subtitle: '친목회비 등 기타 공제 항목',
                                            icon: Icons.savings_outlined,
                                          ),
                                        ],
                                      );
                                    },
                                    child: Icon(
                                      Icons.info_outline,
                                      size: 18,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              const Gap(12),
                              TextField(
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                decoration: const InputDecoration(
                                  labelText: '교직원공제회비 (원)',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.account_balance),
                                  hintText: '예: 50000',
                                ),
                                controller: _teacherAssociationFeeController,
                                onChanged: (value) {
                                  setState(() {
                                    _teacherAssociationFee = int.tryParse(value) ?? 0;
                                  });
                                },
                              ),
                              const Gap(12),
                              TextField(
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                decoration: const InputDecoration(
                                  labelText: '기타 공제 (원)',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.payment),
                                  hintText: '예: 30000',
                                ),
                                controller: _otherDeductionsController,
                                onChanged: (value) {
                                  setState(() {
                                    _otherDeductions = int.tryParse(value) ?? 0;
                                  });
                                },
                              ),
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
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
    return Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600));
  }

  /// 재직연수 계산 (년, 개월)
  /// 호봉 기반 순수 계산만 수행 (추가/제외 경력 미반영)
  /// 정근수당 계산 기준
  Map<String, int> _calculateServiceYears() {
    if (_currentGrade == null) {
      return {'years': 0, 'months': 0};
    }

    final now = DateTime.now();

    // 기본 연수 (호봉 - 9 - 1급 정교사 가산)
    final baseYears = _currentGrade! - 9 - (_hasFirstGradeCertificate ? 1 : 0);

    // 승급월 고려한 개월 수
    final thisYearPromotion = DateTime(now.year, _gradePromotionMonth, 1);
    int totalMonths;

    if (now.isBefore(thisYearPromotion)) {
      // 아직 승급 안 됨
      final lastPromotion = DateTime(now.year - 1, _gradePromotionMonth, 1);
      final monthsSincePromotion =
          (now.year - lastPromotion.year) * 12 + (now.month - lastPromotion.month);
      totalMonths = ((baseYears - 1) * 12) + monthsSincePromotion;
    } else {
      // 승급 완료
      final monthsSincePromotion =
          (now.year - thisYearPromotion.year) * 12 + (now.month - thisYearPromotion.month);
      totalMonths = (baseYears * 12) + monthsSincePromotion;
    }

    if (totalMonths < 0) totalMonths = 0;

    return {'years': totalMonths ~/ 12, 'months': totalMonths % 12};
  }

  /// 교육경력 계산 (년, 개월)
  /// 재직연수 + 추가 - 제외 반영
  /// 교원연구비 계산 기준
  Map<String, int> _calculateTeachingExperience() {
    if (_currentGrade == null) {
      return {'years': 0, 'months': 0};
    }

    final now = DateTime.now();

    // 기본 연수 (호봉 - 9 - 1급 정교사 가산)
    final baseYears = _currentGrade! - 9 - (_hasFirstGradeCertificate ? 1 : 0);

    // 승급월 고려한 개월 수
    final thisYearPromotion = DateTime(now.year, _gradePromotionMonth, 1);
    int totalMonths;

    if (now.isBefore(thisYearPromotion)) {
      // 아직 승급 안 됨
      final lastPromotion = DateTime(now.year - 1, _gradePromotionMonth, 1);
      final monthsSincePromotion =
          (now.year - lastPromotion.year) * 12 + (now.month - lastPromotion.month);
      totalMonths = ((baseYears - 1) * 12) + monthsSincePromotion;
    } else {
      // 승급 완료
      final monthsSincePromotion =
          (now.year - thisYearPromotion.year) * 12 + (now.month - thisYearPromotion.month);
      totalMonths = (baseYears * 12) + monthsSincePromotion;
    }

    // 추가/제외 반영
    totalMonths = totalMonths + _additionalTeachingMonths - _excludedTeachingMonths;
    if (totalMonths < 0) totalMonths = 0;

    return {'years': totalMonths ~/ 12, 'months': totalMonths % 12};
  }

  Widget _buildRetirementAgeDescription() {
    // 출생일이 없으면 기본 설명만 표시
    if (_birthDate == null) {
      String description;
      Color color;

      if (_retirementAge < 62) {
        description = '명예퇴직 (재직 20년 이상)';
        color = context.appColors.warning;
      } else if (_retirementAge == 62) {
        description = '현행 법정 정년 (62세)';
        color = context.appColors.info;
      } else {
        description = '정년 연장 시나리오 (정부 논의 단계, 법 개정 전)';
        color = Theme.of(context).colorScheme.primary;
      }

      return Row(
        children: [
          Icon(Icons.info_outline, size: 14, color: color),
          const Gap(4),
          Text(description, style: TextStyle(fontSize: 12, color: color)),
        ],
      );
    }

    // 출생일이 있으면 최소 퇴직 가능 연령 계산 후 표시
    final twentyYearsAfterEmployment = DateTime(
      _employmentStartDate.year + 20,
      _employmentStartDate.month,
      _employmentStartDate.day,
    );
    final ageAt20YearsService = twentyYearsAfterEmployment.year - _birthDate!.year;

    // 선택된 연령에 대한 설명
    String ageDescription;
    Color ageColor;

    if (_retirementAge < 62) {
      ageDescription = '명예퇴직 (재직 20년 이상)';
      ageColor = context.appColors.warning;
    } else if (_retirementAge == 62) {
      ageDescription = '현행 법정 정년 (62세)';
      ageColor = context.appColors.info;
    } else {
      ageDescription = '정년 연장 시나리오 (정부 논의 단계, 법 개정 전)';
      ageColor = Theme.of(context).colorScheme.primary;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.info_outline, size: 14, color: ageColor),
            const Gap(4),
            Text(ageDescription, style: TextStyle(fontSize: 12, color: ageColor)),
          ],
        ),
        const Gap(4),
        Text(
          '임용일 기준 재직 20년인 만 $ageAt20YearsService세부터 명예퇴직 가능',
          style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
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
    // 출생일 미입력 시 에러 처리
    if (_birthDate == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('출생 연월을 먼저 선택해주세요.'),
          backgroundColor: context.appColors.warning,
        ),
      );
      return;
    }

    // 1. 임용일 + 20년 → 명예퇴직 최소 시점
    final twentyYearsAfterEmployment = DateTime(
      _employmentStartDate.year + 20,
      _employmentStartDate.month,
      _employmentStartDate.day,
    );

    // 2. 명예퇴직 최소 시점의 나이 계산
    final ageAt20YearsService = twentyYearsAfterEmployment.year - _birthDate!.year;

    // 3. 현재 나이 계산
    final currentAge = DateTime.now().year - _birthDate!.year;

    // 4. 최소 퇴직 가능 연령 = max(20년 재직 시 나이, 현재 나이)
    final minRetirementAge = max(ageAt20YearsService, currentAge);

    // 5. 정년 65세 초과 검증
    if (minRetirementAge > 65) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('정년(65세)이 지났거나 퇴직 선택이 불가능합니다.'),
          backgroundColor: context.appColors.warning,
        ),
      );
      return;
    }

    // 6. 동적 연령 범위 생성 (minRetirementAge ~ 65세)
    final ageRange = List.generate(65 - minRetirementAge + 1, (i) => minRetirementAge + i);

    // 7. 현재 선택된 연령이 범위 밖이면 최소값으로 조정
    final safeInitialAge = _retirementAge < minRetirementAge ? minRetirementAge : _retirementAge;

    final selectedAge = await CupertinoPickerModal.show<int>(
      context: context,
      title: '퇴직 예정 연령',
      items: ageRange,
      initialItem: safeInitialAge,
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
        final oldCount = _numberOfChildren;
        _numberOfChildren = selectedChildren;

        // 자녀 생년월일 리스트 크기 동적 조정
        if (_numberOfChildren > oldCount) {
          // 자녀 수 증가: null로 추가
          while (_childrenBirthDates.length < _numberOfChildren) {
            _childrenBirthDates.add(null);
          }
        } else if (_numberOfChildren < oldCount) {
          // 자녀 수 감소: 뒤에서부터 제거
          _childrenBirthDates = _childrenBirthDates.sublist(0, _numberOfChildren);
        }
      });
    }
  }

  Future<void> _showNumberOfParentsPicker() async {
    final selectedParents = await CupertinoPickerModal.show<int>(
      context: context,
      title: '부양 가족 수',
      items: List.generate(3, (i) => i), // 0-2명
      initialItem: _numberOfParents,
      itemBuilder: (count) => '$count명',
    );
    if (selectedParents != null) {
      setState(() {
        _numberOfParents = selectedParents;
      });
    }
  }

  Future<void> _showPositionPicker() async {
    final selectedPosition = await CupertinoPickerModal.show<Position>(
      context: context,
      title: '직급 선택',
      items: Position.values,
      initialItem: _position,
      itemBuilder: (position) => position.displayName,
    );

    if (selectedPosition != null) {
      setState(() {
        final oldPosition = _position;
        _position = selectedPosition;

        // Reset school type if not principal/vice-principal
        if (_position != Position.principal && _position != Position.vicePrincipal) {
          _schoolType = SchoolType.elementary;
        }

        // 보직교사 선택 시 교직수당 가산금에 자동 추가
        if (_position == Position.headTeacher) {
          _teachingAllowanceBonuses = {
            ..._teachingAllowanceBonuses,
            TeachingAllowanceBonus.headTeacher,
          };
        }

        // 보직교사에서 다른 직급으로 변경 시 교직수당 가산금에서 제거
        if (oldPosition == Position.headTeacher && _position != Position.headTeacher) {
          _teachingAllowanceBonuses = _teachingAllowanceBonuses
              .where((b) => b != TeachingAllowanceBonus.headTeacher)
              .toSet();
        }
      });
    }
  }

  Future<void> _showSchoolTypePicker() async {
    final selectedSchoolType = await CupertinoPickerModal.show<SchoolType>(
      context: context,
      title: '학교급 선택',
      items: SchoolType.values,
      initialItem: _schoolType,
      itemBuilder: (schoolType) => schoolType.displayName,
    );

    if (selectedSchoolType != null) {
      setState(() {
        _schoolType = selectedSchoolType;
      });
    }
  }

  void _handleSubmit() {
    // 생년월 필수 입력 검증
    if (_birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('출생 연월을 선택해주세요.'), backgroundColor: context.appColors.warning),
      );
      return;
    }

    // 호봉 필수 입력 검증
    if (_currentGrade == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('현재 호봉을 선택해주세요.'), backgroundColor: context.appColors.warning),
      );
      return;
    }

    // 새로운 방식: Allowance는 기본값으로 설정
    // 실제 수당 계산은 SalaryCalculationService에서 처리

    // 담임 여부는 teachingAllowanceBonuses에서 판단
    final isHomeroom = _teachingAllowanceBonuses.contains(TeachingAllowanceBonus.homeroom);

    // 보직교사 여부는 teachingAllowanceBonuses에서 판단
    final hasPosition = _teachingAllowanceBonuses.contains(TeachingAllowanceBonus.headTeacher);

    final profile = TeacherProfile(
      birthYear: _birthDate!.year,
      birthMonth: _birthDate!.month,
      currentGrade: _currentGrade!,
      position: _position,
      schoolType: _schoolType,
      employmentStartDate: _employmentStartDate,
      retirementAge: _retirementAge,
      gradePromotionMonth: _gradePromotionMonth,
      allowances: Allowance(
        homeroom: isHomeroom ? 200000 : 0,
        headTeacher: hasPosition ? 150000 : 0,
        family: 0, // MonthlyBreakdownService._calculateFamilyAllowance 사용
        veteran: 0, // MonthlyBreakdownService._calculateVeteranAllowance 사용
      ),
      hasSpouse: _hasSpouse,
      numberOfChildren: _numberOfChildren,
      numberOfParents: _numberOfParents,
      youngChildrenBirthDates: _childrenBirthDates.whereType<DateTime>().toList(), // null 제외하고 전달
      isHomeroom: isHomeroom,
      hasPosition: hasPosition,
      teachingAllowanceBonuses: _teachingAllowanceBonuses,
      teacherAssociationFee: _teacherAssociationFee,
      otherDeductions: _otherDeductions,
      hasFirstGradeCertificate: _hasFirstGradeCertificate,
      additionalTeachingMonths: _additionalTeachingMonths,
      excludedTeachingMonths: _excludedTeachingMonths,
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

  Future<void> _showTeachingExperienceEditModal() async {
    // 초기값 설정
    int tempAdditionalYears = _additionalTeachingMonths ~/ 12;
    int tempAdditionalMonths = _additionalTeachingMonths % 12;
    int tempExcludedYears = _excludedTeachingMonths ~/ 12;
    int tempExcludedMonths = _excludedTeachingMonths % 12;

    await showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return DefaultTextStyle(
          style: GoogleFonts.notoSansKr(color: Theme.of(context).colorScheme.onSurface),
          child: Container(
            height: 600,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border(
                      bottom: BorderSide(color: Theme.of(context).colorScheme.outline, width: 0.5),
                    ),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '자동계산',
                          style: TextStyle(color: context.appColors.highlight, fontSize: 15),
                        ),
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          Navigator.pop(context);
                          setState(() {
                            _additionalTeachingMonths = 0;
                            _excludedTeachingMonths = 0;
                          });
                        },
                      ),
                      Text(
                        '교육경력 수정',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      CupertinoButton(
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '완료',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          Navigator.pop(context);
                          setState(() {
                            _additionalTeachingMonths =
                                tempAdditionalYears * 12 + tempAdditionalMonths;
                            _excludedTeachingMonths = tempExcludedYears * 12 + tempExcludedMonths;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                // Pickers
                Expanded(
                  child: CupertinoTheme(
                    data: CupertinoThemeData(
                      textTheme: CupertinoTextThemeData(
                        pickerTextStyle: GoogleFonts.notoSansKr(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        // 추가할 경력
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Theme.of(context).colorScheme.outline,
                                width: 0.5,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_circle_outline,
                                size: 18,
                                color: context.appColors.success,
                              ),
                              const Gap(6),
                              Text(
                                '추가할 경력',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: context.appColors.success,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              // 추가 년
                              Expanded(
                                child: CupertinoPicker(
                                  scrollController: FixedExtentScrollController(
                                    initialItem: tempAdditionalYears,
                                  ),
                                  itemExtent: 40,
                                  backgroundColor: Theme.of(context).colorScheme.surface,
                                  diameterRatio: 1.5,
                                  squeeze: 1.2,
                                  magnification: 1.1,
                                  useMagnifier: true,
                                  selectionOverlay: Container(
                                    decoration: BoxDecoration(
                                      border: Border.symmetric(
                                        horizontal: BorderSide(
                                          color: Theme.of(
                                            context,
                                          ).primaryColor.withValues(alpha: 0.3),
                                          width: 1.5,
                                        ),
                                      ),
                                      color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
                                    ),
                                  ),
                                  onSelectedItemChanged: (index) {
                                    HapticFeedback.selectionClick();
                                    tempAdditionalYears = index;
                                  },
                                  children: List.generate(
                                    11,
                                    (index) => Center(child: Text('$index년')),
                                  ),
                                ),
                              ),
                              // 추가 개월
                              Expanded(
                                child: CupertinoPicker(
                                  scrollController: FixedExtentScrollController(
                                    initialItem: tempAdditionalMonths,
                                  ),
                                  itemExtent: 40,
                                  backgroundColor: Theme.of(context).colorScheme.surface,
                                  diameterRatio: 1.5,
                                  squeeze: 1.2,
                                  magnification: 1.1,
                                  useMagnifier: true,
                                  selectionOverlay: Container(
                                    decoration: BoxDecoration(
                                      border: Border.symmetric(
                                        horizontal: BorderSide(
                                          color: Theme.of(
                                            context,
                                          ).primaryColor.withValues(alpha: 0.3),
                                          width: 1.5,
                                        ),
                                      ),
                                      color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
                                    ),
                                  ),
                                  onSelectedItemChanged: (index) {
                                    HapticFeedback.selectionClick();
                                    tempAdditionalMonths = index;
                                  },
                                  children: List.generate(
                                    12,
                                    (index) => Center(child: Text('$index개월')),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // 제외할 경력
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: Theme.of(context).colorScheme.outline,
                                width: 0.5,
                              ),
                              bottom: BorderSide(
                                color: Theme.of(context).colorScheme.outline,
                                width: 0.5,
                              ),
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.remove_circle_outline,
                                    size: 18,
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                  const Gap(6),
                                  Text(
                                    '제외할 경력',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).colorScheme.error,
                                    ),
                                  ),
                                ],
                              ),
                              const Gap(2),
                              Text(
                                '예: 군 복무 개월 수',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              // 제외 년
                              Expanded(
                                child: CupertinoPicker(
                                  scrollController: FixedExtentScrollController(
                                    initialItem: tempExcludedYears,
                                  ),
                                  itemExtent: 40,
                                  backgroundColor: Theme.of(context).colorScheme.surface,
                                  diameterRatio: 1.5,
                                  squeeze: 1.2,
                                  magnification: 1.1,
                                  useMagnifier: true,
                                  selectionOverlay: Container(
                                    decoration: BoxDecoration(
                                      border: Border.symmetric(
                                        horizontal: BorderSide(
                                          color: Theme.of(
                                            context,
                                          ).primaryColor.withValues(alpha: 0.3),
                                          width: 1.5,
                                        ),
                                      ),
                                      color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
                                    ),
                                  ),
                                  onSelectedItemChanged: (index) {
                                    HapticFeedback.selectionClick();
                                    tempExcludedYears = index;
                                  },
                                  children: List.generate(
                                    11,
                                    (index) => Center(child: Text('$index년')),
                                  ),
                                ),
                              ),
                              // 제외 개월
                              Expanded(
                                child: CupertinoPicker(
                                  scrollController: FixedExtentScrollController(
                                    initialItem: tempExcludedMonths,
                                  ),
                                  itemExtent: 40,
                                  backgroundColor: Theme.of(context).colorScheme.surface,
                                  diameterRatio: 1.5,
                                  squeeze: 1.2,
                                  magnification: 1.1,
                                  useMagnifier: true,
                                  selectionOverlay: Container(
                                    decoration: BoxDecoration(
                                      border: Border.symmetric(
                                        horizontal: BorderSide(
                                          color: Theme.of(
                                            context,
                                          ).primaryColor.withValues(alpha: 0.3),
                                          width: 1.5,
                                        ),
                                      ),
                                      color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
                                    ),
                                  ),
                                  onSelectedItemChanged: (index) {
                                    HapticFeedback.selectionClick();
                                    tempExcludedMonths = index;
                                  },
                                  children: List.generate(
                                    12,
                                    (index) => Center(child: Text('$index개월')),
                                  ),
                                ),
                              ),
                            ],
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
  }

  /// 자녀 서수 헬퍼 함수
  String _getChildOrdinal(int index) {
    const ordinals = ['첫째', '둘째', '셋째', '넷째', '다섯째'];
    if (index < ordinals.length) {
      return ordinals[index];
    }
    return '${index + 1}번째';
  }

  /// 자녀 생년월일 입력 다이얼로그
  Future<void> _showChildrenBirthDatesDialog() async {
    // 임시 리스트 (다이얼로그 내에서만 사용)
    final List<DateTime?> tempBirthDates = List.from(_childrenBirthDates);

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.child_care, color: Theme.of(context).primaryColor),
                  const Gap(8),
                  const Expanded(
                    child: Text(
                      '자녀 생년월일 입력',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '만 6세 이하 자녀만 입력하시면 비과세 혜택을 받을 수 있습니다.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Gap(16),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _numberOfChildren,
                        itemBuilder: (context, index) {
                          final ordinal = _getChildOrdinal(index);
                          final birthDate = tempBirthDates[index];

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: context.appColors.infoLight,
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: context.appColors.info,
                                  ),
                                ),
                              ),
                              title: Text(
                                '$ordinal 생년월일',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: birthDate != null
                                  ? Text(
                                      '${birthDate.year}년 ${birthDate.month}월 ${birthDate.day}일',
                                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                                    )
                                  : Text(
                                      '선택 안 함 (만 6세 초과)',
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (birthDate != null)
                                    IconButton(
                                      icon: const Icon(Icons.clear, size: 20),
                                      onPressed: () {
                                        setDialogState(() {
                                          tempBirthDates[index] = null;
                                        });
                                      },
                                      tooltip: '삭제',
                                    ),
                                  Icon(Icons.calendar_today, color: Theme.of(context).primaryColor),
                                ],
                              ),
                              onTap: () async {
                                DateTime tempDate = birthDate ?? DateTime.now();

                                await showCupertinoModalPopup(
                                  context: context,
                                  builder: (BuildContext pickerContext) {
                                    return DefaultTextStyle(
                                      style: GoogleFonts.notoSansKr(color: Theme.of(context).colorScheme.onSurface),
                                      child: Container(
                                        height: 300,
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.surface,
                                          borderRadius: const BorderRadius.vertical(
                                            top: Radius.circular(16),
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            // Header
                                            Container(
                                              height: 50,
                                              decoration: BoxDecoration(
                                                color: Theme.of(context).colorScheme.surface,
                                                border: Border(
                                                  bottom: BorderSide(
                                                    color: Theme.of(context).colorScheme.outline,
                                                    width: 0.5,
                                                  ),
                                                ),
                                                borderRadius: const BorderRadius.vertical(
                                                  top: Radius.circular(16),
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  CupertinoButton(
                                                    minimumSize: Size.zero,
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                    ),
                                                    child: Text(
                                                      '취소',
                                                      style: TextStyle(
                                                        color: Theme.of(
                                                          context,
                                                        ).colorScheme.onSurfaceVariant,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                    onPressed: () => Navigator.pop(pickerContext),
                                                  ),
                                                  Text(
                                                    '$ordinal 생년월일',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 16,
                                                      color: Theme.of(context).colorScheme.onSurface,
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
                                                        color: Theme.of(context).primaryColor,
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                    onPressed: () {
                                                      HapticFeedback.mediumImpact();
                                                      setDialogState(() {
                                                        tempBirthDates[index] = tempDate;
                                                      });
                                                      Navigator.pop(pickerContext);
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
                                                    dateTimePickerTextStyle: GoogleFonts.notoSansKr(
                                                      color: Theme.of(context).colorScheme.onSurface,
                                                      fontSize: 20,
                                                    ),
                                                  ),
                                                ),
                                                child: CupertinoDatePicker(
                                                  mode: CupertinoDatePickerMode.date,
                                                  backgroundColor: Theme.of(context).colorScheme.surface,
                                                  initialDateTime: tempDate,
                                                  minimumYear: 2015,
                                                  maximumDate: DateTime.now(),
                                                  onDateTimeChanged: (DateTime picked) {
                                                    HapticFeedback.selectionClick();
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
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _childrenBirthDates = tempBirthDates;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('완료'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
