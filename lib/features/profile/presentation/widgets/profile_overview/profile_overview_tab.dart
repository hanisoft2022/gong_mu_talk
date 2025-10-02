/**
 * Profile Overview Tab
 *
 * Main overview tab displaying:
 * - Profile header
 * - Paystub verification card
 * - Sponsorship banner
 * - Timeline section
 * - HANISOFT footer
 *
 * Phase 4 - Extracted from profile_page.dart
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import '../../../../auth/presentation/cubit/auth_cubit.dart';
import '../../cubit/profile_timeline_cubit.dart';
import '../profile_verification/paystub_verification_card.dart';
import '../profile_timeline/timeline_section.dart';
import 'profile_header.dart';
import 'sponsorship_banner.dart';

class ProfileOverviewTab extends StatelessWidget {
  const ProfileOverviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await context.read<ProfileTimelineCubit>().refresh();
      },
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (BuildContext context, AuthState state) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              ProfileHeader(state: state, isOwnProfile: true), // 임시로 항상 자신의 프로필로 설정
              const Gap(16),
              if (state.userId != null) ...[
                PaystubVerificationCard(uid: state.userId!),
                const Gap(16),
              ],
              SponsorshipBanner(state: state),
              const Gap(20),
              Text(
                '라운지 타임라인',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Gap(12),
              const TimelineSection(),
              const Gap(24),
              Center(
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/hanisoft_logo.png',
                      height: 32,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                    const Gap(4),
                    Text(
                      'Powered by HANISOFT',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(16),
            ],
          );
        },
      ),
    );
  }
}
