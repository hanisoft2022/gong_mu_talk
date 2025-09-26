import 'dart:async';
import 'package:flutter/foundation.dart';

import '../domain/pricing_plan.dart';

class ReferralResult {
  const ReferralResult({required this.success, required this.message});

  final bool success;
  final String message;
}

class MonetizationController extends ChangeNotifier {
  MonetizationController()
    : supporterPlan = supporterPlanTemplate,
      referralPolicy = defaultReferralPolicy;

  static const PricingPlan supporterPlanTemplate = PricingPlan(
    id: 'supporter_990',
    name: 'Supporter 990',
    price: 990,
    currency: '₩',
    billingPeriod: '월 정기 후원',
    benefits: <PricingBenefit>[
      PricingBenefit(
        title: '커뮤니티 전용 후원 배지',
        description: '닉네임 옆에 Supporter 배지가 표시됩니다.',
      ),
      PricingBenefit(
        title: '앱 내 광고 제거',
        description: '모든 광고가 제거되어 쾌적한 사용이 가능합니다.',
      ),
      PricingBenefit(title: '매칭 기능 향상', description: '매칭 추천이 하루 2회 추가 제공됩니다.'),
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

  bool get isSupporter => _isSupporter;
  DateTime? get supporterSince => _supporterSince;
  int get rewardsThisYear => _rewardsThisYear;
  DateTime? get lastReferralRewardAt => _lastReferralRewardAt;

  bool _isSupporter = false;
  DateTime? _supporterSince;
  int _rewardsThisYear = 0;
  DateTime? _lastReferralRewardAt;

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

  Future<void> purchaseSupporterPlan() async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    _isSupporter = true;
    _supporterSince ??= DateTime.now();
    notifyListeners();
  }

  Future<void> cancelSupporterPlan() async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    _isSupporter = false;
    notifyListeners();
  }

  ReferralResult redeemReferralReward({required DateTime now}) {
    if (_lastReferralRewardAt != null) {
      final DateTime nextAvailable = _lastReferralRewardAt!.add(
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

    if (_rewardsThisYear >= referralPolicy.maxRewardsPerYear) {
      return const ReferralResult(
        success: false,
        message: '올해 리퍼럴 보상 한도(6회)를 모두 사용했어요.',
      );
    }

    _rewardsThisYear += 1;
    _lastReferralRewardAt = now;
    notifyListeners();
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
    if (_lastReferralRewardAt != null &&
        _lastReferralRewardAt!.year != now.year) {
      _rewardsThisYear = 0;
    }
  }

  String _formatDate(DateTime date) {
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');
    return '${date.year}.$month.$day';
  }
}
