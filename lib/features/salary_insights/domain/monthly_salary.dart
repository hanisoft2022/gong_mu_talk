import 'package:equatable/equatable.dart';

class MonthlySalary extends Equatable {
  const MonthlySalary({
    required this.basePay,
    required this.longevityAllowance,
    required this.mealAllowance,
    required this.teacherAllowance,
    required this.teacherExtraAllowance,
    required this.familyAllowance,
    required this.overtimeAllowance,
    required this.researchAllowance,
    required this.otherAllowances,
    required this.incomeTax,
    required this.localIncomeTax,
    required this.pensionContribution,
    required this.healthInsurance,
    required this.longTermCare,
    required this.unionFee,
    required this.otherDeductions,
  });

  final int basePay;
  final int longevityAllowance;
  final int mealAllowance;
  final int teacherAllowance;
  final int teacherExtraAllowance;
  final int familyAllowance;
  final int overtimeAllowance;
  final int researchAllowance;
  final int otherAllowances;
  final int incomeTax;
  final int localIncomeTax;
  final int pensionContribution;
  final int healthInsurance;
  final int longTermCare;
  final int unionFee;
  final int otherDeductions;

  int get totalAllowances =>
      basePay +
      longevityAllowance +
      mealAllowance +
      teacherAllowance +
      teacherExtraAllowance +
      familyAllowance +
      overtimeAllowance +
      researchAllowance +
      otherAllowances;

  int get totalDeductions =>
      incomeTax +
      localIncomeTax +
      pensionContribution +
      healthInsurance +
      longTermCare +
      unionFee +
      otherDeductions;

  int get netPay => totalAllowances - totalDeductions;

  double get deductionRatio =>
      totalAllowances == 0 ? 0 : totalDeductions / totalAllowances;

  MonthlySalary copyWith({
    int? basePay,
    int? longevityAllowance,
    int? mealAllowance,
    int? teacherAllowance,
    int? teacherExtraAllowance,
    int? familyAllowance,
    int? overtimeAllowance,
    int? researchAllowance,
    int? otherAllowances,
    int? incomeTax,
    int? localIncomeTax,
    int? pensionContribution,
    int? healthInsurance,
    int? longTermCare,
    int? unionFee,
    int? otherDeductions,
  }) {
    return MonthlySalary(
      basePay: basePay ?? this.basePay,
      longevityAllowance: longevityAllowance ?? this.longevityAllowance,
      mealAllowance: mealAllowance ?? this.mealAllowance,
      teacherAllowance: teacherAllowance ?? this.teacherAllowance,
      teacherExtraAllowance:
          teacherExtraAllowance ?? this.teacherExtraAllowance,
      familyAllowance: familyAllowance ?? this.familyAllowance,
      overtimeAllowance: overtimeAllowance ?? this.overtimeAllowance,
      researchAllowance: researchAllowance ?? this.researchAllowance,
      otherAllowances: otherAllowances ?? this.otherAllowances,
      incomeTax: incomeTax ?? this.incomeTax,
      localIncomeTax: localIncomeTax ?? this.localIncomeTax,
      pensionContribution: pensionContribution ?? this.pensionContribution,
      healthInsurance: healthInsurance ?? this.healthInsurance,
      longTermCare: longTermCare ?? this.longTermCare,
      unionFee: unionFee ?? this.unionFee,
      otherDeductions: otherDeductions ?? this.otherDeductions,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    basePay,
    longevityAllowance,
    mealAllowance,
    teacherAllowance,
    teacherExtraAllowance,
    familyAllowance,
    overtimeAllowance,
    researchAllowance,
    otherAllowances,
    incomeTax,
    localIncomeTax,
    pensionContribution,
    healthInsurance,
    longTermCare,
    unionFee,
    otherDeductions,
  ];
}
