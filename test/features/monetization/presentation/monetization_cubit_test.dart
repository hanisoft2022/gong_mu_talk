import 'package:flutter_test/flutter_test.dart';

import 'package:gong_mu_talk/features/monetization/presentation/cubit/monetization_cubit.dart';

void main() {
  group('MonetizationCubit', () {
    late MonetizationCubit cubit;

    setUp(() {
      cubit = MonetizationCubit();
    });

    tearDown(() {
      cubit.close();
    });

    test('marks user as supporter after purchase', () async {
      expect(cubit.state.isSupporter, isFalse);

      await cubit.purchaseSupporterPlan();

      expect(cubit.state.isSupporter, isTrue);
      expect(cubit.state.supporterSince, isNotNull);
    });

    test('enforces referral cooldown and yearly limits', () {
      final DateTime now = DateTime(2024, 1, 1);
      cubit.resetAnnualCounter(reference: now);

      final ReferralResult first = cubit.redeemReferralReward(now: now);
      expect(first.success, isTrue);
      expect(cubit.state.rewardsThisYear, 1);

      final ReferralResult tooSoon = cubit.redeemReferralReward(
        now: now.add(const Duration(days: 1)),
      );
      expect(tooSoon.success, isFalse);

      DateTime cursor = now.add(const Duration(days: 8));
      int granted = 1;
      while (granted < cubit.referralPolicy.maxRewardsPerYear) {
        final ReferralResult result = cubit.redeemReferralReward(now: cursor);
        expect(result.success, isTrue);
        cursor = cursor.add(const Duration(days: 8));
        granted += 1;
      }

      final ReferralResult limitReached = cubit.redeemReferralReward(
        now: cursor,
      );
      expect(limitReached.success, isFalse);
      expect(
        cubit.state.rewardsThisYear,
        cubit.referralPolicy.maxRewardsPerYear,
      );
    });

    test('recognises allowed email domains', () {
      expect(cubit.isAllowedEmail('user@korea.kr'), isTrue);
      expect(cubit.isAllowedEmail('user@mail.go.kr'), isTrue);
      expect(cubit.isAllowedEmail('user@example.com'), isFalse);
      expect(cubit.isAllowedEmail('invalid-email'), isFalse);
    });
  });
}
