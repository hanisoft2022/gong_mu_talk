/// Profile Header Widget
///
/// Displays comprehensive user profile information in a card format.
///
/// **Purpose**:
/// - Shows user's basic profile information (avatar, nickname, join date)
/// - Displays follower/following statistics with tap actions
/// - Shows verification status (email, paystub/career)
/// - Provides edit button for own profile or follow button for others
/// - Includes test career selector in debug mode
///
/// **Features**:
/// - Profile avatar with placeholder for missing images
/// - Bio section with expand/collapse for long text
/// - Clickable follower/following stats
/// - Verification status indicators
/// - Test mode career selector (kDebugMode only)
///
/// **Key Components**:
/// - BioCard: Expandable bio text
/// - StatCard: Follower/following statistics
/// - VerificationStatusRow: Email verification status
/// - PaystubStatusRow: Career verification status
/// - FollowButton: Follow/unfollow button for other users
///
/// **Related**:
/// - profile_header_widgets.dart: Reusable UI components
/// - profile_relations_sheet.dart: Follower/following list
/// - test_career_selector.dart: Test mode career selection
/// - ../../constants/test_careers.dart: Career options list

library;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../domain/career_track.dart';
import '../../views/profile_edit_page.dart';
import '../../cubit/profile_relations_cubit.dart';
import 'profile_header_widgets.dart';
import 'profile_relations_sheet.dart';
import 'test_career_selector.dart';

/// Main profile header widget showing user information and verification status
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.state,
    required this.isOwnProfile,
  });

  final AuthState state;
  final bool isOwnProfile;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단: 닉네임, 액션 버튼
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 닉네임
                      Text(
                        state.nickname,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Gap(4),
                      // 가입일 표시
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          const Gap(6),
                          Text(
                            '2024년 9월에 가입',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // 우측 액션 버튼 (본인 프로필만 표시됨)
                if (isOwnProfile)
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (BuildContext context) =>
                              const ProfileEditPage(),
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.edit_outlined,
                      color: theme.colorScheme.onSurface,
                    ),
                    tooltip: '프로필 수정',
                  ),
              ],
            ),

            // 자기소개
            if (state.bio != null && state.bio!.trim().isNotEmpty) ...[
              const Gap(20),
              BioCard(bio: state.bio!.trim()),
            ] else
              const Gap(16),

            const Gap(20),

            // 팔로워/팔로잉 통계
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: '팔로잉',
                    count: state.followingCount,
                    onTap: () => showProfileRelationsSheet(
                      context,
                      ProfileRelationType.following,
                    ),
                  ),
                ),
                const Gap(16),
                Expanded(
                  child: StatCard(
                    title: '팔로워',
                    count: state.followerCount,
                    onTap: () => showProfileRelationsSheet(
                      context,
                      ProfileRelationType.followers,
                    ),
                  ),
                ),
              ],
            ),

            const Gap(20),

            // 인증 상태
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const Gap(8),
                      Text(
                        '인증 정보',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const Gap(12),
                  VerificationStatusRow(
                    icon: state.isGovernmentEmailVerified
                        ? Icons.verified
                        : Icons.email_outlined,
                    label: '공직자 통합 메일 인증',
                    isVerified: state.isGovernmentEmailVerified,
                  ),
                  if (state.userId != null) ...[
                    const Gap(8),
                    PaystubStatusRow(uid: state.userId!),
                  ],

                  // 직렬 설정 상태 (인증 완료 시에만 표시)
                  if (state.serial != 'unknown' &&
                      state.careerHierarchy != null) ...[
                    const Gap(8),
                    Row(
                      children: [
                        Icon(
                          Icons.verified,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        const Gap(8),
                        const Expanded(
                          child: Text(
                            '직렬',
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                        Text(
                          state.careerTrack.displayName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // 임시 직렬 선택 버튼 (테스트용)
            if (kDebugMode) ...[
              const Gap(12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.error.withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.bug_report,
                          size: 16,
                          color: theme.colorScheme.error,
                        ),
                        const Gap(8),
                        Text(
                          '테스트 모드',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const Gap(8),
                    Text(
                      '라운지 시스템 테스트를 위한 임시 직렬 선택',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                    const Gap(8),
                    ElevatedButton(
                      onPressed: () => showTestCareerSelector(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.error,
                        foregroundColor: theme.colorScheme.onError,
                      ),
                      child: const Text('임시 직렬 선택'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
