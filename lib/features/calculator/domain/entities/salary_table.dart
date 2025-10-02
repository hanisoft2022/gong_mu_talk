import 'package:equatable/equatable.dart';

/// 공무원 봉급표
/// 특정 연도의 직렬별 봉급 기준
class SalaryTable extends Equatable {
  const SalaryTable({
    required this.year,
    required this.track,
    required this.grades,
    this.metadata = const {},
  });

  /// 적용 연도
  final int year;

  /// 직렬 (일반직, 특정직 등)
  final String track;

  /// 계급별 봉급표
  /// Key: 계급 ID (예: '9', '8', '7', ..., '1')
  final Map<String, GradeSteps> grades;

  /// 메타데이터 (출처, 업데이트 날짜 등)
  final Map<String, dynamic> metadata;

  /// 특정 계급의 호봉별 봉급 조회
  GradeSteps? getGrade(String gradeId) => grades[gradeId];

  /// 특정 계급/호봉의 봉급 조회
  double? getSalary(String gradeId, int step) {
    return grades[gradeId]?.getSalary(step);
  }

  @override
  List<Object?> get props => [year, track, grades, metadata];
}

/// 계급별 호봉 단계 봉급표
class GradeSteps extends Equatable {
  const GradeSteps({
    required this.gradeId,
    required this.gradeName,
    required this.steps,
    required this.minStep,
    required this.maxStep,
  });

  /// 계급 ID (예: '9', '8', '7')
  final String gradeId;

  /// 계급명 (예: '9급', '8급', '7급')
  final String gradeName;

  /// 호봉별 봉급
  /// Key: 호봉 (1, 2, 3, ...)
  /// Value: 봉급액
  final Map<int, double> steps;

  /// 최소 호봉
  final int minStep;

  /// 최대 호봉
  final int maxStep;

  /// 특정 호봉의 봉급 조회
  double? getSalary(int step) => steps[step];

  /// 호봉이 유효한 범위인지 확인
  bool isValidStep(int step) => step >= minStep && step <= maxStep;

  /// 다음 호봉의 봉급 조회
  double? getNextStepSalary(int currentStep) {
    if (currentStep >= maxStep) return null;
    return steps[currentStep + 1];
  }

  @override
  List<Object?> get props => [gradeId, gradeName, steps, minStep, maxStep];
}

/// 2025년 일반직 9급 봉급표 샘플
/// 출처: 인사혁신처 (2025년 공무원 봉급표)
class SalaryTableSamples {
  /// 2025년 일반직 공무원 봉급표 (샘플)
  static SalaryTable general2025() {
    return const SalaryTable(
      year: 2025,
      track: 'general',
      grades: {
        '9': GradeSteps(
          gradeId: '9',
          gradeName: '9급',
          minStep: 1,
          maxStep: 19,
          steps: {
            1: 1956000,
            2: 2034000,
            3: 2112000,
            4: 2190000,
            5: 2268000,
            6: 2346000,
            7: 2424000,
            8: 2502000,
            9: 2580000,
            10: 2658000,
            11: 2736000,
            12: 2814000,
            13: 2892000,
            14: 2970000,
            15: 3048000,
            16: 3126000,
            17: 3204000,
            18: 3282000,
            19: 3360000,
          },
        ),
        '8': GradeSteps(
          gradeId: '8',
          gradeName: '8급',
          minStep: 1,
          maxStep: 20,
          steps: {
            1: 2112000,
            2: 2196000,
            3: 2280000,
            4: 2364000,
            5: 2448000,
            6: 2532000,
            7: 2616000,
            8: 2700000,
            9: 2784000,
            10: 2868000,
            11: 2952000,
            12: 3036000,
            13: 3120000,
            14: 3204000,
            15: 3288000,
            16: 3372000,
            17: 3456000,
            18: 3540000,
            19: 3624000,
            20: 3708000,
          },
        ),
        '7': GradeSteps(
          gradeId: '7',
          gradeName: '7급',
          minStep: 1,
          maxStep: 21,
          steps: {
            1: 2280000,
            2: 2376000,
            3: 2472000,
            4: 2568000,
            5: 2664000,
            6: 2760000,
            7: 2856000,
            8: 2952000,
            9: 3048000,
            10: 3144000,
            11: 3240000,
            12: 3336000,
            13: 3432000,
            14: 3528000,
            15: 3624000,
            16: 3720000,
            17: 3816000,
            18: 3912000,
            19: 4008000,
            20: 4104000,
            21: 4200000,
          },
        ),
        '6': GradeSteps(
          gradeId: '6',
          gradeName: '6급',
          minStep: 1,
          maxStep: 22,
          steps: {
            1: 2472000,
            2: 2580000,
            3: 2688000,
            4: 2796000,
            5: 2904000,
            6: 3012000,
            7: 3120000,
            8: 3228000,
            9: 3336000,
            10: 3444000,
            11: 3552000,
            12: 3660000,
            13: 3768000,
            14: 3876000,
            15: 3984000,
            16: 4092000,
            17: 4200000,
            18: 4308000,
            19: 4416000,
            20: 4524000,
            21: 4632000,
            22: 4740000,
          },
        ),
        '5': GradeSteps(
          gradeId: '5',
          gradeName: '5급',
          minStep: 1,
          maxStep: 23,
          steps: {
            1: 2688000,
            2: 2814000,
            3: 2940000,
            4: 3066000,
            5: 3192000,
            6: 3318000,
            7: 3444000,
            8: 3570000,
            9: 3696000,
            10: 3822000,
            11: 3948000,
            12: 4074000,
            13: 4200000,
            14: 4326000,
            15: 4452000,
            16: 4578000,
            17: 4704000,
            18: 4830000,
            19: 4956000,
            20: 5082000,
            21: 5208000,
            22: 5334000,
            23: 5460000,
          },
        ),
      },
      metadata: {
        'source': '인사혁신처',
        'updatedAt': '2025-01-01',
        'description': '2025년 일반직공무원 봉급표',
      },
    );
  }

  /// 2024년 일반직 공무원 봉급표 (샘플 - 2025년 대비 약 2% 낮음)
  static SalaryTable general2024() {
    return const SalaryTable(
      year: 2024,
      track: 'general',
      grades: {
        '9': GradeSteps(
          gradeId: '9',
          gradeName: '9급',
          minStep: 1,
          maxStep: 19,
          steps: {
            1: 1918000,
            2: 1994000,
            3: 2070000,
            4: 2146000,
            5: 2222000,
            6: 2298000,
            7: 2374000,
            8: 2450000,
            9: 2526000,
            10: 2602000,
            11: 2678000,
            12: 2754000,
            13: 2830000,
            14: 2906000,
            15: 2982000,
            16: 3058000,
            17: 3134000,
            18: 3210000,
            19: 3286000,
          },
        ),
        // 다른 계급도 유사하게 추가 가능
      },
      metadata: {
        'source': '인사혁신처',
        'updatedAt': '2024-01-01',
        'description': '2024년 일반직공무원 봉급표',
      },
    );
  }
}
