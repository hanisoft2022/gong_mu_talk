import 'package:flutter_test/flutter_test.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/position.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/school_type.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/teacher_profile.dart';
import 'package:gong_mu_talk/features/calculator/domain/services/salary_calculation_service.dart';
import 'package:gong_mu_talk/features/calculator/domain/services/tax_calculation_service.dart';

void main() {
  late SalaryCalculationService service;

  setUp(() {
    final taxService = TaxCalculationService();
    service = SalaryCalculationService(taxService);
  });

  group('교원연구비 계산 로직 검증', () {
    test('교장 - 유·초등: 75,000원', () {
      final allowance = service.calculateResearchAllowance(
        position: Position.principal,
        schoolType: SchoolType.elementary,
        teachingExperienceYears: 10,
      );
      expect(allowance, 75000);
    });

    test('교장 - 중등: 60,000원', () {
      final allowance = service.calculateResearchAllowance(
        position: Position.principal,
        schoolType: SchoolType.secondary,
        teachingExperienceYears: 10,
      );
      expect(allowance, 60000);
    });

    test('교감 - 유·초등: 65,000원', () {
      final allowance = service.calculateResearchAllowance(
        position: Position.vicePrincipal,
        schoolType: SchoolType.elementary,
        teachingExperienceYears: 10,
      );
      expect(allowance, 65000);
    });

    test('교감 - 중등: 60,000원', () {
      final allowance = service.calculateResearchAllowance(
        position: Position.vicePrincipal,
        schoolType: SchoolType.secondary,
        teachingExperienceYears: 10,
      );
      expect(allowance, 60000);
    });

    test('수석교사: 60,000원 (학교급 무관)', () {
      final allowanceElementary = service.calculateResearchAllowance(
        position: Position.seniorTeacher,
        schoolType: SchoolType.elementary,
        teachingExperienceYears: 10,
      );
      expect(allowanceElementary, 60000);

      final allowanceSecondary = service.calculateResearchAllowance(
        position: Position.seniorTeacher,
        schoolType: SchoolType.secondary,
        teachingExperienceYears: 10,
      );
      expect(allowanceSecondary, 60000);
    });

    test('보직교사: 60,000원 (학교급 무관)', () {
      final allowanceElementary = service.calculateResearchAllowance(
        position: Position.headTeacher,
        schoolType: SchoolType.elementary,
        teachingExperienceYears: 10,
      );
      expect(allowanceElementary, 60000);

      final allowanceSecondary = service.calculateResearchAllowance(
        position: Position.headTeacher,
        schoolType: SchoolType.secondary,
        teachingExperienceYears: 10,
      );
      expect(allowanceSecondary, 60000);
    });

    test('일반교사 - 교육경력 5년 미만: 75,000원', () {
      final allowance = service.calculateResearchAllowance(
        position: Position.teacher,
        schoolType: SchoolType.elementary,
        teachingExperienceYears: 3,
      );
      expect(allowance, 75000);
    });

    test('일반교사 - 교육경력 5년 이상: 60,000원', () {
      final allowance = service.calculateResearchAllowance(
        position: Position.teacher,
        schoolType: SchoolType.elementary,
        teachingExperienceYears: 8,
      );
      expect(allowance, 60000);
    });

    test('일반교사 - 교육경력 정확히 5년: 60,000원', () {
      final allowance = service.calculateResearchAllowance(
        position: Position.teacher,
        schoolType: SchoolType.elementary,
        teachingExperienceYears: 5,
      );
      expect(allowance, 60000);
    });

    test('일반교사 - 교육경력 0년: 75,000원', () {
      final allowance = service.calculateResearchAllowance(
        position: Position.teacher,
        schoolType: SchoolType.elementary,
        teachingExperienceYears: 0,
      );
      expect(allowance, 75000);
    });
  });

  group('교원연구비 우선순위 검증', () {
    test('교장 > 교감 > 수석교사 > 보직교사 > 일반교사 순서', () {
      // 교장
      final principal = service.calculateResearchAllowance(
        position: Position.principal,
        schoolType: SchoolType.elementary,
        teachingExperienceYears: 10,
      );

      // 교감
      final vicePrincipal = service.calculateResearchAllowance(
        position: Position.vicePrincipal,
        schoolType: SchoolType.elementary,
        teachingExperienceYears: 10,
      );

      // 수석교사
      final seniorTeacher = service.calculateResearchAllowance(
        position: Position.seniorTeacher,
        schoolType: SchoolType.elementary,
        teachingExperienceYears: 10,
      );

      // 보직교사
      final headTeacher = service.calculateResearchAllowance(
        position: Position.headTeacher,
        schoolType: SchoolType.elementary,
        teachingExperienceYears: 10,
      );

      // 일반교사 (교육경력 5년 이상)
      final teacher = service.calculateResearchAllowance(
        position: Position.teacher,
        schoolType: SchoolType.elementary,
        teachingExperienceYears: 10,
      );

      // 우선순위 검증
      expect(principal, greaterThanOrEqualTo(vicePrincipal));
      expect(vicePrincipal, greaterThanOrEqualTo(seniorTeacher));
      expect(seniorTeacher, greaterThanOrEqualTo(headTeacher));
      expect(headTeacher, greaterThanOrEqualTo(teacher));

      // 구체적인 금액 검증
      expect(principal, 75000);
      expect(vicePrincipal, 65000);
      expect(seniorTeacher, 60000);
      expect(headTeacher, 60000);
      expect(teacher, 60000);
    });
  });

  group('학교급 구분이 영향을 미치는 경우', () {
    test('교장/교감은 학교급에 따라 금액이 달라짐', () {
      // 교장
      final principalElementary = service.calculateResearchAllowance(
        position: Position.principal,
        schoolType: SchoolType.elementary,
        teachingExperienceYears: 10,
      );
      final principalSecondary = service.calculateResearchAllowance(
        position: Position.principal,
        schoolType: SchoolType.secondary,
        teachingExperienceYears: 10,
      );
      expect(principalElementary, 75000);
      expect(principalSecondary, 60000);
      expect(principalElementary, isNot(equals(principalSecondary)));

      // 교감
      final vicePrincipalElementary = service.calculateResearchAllowance(
        position: Position.vicePrincipal,
        schoolType: SchoolType.elementary,
        teachingExperienceYears: 10,
      );
      final vicePrincipalSecondary = service.calculateResearchAllowance(
        position: Position.vicePrincipal,
        schoolType: SchoolType.secondary,
        teachingExperienceYears: 10,
      );
      expect(vicePrincipalElementary, 65000);
      expect(vicePrincipalSecondary, 60000);
      expect(vicePrincipalElementary, isNot(equals(vicePrincipalSecondary)));
    });

    test('수석교사/보직교사/일반교사는 학교급에 무관하게 동일한 금액', () {
      // 수석교사
      final seniorTeacherElementary = service.calculateResearchAllowance(
        position: Position.seniorTeacher,
        schoolType: SchoolType.elementary,
        teachingExperienceYears: 10,
      );
      final seniorTeacherSecondary = service.calculateResearchAllowance(
        position: Position.seniorTeacher,
        schoolType: SchoolType.secondary,
        teachingExperienceYears: 10,
      );
      expect(seniorTeacherElementary, seniorTeacherSecondary);

      // 보직교사
      final headTeacherElementary = service.calculateResearchAllowance(
        position: Position.headTeacher,
        schoolType: SchoolType.elementary,
        teachingExperienceYears: 10,
      );
      final headTeacherSecondary = service.calculateResearchAllowance(
        position: Position.headTeacher,
        schoolType: SchoolType.secondary,
        teachingExperienceYears: 10,
      );
      expect(headTeacherElementary, headTeacherSecondary);

      // 일반교사
      final teacherElementary = service.calculateResearchAllowance(
        position: Position.teacher,
        schoolType: SchoolType.elementary,
        teachingExperienceYears: 10,
      );
      final teacherSecondary = service.calculateResearchAllowance(
        position: Position.teacher,
        schoolType: SchoolType.secondary,
        teachingExperienceYears: 10,
      );
      expect(teacherElementary, teacherSecondary);
    });
  });

  group('교육경력 계산 검증', () {
    test('1급 정교사 소지 - 호봉 기반 교육경력 계산', () {
      // 14호봉, 3월 승급, 1급 정교사 O
      final profile = TeacherProfile(
        birthYear: 1990,
        birthMonth: 3,
        currentGrade: 14,
        position: Position.teacher,
        employmentStartDate: DateTime(2020, 3, 1),
        gradePromotionMonth: 3,
        hasFirstGradeCertificate: true,
      );

      // 14 - 9 - 1 = 4년
      expect(profile.getTeachingExperienceYears(), 4);

      // 교원연구비: 4년 < 5년이므로 75,000원
      final allowance = service.calculateResearchAllowance(
        position: profile.position,
        schoolType: profile.schoolType,
        teachingExperienceYears: profile.getTeachingExperienceYears(),
      );
      expect(allowance, 75000);
    });

    test('2급 정교사 - 호봉 기반 교육경력 계산', () {
      // 14호봉, 3월 승급, 1급 정교사 X
      final profile = TeacherProfile(
        birthYear: 1990,
        birthMonth: 3,
        currentGrade: 14,
        position: Position.teacher,
        employmentStartDate: DateTime(2020, 3, 1),
        gradePromotionMonth: 3,
        hasFirstGradeCertificate: false,
      );

      // 14 - 9 = 5년
      expect(profile.getTeachingExperienceYears(), 5);

      // 교원연구비: 5년 >= 5년이므로 60,000원
      final allowance = service.calculateResearchAllowance(
        position: profile.position,
        schoolType: profile.schoolType,
        teachingExperienceYears: profile.getTeachingExperienceYears(),
      );
      expect(allowance, 60000);
    });

    test('교육경력 추가 - 기간제 경력 포함', () {
      // 12호봉, 3월 승급, 1급 정교사 O, 기간제 36개월 추가
      final profile = TeacherProfile(
        birthYear: 1990,
        birthMonth: 3,
        currentGrade: 12,
        position: Position.teacher,
        employmentStartDate: DateTime(2020, 3, 1),
        gradePromotionMonth: 3,
        hasFirstGradeCertificate: true,
        additionalTeachingMonths: 36, // 3년 추가
      );

      // (12 - 9 - 1) + 3 = 5년
      expect(profile.getTeachingExperienceYears(), 5);

      // 교원연구비: 5년 >= 5년이므로 60,000원
      final allowance = service.calculateResearchAllowance(
        position: profile.position,
        schoolType: profile.schoolType,
        teachingExperienceYears: profile.getTeachingExperienceYears(),
      );
      expect(allowance, 60000);
    });

    test('교육경력 제외 - 군 복무 제외', () {
      // 16호봉, 3월 승급, 1급 정교사 O, 군 복무 24개월 제외
      final profile = TeacherProfile(
        birthYear: 1990,
        birthMonth: 3,
        currentGrade: 16,
        position: Position.teacher,
        employmentStartDate: DateTime(2020, 3, 1),
        gradePromotionMonth: 3,
        hasFirstGradeCertificate: true,
        excludedTeachingMonths: 24, // 2년 제외
      );

      // (16 - 9 - 1) - 2 = 4년
      expect(profile.getTeachingExperienceYears(), 4);

      // 교원연구비: 4년 < 5년이므로 75,000원
      final allowance = service.calculateResearchAllowance(
        position: profile.position,
        schoolType: profile.schoolType,
        teachingExperienceYears: profile.getTeachingExperienceYears(),
      );
      expect(allowance, 75000);
    });

    test('교육경력 경계값 - 4년대 vs 5년대', () {
      // 1급 정교사 O: 14호봉 - 9 - 1 = 4년 (+ 승급 후 경과 개월)
      final profile1 = TeacherProfile(
        birthYear: 1990,
        birthMonth: 3,
        currentGrade: 14,
        position: Position.teacher,
        employmentStartDate: DateTime(2020, 3, 1),
        gradePromotionMonth: 3,
        hasFirstGradeCertificate: true,
      );
      final months1 = profile1.getTeachingExperienceMonths();
      final years1 = profile1.getTeachingExperienceYears();

      // 4년대여야 함
      expect(years1, 4);
      expect(months1, greaterThanOrEqualTo(48));
      expect(months1, lessThan(60));

      final allowance1 = service.calculateResearchAllowance(
        position: profile1.position,
        schoolType: profile1.schoolType,
        teachingExperienceYears: years1,
      );
      expect(allowance1, 75000);

      // 2급 정교사: 14호봉 - 9 = 5년 (+ 승급 후 경과 개월)
      final profile2 = TeacherProfile(
        birthYear: 1990,
        birthMonth: 3,
        currentGrade: 14,
        position: Position.teacher,
        employmentStartDate: DateTime(2020, 3, 1),
        gradePromotionMonth: 3,
        hasFirstGradeCertificate: false,
      );
      final months2 = profile2.getTeachingExperienceMonths();
      final years2 = profile2.getTeachingExperienceYears();

      // 5년대여야 함
      expect(years2, 5);
      expect(months2, greaterThanOrEqualTo(60));
      expect(months2, lessThan(72));

      final allowance2 = service.calculateResearchAllowance(
        position: profile2.position,
        schoolType: profile2.schoolType,
        teachingExperienceYears: years2,
      );
      expect(allowance2, 60000);
    });
  });
}
