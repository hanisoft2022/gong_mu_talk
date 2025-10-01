import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/theme/theme_cubit.dart';
import '../../../../di/di.dart';
import '../../../../routing/app_router.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/widgets/auth_dialog.dart';
import '../../data/paystub_verification_repository.dart';
import '../../domain/career_track.dart';
import '../../domain/career_hierarchy.dart';
import '../../domain/paystub_verification.dart';
import '../../domain/user_profile.dart';
import '../../../community/domain/models/post.dart';
import '../../../community/domain/services/lounge_access_service.dart';
import '../cubit/profile_relations_cubit.dart';
import '../cubit/profile_timeline_cubit.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, this.targetUserId});

  final String? targetUserId; // null이면 자신의 프로필, 값이 있으면 타인의 프로필

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return BlocBuilder<AuthCubit, AuthState>(
      buildWhen: (AuthState previous, AuthState current) =>
          previous.isLoggedIn != current.isLoggedIn,
      builder: (BuildContext context, AuthState state) {
        if (!state.isLoggedIn) {
          return Scaffold(
            appBar: AppBar(
              leading: BackButton(onPressed: () => context.pop()),
              title: const Text('마이페이지'),
            ),
            body: _ProfileLoggedOut(theme: theme),
          );
        }

        return MultiBlocProvider(
          providers: [
            BlocProvider<ProfileTimelineCubit>(
              create: (_) => getIt<ProfileTimelineCubit>()..loadInitial(),
            ),
            BlocProvider<ProfileRelationsCubit>(create: (_) => getIt<ProfileRelationsCubit>()),
          ],
          child: const _ProfileLoggedInScaffold(),
        );
      },
    );
  }
}

