import 'package:equatable/equatable.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/allowance.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/position.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/school_type.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/teaching_allowance_bonus.dart';

/// 교사 프로필 정보
class TeacherProfile extends Equatable {
  /// 출생 년도
  final int birthYear;

  /// 출생 월
  final int birthMonth;

  /// 현재 호봉
  final int currentGrade;

  /// 현재 직급
  final Position position;

  /// 학교급 (교원연구비 산정용 - 교장/교감만 사용)
  final SchoolType schoolType;

  /// 재직 시작일
  final DateTime employmentStartDate;

  /// 예상 퇴직일 (nullable: 미정일 수 있음)
  final DateTime? expectedRetirementDate;

  /// 퇴직 예정 연령 (62세 기본)
  final int retirementAge;

  /// 호봉 승급월 (1-12월, 기본 3월)
  final int gradePromotionMonth;

  /// 수당 정보
  final Allowance allowances;

  /// 기준소득월액 (계산용)
  final int? baseIncomeMonthly;

  /// 배우자 유무
  final bool hasSpouse;

  /// 자녀 수
  final int numberOfChildren;

  /// 60세 이상 직계존속 수
  final int numberOfParents;

  /// 6세 이하 자녀 생년월일 목록
  final List<DateTime> youngChildrenBirthDates;

  /// 담임 여부
  final bool isHomeroom;

  /// 보직 여부
  final bool hasPosition;

  /// 교직수당 가산금 (담임 제외)
  final Set<TeachingAllowanceBonus> teachingAllowanceBonuses;

  /// 교직원공제회비 (월)
  final int teacherAssociationFee;

  /// 기타 공제 (월)
  final int otherDeductions;

  /// 1급 정교사 자격증 소지 여부 (기본 true)
  final bool hasFirstGradeCertificate;

  /// 추가 교육경력 (개월, 기본 0)
  final int additionalTeachingMonths;

  /// 제외할 교육경력 (개월, 기본 0)
  final int excludedTeachingMonths;

  const TeacherProfile({
    required this.birthYear,
    required this.birthMonth,
    required this.currentGrade,
    required this.position,
    required this.employmentStartDate,
    this.expectedRetirementDate,
    this.retirementAge = 62,
    this.gradePromotionMonth = 3,
    this.schoolType = SchoolType.elementary,
    this.allowances = const Allowance(),
    this.baseIncomeMonthly,
    this.hasSpouse = false,
    this.numberOfChildren = 0,
    this.numberOfParents = 0,
    this.youngChildrenBirthDates = const [],
    this.isHomeroom = false,
    this.hasPosition = false,
    this.teachingAllowanceBonuses = const {},
    this.teacherAssociationFee = 0,
    this.otherDeductions = 0,
    this.hasFirstGradeCertificate = true,
    this.additionalTeachingMonths = 0,
    this.excludedTeachingMonths = 0,
  });

  /// 정년퇴직일 자동 계산
  DateTime calculateRetirementDate() {
    return DateTime(birthYear + retirementAge, birthMonth, 1);
  }

  /// 재직연수 계산 (개월 단위)
  /// 호봉 + 승급월 기반으로 정확하게 계산
  int getServiceMonths() {
    final now = DateTime.now();

    // 1. 기본 연수 (호봉 - 9호봉 시작 - 1급 정교사 가산)
    final baseYears = currentGrade - 9 - (hasFirstGradeCertificate ? 1 : 0);

    // 2. 올해 승급일
    final thisYearPromotion = DateTime(now.year, gradePromotionMonth, 1);

    // 3. 승급월 기준 개월 수 계산
    if (now.isBefore(thisYearPromotion)) {
      // 아직 승급 안 됨 = 작년에 현재 호봉이 됨
      final lastPromotion = DateTime(now.year - 1, gradePromotionMonth, 1);
      final monthsSincePromotion = _calculateMonthDifference(lastPromotion, now);
      return ((baseYears - 1) * 12) + monthsSincePromotion;
    } else {
      // 승급 완료 = 올해 현재 호봉이 됨
      final monthsSincePromotion = _calculateMonthDifference(thisYearPromotion, now);
      return (baseYears * 12) + monthsSincePromotion;
    }
  }

  /// 재직연수 (년)
  int getServiceYears() => getServiceMonths() ~/ 12;

  /// 재직연수 나머지 개월
  int getServiceRemainingMonths() => getServiceMonths() % 12;

