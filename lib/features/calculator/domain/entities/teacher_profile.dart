import 'package:equatable/equatable.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/allowance.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/position.dart';

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
    this.allowances = const Allowance(),
    this.baseIncomeMonthly,
    this.hasSpouse = false,
    this.numberOfChildren = 0,
    this.isHomeroom = false,
    this.hasPosition = false,
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

  /// 수당 정보
  final Allowance allowances;

  /// 기준소득월액 (계산용)
  final int? baseIncomeMonthly;

  /// 배우자 유무
  final bool hasSpouse;

  /// 자녀 수
  final int numberOfChildren;

  /// 담임 여부
  final bool isHomeroom;

  /// 보직 여부
  final bool hasPosition;

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
        allowances,
        baseIncomeMonthly,
        hasSpouse,
        numberOfChildren,
        isHomeroom,
        hasPosition,
      ];

  TeacherProfile copyWith({
    int? birthYear,
    int? birthMonth,
    int? currentGrade,
    Position? position,
    DateTime? employmentStartDate,
    DateTime? expectedRetirementDate,
    int? retirementAge,
    Allowance? allowances,
    int? baseIncomeMonthly,
    bool? hasSpouse,
    int? numberOfChildren,
    bool? isHomeroom,
    bool? hasPosition,
  }) {
    return TeacherProfile(
      birthYear: birthYear ?? this.birthYear,
      birthMonth: birthMonth ?? this.birthMonth,
      currentGrade: currentGrade ?? this.currentGrade,
      position: position ?? this.position,
      employmentStartDate: employmentStartDate ?? this.employmentStartDate,
      expectedRetirementDate: expectedRetirementDate ?? this.expectedRetirementDate,
      retirementAge: retirementAge ?? this.retirementAge,
      allowances: allowances ?? this.allowances,
      baseIncomeMonthly: baseIncomeMonthly ?? this.baseIncomeMonthly,
      hasSpouse: hasSpouse ?? this.hasSpouse,
      numberOfChildren: numberOfChildren ?? this.numberOfChildren,
      isHomeroom: isHomeroom ?? this.isHomeroom,
      hasPosition: hasPosition ?? this.hasPosition,
    );
  }
}
