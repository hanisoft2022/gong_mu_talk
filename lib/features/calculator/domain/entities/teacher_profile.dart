import 'package:equatable/equatable.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/allowance.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/position.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/teaching_allowance_bonus.dart';

/// 교사 프로필 정보
class TeacherProfile extends Equatable {
  const TeacherProfile({
    required this.birthYear,
    required this.birthMonth,
    required this.currentGrade,
    required this.position,
    required this.employmentStartDate,
    this.expectedRetirementDate,
    this.retirementAge = 62,
    this.gradePromotionMonth = 3,
    this.allowances = const Allowance(),
    this.baseIncomeMonthly,
    this.hasSpouse = false,
    this.numberOfChildren = 0,
    this.numberOfParents = 0,
    this.isHomeroom = false,
    this.hasPosition = false,
    this.teachingAllowanceBonuses = const {},
  });

  /// 출생 년도
  final int birthYear;

  /// 출생 월
  final int birthMonth;

  /// 현재 호봉
  final int currentGrade;

  /// 현재 직급
  final Position position;

  /// 재직 시작일
  final DateTime employmentStartDate;

  /// 예상 퇴직일 (nullable: 미정일 수 있음)
  final DateTime? expectedRetirementDate;

  /// 퇴직 예정 연령 (65세 기본)
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

  /// 담임 여부
  final bool isHomeroom;

  /// 보직 여부
  final bool hasPosition;

  /// 교직수당 가산금 (담임 제외)
  final Set<TeachingAllowanceBonus> teachingAllowanceBonuses;

  /// 정년퇴직일 자동 계산
  DateTime calculateRetirementDate() {
    return DateTime(birthYear + retirementAge, birthMonth, 1);
  }

  @override
  List<Object?> get props => [
    birthYear,
    birthMonth,
    currentGrade,
    position,
    employmentStartDate,
    expectedRetirementDate,
    retirementAge,
    gradePromotionMonth,
    allowances,
    baseIncomeMonthly,
    hasSpouse,
    numberOfChildren,
    numberOfParents,
    isHomeroom,
    hasPosition,
    teachingAllowanceBonuses,
  ];

  TeacherProfile copyWith({
    int? birthYear,
    int? birthMonth,
    int? currentGrade,
    Position? position,
    DateTime? employmentStartDate,
    DateTime? expectedRetirementDate,
    int? retirementAge,
    int? gradePromotionMonth,
    Allowance? allowances,
    int? baseIncomeMonthly,
    bool? hasSpouse,
    int? numberOfChildren,
    int? numberOfParents,
    bool? isHomeroom,
    bool? hasPosition,
    Set<TeachingAllowanceBonus>? teachingAllowanceBonuses,
  }) {
    return TeacherProfile(
      birthYear: birthYear ?? this.birthYear,
      birthMonth: birthMonth ?? this.birthMonth,
      currentGrade: currentGrade ?? this.currentGrade,
      position: position ?? this.position,
      employmentStartDate: employmentStartDate ?? this.employmentStartDate,
      expectedRetirementDate:
          expectedRetirementDate ?? this.expectedRetirementDate,
      retirementAge: retirementAge ?? this.retirementAge,
      gradePromotionMonth: gradePromotionMonth ?? this.gradePromotionMonth,
      allowances: allowances ?? this.allowances,
      baseIncomeMonthly: baseIncomeMonthly ?? this.baseIncomeMonthly,
      hasSpouse: hasSpouse ?? this.hasSpouse,
      numberOfChildren: numberOfChildren ?? this.numberOfChildren,
      numberOfParents: numberOfParents ?? this.numberOfParents,
      isHomeroom: isHomeroom ?? this.isHomeroom,
      hasPosition: hasPosition ?? this.hasPosition,
      teachingAllowanceBonuses:
          teachingAllowanceBonuses ?? this.teachingAllowanceBonuses,
    );
  }

  /// JSON 직렬화
  Map<String, dynamic> toJson() {
    return {
      'birthYear': birthYear,
      'birthMonth': birthMonth,
      'currentGrade': currentGrade,
      'position': position.name,
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
      'isHomeroom': isHomeroom,
      'hasPosition': hasPosition,
      'teachingAllowanceBonuses':
          teachingAllowanceBonuses.map((e) => e.name).toList(),
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

    return TeacherProfile(
      birthYear: json['birthYear'] as int,
      birthMonth: json['birthMonth'] as int,
      currentGrade: json['currentGrade'] as int,
      position: Position.values.firstWhere(
        (e) => e.name == json['position'],
        orElse: () => Position.teacher,
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
      isHomeroom: json['isHomeroom'] as bool? ?? false,
      hasPosition: json['hasPosition'] as bool? ?? false,
      teachingAllowanceBonuses: bonuses,
    );
  }
}
