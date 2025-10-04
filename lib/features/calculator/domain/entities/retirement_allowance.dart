import 'package:equatable/equatable.dart';

/// 퇴직금 정보
class RetirementAllowance extends Equatable {
  const RetirementAllowance({
    required this.retirementPay,
    this.earlyRetirementBonus = 0,
    this.retirementPension = 0,
    required this.totalAmount,
    required this.retirementAge,
    required this.serviceYears,
    this.isEarlyRetirement = false,
  });

  /// 퇴직수당
  final int retirementPay;

  /// 명예퇴직 가산금 (조기퇴직 시)
  final int earlyRetirementBonus;

  /// 퇴직연금
  final int retirementPension;

  /// 총 퇴직금
  final int totalAmount;

  /// 퇴직 연령
  final int retirementAge;

  /// 재직 년수
  final int serviceYears;

  /// 명예퇴직 여부
  final bool isEarlyRetirement;

  /// 명예퇴직 가산 비율 (%)
  double get earlyRetirementBonusRate {
    if (!isEarlyRetirement || retirementPay == 0) return 0.0;
    return (earlyRetirementBonus / retirementPay) * 100;
  }

  @override
  List<Object?> get props => [
        retirementPay,
        earlyRetirementBonus,
        retirementPension,
        totalAmount,
        retirementAge,
        serviceYears,
        isEarlyRetirement,
      ];

  RetirementAllowance copyWith({
    int? retirementPay,
    int? earlyRetirementBonus,
    int? retirementPension,
    int? totalAmount,
    int? retirementAge,
    int? serviceYears,
    bool? isEarlyRetirement,
  }) {
    return RetirementAllowance(
      retirementPay: retirementPay ?? this.retirementPay,
      earlyRetirementBonus: earlyRetirementBonus ?? this.earlyRetirementBonus,
      retirementPension: retirementPension ?? this.retirementPension,
      totalAmount: totalAmount ?? this.totalAmount,
      retirementAge: retirementAge ?? this.retirementAge,
      serviceYears: serviceYears ?? this.serviceYears,
      isEarlyRetirement: isEarlyRetirement ?? this.isEarlyRetirement,
    );
  }
}