class _ProfileLoggedOut extends StatelessWidget {
  const _ProfileLoggedOut({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 56, color: theme.colorScheme.primary),
            const Gap(12),
            Text(
              '로그인이 필요합니다',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Gap(8),
            Text(
              '프로필을 관리하려면 먼저 로그인해주세요.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const Gap(16),
            FilledButton(
              onPressed: () => _showAuthDialog(context),
              child: const Text('로그인 / 회원가입'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileLoggedInScaffold extends StatefulWidget {
  const _ProfileLoggedInScaffold();

  @override
  State<_ProfileLoggedInScaffold> createState() => _ProfileLoggedInScaffoldState();
}

class _ProfileLoggedInScaffoldState extends State<_ProfileLoggedInScaffold> {
  String? _lastShownMessage;
  DateTime? _lastMessageTime;

  void _showMessageIfDifferent(BuildContext context, String message) {
    final now = DateTime.now();

    // 같은 메시지를 1초 이내에 연속으로 표시하지 않음
    if (_lastShownMessage == message &&
        _lastMessageTime != null &&
        now.difference(_lastMessageTime!).inMilliseconds < 1000) {
      return;
    }

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.clearSnackBars(); // 큐의 모든 스낵바 제거
    scaffoldMessenger.removeCurrentSnackBar(); // 현재 스낵바도 제거

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );

    _lastShownMessage = message;
    _lastMessageTime = now;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (AuthState previous, AuthState current) =>
          previous.lastMessage != current.lastMessage && current.lastMessage != null,
      listener: (BuildContext context, AuthState state) {
        final String? message = state.lastMessage;
        if (message == null) {
          return;
        }
        _showMessageIfDifferent(context, message);
        context.read<AuthCubit>().clearLastMessage();
      },
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            leading: BackButton(onPressed: () => context.pop()),
            title: const Text('마이페이지'),
            bottom: const TabBar(
              tabs: [
                Tab(text: '프로필'),
                Tab(text: '앱 설정'),
              ],
            ),
          ),
          body: const TabBarView(children: [_ProfileOverviewTab(), _ProfileSettingsTab()]),
        ),
      ),
    );
  }
}

class _ProfileOverviewTab extends StatelessWidget {
  const _ProfileOverviewTab();

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
              _ProfileHeader(state: state, isOwnProfile: true), // 임시로 항상 자신의 프로필로 설정
              const Gap(16),
              if (state.userId != null) ...[
                _PaystubVerificationCard(uid: state.userId!),
                const Gap(16),
              ],
              _SponsorshipBanner(state: state),
              const Gap(20),
              Text(
                '라운지 타임라인',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Gap(12),
              const _TimelineSection(),
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

class _TimelineSection extends StatelessWidget {
  const _TimelineSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileTimelineCubit, ProfileTimelineState>(
      builder: (BuildContext context, ProfileTimelineState state) {
        switch (state.status) {
          case ProfileTimelineStatus.initial:
          case ProfileTimelineStatus.loading:
            return const Center(
              child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()),
            );
          case ProfileTimelineStatus.error:
            return Column(
              children: [
                Text(
                  state.errorMessage ?? '타임라인을 불러오지 못했습니다.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const Gap(12),
                OutlinedButton(
                  onPressed: () => context.read<ProfileTimelineCubit>().loadInitial(),
                  child: const Text('다시 시도'),
                ),
              ],
            );
          case ProfileTimelineStatus.refreshing:
          case ProfileTimelineStatus.loaded:
            if (state.posts.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.forum_outlined,
                          size: 48,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const Gap(16),
                      Text(
                        '아직 작성한 글이 없습니다',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Gap(8),
                      Text(
                        '라운지에서 첫 글을 작성해보세요!',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const Gap(20),
                      FilledButton.icon(
                        onPressed: () {
                          // 커뮤니티 탭으로 이동
                          DefaultTabController.of(context).animateTo(0);
                        },
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('첫 글 작성하기'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return Column(
              children: [
                ...state.posts.map(
                  (Post post) => Column(
                    children: [
                      _TimelinePostTile(post: post),
                      Divider(
                        color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
                      ),
                    ],
                  ),
                ),
                if (state.hasMore) ...[
                  const Gap(8),
                  OutlinedButton(
                    onPressed: () => context.read<ProfileTimelineCubit>().loadMore(),
                    child: state.isLoadingMore
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('더 보기'),
                  ),
                ],
              ],
            );
        }
      },
    );
  }
}

class _TimelinePostTile extends StatelessWidget {
  const _TimelinePostTile({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return InkWell(
      onTap: () => context.pushNamed(
        CommunityPostDetailRoute.name,
        pathParameters: {'postId': post.id},
        extra: post,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  post.audience == PostAudience.serial ? post.serial.toUpperCase() : '전체 공개',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(post.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const Gap(8),
            Text(
              post.text,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const Gap(8),
            Row(
              children: [
                _TimelineStat(icon: Icons.favorite_border, value: post.likeCount),
                const Gap(12),
                _TimelineStat(icon: Icons.mode_comment_outlined, value: post.commentCount),
                const Gap(12),
                _TimelineStat(icon: Icons.visibility_outlined, value: post.viewCount),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineStat extends StatelessWidget {
  const _TimelineStat({required this.icon, required this.value});

  final IconData icon;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const Gap(4),
        Text('$value', style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.state, required this.isOwnProfile});

  final AuthState state;
  final bool isOwnProfile;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    // 닉네임 마스킹 처리
    final String displayNickname = _getMaskedNickname(state.nickname, isOwnProfile);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단: 프로필 이미지, 닉네임, 액션 버튼
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProfileAvatar(photoUrl: state.photoUrl, nickname: displayNickname),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 닉네임
                      Text(
                        displayNickname,
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
                // 우측 액션 버튼
                if (isOwnProfile)
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (BuildContext context) => const ProfileEditPage(),
                        ),
                      );
                    },
                    icon: Icon(Icons.edit_outlined, color: theme.colorScheme.onSurface),
                    tooltip: '프로필 수정',
                  )
                else
                  _FollowButton(targetUserId: state.userId ?? ''),
              ],
            ),
            // 자기소개
            if (state.bio != null && state.bio!.trim().isNotEmpty) ...[
              const Gap(20),
              _BioCard(bio: state.bio!.trim()),
            ] else
              const Gap(16),
            const Gap(20),
            // 팔로워/팔로잉 통계
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: '팔로잉',
                    count: state.followingCount,
                    onTap: () => _showRelationsSheet(context, ProfileRelationType.following),
                  ),
                ),
                const Gap(16),
                Expanded(
                  child: _StatCard(
                    title: '팔로워',
                    count: state.followerCount,
                    onTap: () => _showRelationsSheet(context, ProfileRelationType.followers),
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
                  _VerificationStatusRow(
                    icon: state.isGovernmentEmailVerified ? Icons.verified : Icons.email_outlined,
                    label: '공직자 통합 메일 인증',
                    isVerified: state.isGovernmentEmailVerified,
                  ),
                  if (state.userId != null) ...[const Gap(8), _PaystubStatusRow(uid: state.userId!)],

                  // 직렬 설정 상태 (인증 완료 시에만 표시)
                  if (state.serial != 'unknown' && state.careerHierarchy != null) ...[
                    const Gap(8),
                    Row(
                      children: [
                        Icon(Icons.verified, size: 16, color: theme.colorScheme.primary),
                        const Gap(8),
                        const Expanded(
                          child: Text('직렬', style: TextStyle(color: Colors.black)),
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
                  border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.5)),
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
                      onPressed: () => _showTestCareerSelector(context),
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

  static const List<Map<String, String>> testCareers = [
    // ================================
    // 교육공무원 (Education Officials)
    // ================================

    // 초등교사
    {'id': 'elementary_teacher', 'name': '🏫 초등교사'},

    // 중등교사 - 교과별
    {'id': 'secondary_math_teacher', 'name': '📐 중등수학교사'},
    {'id': 'secondary_korean_teacher', 'name': '📖 중등국어교사'},
    {'id': 'secondary_english_teacher', 'name': '🌍 중등영어교사'},
    {'id': 'secondary_science_teacher', 'name': '🔬 중등과학교사'},
    {'id': 'secondary_social_teacher', 'name': '🌏 중등사회교사'},
    {'id': 'secondary_arts_teacher', 'name': '🎨 중등예체능교사'},

    // 유치원/특수교육교사
    {'id': 'kindergarten_teacher', 'name': '👶 유치원교사'},
    {'id': 'special_education_teacher', 'name': '🤝 특수교육교사'},

    // 비교과 교사
    {'id': 'counselor_teacher', 'name': '💬 상담교사'},
    {'id': 'health_teacher', 'name': '🏥 보건교사'},
    {'id': 'librarian_teacher', 'name': '📚 사서교사'},
    {'id': 'nutrition_teacher', 'name': '🍎 영양교사'},

    // ================================
    // 일반행정직 (General Administrative)
    // ================================

    // 국가직
    {'id': 'admin_9th_national', 'name': '📋 9급 국가행정직'},
    {'id': 'admin_7th_national', 'name': '📊 7급 국가행정직'},
    {'id': 'admin_5th_national', 'name': '💼 5급 국가행정직'},

    // 지방직
    {'id': 'admin_9th_local', 'name': '📋 9급 지방행정직'},
    {'id': 'admin_7th_local', 'name': '📊 7급 지방행정직'},
    {'id': 'admin_5th_local', 'name': '💼 5급 지방행정직'},

    // 세무·관세
    {'id': 'tax_officer', 'name': '💰 세무직'},
    {'id': 'customs_officer', 'name': '🛃 관세직'},

    // ================================
    // 전문행정직 (Specialized Administrative)
    // ================================

    {'id': 'job_counselor', 'name': '💼 고용노동직'},
    {'id': 'statistics_officer', 'name': '📊 통계직'},
    {'id': 'librarian', 'name': '📖 사서직'},
    {'id': 'auditor', 'name': '🔍 감사직'},
    {'id': 'security_officer', 'name': '🔐 방호직'},

    // ================================
    // 보건복지직 (Health & Welfare)
    // ================================

    {'id': 'public_health_officer', 'name': '🏥 보건직'},
    {'id': 'medical_technician', 'name': '🔬 의료기술직'},
    {'id': 'nurse', 'name': '💉 간호직'},
    {'id': 'medical_officer', 'name': '⚕️ 의무직'},
    {'id': 'pharmacist', 'name': '💊 약무직'},
    {'id': 'food_sanitation', 'name': '🍽️ 식품위생직'},
    {'id': 'social_worker', 'name': '🤲 사회복지직'},

    // ================================
    // 공안직 (Public Security)
    // ================================

    {'id': 'correction_officer', 'name': '⚖️ 교정직'},
    {'id': 'probation_officer', 'name': '👁️ 보호직'},
    {'id': 'prosecution_officer', 'name': '⚖️ 검찰직'},
    {'id': 'drug_investigation_officer', 'name': '🔬 마약수사직'},
    {'id': 'immigration_officer', 'name': '🛂 출입국관리직'},
    {'id': 'railroad_police', 'name': '🚄 철도경찰직'},
    {'id': 'security_guard', 'name': '🛡️ 경위직'},

    // ================================
    // 치안/안전 (Public Safety)
    // ================================

    {'id': 'police', 'name': '👮‍♂️ 경찰관'},
    {'id': 'firefighter', 'name': '👨‍🚒 소방관'},
    {'id': 'coast_guard', 'name': '🌊 해양경찰'},

    // ================================
    // 군인 (Military)
    // ================================

    {'id': 'army', 'name': '🪖 육군'},
    {'id': 'navy', 'name': '⚓ 해군'},
    {'id': 'air_force', 'name': '✈️ 공군'},
    {'id': 'military_civilian', 'name': '🎖️ 군무원'},

    // ================================
    // 기술직 (Technical Tracks)
    // ================================

    // 공업직 (대표)
    {'id': 'mechanical_engineer', 'name': '⚙️ 기계직'},
    {'id': 'electrical_engineer', 'name': '⚡ 전기직'},
    {'id': 'electronics_engineer', 'name': '📡 전자직'},
    {'id': 'chemical_engineer', 'name': '🧪 화공직'},

    // 시설환경직 (대표)
    {'id': 'civil_engineer', 'name': '🏗️ 토목직'},
    {'id': 'architect', 'name': '🏛️ 건축직'},
    {'id': 'environmental_officer', 'name': '🌱 환경직'},

    // 농림수산직 (대표)
    {'id': 'agriculture_officer', 'name': '🌾 농업직'},
    {'id': 'fisheries_officer', 'name': '🐟 수산직'},
    {'id': 'veterinarian', 'name': '🐾 수의직'},

    // IT통신직
    {'id': 'computer_officer', 'name': '💻 전산직'},
    {'id': 'broadcasting_communication', 'name': '📺 방송통신직'},

    // 관리운영직
    {'id': 'facility_management', 'name': '🏢 시설관리직'},
    {'id': 'sanitation_worker', 'name': '🧹 위생직'},
    {'id': 'cook', 'name': '👨‍🍳 조리직'},

    // ================================
    // 기타 직렬 (Others)
    // ================================

    {'id': 'postal_service', 'name': '📮 우정직'},
    {'id': 'researcher', 'name': '🔬 연구직'},

    // ================================
    // Fallback / Reset
    // ================================

    {'id': 'none', 'name': '❌ 직렬 없음 (기본)'},
  ];

  void _showTestCareerSelector(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    '테스트용 직렬 선택',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                const Divider(height: 1),
                ...testCareers.map((career) {
                  return ListTile(
                    title: Text(career['name']!),
                    subtitle: Text('ID: ${career['id']}'),
                    onTap: () {
                      Navigator.pop(context);
                      _updateTestCareer(context, career['id']!);
                    },
                  );
                }),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _updateTestCareer(BuildContext context, String careerId) async {
    try {
      final AuthCubit authCubit = context.read<AuthCubit>();
      final String? userId = authCubit.state.userId;

      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('로그인이 필요합니다')));
        return;
      }

      // CareerHierarchy 생성
      CareerHierarchy? careerHierarchy;
      List<String> accessibleLoungeIds = ['all']; // 기본값
      String defaultLoungeId = 'all';

      if (careerId != 'none') {
        careerHierarchy = CareerHierarchy.fromSpecificCareer(careerId);

        // LoungeAccessService를 사용하여 접근 가능한 라운지 ID 생성
        final accessibleLounges = LoungeAccessService.getAccessibleLounges(careerHierarchy);
        accessibleLoungeIds = accessibleLounges.map((lounge) => lounge.id).toList();

        // 기본 라운지는 LoungeAccessService를 통해 가져옴
        defaultLoungeId = LoungeAccessService.getDefaultLoungeId(careerHierarchy);
      }

      // Firestore 직접 업데이트
      // 테스트 모드에서는 testModeCareer 필드에 직렬 정보 저장
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'careerHierarchy': careerHierarchy?.toMap(),
        'accessibleLoungeIds': accessibleLoungeIds,
        'defaultLoungeId': defaultLoungeId,
        'testModeCareer': careerHierarchy?.toMap(), // 테스트 모드 직렬 정보
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // AuthCubit 새로고침
      await authCubit.refreshAuthStatus();

      if (context.mounted) {
        final careerName = testCareers.firstWhere(
          (c) => c['id'] == careerId,
          orElse: () => {'name': careerId},
        )['name'];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('테스트 직렬이 "$careerName"(으)로 설정되었습니다'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('오류가 발생했습니다: $e')));
      }
    }
  }
}

// 새로운 위젯들
class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.count, required this.onTap});

  final String title;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final IconData icon = title == '팔로잉' ? Icons.people_outline : Icons.favorite_border;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            const Gap(6),
            Text(
              '$count',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const Gap(2),
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BioCard extends StatefulWidget {
  const _BioCard({required this.bio});

  final String bio;

  @override
  State<_BioCard> createState() => _BioCardState();
}

class _BioCardState extends State<_BioCard> {
  bool _isExpanded = false;
  static const int _maxLines = 3;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isLongText = widget.bio.length > 100;

    return Container(
      width: double.infinity,
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
                Icons.chat_bubble_outline,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const Gap(8),
              Text(
                '자기소개',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const Gap(12),
          Text(
            widget.bio,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: _isExpanded ? null : _maxLines,
            overflow: _isExpanded ? null : TextOverflow.ellipsis,
          ),
          if (isLongText) ...[
            const Gap(8),
            InkWell(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isExpanded ? '접기' : '더보기',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Gap(4),
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _VerificationStatusRow extends StatelessWidget {
  const _VerificationStatusRow({required this.icon, required this.label, required this.isVerified});

  final IconData icon;
  final String label;
  final bool isVerified;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: isVerified ? theme.colorScheme.primary : theme.colorScheme.error,
        ),
        const Gap(8),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface),
          ),
        ),
        Text(
          isVerified ? '인증됨' : '미인증',
          style: theme.textTheme.bodySmall?.copyWith(
            color: isVerified ? theme.colorScheme.primary : theme.colorScheme.error,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _PaystubStatusRow extends StatelessWidget {
  const _PaystubStatusRow({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    final PaystubVerificationRepository repository = getIt<PaystubVerificationRepository>();
    final ThemeData theme = Theme.of(context);

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> userSnapshot) {
        // 테스트 모드 직렬이 설정되어 있으면 인증됨으로 표시
        bool isTestModeVerified = false;
        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          final data = userSnapshot.data!.data() as Map<String, dynamic>?;
          isTestModeVerified = data != null && data['testModeCareer'] != null;
        }

        if (isTestModeVerified) {
          return Row(
            children: [
              Icon(
                Icons.verified,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const Gap(8),
              Expanded(
                child: Text(
                  '직렬 인증',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface),
                ),
              ),
              Text(
                '인증됨',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );
        }

        return StreamBuilder<PaystubVerification>(
          stream: repository.watchVerification(uid),
          builder: (BuildContext context, AsyncSnapshot<PaystubVerification> snapshot) {
            final PaystubVerification verification = snapshot.data ?? PaystubVerification.none;

            return Row(
              children: [
                Icon(
                  verification.status == PaystubVerificationStatus.verified
                      ? Icons.verified
                      : verification.status == PaystubVerificationStatus.processing
                      ? Icons.hourglass_empty
                      : Icons.description_outlined,
                  size: 16,
                  color: verification.status == PaystubVerificationStatus.verified
                      ? theme.colorScheme.primary
                      : verification.status == PaystubVerificationStatus.processing
                      ? theme.colorScheme.tertiary
                      : theme.colorScheme.error,
                ),
                const Gap(8),
                Expanded(
                  child: Text(
                    '직렬 인증',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface),
                  ),
                ),
                Text(
                  verification.status == PaystubVerificationStatus.verified
                      ? '인증됨'
                      : verification.status == PaystubVerificationStatus.processing
                      ? '검토중'
                      : '미인증',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: verification.status == PaystubVerificationStatus.verified
                        ? theme.colorScheme.primary
                        : verification.status == PaystubVerificationStatus.processing
                        ? theme.colorScheme.tertiary
                        : theme.colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.photoUrl, required this.nickname});

  final String? photoUrl;
  final String nickname;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return CircleAvatar(
      radius: 32,
      backgroundColor: photoUrl != null && photoUrl!.isNotEmpty
          ? Colors.transparent
          : theme.colorScheme.primaryContainer,
      backgroundImage: photoUrl != null && photoUrl!.isNotEmpty
          ? CachedNetworkImageProvider(photoUrl!)
          : null,
      child: photoUrl == null || photoUrl!.isEmpty
          ? Text(
              nickname.isEmpty ? '?' : nickname.characters.first,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            )
          : null,
    );
  }
}

class _ProfileSettingsTab extends StatefulWidget {
  const _ProfileSettingsTab();

  @override
  State<_ProfileSettingsTab> createState() => _ProfileSettingsTabState();
}

class _ProfileSettingsTabState extends State<_ProfileSettingsTab> {
  late final TextEditingController _currentPasswordController;
  late final TextEditingController _newPasswordController;
  late final TextEditingController _confirmPasswordController;
  late final TextEditingController _deletePasswordController;

  // 알림 설정 상태
  bool _likeNotifications = true;
  bool _commentNotifications = true;
  bool _followNotifications = true;

  @override
  void initState() {
    super.initState();
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _deletePasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _snackBarTimer?.cancel();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _deletePasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (BuildContext context, AuthState state) {
        final bool isProcessing = state.isProcessing;
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [
            _SettingsSection(
              title: '알림 설정',
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.only(left: 16),
                  leading: const Icon(Icons.notifications_outlined, size: 20),
                  title: const Text('전체 알림'),
                  subtitle: const Text('모든 알림을 받을지 설정합니다.'),
                  trailing: Switch.adaptive(
                    value: state.notificationsEnabled,
                    onChanged: isProcessing
                        ? null
                        : (bool value) =>
                              context.read<AuthCubit>().updateNotificationsEnabled(value),
                  ),
                ),
                const Divider(),
                ListTile(
                  contentPadding: const EdgeInsets.only(left: 16),
                  leading: Icon(
                    Icons.favorite_outline,
                    size: 20,
                    color: state.notificationsEnabled
                        ? null
                        : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  title: Text(
                    '좋아요 알림',
                    style: TextStyle(
                      color: state.notificationsEnabled
                          ? null
                          : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  subtitle: Text(
                    '내 게시물에 좋아요가 달렸을 때',
                    style: TextStyle(
                      color: state.notificationsEnabled
                          ? null
                          : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  trailing: Switch.adaptive(
                    value: state.notificationsEnabled ? _likeNotifications : false,
                    onChanged: (isProcessing || !state.notificationsEnabled)
                        ? null
                        : (value) {
                            setState(() {
                              _likeNotifications = value;
                            });
                            // SharedPreferences 저장 로직은 향후 구현 예정
                          },
                  ),
                ),
                ListTile(
                  contentPadding: const EdgeInsets.only(left: 16),
                  leading: Icon(
                    Icons.comment_outlined,
                    size: 20,
                    color: state.notificationsEnabled
                        ? null
                        : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  title: Text(
                    '댓글 알림',
                    style: TextStyle(
                      color: state.notificationsEnabled
                          ? null
                          : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  subtitle: Text(
                    '내 게시물에 댓글이 달렸을 때',
                    style: TextStyle(
                      color: state.notificationsEnabled
                          ? null
                          : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  trailing: Switch.adaptive(
                    value: state.notificationsEnabled ? _commentNotifications : false,
                    onChanged: (isProcessing || !state.notificationsEnabled)
                        ? null
                        : (value) {
                            setState(() {
                              _commentNotifications = value;
                            });
                            // SharedPreferences 저장 로직은 향후 구현 예정
                          },
                  ),
                ),
                ListTile(
                  contentPadding: const EdgeInsets.only(left: 16),
                  leading: Icon(
                    Icons.person_add_outlined,
                    size: 20,
                    color: state.notificationsEnabled
                        ? null
                        : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  title: Text(
                    '팔로우 알림',
                    style: TextStyle(
                      color: state.notificationsEnabled
                          ? null
                          : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  subtitle: Text(
                    '새로운 팔로워가 생겼을 때',
                    style: TextStyle(
                      color: state.notificationsEnabled
                          ? null
                          : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  trailing: Switch.adaptive(
                    value: state.notificationsEnabled ? _followNotifications : false,
                    onChanged: (isProcessing || !state.notificationsEnabled)
                        ? null
                        : (value) {
                            setState(() {
                              _followNotifications = value;
                            });
                            // SharedPreferences 저장 로직은 향후 구현 예정
                          },
                  ),
                ),
              ],
            ),
            const Gap(16),
            _SettingsSection(
              title: '비밀번호 변경',
              children: [
                TextField(
                  controller: _currentPasswordController,
                  obscureText: true,
                  enabled: !isProcessing,
                  decoration: const InputDecoration(labelText: '현재 비밀번호'),
                ),
                const Gap(12),
                TextField(
                  controller: _newPasswordController,
                  obscureText: true,
                  enabled: !isProcessing,
                  decoration: const InputDecoration(labelText: '새 비밀번호'),
                ),
                const Gap(12),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  enabled: !isProcessing,
                  decoration: const InputDecoration(labelText: '새 비밀번호 확인'),
                ),
                const Gap(12),
                FilledButton(
                  onPressed: isProcessing
                      ? null
                      : () async {
                          final String currentPassword = _currentPasswordController.text.trim();
                          final String newPassword = _newPasswordController.text.trim();
                          final String confirmPassword = _confirmPasswordController.text.trim();
                          if (currentPassword.isEmpty ||
                              newPassword.isEmpty ||
                              confirmPassword.isEmpty) {
                            _showMessage(context, '비밀번호를 모두 입력해주세요.');
                            return;
                          }
                          if (newPassword != confirmPassword) {
                            _showMessage(context, '새 비밀번호가 일치하지 않습니다.');
                            return;
                          }
                          await context.read<AuthCubit>().changePassword(
                            currentPassword: currentPassword,
                            newPassword: newPassword,
                          );
                          if (mounted) {
                            _currentPasswordController.clear();
                            _newPasswordController.clear();
                            _confirmPasswordController.clear();
                          }
                        },
                  child: const Text('비밀번호 변경'),
                ),
              ],
            ),
            const Gap(16),
            _SettingsSection(
              title: '고객 지원',
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.feedback_outlined),
                  title: const Text('피드백 보내기'),
                  subtitle: const Text('개선 사항이나 문제를 신고해주세요.'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showFeedbackDialog(context),
                ),
              ],
            ),
            const Gap(16),
            _SettingsSection(
              title: '개인정보 및 약관',
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('개인정보 처리방침'),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => _launchUrl('https://www.hanisoft.kr/privacy'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('서비스 이용약관'),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => _launchUrl('https://www.hanisoft.kr/terms'),
                ),
              ],
            ),
            const Gap(16),
            _SettingsSection(
              title: '앱 정보',
              children: [
                FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snapshot) {
                    final String versionText = snapshot.hasData
                        ? '${snapshot.data!.version} (빌드 ${snapshot.data!.buildNumber})'
                        : '1.0.0 (빌드 1)';
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.info_outline),
                      title: const Text('버전 정보'),
                      subtitle: Text(versionText),
                      onTap: () => _showVersionInfo(context),
                    );
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.code_outlined),
                  title: const Text('개발자 정보'),
                  subtitle: const Text('HANISOFT'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showDeveloperInfo(context),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.code),
                  title: const Text('오픈소스 라이선스'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showLicenses(context),
                ),
              ],
            ),
            const Gap(16),
            _SettingsSection(
              title: '계정 관리',
              children: [
                FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.errorContainer,
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                  onPressed: isProcessing ? null : () => _confirmDeleteAccount(context),
                  child: const Text('회원 탈퇴'),
                ),
              ],
            ),
            const Gap(16),
          ],
        );
      },
    );
  }

  void _confirmDeleteAccount(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('회원 탈퇴'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('탈퇴를 진행하려면 비밀번호를 입력해주세요.'),
              const Gap(12),
              TextField(
                controller: _deletePasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: '비밀번호'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('취소')),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.errorContainer,
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () async {
                final String password = _deletePasswordController.text.trim();
                final AuthCubit authCubit = context.read<AuthCubit>();
                final NavigatorState navigator = Navigator.of(context);
                await authCubit.deleteAccount(currentPassword: password.isEmpty ? null : password);
                if (!mounted) {
                  return;
                }
                navigator.pop();
                _deletePasswordController.clear();
              },
              child: const Text('탈퇴하기'),
            ),
          ],
        );
      },
    );
  }

  Timer? _snackBarTimer;

  void _showMessage(BuildContext context, String message) {
    // 이전 타이머 취소
    _snackBarTimer?.cancel();

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // 즉시 이전 스낵바 제거
    scaffoldMessenger.removeCurrentSnackBar();

    // 짧은 지연 후 새 스낵바 표시 (연속 호출 방지)
    _snackBarTimer = Timer(const Duration(milliseconds: 100), () {
      if (context.mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  void _showFeedbackDialog(BuildContext context) {
    final TextEditingController feedbackController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('피드백 보내기'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('개선 사항이나 문제점을 알려주세요.'),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: feedbackController,
                      maxLines: 5,
                      enabled: !isLoading,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '피드백 내용을 입력해주세요.';
                        }
                        if (value.trim().length < 10) {
                          return '10글자 이상 입력해주세요.';
                        }
                        return null;
                      },
                      decoration: const InputDecoration(
                        hintText: '의견을 자유롭게 작성해주세요...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                  child: const Text('취소'),
                ),
                FilledButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (formKey.currentState?.validate() ?? false) {
                            setState(() => isLoading = true);
                            try {
                              await _sendFeedbackEmail(feedbackController.text.trim());
                              if (context.mounted) {
                                Navigator.of(context).pop();
                                _showMessage(context, '피드백이 전송되었습니다. 감사합니다!');
                              }
                            } catch (error) {
                              if (context.mounted) {
                                setState(() => isLoading = false);
                                _showMessage(context, '피드백 전송 중 오류가 발생했습니다: $error');
                              }
                            }
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('전송'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _sendFeedbackEmail(String feedback) async {
    final AuthState authState = context.read<AuthCubit>().state;
    final String userEmail = authState.email ?? 'anonymous@example.com';
    final String userName = authState.nickname.isNotEmpty ? authState.nickname : '익명 사용자';

    // 이메일 제목과 본문 구성
    final String subject = Uri.encodeComponent('[공무톡] 사용자 피드백');
    final String body = Uri.encodeComponent('''
안녕하세요, 공무톡 개발팀입니다.

사용자로부터 다음과 같은 피드백을 받았습니다.

--- 사용자 정보 ---
이름: $userName
이메일: $userEmail
작성 시간: ${DateTime.now().toString()}

--- 피드백 내용 ---
$feedback

---
이 메시지는 공무톡 앱에서 자동으로 생성되었습니다.
    ''');

    // mailto URL 구성
    final String mailtoUrl = 'mailto:hanisoft2022@gmail.com?subject=$subject&body=$body';
    final Uri uri = Uri.parse(mailtoUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw Exception('이메일 앱을 열 수 없습니다. 기기에 이메일 앱이 설치되어 있는지 확인해주세요.');
    }
  }

  Future<void> _launchUrl(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          _showMessage(context, 'URL을 열 수 없습니다: $url');
        }
      }
    } catch (error) {
      if (mounted) {
        _showMessage(context, 'URL을 여는 중 오류가 발생했습니다: $error');
      }
    }
  }

  void _showVersionInfo(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return FutureBuilder<PackageInfo>(
          future: PackageInfo.fromPlatform(),
          builder: (context, snapshot) {
            final PackageInfo? packageInfo = snapshot.data;

            return AlertDialog(
              title: const Text('버전 정보'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('앱 이름: ${packageInfo?.appName ?? '공무톡'}'),
                  Text('앱 버전: ${packageInfo?.version ?? '1.0.0'}'),
                  Text('빌드 번호: ${packageInfo?.buildNumber ?? '1'}'),
                  Text('패키지명: ${packageInfo?.packageName ?? 'kr.hanisoft.gong_mu_talk'}'),
                  const SizedBox(height: 16),
                  const Text('최신 버전을 사용 중입니다.'),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('확인')),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeveloperInfo(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('개발자 정보'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('개발사: HANISOFT'),
              Text('이메일: contact@hanisoft.kr'),
              SizedBox(height: 16),
              Text('공무톡은 공무원을 위한 종합 서비스 플랫폼입니다.'),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('확인')),
          ],
        );
      },
    );
  }

  void _showLicenses(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (BuildContext context) => const _CustomLicensePage()));
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const Gap(12),
        ...children,
      ],
    );
  }
}

void _showRelationsSheet(BuildContext context, ProfileRelationType type) {
  final ProfileRelationsCubit cubit = context.read<ProfileRelationsCubit>();
  cubit.load(type);

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext context) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (BuildContext context, ScrollController controller) {
          return BlocBuilder<ProfileRelationsCubit, ProfileRelationsState>(
            builder: (BuildContext context, ProfileRelationsState state) {
              return Column(
                children: [
                  Container(
                    width: 48,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          state.type == ProfileRelationType.followers ? '팔로워' : '팔로잉',
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Builder(
                      builder: (BuildContext context) {
                        if (state.status == ProfileRelationsStatus.loading ||
                            state.status == ProfileRelationsStatus.refreshing) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (state.status == ProfileRelationsStatus.error) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(state.errorMessage ?? '목록을 불러오지 못했습니다.'),
                                const Gap(12),
                                OutlinedButton(
                                  onPressed: () => cubit.load(state.type),
                                  child: const Text('다시 시도'),
                                ),
                              ],
                            ),
                          );
                        }
                        if (state.users.isEmpty) {
                          return Center(
                            child: Text(
                              state.type == ProfileRelationType.followers
                                  ? '아직 나를 팔로우한 사용자가 없습니다.'
                                  : '아직 팔로우 중인 사용자가 없습니다.',
                            ),
                          );
                        }
                        return NotificationListener<ScrollNotification>(
                          onNotification: (ScrollNotification notification) {
                            if (notification.metrics.pixels >=
                                    notification.metrics.maxScrollExtent - 120 &&
                                !state.isLoadingMore &&
                                state.hasMore) {
                              cubit.loadMore();
                            }
                            return false;
                          },
                          child: ListView.separated(
                            controller: controller,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            itemBuilder: (BuildContext context, int index) {
                              final UserProfile profile = state.users[index];
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  radius: 22,
                                  backgroundImage: profile.photoUrl == null
                                      ? null
                                      : CachedNetworkImageProvider(profile.photoUrl!),
                                  child: profile.photoUrl == null
                                      ? Text(profile.nickname.characters.first)
                                      : null,
                                ),
                                title: Text(profile.nickname),
                                subtitle: Text(
                                  profile.bio?.isEmpty ?? true
                                      ? '${profile.careerTrack.displayName} · ${profile.region}'
                                      : profile.bio!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: state.type == ProfileRelationType.following
                                    ? TextButton(
                                        onPressed: () => cubit.unfollow(profile.uid),
                                        child: const Text('언팔로우'),
                                      )
                                    : null,
                                onTap: null,
                              );
                            },
                            separatorBuilder: (_, __) => const Divider(),
                            itemCount: state.users.length,
                          ),
                        );
                      },
                    ),
                  ),
                  if (state.isLoadingMore)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: CircularProgressIndicator(),
                    ),
                ],
              );
            },
          );
        },
      );
    },
  );
}

void _showAuthDialog(BuildContext context) {
  showDialog<void>(context: context, builder: (_) => const AuthDialog());
}

class _FollowButton extends StatefulWidget {
  const _FollowButton({required this.targetUserId});

  final String targetUserId;

  @override
  State<_FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<_FollowButton> {
  bool _isFollowing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkFollowStatus();
  }

  Future<void> _checkFollowStatus() async {
    try {
      final authState = context.read<AuthCubit>().state;
      final currentUserId = authState.userId;

      if (currentUserId == null || currentUserId == widget.targetUserId) {
        setState(() {
          _isFollowing = false;
        });
        return;
      }

      // Firestore에서 팔로우 관계 확인
      final followDoc = await FirebaseFirestore.instance
          .collection('follows')
          .doc('${currentUserId}_${widget.targetUserId}')
          .get();

      if (mounted) {
        setState(() {
          _isFollowing = followDoc.exists;
        });
      }
    } catch (error) {
      // 에러 발생 시 기본값으로 설정
      if (mounted) {
        setState(() {
          _isFollowing = false;
        });
      }
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _toggleFollow() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authState = context.read<AuthCubit>().state;
      final currentUserId = authState.userId;

      if (currentUserId == null || currentUserId == widget.targetUserId) {
        throw Exception('잘못된 요청입니다.');
      }

      final db = FirebaseFirestore.instance;
      final followDocId = '${currentUserId}_${widget.targetUserId}';

      if (_isFollowing) {
        // 언팔로우: Firestore에서 팔로우 관계 삭제
        await db.runTransaction((transaction) async {
          // follows 컬렉션에서 삭제
          transaction.delete(db.collection('follows').doc(followDocId));

          // 팔로워 카운트 감소
          final targetUserRef = db.collection('users').doc(widget.targetUserId);
          transaction.update(targetUserRef, {'followerCount': FieldValue.increment(-1)});

          // 팔로잉 카운트 감소
          final currentUserRef = db.collection('users').doc(currentUserId);
          transaction.update(currentUserRef, {'followingCount': FieldValue.increment(-1)});
        });
      } else {
        // 팔로우: Firestore에 팔로우 관계 추가
        await db.runTransaction((transaction) async {
          // follows 컬렉션에 추가
          transaction.set(db.collection('follows').doc(followDocId), {
            'followerId': currentUserId,
            'followingId': widget.targetUserId,
            'createdAt': FieldValue.serverTimestamp(),
          });

          // 팔로워 카운트 증가
          final targetUserRef = db.collection('users').doc(widget.targetUserId);
          transaction.update(targetUserRef, {'followerCount': FieldValue.increment(1)});

          // 팔로잉 카운트 증가
          final currentUserRef = db.collection('users').doc(currentUserId);
          transaction.update(currentUserRef, {'followingCount': FieldValue.increment(1)});
        });
      }

      setState(() {
        _isFollowing = !_isFollowing;
      });

      if (mounted) {
        _showMessage(context, _isFollowing ? '팔로우했습니다' : '팔로우를 취소했습니다');
      }
    } catch (error) {
      if (mounted) {
        _showMessage(context, '오류가 발생했습니다: $error');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return IconButton(
      onPressed: _isLoading ? null : _toggleFollow,
      icon: _isLoading
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          : Icon(
              _isFollowing ? Icons.person_remove_outlined : Icons.person_add_outlined,
              color: _isFollowing ? theme.colorScheme.error : theme.colorScheme.primary,
            ),
      tooltip: _isFollowing ? '팔로우 취소' : '팔로우',
    );
  }
}

String _formatDate(DateTime dateTime) {
  final DateTime now = DateTime.now();
  final Duration difference = now.difference(dateTime);
  if (difference.inMinutes.abs() < 1) {
    return '방금';
  }
  if (difference.inMinutes < 60) {
    return '${difference.inMinutes}분 전';
  }
  if (difference.inHours < 24) {
    return '${difference.inHours}시간 전';
  }
  if (difference.inDays < 7) {
    return '${difference.inDays}일 전';
  }
  return '${dateTime.year}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.day.toString().padLeft(2, '0')}';
}

String _getMaskedNickname(String nickname, bool isOwnProfile) {
  if (isOwnProfile || nickname.isEmpty) {
    return nickname;
  }

  // 다른 사람의 프로필: 첫 글자 + ***
  final String firstChar = nickname.characters.first;
  return '$firstChar***';
}

class _SponsorshipBanner extends StatelessWidget {
  const _SponsorshipBanner({required this.state});

  final AuthState state;

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

// 새로운 프로필 편집 화면
class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  late final TextEditingController _nicknameController;
  late final TextEditingController _bioController;

  // 토글 처리 중 상태
  bool _isUpdatingSerialVisibility = false;

  @override
  void initState() {
    super.initState();
    final AuthState state = context.read<AuthCubit>().state;
    _nicknameController = TextEditingController(text: state.nickname);
    _bioController = TextEditingController(text: state.bio ?? '');
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (AuthState previous, AuthState current) =>
          previous.nickname != current.nickname || previous.bio != current.bio,
      listener: (BuildContext context, AuthState state) {
        _nicknameController.text = state.nickname;
        _bioController.text = state.bio ?? '';
      },
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (BuildContext context, AuthState state) {
          final bool isProcessing = state.isProcessing;

          return Scaffold(
            appBar: AppBar(
              leading: BackButton(onPressed: () => context.pop()),
              title: const Text('프로필 편집'),
              actions: [
                TextButton(
                  onPressed: isProcessing ? null : _saveProfile,
                  child: Text(
                    '저장',
                    style: TextStyle(
                      color: isProcessing
                          ? Theme.of(context).colorScheme.onSurfaceVariant
                          : Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            body: SafeArea(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                children: [
                  // 프로필 이미지 섹션
                  _ProfileImageSection(
                    photoUrl: state.photoUrl,
                    nickname: state.nickname,
                    isProcessing: isProcessing,
                  ),
                  const Gap(24),

                  // 닉네임 섹션
                  _ProfileEditSection(
                    title: '닉네임',
                    child: TextField(
                      controller: _nicknameController,
                      enabled: !isProcessing,
                      maxLength: 20,
                      decoration: const InputDecoration(
                        hintText: '닉네임을 입력하세요',
                        counterText: '',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const Gap(24),

                  // 자기소개 섹션
                  _ProfileEditSection(
                    title: '자기소개',
                    child: TextField(
                      controller: _bioController,
                      enabled: !isProcessing,
                      maxLines: 5,
                      maxLength: 300,
                      decoration: const InputDecoration(
                        hintText: '자신을 소개해보세요',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const Gap(24),

                  // 테마 설정 섹션
                  _ProfileEditSection(
                    title: '화면 및 테마',
                    child: _ThemeSettingsSection(isProcessing: isProcessing),
                  ),
                  const Gap(24),

                  // 공개 설정 섹션
                  _ProfileEditSection(
                    title: '공개 설정',
                    child: Column(
                      children: [
                        SwitchListTile.adaptive(
                          value: state.serialVisible,
                          onChanged: (isProcessing || _isUpdatingSerialVisibility)
                              ? null
                              : (bool value) async {
                                  setState(() => _isUpdatingSerialVisibility = true);
                                  try {
                                    await context.read<AuthCubit>().updateSerialVisibility(value);
                                  } finally {
                                    if (mounted) {
                                      setState(() => _isUpdatingSerialVisibility = false);
                                    }
                                  }
                                },
                          title: const Text('직렬 공개'),
                          subtitle: const Text('라운지와 댓글에 내 직렬을 표시할지 선택할 수 있습니다.'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _saveProfile() async {
    final String nickname = _nicknameController.text.trim();
    final String bio = _bioController.text.trim();

    if (nickname.isEmpty) {
      _showMessage(context, '닉네임을 입력해주세요.');
      return;
    }

    final AuthCubit authCubit = context.read<AuthCubit>();
    final AuthState currentState = authCubit.state;

    try {
      // 닉네임이 변경된 경우
      if (nickname != currentState.nickname) {
        await authCubit.updateNickname(nickname);
      }

      // 자기소개가 변경된 경우
      if (bio != (currentState.bio ?? '')) {
        await authCubit.updateBio(bio);
      }

      if (mounted) {
        _showMessage(context, '프로필이 저장되었습니다.');
        context.pop();
      }
    } catch (error) {
      if (mounted) {
        _showMessage(context, '저장 중 오류가 발생했습니다: $error');
      }
    }
  }
}

class _ProfileEditSection extends StatelessWidget {
  const _ProfileEditSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const Gap(8),
        child,
      ],
    );
  }
}

class _ProfileImageSection extends StatelessWidget {
  const _ProfileImageSection({
    required this.photoUrl,
    required this.nickname,
    required this.isProcessing,
  });

  final String? photoUrl;
  final String nickname;
  final bool isProcessing;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      children: [
        _ProfileAvatar(photoUrl: photoUrl, nickname: nickname),
        const Gap(12),
        TextButton.icon(
          onPressed: isProcessing ? null : () => _showImagePicker(context),
          icon: Icon(Icons.camera_alt_outlined, size: 18, color: theme.colorScheme.primary),
          label: Text(
            '프로필 사진 변경',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary),
          ),
        ),
      ],
    );
  }

  Future<void> _showImagePicker(BuildContext context) async {
    final ThemeData theme = Theme.of(context);
    final bool hasProfileImage = (photoUrl != null && photoUrl!.isNotEmpty);

    await showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('앨범에서 선택'),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  await _pickImageFromGallery(context);
                },
              ),
              if (hasProfileImage)
                ListTile(
                  leading: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                  title: Text('기본 이미지로 변경', style: TextStyle(color: theme.colorScheme.error)),
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    await context.read<AuthCubit>().removeProfileImage();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImageFromGallery(BuildContext context) async {
    final AuthCubit authCubit = context.read<AuthCubit>();
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result == null) return;

      final PlatformFile file = result.files.single;
      final Uint8List? bytes = file.bytes;
      if (bytes == null) {
        throw PlatformException(code: 'bytes-unavailable', message: '선택한 파일 데이터를 불러오지 못했습니다.');
      }

      final String extension = (file.extension ?? '').toLowerCase();
      final String contentType = extension.isNotEmpty ? 'image/$extension' : 'image/jpeg';

      await authCubit.updateProfileImage(
        bytes: bytes,
        fileName: file.name,
        contentType: contentType,
      );
    } on PlatformException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('이미지를 불러오지 못했습니다: ${error.message}'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

// --- Existing components reused below ---

class _PaystubVerificationCard extends StatefulWidget {
  const _PaystubVerificationCard({required this.uid});

  final String uid;

  @override
  State<_PaystubVerificationCard> createState() => _PaystubVerificationCardState();
}

class _PaystubVerificationCardState extends State<_PaystubVerificationCard> {
  PaystubVerificationRepository get _repository => getIt<PaystubVerificationRepository>();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(widget.uid).snapshots(),
      builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> userSnapshot) {
        // 테스트 모드 직렬이 설정되어 있으면 카드 숨김
        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          final data = userSnapshot.data!.data() as Map<String, dynamic>?;
          if (data != null && data['testModeCareer'] != null) {
            return const SizedBox.shrink();
          }
        }

        return StreamBuilder<PaystubVerification>(
          stream: _repository.watchVerification(widget.uid),
          builder: (BuildContext context, AsyncSnapshot<PaystubVerification> snapshot) {
            final PaystubVerification verification = snapshot.data ?? PaystubVerification.none;
            final bool isProcessingTimedOut = _isProcessingTimedOut(verification);

            // 인증 완료 시 카드 숨김
            if (verification.status == PaystubVerificationStatus.verified) {
              return const SizedBox.shrink();
            }

            return Card(
              child: InkWell(
                onTap: verification.status == PaystubVerificationStatus.none ||
                        (verification.status == PaystubVerificationStatus.processing &&
                            isProcessingTimedOut)
                    ? () => context.push('/profile/verify-paystub')
                    : null,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: verification.status == PaystubVerificationStatus.processing
                              ? Colors.orange.withValues(alpha: 0.1)
                              : theme.colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          verification.status == PaystubVerificationStatus.processing
                              ? Icons.hourglass_empty
                              : Icons.verified_user,
                          color: verification.status == PaystubVerificationStatus.processing
                              ? Colors.orange.shade700
                              : theme.colorScheme.primary,
                          size: 24,
                        ),
                      ),
                      const Gap(16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '직렬 인증',
                              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const Gap(4),
                            Text(
                              verification.status == PaystubVerificationStatus.processing
                                  ? '인증 처리 중입니다 (1-2일 소요)'
                                  : '전문 라운지를 이용하려면 직렬 인증이 필요합니다',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Gap(8),
                      if (verification.status == PaystubVerificationStatus.none ||
                          (verification.status == PaystubVerificationStatus.processing &&
                              isProcessingTimedOut))
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        )
                      else if (verification.status == PaystubVerificationStatus.processing)
                        const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  bool _isProcessingTimedOut(PaystubVerification verification) {
    if (verification.status != PaystubVerificationStatus.processing) {
      return false;
    }
    final DateTime? updatedAt = verification.updatedAt;
    if (updatedAt == null) {
      return false;
    }
    final Duration elapsed = DateTime.now().difference(updatedAt);
    return elapsed.inMinutes >= 2;
  }
}

class _GovernmentEmailVerificationCard extends StatefulWidget {
  const _GovernmentEmailVerificationCard();

  @override
  State<_GovernmentEmailVerificationCard> createState() => _GovernmentEmailVerificationCardState();
}

class _GovernmentEmailVerificationCardState extends State<_GovernmentEmailVerificationCard> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final bool isLoading = state.isGovernmentEmailVerificationInProgress;
        final bool isVerified = state.isGovernmentEmailVerified;

        if (isVerified) {
          return Card(
            color: theme.colorScheme.primaryContainer,
            child: ListTile(
              leading: Icon(Icons.verified_outlined, color: theme.colorScheme.onPrimaryContainer),
              title: const Text('공직자 통합 메일 인증 완료'),
              subtitle: const Text('확장 기능을 모두 이용할 수 있습니다.'),
              trailing: TextButton(
                onPressed: () =>
                    context.read<AuthCubit>().clearGovernmentEmailVerificationForTesting(),
                child: const Text('인증 취소(개발)'),
              ),
            ),
          );
        }

        return BlocListener<AuthCubit, AuthState>(
          listenWhen: (previous, current) =>
              previous.lastMessage != current.lastMessage && current.lastMessage != null,
          listener: (context, authState) {
            final String? message = authState.lastMessage;
            if (message == null || message.isEmpty) {
              return;
            }
            _showMessage(context, message);
            context.read<AuthCubit>().clearLastMessage();
          },
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.mark_email_unread_outlined, color: theme.colorScheme.primary),
                        const Gap(8),
                        Text(
                          '공직자 통합 메일 인증',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const Gap(12),
                    Text(
                      '공무원 계정(@korea.kr, .go.kr) 또는 공직자메일 서비스(@naver.com)로 인증하면 커뮤니티, 매칭 등 확장 기능을 이용할 수 있습니다. 입력하신 주소로 인증 메일을 보내드려요.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const Gap(12),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: '공무원 메일 주소',
                        hintText: 'example@korea.kr',
                      ),
                      validator: _validateGovernmentEmail,
                    ),
                    const Gap(12),
                    FilledButton.icon(
                      onPressed: isLoading ? null : _submit,
                      icon: isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_outlined),
                      label: const Text('인증 메일 보내기'),
                    ),
                    TextButton.icon(
                      onPressed: isLoading
                          ? null
                          : () => context.read<AuthCubit>().refreshAuthStatus(),
                      icon: const Icon(Icons.refresh_outlined),
                      label: const Text('메일 확인 후 상태 새로고침'),
                    ),
                    const Gap(12),
                    Text(
                      '인증 메일에 포함된 링크를 24시간 이내에 열어야 합니다. 링크를 열면 계정 이메일이 공무원 메일로 변경되지만, 기존에 사용하던 로그인 방식(이메일 또는 소셜 계정)은 계속 사용할 수 있습니다.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _submit() {
    final FormState? form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    final String email = _emailController.text.trim();
    context.read<AuthCubit>().requestGovernmentEmailVerification(email: email);
  }

  String? _validateGovernmentEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '공무원 메일 주소를 입력해주세요.';
    }

    final String email = value.trim().toLowerCase();
    // 임시로 @naver.com 도메인도 허용
    if (!email.endsWith('@korea.kr') &&
        !email.endsWith('.go.kr') &&
        !email.endsWith('@naver.com')) {
      return '공무원 메일(@korea.kr, .go.kr) 또는 공직자메일 서비스(@naver.com) 주소만 인증할 수 있습니다.';
    }

    return null;
  }
}

class _ThemeSettingsSection extends StatelessWidget {
  const _ThemeSettingsSection({required this.isProcessing});

  final bool isProcessing;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, currentThemeMode) {
        return Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(_getThemeIcon(currentThemeMode), color: theme.colorScheme.primary),
              title: const Text('테마 설정'),
              subtitle: Text(_getThemeDescription(currentThemeMode)),
              trailing: Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
              onTap: isProcessing ? null : () => _showThemeDialog(context),
            ),
          ],
        );
      },
    );
  }

  IconData _getThemeIcon(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.brightness_auto;
    }
  }

  String _getThemeDescription(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return '라이트 모드';
      case ThemeMode.dark:
        return '다크 모드';
      case ThemeMode.system:
        return '시스템 설정 따르기';
    }
  }

  void _showThemeDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, currentThemeMode) {
            return AlertDialog(
              title: const Text('테마 선택'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ThemeOptionTile(
                    title: '시스템 설정 따르기',
                    subtitle: '기기의 시스템 설정을 따라 자동으로 변경됩니다',
                    icon: Icons.brightness_auto,
                    themeMode: ThemeMode.system,
                    currentThemeMode: currentThemeMode,
                    onTap: () {
                      context.read<ThemeCubit>().setTheme(ThemeMode.system);
                      Navigator.of(context).pop();
                    },
                  ),
                  _ThemeOptionTile(
                    title: '라이트 모드',
                    subtitle: '밝은 화면으로 표시됩니다',
                    icon: Icons.light_mode,
                    themeMode: ThemeMode.light,
                    currentThemeMode: currentThemeMode,
                    onTap: () {
                      context.read<ThemeCubit>().setTheme(ThemeMode.light);
                      Navigator.of(context).pop();
                    },
                  ),
                  _ThemeOptionTile(
                    title: '다크 모드',
                    subtitle: '어두운 화면으로 표시됩니다',
                    icon: Icons.dark_mode,
                    themeMode: ThemeMode.dark,
                    currentThemeMode: currentThemeMode,
                    onTap: () {
                      context.read<ThemeCubit>().setTheme(ThemeMode.dark);
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ThemeOptionTile extends StatelessWidget {
  const _ThemeOptionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.themeMode,
    required this.currentThemeMode,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final ThemeMode themeMode;
  final ThemeMode currentThemeMode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isSelected = themeMode == currentThemeMode;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        icon,
        color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? theme.colorScheme.primary : null,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: isSelected ? Icon(Icons.check, color: theme.colorScheme.primary) : null,
      onTap: onTap,
    );
  }
}

class _CustomLicensePage extends StatefulWidget {
  const _CustomLicensePage();

  @override
  State<_CustomLicensePage> createState() => _CustomLicensePageState();
}

class _CustomLicensePageState extends State<_CustomLicensePage> {
  late Future<List<LicenseEntry>> _licensesFuture;

  @override
  void initState() {
    super.initState();
    _licensesFuture = _loadLicenses();
  }

  Future<List<LicenseEntry>> _loadLicenses() async {
    final List<LicenseEntry> licenses = <LicenseEntry>[];
    await for (final LicenseEntry license in LicenseRegistry.licenses) {
      licenses.add(license);
    }
    return licenses;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('오픈소스 라이선스'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
      ),
      body: FutureBuilder<List<LicenseEntry>>(
        future: _licensesFuture,
        builder: (BuildContext context, AsyncSnapshot<List<LicenseEntry>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                  const Gap(16),
                  Text('라이선스 정보를 불러올 수 없습니다.', style: theme.textTheme.titleMedium),
                  const Gap(8),
                  Text(
                    '${snapshot.error}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final List<LicenseEntry> licenses = snapshot.data ?? [];

          return CustomScrollView(
            slivers: [
              // 앱 정보 헤더
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '공무톡',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const Gap(8),
                      Text(
                        '버전 1.0.0',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const Gap(16),
                      Text(
                        '© 2025 HANISOFT. All rights reserved.\n\n'
                        '공무톡은 대한민국 공무원을 위한 종합 플랫폼입니다. '
                        '오픈소스 라이브러리의 기여에 감사드립니다.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              // 라이선스 개수 정보
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.colorScheme.outlineVariant, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '오픈소스 라이브러리 정보',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const Gap(8),
                      Text('직접 사용: 약 50개의 주요 라이브러리', style: theme.textTheme.bodyMedium),
                      Text(
                        '전체 포함: ${licenses.length}개 (의존성 포함)',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const Gap(4),
                      Text(
                        '※ 각 라이브러리의 하위 의존성까지 모두 포함된 수치입니다.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 라이선스 목록
              SliverList(
                delegate: SliverChildBuilderDelegate((BuildContext context, int index) {
                  final LicenseEntry license = licenses[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: theme.colorScheme.outlineVariant, width: 1),
                    ),
                    child: ListTile(
                      title: Text(
                        license.packages.join(', '),
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      subtitle: license.paragraphs.isNotEmpty
                          ? Text(
                              license.paragraphs.first.text,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall,
                            )
                          : null,
                      trailing: Icon(
                        Icons.chevron_right,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      onTap: () => _showLicenseDetail(context, license),
                    ),
                  );
                }, childCount: licenses.length),
              ),

              // 하단 여백
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
            ],
          );
        },
      ),
    );
  }

  void _showLicenseDetail(BuildContext context, LicenseEntry license) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        final ThemeData theme = Theme.of(context);
        return AlertDialog(
          title: Text(
            license.packages.join(', '),
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: license.paragraphs.map((LicenseParagraph paragraph) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      paragraph.text,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        height: 1.4,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('닫기')),
          ],
        );
      },
    );
  }
}
