import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';

import '../../../../di/di.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../data/monetization_controller.dart';
import '../../domain/pricing_plan.dart';

class MonetizationPage extends StatefulWidget {
  const MonetizationPage({super.key});

  @override
  State<MonetizationPage> createState() => _MonetizationPageState();
}

class _MonetizationPageState extends State<MonetizationPage> {
  late final MonetizationController _controller;
  final TextEditingController _referralEmailController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = getIt<MonetizationController>()..resetAnnualCounter();
  }

  @override
  void dispose() {
    _referralEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('후원하기')),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            children: [
              _DonationPlanCard(controller: _controller),
              const Gap(24),
              _ReferralPolicyCard(
                controller: _controller,
                emailController: _referralEmailController,
              ),
              const Gap(24),
              const _AllowedDomainList(
                domains: MonetizationController.allowedReferralDomains,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DonationPlanCard extends StatelessWidget {
  const _DonationPlanCard({required this.controller});

  final MonetizationController controller;

  @override
  Widget build(BuildContext context) {
    final PricingPlan plan = controller.supporterPlan;
    final bool isSupporter = controller.isSupporter;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              plan.name,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const Gap(4),
            Text(
              '${plan.formattedPrice}/${plan.billingPeriod}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Gap(16),
            Text(
              '혜택',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Gap(8),
            ...plan.benefits.map(
              (PricingBenefit benefit) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.check_circle_outline),
                title: Text(benefit.title),
                subtitle: benefit.description == null
                    ? null
                    : Text(benefit.description!),
              ),
            ),
            const Gap(12),
            FilledButton(
              onPressed: isSupporter
                  ? () async {
                      await controller.cancelSupporterPlan();
                      if (!context.mounted) {
                        return;
                      }
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(
                            content: Text('후원하기 990 구독이 해지되었습니다.'),
                          ),
                        );
                    }
                  : () async {
                      await controller.purchaseSupporterPlan();
                      if (!context.mounted) {
                        return;
                      }
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(
                            content: Text(
                              '스토어 결제가 완료되었다고 가정하고 후원 상태를 업데이트했습니다.',
                            ),
                          ),
                        );
                    },
              child: Text(isSupporter ? '후원 해지' : '스토어 결제로 후원 시작'),
            ),
            if (controller.supporterSince != null) ...[
              const Gap(8),
              Text(
                '후원 시작일: ${controller.supporterSince!.year}.${controller.supporterSince!.month.toString().padLeft(2, '0')}.${controller.supporterSince!.day.toString().padLeft(2, '0')}',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReferralPolicyCard extends StatelessWidget {
  const _ReferralPolicyCard({
    required this.controller,
    required this.emailController,
  });

  final MonetizationController controller;
  final TextEditingController emailController;

  @override
  Widget build(BuildContext context) {
    final ReferralRewardPolicy policy = controller.referralPolicy;
    final String currentUserId = getIt<AuthCubit>().state.userId ?? 'user';
    final String link = controller.generateReferralLink(currentUserId);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '공직자 메일 리퍼럴',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const Gap(8),
            const Text('피추천인이 공직자 메일 인증을 완료하면 추천인과 피추천인 모두 광고 제거 30일 혜택을 받아요.'),
            const Gap(12),
            _PolicyRow(
              title: '보상',
              description:
                  '추천인 +${policy.referrerDays}일 · 피추천인 +${policy.referredDays}일',
            ),
            _PolicyRow(
              title: '연 보상 한도',
              description:
                  '연 ${policy.maxRewardsPerYear}회 (쿨다운 ${policy.cooldownDays}일)',
            ),
            const Divider(height: 32),
            Text('공유 링크', style: Theme.of(context).textTheme.titleSmall),
            const Gap(8),
            OutlinedButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: link));
                if (!context.mounted) {
                  return;
                }
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    const SnackBar(content: Text('리퍼럴 링크가 복사되었습니다.')),
                  );
              },
              icon: const Icon(Icons.link),
              label: Text(link),
            ),
            const Gap(16),
            Text('인증 이메일 확인', style: Theme.of(context).textTheme.titleSmall),
            const Gap(8),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: '피추천인 이메일',
                hintText: '예) hong@go.kr',
              ),
            ),
            const Gap(12),
            FilledButton.tonal(
              onPressed: () {
                final String input = emailController.text.trim();
                if (input.isEmpty) {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      const SnackBar(content: Text('이메일을 입력해주세요.')),
                    );
                  return;
                }
                final bool allowed = controller.isAllowedEmail(input);
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text(
                        allowed
                            ? '허용된 공직자 도메인입니다. 리퍼럴 가능해요!'
                            : '허용되지 않은 메일 도메인입니다. 공직자 메일인지 확인해주세요.',
                      ),
                    ),
                  );
              },
              child: const Text('이메일 도메인 확인'),
            ),
            const Gap(16),
            FilledButton.icon(
              onPressed: () {
                final ReferralResult result = controller.redeemReferralReward(
                  now: DateTime.now(),
                );
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(content: Text(result.message)));
              },
              icon: const Icon(Icons.card_giftcard_outlined),
              label: const Text('리퍼럴 보상 수령'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PolicyRow extends StatelessWidget {
  const _PolicyRow({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(title, style: Theme.of(context).textTheme.labelLarge),
          ),
          const Gap(8),
          Expanded(
            child: Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _AllowedDomainList extends StatelessWidget {
  const _AllowedDomainList({required this.domains});

  final List<String> domains;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: const Text('허용 공직자 메일 도메인'),
      subtitle: const Text('하위 도메인 포함'),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Wrap(
            spacing: 12,
            runSpacing: 8,
            children: domains
                .map((String domain) => Chip(label: Text(domain)))
                .toList(growable: false),
          ),
        ),
      ],
    );
  }
}