  /// 교육경력 계산 (개월 단위)
  /// 재직연수 기본값 + 추가 - 제외
  int getTeachingExperienceMonths() {
    final baseMonths = getServiceMonths();
    return (baseMonths + additionalTeachingMonths - excludedTeachingMonths).clamp(0, 1200);
  }

  /// 교육경력 (년)
  int getTeachingExperienceYears() => getTeachingExperienceMonths() ~/ 12;

  /// 교육경력 나머지 개월
  int getTeachingExperienceRemainingMonths() => getTeachingExperienceMonths() % 12;

  /// 교육경력 수정 여부
  bool isTeachingExperienceModified() {
    return additionalTeachingMonths > 0 || excludedTeachingMonths > 0;
  }

  /// 두 날짜 간 개월 수 차이 계산 (일자까지 고려)
  int _calculateMonthDifference(DateTime from, DateTime to) {
    int months = (to.year - from.year) * 12 + (to.month - from.month);
    if (to.day < from.day) {
      months--; // 일자가 안 지났으면 -1개월
    }
    return months.clamp(0, 1200);
  }

  @override
  List<Object?> get props => [
        birthYear,
        birthMonth,
        currentGrade,
        position,
        schoolType,
        employmentStartDate,
        expectedRetirementDate,
        retirementAge,
        gradePromotionMonth,
        allowances,
        baseIncomeMonthly,
        hasSpouse,
        numberOfChildren,
        numberOfParents,
        youngChildrenBirthDates,
        isHomeroom,
        hasPosition,
        teachingAllowanceBonuses,
        teacherAssociationFee,
        otherDeductions,
        hasFirstGradeCertificate,
        additionalTeachingMonths,
        excludedTeachingMonths,
      ];

  TeacherProfile copyWith({
    int? birthYear,
    int? birthMonth,
    int? currentGrade,
    Position? position,
    SchoolType? schoolType,
    DateTime? employmentStartDate,
    DateTime? expectedRetirementDate,
    int? retirementAge,
    int? gradePromotionMonth,
    Allowance? allowances,
    int? baseIncomeMonthly,
    bool? hasSpouse,
    int? numberOfChildren,
    int? numberOfParents,
    List<DateTime>? youngChildrenBirthDates,
    bool? isHomeroom,
    bool? hasPosition,
    Set<TeachingAllowanceBonus>? teachingAllowanceBonuses,
    int? teacherAssociationFee,
    int? otherDeductions,
    bool? hasFirstGradeCertificate,
    int? additionalTeachingMonths,
    int? excludedTeachingMonths,
  }) {
    return TeacherProfile(
      birthYear: birthYear ?? this.birthYear,
      birthMonth: birthMonth ?? this.birthMonth,
      currentGrade: currentGrade ?? this.currentGrade,
      position: position ?? this.position,
      schoolType: schoolType ?? this.schoolType,
      employmentStartDate: employmentStartDate ?? this.employmentStartDate,
      expectedRetirementDate: expectedRetirementDate ?? this.expectedRetirementDate,
      retirementAge: retirementAge ?? this.retirementAge,
      gradePromotionMonth: gradePromotionMonth ?? this.gradePromotionMonth,
      allowances: allowances ?? this.allowances,
      baseIncomeMonthly: baseIncomeMonthly ?? this.baseIncomeMonthly,
      hasSpouse: hasSpouse ?? this.hasSpouse,
      numberOfChildren: numberOfChildren ?? this.numberOfChildren,
      numberOfParents: numberOfParents ?? this.numberOfParents,
      youngChildrenBirthDates: youngChildrenBirthDates ?? this.youngChildrenBirthDates,
      isHomeroom: isHomeroom ?? this.isHomeroom,
      hasPosition: hasPosition ?? this.hasPosition,
      teachingAllowanceBonuses: teachingAllowanceBonuses ?? this.teachingAllowanceBonuses,
      teacherAssociationFee: teacherAssociationFee ?? this.teacherAssociationFee,
      otherDeductions: otherDeductions ?? this.otherDeductions,
      hasFirstGradeCertificate: hasFirstGradeCertificate ?? this.hasFirstGradeCertificate,
      additionalTeachingMonths: additionalTeachingMonths ?? this.additionalTeachingMonths,
      excludedTeachingMonths: excludedTeachingMonths ?? this.excludedTeachingMonths,
    );
  }

