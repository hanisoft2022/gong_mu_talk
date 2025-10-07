/// Profile Overview Tab
///
/// Main overview tab displaying:
/// - Profile header
/// - Paystub verification card
/// - Timeline section
/// - HANISOFT footer
///
/// Phase 4 - Extracted from profile_page.dart
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import '../../../../../core/utils/performance_optimizations.dart';
import '../../../../auth/presentation/cubit/auth_cubit.dart';
import '../../cubit/profile_timeline_cubit.dart';
import '../profile_verification/paystub_verification_card.dart';
import '../profile_timeline/timeline_section.dart';
import 'profile_header.dart';

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
          final bool hasUserId = state.userId != null;
          final int itemCount = hasUserId ? 9 : 7;

          return OptimizedListView(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: itemCount,
            itemBuilder: (context, index) {
              if (index == 0) {
                if (state.userProfile == null) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: ProfileHeader(
                    profile: state.userProfile!,
                    isOwnProfile: true,
                    currentUserId: state.userId,
                  ),
                );
              } else if (index == 1) {
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Gap(16),
                );
              } else if (hasUserId && index == 2) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: PaystubVerificationCard(uid: state.userId!),
                );
              } else if (hasUserId && index == 3) {
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Gap(16),
                );
              }

              final baseIndex = hasUserId ? index - 4 : index - 2;

              if (baseIndex == 0) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '작성한 글',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              } else if (baseIndex == 1) {
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Gap(12),
                );
              } else if (baseIndex == 2) {
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: TimelineSection(),
                );
              } else if (baseIndex == 3) {
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Gap(24),
                );
              } else if (baseIndex == 4) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Center(
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
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                );
              } else {
                return const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Gap(16),
                );
              }
            },
          );
        },
      ),
    );
  }
}
