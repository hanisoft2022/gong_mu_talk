import 'package:equatable/equatable.dart';

class PricingBenefit extends Equatable {
  const PricingBenefit({required this.title, this.description});

  final String title;
  final String? description;

  @override
  List<Object?> get props => <Object?>[title, description];
}

class PricingPlan extends Equatable {
  const PricingPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.currency,
    required this.billingPeriod,
    required this.benefits,
  });

  final String id;
  final String name;
  final int price;
  final String currency;
  final String billingPeriod;
  final List<PricingBenefit> benefits;

  String get formattedPrice => '$currency${price.toString()}';

  @override
  List<Object?> get props => <Object?>[
        id,
        name,
        price,
        currency,
        billingPeriod,
        benefits,
      ];
}

class ReferralRewardPolicy {
  const ReferralRewardPolicy({
    required this.referredDays,
    required this.referrerDays,
    required this.maxRewardsPerYear,
    required this.cooldownDays,
  });

  final int referredDays;
  final int referrerDays;
  final int maxRewardsPerYear;
  final int cooldownDays;
}
