import 'package:equatable/equatable.dart';

import 'salary_breakdown.dart';
import 'salary_input.dart';
import 'salary_track.dart';

/// 급여 계산 히스토리 엔티티
class CalculationHistory extends Equatable {
  const CalculationHistory({
    required this.id,
    required this.timestamp,
    required this.input,
    required this.result,
    this.label,
  });

  /// 고유 ID
  final String id;

  /// 계산 시간
  final DateTime timestamp;

  /// 입력 데이터
  final SalaryInput input;

  /// 계산 결과
  final SalaryBreakdown result;

  /// 사용자 지정 라벨 (예: "승진 후 시뮬레이션", "현재 급여")
  final String? label;

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'input': {
        'baseMonthlySalary': input.baseMonthlySalary,
        'workingDaysPerMonth': input.workingDaysPerMonth,
        'allowances': input.allowances.map(
          (key, value) => MapEntry(key.name, value),
        ),
        'annualBonus': input.annualBonus,
        'pensionContributionRate': input.pensionContributionRate,
        'appointmentYear': input.appointmentYear,
        'track': input.track.name,
        'gradeId': input.gradeId,
        'step': input.step,
      },
      'result': {
        'monthlyTotal': result.monthlyTotal,
        'dailyRate': result.dailyRate,
        'yearlyTotal': result.yearlyTotal,
        'allowancesTotal': result.allowancesTotal,
        'pensionContribution': result.pensionContribution,
        'incomeTax': result.incomeTax,
        'localIncomeTax': result.localIncomeTax,
        'healthInsurance': result.healthInsurance,
        'longTermCare': result.longTermCare,
        'totalDeductions': result.totalDeductions,
        'netPay': result.netPay,
        'yearlyNet': result.yearlyNet,
        'minimumDailyWage': result.minimumDailyWage,
        'minimumWageGap': result.minimumWageGap,
      },
      if (label != null) 'label': label,
    };
  }

  /// JSON에서 생성
  factory CalculationHistory.fromJson(Map<String, dynamic> json) {
    final inputJson = json['input'] as Map<String, dynamic>;
    final resultJson = json['result'] as Map<String, dynamic>;

    return CalculationHistory(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      input: SalaryInput(
        baseMonthlySalary: (inputJson['baseMonthlySalary'] as num).toDouble(),
        workingDaysPerMonth: inputJson['workingDaysPerMonth'] as int,
        allowances: const {},
        annualBonus: (inputJson['annualBonus'] as num).toDouble(),
        pensionContributionRate: (inputJson['pensionContributionRate'] as num).toDouble(),
        appointmentYear: inputJson['appointmentYear'] as int,
        track: SalaryTrack.values.firstWhere(
          (t) => t.name == inputJson['track'],
        ),
        gradeId: inputJson['gradeId'] as String,
        step: inputJson['step'] as int,
        isAutoCalculated: false,
      ),
      result: SalaryBreakdown(
        monthlyTotal: (resultJson['monthlyTotal'] as num).toDouble(),
        dailyRate: (resultJson['dailyRate'] as num).toDouble(),
        yearlyTotal: (resultJson['yearlyTotal'] as num).toDouble(),
        allowancesTotal: (resultJson['allowancesTotal'] as num).toDouble(),
        pensionContribution: (resultJson['pensionContribution'] as num).toDouble(),
        incomeTax: (resultJson['incomeTax'] as num?)?.toDouble() ?? 0,
        localIncomeTax: (resultJson['localIncomeTax'] as num?)?.toDouble() ?? 0,
        healthInsurance: (resultJson['healthInsurance'] as num?)?.toDouble() ?? 0,
        longTermCare: (resultJson['longTermCare'] as num?)?.toDouble() ?? 0,
        totalDeductions: (resultJson['totalDeductions'] as num?)?.toDouble() ?? 0,
        netPay: (resultJson['netPay'] as num?)?.toDouble() ?? 0,
        yearlyNet: (resultJson['yearlyNet'] as num?)?.toDouble() ?? 0,
        minimumDailyWage: (resultJson['minimumDailyWage'] as num).toDouble(),
        minimumWageGap: (resultJson['minimumWageGap'] as num).toDouble(),
        notes: const [],
      ),
      label: json['label'] as String?,
    );
  }

  /// 라벨이 있는 복사본 생성
  CalculationHistory copyWithLabel(String newLabel) {
    return CalculationHistory(
      id: id,
      timestamp: timestamp,
      input: input,
      result: result,
      label: newLabel,
    );
  }

  @override
  List<Object?> get props => [id, timestamp, input, result, label];
}
