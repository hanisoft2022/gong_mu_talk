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

import '../../../domain/career_track.dart';
import '../../../domain/user_profile.dart';
import '../../../../community/domain/models/lounge_definitions.dart';
import '../../cubit/profile_relations_cubit.dart';
import '../../views/profile_edit_page.dart';
import 'profile_relations_sheet.dart';
import 'test_career_selector.dart';

/// Main profile header widget showing user information and verification status
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.profile,
    required this.isOwnProfile,
    this.currentUserId,
    this.followButton,
  });

  final UserProfile profile;
  final bool isOwnProfile;
  final String? currentUserId;
  final Widget? followButton;

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
            // Top: Career Track + Emoji + Nickname + Action Button
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildCareerAndNickname(context, theme)),
                const Gap(8),
                // Action Button (Edit or Follow)
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
                  )
                else if (followButton != null)
                  followButton!,
              ],
            ),

            const Gap(16),

            // Follower/Following Stats (Instagram-style inline)
            _buildInlineStats(context),

            // Bio
            if (profile.bio != null && profile.bio!.trim().isNotEmpty) ...[
              const Gap(16),
              _buildSimplifiedBio(theme),
            ],

            // Test Career Selector (Debug Mode, Own Profile Only)
            if (kDebugMode && isOwnProfile) ...[
              const Gap(12),
              _buildTestCareerSelector(theme, context),
            ],
          ],
        ),
      ),
    );
  }

  // Career Track + Emoji + Nickname + Join Date + Verification Icons
  Widget _buildCareerAndNickname(BuildContext context, ThemeData theme) {
    final String displayText;

    // Try to get specific career name from careerHierarchy
    if (profile.careerHierarchy != null &&
        profile.careerHierarchy!.specificCareer != 'none') {
      final specificCareer = profile.careerHierarchy!.specificCareer;

      // Find matching lounge in LoungeDefinitions
      final lounge = LoungeDefinitions.defaultLounges.firstWhere(
        (l) => l.id == specificCareer,
        orElse: () => LoungeDefinitions.defaultLounges.first,
      );

      // If found and not the fallback 'all' lounge
      if (lounge.id == specificCareer) {
        // Show: [구체적 직렬명] [이모지] [닉네임]
        displayText = '${lounge.name} ${lounge.emoji} ${profile.nickname}';
      } else if (profile.careerTrack != CareerTrack.none) {
        // Fallback to careerTrack
        displayText =
            '${profile.careerTrack.displayName} ${profile.careerTrack.emoji} ${profile.nickname}';
      } else {
        displayText = profile.nickname;
      }
    } else if (profile.careerTrack != CareerTrack.none) {
      // Legacy: Use careerTrack if careerHierarchy not available
      displayText =
          '${profile.careerTrack.displayName} ${profile.careerTrack.emoji} ${profile.nickname}';
    } else {
      // No career info: Just nickname
      displayText = profile.nickname;
    }

    // Format join date
    final String joinDate = _formatJoinDate(profile.createdAt);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          displayText,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        ),
        const Gap(4),
        // Join date + Verification icons on the same line
        Text(
          joinDate,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  // Format join date (e.g., "2024년 9월 15일 가입")
  String _formatJoinDate(DateTime createdAt) {
    return '${createdAt.year}년 ${createdAt.month}월 ${createdAt.day}일 가입';
  }

  // Inline Stats (Instagram-style: "23 posts · 355k followers · 77 following")
  Widget _buildInlineStats(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        // Posts count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: RichText(
            text: TextSpan(
              style: theme.textTheme.bodyMedium,
              children: [
                TextSpan(
                  text: '${profile.postCount}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const TextSpan(text: ' 게시물'),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            '·',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        // Followers count
        InkWell(
          onTap: isOwnProfile
              ? () => showProfileRelationsSheet(
                  context,
                  ProfileRelationType.followers,
                )
              : () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('다른 사용자의 팔로워 목록은 곧 제공될 예정입니다.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: RichText(
              text: TextSpan(
                style: theme.textTheme.bodyMedium,
                children: [
                  TextSpan(
                    text: '${profile.followerCount}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const TextSpan(text: ' 팔로워'),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            '·',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        // Following count
        InkWell(
          onTap: isOwnProfile
              ? () => showProfileRelationsSheet(
                  context,
                  ProfileRelationType.following,
                )
              : () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('다른 사용자의 팔로잉 목록은 곧 제공될 예정입니다.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: RichText(
              text: TextSpan(
                style: theme.textTheme.bodyMedium,
                children: [
                  TextSpan(
                    text: '${profile.followingCount}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const TextSpan(text: ' 팔로잉'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Simplified Bio (no card, just text with expand functionality)
  Widget _buildSimplifiedBio(ThemeData theme) {
    return _ExpandableBio(bio: profile.bio!.trim(), theme: theme);
  }

  // Test Career Selector (Debug Mode Only)
  Widget _buildTestCareerSelector(ThemeData theme, BuildContext context) {
    return Container(
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
              Icon(Icons.bug_report, size: 16, color: theme.colorScheme.error),
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
    );
  }
}

/// Expandable Bio Widget
class _ExpandableBio extends StatefulWidget {
  const _ExpandableBio({required this.bio, required this.theme});

  final String bio;
  final ThemeData theme;

  @override
  State<_ExpandableBio> createState() => _ExpandableBioState();
}

class _ExpandableBioState extends State<_ExpandableBio> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.bio,
          style: widget.theme.textTheme.bodyMedium?.copyWith(
            height: 1.4,
            color: widget.theme.colorScheme.onSurface,
          ),
          maxLines: _isExpanded ? null : 3,
          overflow: _isExpanded ? null : TextOverflow.ellipsis,
        ),
        if (widget.bio.split('\n').length > 3 || widget.bio.length > 90)
          GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _isExpanded ? '접기' : '더보기',
                style: widget.theme.textTheme.bodySmall?.copyWith(
                  color: widget.theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
