import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/pricing_plan.dart';

class ReferralResult {
  const ReferralResult({required this.success, required this.message});

  final bool success;
  final String message;
}

class MonetizationState extends Equatable {
  const MonetizationState({
    this.isSupporter = false,
    this.supporterSince,
    this.rewardsThisYear = 0,
    this.lastReferralRewardAt,
  });

  final bool isSupporter;
  final DateTime? supporterSince;
  final int rewardsThisYear;
  final DateTime? lastReferralRewardAt;

  MonetizationState copyWith({
    bool? isSupporter,
    DateTime? supporterSince,
    int? rewardsThisYear,
    DateTime? lastReferralRewardAt,
  }) {
    return MonetizationState(
      isSupporter: isSupporter ?? this.isSupporter,
      supporterSince: supporterSince ?? this.supporterSince,
      rewardsThisYear: rewardsThisYear ?? this.rewardsThisYear,
      lastReferralRewardAt: lastReferralRewardAt ?? this.lastReferralRewardAt,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    isSupporter,
    supporterSince,
    rewardsThisYear,
    lastReferralRewardAt,
  ];
}

class MonetizationCubit extends Cubit<MonetizationState> {
  MonetizationCubit()
    : supporterPlan = supporterPlanTemplate,
      referralPolicy = defaultReferralPolicy,
      super(const MonetizationState());

  static const PricingPlan supporterPlanTemplate = PricingPlan(
    id: 'supporter_990',
    name: '후원하기 990',
    price: 990,
    currency: '₩',
    billingPeriod: '월 정기 후원',
    benefits: <PricingBenefit>[
      PricingBenefit(
        title: '커뮤니티 전용 후원 배지',
        description: '닉네임 옆에 후원 배지가 표시됩니다.',
      ),
      PricingBenefit(
        title: '앱 내 광고 제거',
        description: '모든 광고가 제거되어 쾌적한 사용이 가능합니다.',
      ),
      PricingBenefit(
        title: '서비스 유지 보수에 기여',
        description: '후원해 주신 금액은 커뮤니티 품질 개선에 사용됩니다.',
      ),
    ],
  );

  static const ReferralRewardPolicy defaultReferralPolicy =
      ReferralRewardPolicy(
        referredDays: 30,
        referrerDays: 30,
        maxRewardsPerYear: 6,
        cooldownDays: 7,
      );

  final PricingPlan supporterPlan;
  final ReferralRewardPolicy referralPolicy;

  static const List<String> allowedReferralDomains = <String>[
    'korea.kr',
    'go.kr',
    'sen.go.kr',
    'goe.go.kr',
    'pen.go.kr',
    'ice.go.kr',
    'dge.go.kr',
    'gen.go.kr',
    'dje.go.kr',
    'use.go.kr',
    'sje.go.kr',
    'cbe.go.kr',
    'cne.go.kr',
    'jbe.go.kr',
    'jne.go.kr',
    'gbe.go.kr',
    'gne.go.kr',
    'jje.go.kr',
    'police.go.kr',
    'fire.go.kr',
    'nts.go.kr',
    'customs.go.kr',
    'scourt.go.kr',
    'spo.go.kr',
    'mnd.go.kr',
    'army.mil.kr',
    'navy.mil.kr',
    'af.mil.kr',
  ];

  static const Duration _operationDelay = Duration(milliseconds: 350);

  Future<void> purchaseSupporterPlan() async {
    await Future<void>.delayed(_operationDelay);
    final DateTime now = DateTime.now();
    emit(
      state.copyWith(
        isSupporter: true,
        supporterSince: state.supporterSince ?? now,
      ),
    );
  }

  Future<void> cancelSupporterPlan() async {
    await Future<void>.delayed(_operationDelay);
    emit(state.copyWith(isSupporter: false));
  }

  ReferralResult redeemReferralReward({required DateTime now}) {
    final DateTime? lastRewardedAt = state.lastReferralRewardAt;
    if (lastRewardedAt != null) {
      final DateTime nextAvailable = lastRewardedAt.add(
        Duration(days: referralPolicy.cooldownDays),
      );
      if (now.isBefore(nextAvailable)) {
        return ReferralResult(
          success: false,
          message:
              '리퍼럴 보상은 ${referralPolicy.cooldownDays}일 간 휴식 후 이용할 수 있어요. 다음 가능일: ${_formatDate(nextAvailable)}',
        );
      }
    }

    if (state.rewardsThisYear >= referralPolicy.maxRewardsPerYear) {
      return const ReferralResult(
        success: false,
        message: '올해 리퍼럴 보상 한도(6회)를 모두 사용했어요.',
      );
    }

    emit(
      state.copyWith(
        rewardsThisYear: state.rewardsThisYear + 1,
        lastReferralRewardAt: now,
      ),
    );
    return ReferralResult(
      success: true,
      message: '리퍼럴 보상이 적용되었습니다. +${referralPolicy.referrerDays}일!',
    );
  }

  String generateReferralLink(String userId) {
    return 'https://gongmutalk.app/referral/$userId';
  }

  bool isAllowedEmail(String email) {
    final int atIndex = email.indexOf('@');
    if (atIndex <= 0 || atIndex == email.length - 1) {
      return false;
    }
    final String domain = email.substring(atIndex + 1).toLowerCase();
    return allowedReferralDomains.any(
      (String allowed) => domain == allowed || domain.endsWith('.$allowed'),
    );
  }

  void resetAnnualCounter({DateTime? reference}) {
    final DateTime now = reference ?? DateTime.now();
    final DateTime? lastRewardedAt = state.lastReferralRewardAt;
    if (lastRewardedAt != null && lastRewardedAt.year != now.year) {
      emit(state.copyWith(rewardsThisYear: 0));
    }
  }

  String _formatDate(DateTime date) {
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');
    return '${date.year}.$month.$day';
  }
}
