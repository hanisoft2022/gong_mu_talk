import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
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
  late DateTime? _birthDate;
  late int? _currentGrade;
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
    _employmentStartDate = widget.initialProfile?.employmentStartDate ??
        DateTime(2025, 3, 1);
    
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
                    _buildSectionTitle('📍 출생 연월'),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        DateTime tempDate = _birthDate ?? DateTime(1990, 1, 1);
                        
                        await showCupertinoModalPopup(
                          context: context,
                          builder: (BuildContext context) {
                            return DefaultTextStyle(
                              style: GoogleFonts.notoSansKr(color: Colors.black87),
                              child: Container(
                                height: 300,
                                decoration: BoxDecoration(
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
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(16),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        CupertinoButton(
                                          minSize: 0,
                                          padding: EdgeInsets.symmetric(horizontal: 12),
                                          child: Text(
                                            '취소',
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
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
                                            color: Colors.black87,
                                          ),
                                        ),
                                        CupertinoButton(
                                          minSize: 0,
                                          padding: EdgeInsets.symmetric(horizontal: 12),
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
                                              // 일자는 항상 1일로 설정
                                              _birthDate = DateTime(tempDate.year, tempDate.month, 1);
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
                                            color: Colors.black87,
                                            fontSize: 20,
                                          ),
                                        ),
                                      ),
                                      child: CupertinoDatePicker(
                                        mode: CupertinoDatePickerMode.date,
                                        backgroundColor: Colors.white,
                                        initialDateTime: _birthDate ?? DateTime(1990, 1, 1),
                                        minimumYear: 1960,
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

                    const SizedBox(height: 24),

                    // 현재 호봉
                    _buildSectionTitle('📍 현재 호봉'),
                    const SizedBox(height: 8),
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

                    const SizedBox(height: 24),

                    // 임용일
                    _buildSectionTitle('📍 임용일'),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        DateTime tempDate = _employmentStartDate;
                        
                        await showCupertinoModalPopup(
                          context: context,
                          builder: (BuildContext context) {
                            return DefaultTextStyle(
                              style: GoogleFonts.notoSansKr(color: Colors.black87),
                              child: Container(
                                height: 300,
                                decoration: BoxDecoration(
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
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(16),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        CupertinoButton(
                                          minSize: 0,
                                          padding: EdgeInsets.symmetric(horizontal: 12),
                                          child: Text(
                                            '취소',
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
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
                                            color: Colors.black87,
                                          ),
                                        ),
                                        CupertinoButton(
                                          minSize: 0,
                                          padding: EdgeInsets.symmetric(horizontal: 12),
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

                    const SizedBox(height: 24),

                    // 퇴직 예정 연령
                    Row(
                      children: [
                        _buildSectionTitle('📍 퇴직 예정 연령'),
                        const SizedBox(width: 4),
                        Tooltip(
                          message: '만 나이 기준입니다',
                          child: Icon(
                            Icons.info_outline,
                            size: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
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

                    const SizedBox(height: 32),

                    // 선택 입력 (접을 수 있는 섹션)
                    ExpansionTile(
                      title: const Text('⚙️ 더 정확하게 계산하기 (선택)'),
                      children: [
                        // 직급 선택
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '직급',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
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
                            ],
                          ),
                        ),
                        
                        const Divider(),
                        
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
                        ListTile(
                          title: Row(
                            children: [
                              const Expanded(
                                child: Text('정년 연장 적용 (62세 → 65세)'),
                              ),
                              IconButton(
                                icon: const Icon(Icons.info_outline),
                                iconSize: 20,
                                color: Colors.blue,
                                onPressed: () => _showRetirementExtensionDialog(context),
                                tooltip: '정년 연장 제도 상세 안내',
                              ),
                            ],
                          ),
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
                          trailing: Switch(
                            value: _retirementExtension,
                            onChanged: (val) {
                              setState(() {
                                _retirementExtension = val;
                                _retirementAge = val ? 65 : 62;
                              });
                            },
                          ),
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

  Future<void> _showGradePicker() async {
    int tempGrade = _currentGrade ?? 15; // 기본값 15호봉
    
    await showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return DefaultTextStyle(
          style: GoogleFonts.notoSansKr(color: Colors.black87),
          child: Container(
            height: 300,
            decoration: BoxDecoration(
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
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        minSize: 0,
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '취소',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text(
                        '호봉 선택',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      CupertinoButton(
                        minSize: 0,
                        padding: EdgeInsets.symmetric(horizontal: 12),
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
                            _currentGrade = tempGrade;
                          });
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
                // Picker
                Expanded(
                  child: CupertinoTheme(
                    data: CupertinoThemeData(
                      textTheme: CupertinoTextThemeData(
                        pickerTextStyle: GoogleFonts.notoSansKr(
                          color: Colors.black87,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    child: CupertinoPicker(
                      scrollController: FixedExtentScrollController(
                        initialItem: tempGrade - 6, // 6호봉부터 시작
                      ),
                      itemExtent: 40,
                      backgroundColor: Colors.white,
                      diameterRatio: 1.5, // 곡률 조정 (더 평평하게)
                      squeeze: 1.2, // 항목 간격 조정
                      magnification: 1.1, // 선택된 항목 확대
                      useMagnifier: true, // 확대 효과 사용
                      selectionOverlay: Container(
                        decoration: BoxDecoration(
                          border: Border.symmetric(
                            horizontal: BorderSide(
                              color: Theme.of(context).primaryColor.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          color: Theme.of(context).primaryColor.withOpacity(0.05),
                        ),
                      ),
                      onSelectedItemChanged: (int index) {
                        HapticFeedback.selectionClick(); // 햅틱 피드백
                        tempGrade = index + 6; // 6호봉부터 시작
                      },
                      children: List.generate(35, (index) {
                        final grade = index + 6;
                        return Center(
                          child: Text('$grade호봉'),
                        );
                      }),
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

  Future<void> _showRetirementAgePicker() async {
    int tempAge = _retirementAge;
    
    await showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return DefaultTextStyle(
          style: GoogleFonts.notoSansKr(color: Colors.black87),
          child: Container(
            height: 300,
            decoration: BoxDecoration(
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
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        minSize: 0,
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '취소',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text(
                        '퇴직 예정 연령',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      CupertinoButton(
                        minSize: 0,
                        padding: EdgeInsets.symmetric(horizontal: 12),
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
                            _retirementAge = tempAge;
                          });
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
                // Picker
                Expanded(
                  child: CupertinoTheme(
                    data: CupertinoThemeData(
                      textTheme: CupertinoTextThemeData(
                        pickerTextStyle: GoogleFonts.notoSansKr(
                          color: Colors.black87,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    child: CupertinoPicker(
                      scrollController: FixedExtentScrollController(
                        initialItem: tempAge - 60, // 60세부터 시작
                      ),
                      itemExtent: 40,
                      backgroundColor: Colors.white,
                      diameterRatio: 1.5, // 곡률 조정 (더 평평하게)
                      squeeze: 1.2, // 항목 간격 조정
                      magnification: 1.1, // 선택된 항목 확대
                      useMagnifier: true, // 확대 효과 사용
                      selectionOverlay: Container(
                        decoration: BoxDecoration(
                          border: Border.symmetric(
                            horizontal: BorderSide(
                              color: Theme.of(context).primaryColor.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          color: Theme.of(context).primaryColor.withOpacity(0.05),
                        ),
                      ),
                      onSelectedItemChanged: (int index) {
                        HapticFeedback.selectionClick(); // 햅틱 피드백
                        tempAge = index + 60; // 60세부터 시작
                      },
                      children: List.generate(11, (index) {
                        final age = index + 60;
                        return Center(
                          child: Text('$age세'),
                        );
                      }),
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

  void _showRetirementExtensionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          '정년 연장 제도 안내',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogSection(
                '📌 현재 상황 (2025년)',
                [
                  '• 교원 법정 정년: 만 62세',
                  '• 연금 수령 시작 연령:',
                  '  └ 2024~2026년 퇴직자: 62세',
                  '  └ 2027~2029년 퇴직자: 63세',
                  '  └ 2030~2032년 퇴직자: 64세',
                  '  └ 2033년 이후 퇴직자: 65세',
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.orange[700], size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          '핵심 문제: 소득 공백기',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '2033년 이후 62세에 정년퇴직하면\n65세까지 3년간 무소득 기간 발생!',
                      style: TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'OECD 국가 중 유일하게 정년과\n연금 수령 연령이 불일치합니다.',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildDialogSection(
                '🏛️ 정년 연장 논의 현황',
                [
                  '▪️ 현재 상태: 아직 확정되지 않음',
                  '  - 13개 법안이 국회에 계류 중',
                  '  - 입법 여부 불투명',
                  '',
                  '▪️ 정부 추진 일정 (계획안):',
                  '  - 2025년: 법안 통과 목표',
                  '  - 2027년: 만 63세 시행',
                  '  - 2028~2032년: 만 64세',
                  '  - 2033년: 만 65세 완전 시행',
                  '',
                  '▪️ 교원 특수성:',
                  '  과거 65세 정년이었으나',
                  '  IMF 이후 62세로 단축',
                ],
              ),
              const SizedBox(height: 16),
              _buildDialogSection(
                '💭 주요 찬반 의견',
                [
                  '✅ 찬성',
                  '• 연금 공백기 해소',
                  '• 노동인력 부족 대응',
                  '• 퇴직 후 재취업 어려움 해결',
                  '',
                  '❌ 반대',
                  '• 학령인구 감소로 교사 과잉',
                  '• 청년 교사 일자리 감소',
                  '• 인사 적체 심화',
                  '• 고령 교사의 교육 효과성 논란',
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: Colors.blue[700], size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          '이 옵션을 켜면?',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '계산기는 정년 65세를 가정하여\n퇴직금 및 연금을 계산합니다.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '주의사항',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '아직 확정되지 않은 사항이므로\n참고용으로만 활용하시기 바랍니다.\n\n실제 정년은 현행 62세입니다.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                item,
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
            )),
      ],
    );
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
    final profile = TeacherProfile(
      birthYear: _birthDate!.year,
      birthMonth: _birthDate!.month,
      currentGrade: _currentGrade!,
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