  /// JSON 직렬화
  Map<String, dynamic> toJson() {
    return {
      'birthYear': birthYear,
      'birthMonth': birthMonth,
      'currentGrade': currentGrade,
      'position': position.name,
      'schoolType': schoolType.name,
      'employmentStartDate': employmentStartDate.toIso8601String(),
      'expectedRetirementDate': expectedRetirementDate?.toIso8601String(),
      'retirementAge': retirementAge,
      'gradePromotionMonth': gradePromotionMonth,
      'allowances': {
        'homeroom': allowances.homeroom,
        'headTeacher': allowances.headTeacher,
        'family': allowances.family,
        'veteran': allowances.veteran,
      },
      'baseIncomeMonthly': baseIncomeMonthly,
      'hasSpouse': hasSpouse,
      'numberOfChildren': numberOfChildren,
      'numberOfParents': numberOfParents,
      'youngChildrenBirthDates': youngChildrenBirthDates.map((d) => d.toIso8601String()).toList(),
      'isHomeroom': isHomeroom,
      'hasPosition': hasPosition,
      'teachingAllowanceBonuses':
          teachingAllowanceBonuses.map((e) => e.name).toList(),
      'teacherAssociationFee': teacherAssociationFee,
      'otherDeductions': otherDeductions,
      'hasFirstGradeCertificate': hasFirstGradeCertificate,
      'additionalTeachingMonths': additionalTeachingMonths,
      'excludedTeachingMonths': excludedTeachingMonths,
    };
  }

  /// JSON 역직렬화
  factory TeacherProfile.fromJson(Map<String, dynamic> json) {
    final bonusesList = json['teachingAllowanceBonuses'] as List<dynamic>?;
    final bonuses = bonusesList
            ?.map((name) => TeachingAllowanceBonus.values.firstWhere(
                  (e) => e.name == name,
                  orElse: () => TeachingAllowanceBonus.specialEducation,
                ))
            .toSet() ??
        <TeachingAllowanceBonus>{};
    final youngChildrenDatesList = json['youngChildrenBirthDates'] as List<dynamic>?;

    return TeacherProfile(
      birthYear: json['birthYear'] as int,
      birthMonth: json['birthMonth'] as int,
      currentGrade: json['currentGrade'] as int,
      position: Position.values.firstWhere(
        (e) => e.name == json['position'],
        orElse: () => Position.teacher,
      ),
      schoolType: SchoolType.values.firstWhere(
        (e) => e.name == json['schoolType'],
        orElse: () => SchoolType.elementary,
      ),
      employmentStartDate: DateTime.parse(json['employmentStartDate'] as String),
      expectedRetirementDate: json['expectedRetirementDate'] != null
          ? DateTime.parse(json['expectedRetirementDate'] as String)
          : null,
      retirementAge: json['retirementAge'] as int? ?? 62,
      gradePromotionMonth: json['gradePromotionMonth'] as int? ?? 3,
      allowances: Allowance(
        homeroom: json['allowances']?['homeroom'] as int? ?? 0,
        headTeacher: json['allowances']?['headTeacher'] as int? ?? 0,
        family: json['allowances']?['family'] as int? ?? 0,
        veteran: json['allowances']?['veteran'] as int? ?? 0,
      ),
      baseIncomeMonthly: json['baseIncomeMonthly'] as int?,
      hasSpouse: json['hasSpouse'] as bool? ?? false,
      numberOfChildren: json['numberOfChildren'] as int? ?? 0,
      numberOfParents: json['numberOfParents'] as int? ?? 0,
      youngChildrenBirthDates: youngChildrenDatesList?.map((d) => DateTime.parse(d as String)).toList() ?? [],
      isHomeroom: json['isHomeroom'] as bool? ?? false,
      hasPosition: json['hasPosition'] as bool? ?? false,
      teachingAllowanceBonuses: bonuses,
      teacherAssociationFee: json['teacherAssociationFee'] as int? ?? 0,
      otherDeductions: json['otherDeductions'] as int? ?? 0,
      hasFirstGradeCertificate: json['hasFirstGradeCertificate'] as bool? ?? true,
      additionalTeachingMonths: json['additionalTeachingMonths'] as int? ?? 0,
      excludedTeachingMonths: json['excludedTeachingMonths'] as int? ?? 0,
    );
  }
}
