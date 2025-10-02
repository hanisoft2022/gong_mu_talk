import 'package:equatable/equatable.dart';

import 'salary_allowance_type.dart';

/// 경력 이벤트 (승진, 휴직, 전보 등)
abstract class CareerEvent extends Equatable {
  const CareerEvent({
    required this.year,
    required this.description,
  });

  /// 발생 연도
  final int year;

  /// 설명
  final String description;

  /// 이벤트 타입
  String get type;

  @override
  List<Object?> get props => [year, description, type];
}

/// 승진 이벤트
class PromotionEvent extends CareerEvent {
  const PromotionEvent({
    required super.year,
    required this.newGrade,
    this.newStep = 1,
    super.description = '승진',
  });

  /// 새 계급
  final String newGrade;

  /// 새 호봉
  final int newStep;

  @override
  String get type => 'promotion';

  @override
  List<Object?> get props => [...super.props, newGrade, newStep];
}

/// 정기승급 이벤트
class StepIncrementEvent extends CareerEvent {
  const StepIncrementEvent({
    required super.year,
    this.increment = 1,
    super.description = '정기승급',
  });

  /// 호봉 증가량 (기본 1호봉)
  final int increment;

  @override
  String get type => 'step_increment';

  @override
  List<Object?> get props => [...super.props, increment];
}

/// 휴직 이벤트
class LeaveEvent extends CareerEvent {
  const LeaveEvent({
    required super.year,
    required this.durationMonths,
    required this.leaveType,
    this.isPaid = false,
    super.description = '휴직',
  });

  /// 휴직 기간 (개월)
  final int durationMonths;

  /// 휴직 종류
  final LeaveType leaveType;

  /// 유급 여부
  final bool isPaid;

  @override
  String get type => 'leave';

  @override
  List<Object?> get props => [
        ...super.props,
        durationMonths,
        leaveType,
        isPaid,
      ];
}

/// 휴직 종류
enum LeaveType {
  /// 출산휴가
  maternity('출산휴가'),

  /// 육아휴직
  childcare('육아휴직'),

  /// 병가
  sick('병가'),

  /// 연수휴직
  training('연수휴직'),

  /// 기타
  other('기타');

  const LeaveType(this.displayName);
  final String displayName;
}

/// 전보 이벤트 (부서 이동, 지역 이동 등)
class TransferEvent extends CareerEvent {
  const TransferEvent({
    required super.year,
    this.baseSalaryChange,
    this.allowanceChanges = const {},
    super.description = '전보',
  });

  /// 기본급 변경 (null이면 변경 없음)
  final double? baseSalaryChange;

  /// 수당 변경
  final Map<SalaryAllowanceType, double> allowanceChanges;

  @override
  String get type => 'transfer';

  @override
  List<Object?> get props => [...super.props, baseSalaryChange, allowanceChanges];
}

/// 급여 조정 이벤트 (특별 인상 등)
class SalaryAdjustmentEvent extends CareerEvent {
  const SalaryAdjustmentEvent({
    required super.year,
    required this.adjustmentRate,
    super.description = '급여 조정',
  });

  /// 조정 비율 (예: 0.05 = 5% 인상)
  final double adjustmentRate;

  @override
  String get type => 'salary_adjustment';

  @override
  List<Object?> get props => [...super.props, adjustmentRate];
}

/// 경력 시나리오
/// 여러 경력 이벤트를 포함하는 시나리오
class CareerScenario extends Equatable {
  const CareerScenario({
    required this.name,
    required this.events,
    this.description,
  });

  /// 시나리오 이름
  final String name;

  /// 이벤트 목록
  final List<CareerEvent> events;

  /// 설명
  final String? description;

  /// 특정 연도의 이벤트 조회
  List<CareerEvent> getEventsForYear(int year) {
    return events.where((event) => event.year == year).toList();
  }

  /// 시나리오에 이벤트 추가
  CareerScenario addEvent(CareerEvent event) {
    final updatedEvents = [...events, event]
      ..sort((a, b) => a.year.compareTo(b.year));
    
    return CareerScenario(
      name: name,
      events: updatedEvents,
      description: description,
    );
  }

  /// 시나리오에서 이벤트 제거
  CareerScenario removeEvent(CareerEvent event) {
    final updatedEvents = events.where((e) => e != event).toList();
    
    return CareerScenario(
      name: name,
      events: updatedEvents,
      description: description,
    );
  }

  @override
  List<Object?> get props => [name, events, description];
}

/// 사전 정의된 시나리오 샘플
class CareerScenarioSamples {
  /// 일반적인 경력 경로 (9급 → 5급)
  static CareerScenario typicalCareer() {
    final currentYear = DateTime.now().year;
    
    return CareerScenario(
      name: '일반적인 승진 경로',
      description: '9급 신규 임용 후 정상적인 승진 경로',
      events: [
        // 정기승급 (매년)
        for (int i = 1; i <= 30; i++)
          StepIncrementEvent(year: currentYear + i),
        
        // 승진
        PromotionEvent(year: currentYear + 3, newGrade: '8'),
        PromotionEvent(year: currentYear + 7, newGrade: '7'),
        PromotionEvent(year: currentYear + 12, newGrade: '6'),
        PromotionEvent(year: currentYear + 18, newGrade: '5'),
      ],
    );
  }

  /// 육아휴직 포함 경력
  static CareerScenario withChildcare() {
    final currentYear = DateTime.now().year;
    
    return CareerScenario(
      name: '육아휴직 포함',
      description: '출산 및 육아휴직을 포함한 경력',
      events: [
        // 정기승급
        for (int i = 1; i <= 30; i++)
          if (i != 5 && i != 10) // 휴직 기간 제외
            StepIncrementEvent(year: currentYear + i),
        
        // 출산 및 육아휴직
        LeaveEvent(
          year: currentYear + 5,
          durationMonths: 12,
          leaveType: LeaveType.childcare,
          description: '첫째 육아휴직',
        ),
        LeaveEvent(
          year: currentYear + 10,
          durationMonths: 12,
          leaveType: LeaveType.childcare,
          description: '둘째 육아휴직',
        ),
        
        // 승진 (휴직으로 약간 지연)
        PromotionEvent(year: currentYear + 4, newGrade: '8'),
        PromotionEvent(year: currentYear + 9, newGrade: '7'),
        PromotionEvent(year: currentYear + 15, newGrade: '6'),
        PromotionEvent(year: currentYear + 22, newGrade: '5'),
      ],
    );
  }

  /// 빠른 승진 경로
  static CareerScenario fastTrack() {
    final currentYear = DateTime.now().year;
    
    return CareerScenario(
      name: '빠른 승진',
      description: '우수 인력 빠른 승진 경로',
      events: [
        // 정기승급
        for (int i = 1; i <= 25; i++)
          StepIncrementEvent(year: currentYear + i),
        
        // 빠른 승진
        PromotionEvent(year: currentYear + 2, newGrade: '8'),
        PromotionEvent(year: currentYear + 5, newGrade: '7'),
        PromotionEvent(year: currentYear + 9, newGrade: '6'),
        PromotionEvent(year: currentYear + 14, newGrade: '5'),
        PromotionEvent(year: currentYear + 20, newGrade: '4'),
      ],
    );
  }
}
