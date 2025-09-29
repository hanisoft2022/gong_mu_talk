import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_cubit.dart';
import '../../../../di/di.dart';
import '../../../../routing/app_router.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/widgets/auth_dialog.dart';
import '../../data/paystub_verification_repository.dart';
import '../../domain/career_track.dart';
import '../../domain/paystub_verification.dart';
import '../../domain/user_profile.dart';
import '../../../community/domain/models/post.dart';
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

class _ProfileLoggedInScaffold extends StatelessWidget {
  const _ProfileLoggedInScaffold();

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
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: [
              _ProfileHeader(state: state, isOwnProfile: true), // 임시로 항상 자신의 프로필로 설정
              const Gap(12),
              _SponsorshipBanner(state: state),
              const Gap(16),
              Text(
                '라운지 타임라인',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Gap(12),
              const _TimelineSection(),
              const Gap(16),
              Center(
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/hanisoft_logo.png',
                      height: 40,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                    const Gap(8),
                    Text(
                      'Powered by HANISOFT',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
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
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Icon(
                      Icons.forum_outlined,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const Gap(12),
                    Text('아직 작성한 글이 없습니다.', style: Theme.of(context).textTheme.bodyMedium),
                    const Gap(4),
                    Text(
                      '라운지에서 첫 글을 작성해보세요!',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            }
            return Column(
              children: [
                ...state.posts.map((Post post) => _TimelinePostTile(post: post)),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.pushNamed(
          CommunityPostDetailRoute.name,
          pathParameters: {'postId': post.id},
          extra: post,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Chip(
                    label: Text(
                      post.audience == PostAudience.serial ? post.serial.toUpperCase() : '전체 공개',
                    ),
                  ),
                  const Spacer(),
                  Text(_formatDate(post.createdAt), style: theme.textTheme.bodySmall),
                ],
              ),
              const Gap(8),
              Text(
                post.text,
                style: theme.textTheme.bodyLarge,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const Gap(12),
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
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant, width: 0.5),
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
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Gap(6),
                      // 가입일 표시
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const Gap(6),
                          Text(
                            '2024년 9월에 가입',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // 우측 액션 버튼
                if (isOwnProfile)
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (BuildContext context) => const ProfileEditPage(),
                          ),
                        );
                      },
                      icon: Icon(Icons.edit_outlined, color: theme.colorScheme.onSurfaceVariant),
                      tooltip: '프로필 수정',
                    ),
                  )
                else
                  _FollowButton(targetUserId: state.userId ?? ''),
              ],
            ),
            const Gap(16),
            // 자기소개
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.outlineVariant, width: 0.5),
              ),
              child: Text(
                (state.bio != null && state.bio!.trim().isNotEmpty)
                    ? state.bio!.trim()
                    : '작성된 자기소개가 없습니다.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: (state.bio != null && state.bio!.trim().isNotEmpty)
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurfaceVariant,
                  fontStyle: (state.bio != null && state.bio!.trim().isNotEmpty)
                      ? FontStyle.normal
                      : FontStyle.italic,
                  height: 1.4,
                ),
              ),
            ),
            const Gap(16),
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
                const Gap(12),
                Expanded(
                  child: _StatCard(
                    title: '팔로워',
                    count: state.followerCount,
                    onTap: () => _showRelationsSheet(context, ProfileRelationType.followers),
                  ),
                ),
              ],
            ),
            const Gap(12),
            // 기본 정보 (개선된 레이아웃)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '기본 정보',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Gap(8),
                  Row(
                    children: [
                      Expanded(
                        child: _InfoChip(
                          icon: Icons.badge_outlined,
                          label: state.serial == 'unknown'
                              ? '직렬 미설정'
                              : state.careerTrack.displayName,
                          color: state.serial == 'unknown'
                              ? theme.colorScheme.error
                              : theme.colorScheme.primary,
                        ),
                      ),
                      const Gap(8),
                      Expanded(
                        child: _InfoChip(
                          icon: Icons.stars_outlined,
                          label: '포인트 ${state.points}',
                          color: theme.colorScheme.tertiary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Gap(12),
            // 인증 상태 (개선된 레이아웃)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '인증 상태',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Gap(8),
                  Column(
                    children: [
                      _VerificationStatusRow(
                        icon: state.isGovernmentEmailVerified ? Icons.verified : Icons.close,
                        label: '공직자 메일 인증',
                        isVerified: state.isGovernmentEmailVerified,
                      ),
                      if (state.userId != null) ...[
                        const Gap(8),
                        _PaystubStatusRow(uid: state.userId!),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outlineVariant, width: 0.5),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
            const Gap(2),
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const Gap(6),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(color: color, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isVerified
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
            : theme.colorScheme.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isVerified
              ? theme.colorScheme.primary.withValues(alpha: 0.3)
              : theme.colorScheme.error.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Row(
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
              style: theme.textTheme.bodySmall?.copyWith(
                color: isVerified ? theme.colorScheme.primary : theme.colorScheme.error,
                fontWeight: FontWeight.w500,
              ),
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
      ),
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

    return StreamBuilder<PaystubVerification>(
      stream: repository.watchVerification(uid),
      builder: (BuildContext context, AsyncSnapshot<PaystubVerification> snapshot) {
        final PaystubVerification verification = snapshot.data ?? PaystubVerification.none;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: verification.status == PaystubVerificationStatus.verified
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
                : verification.status == PaystubVerificationStatus.processing
                ? theme.colorScheme.tertiaryContainer.withValues(alpha: 0.3)
                : theme.colorScheme.errorContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: verification.status == PaystubVerificationStatus.verified
                  ? theme.colorScheme.primary.withValues(alpha: 0.3)
                  : verification.status == PaystubVerificationStatus.processing
                  ? theme.colorScheme.tertiary.withValues(alpha: 0.3)
                  : theme.colorScheme.error.withValues(alpha: 0.3),
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              Icon(
                verification.status == PaystubVerificationStatus.verified
                    ? Icons.verified
                    : verification.status == PaystubVerificationStatus.processing
                    ? Icons.hourglass_empty
                    : Icons.close,
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
                  '급여명세서 인증',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: verification.status == PaystubVerificationStatus.verified
                        ? theme.colorScheme.primary
                        : verification.status == PaystubVerificationStatus.processing
                        ? theme.colorScheme.tertiary
                        : theme.colorScheme.error,
                    fontWeight: FontWeight.w500,
                  ),
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
          ),
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

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2), width: 2),
      ),
      child: CircleAvatar(
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
      ),
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
                SwitchListTile.adaptive(
                  value: state.notificationsEnabled,
                  onChanged: isProcessing
                      ? null
                      : (bool value) => context.read<AuthCubit>().updateNotificationsEnabled(value),
                  title: const Text('전체 알림'),
                  subtitle: const Text('모든 알림을 받을지 설정합니다.'),
                ),
                if (state.notificationsEnabled) ...[
                  const Divider(),
                  ListTile(
                    contentPadding: const EdgeInsets.only(left: 16),
                    leading: const Icon(Icons.favorite_outline, size: 20),
                    title: const Text('좋아요 알림'),
                    subtitle: const Text('내 게시물에 좋아요가 달렸을 때'),
                    trailing: Switch.adaptive(
                      value: true, // TODO: 실제 설정 값으로 연결
                      onChanged: isProcessing
                          ? null
                          : (value) {
                              // TODO: 개별 알림 설정 구현
                            },
                    ),
                  ),
                  ListTile(
                    contentPadding: const EdgeInsets.only(left: 16),
                    leading: const Icon(Icons.comment_outlined, size: 20),
                    title: const Text('댓글 알림'),
                    subtitle: const Text('내 게시물에 댓글이 달렸을 때'),
                    trailing: Switch.adaptive(
                      value: true, // TODO: 실제 설정 값으로 연결
                      onChanged: isProcessing
                          ? null
                          : (value) {
                              // TODO: 개별 알림 설정 구현
                            },
                    ),
                  ),
                  ListTile(
                    contentPadding: const EdgeInsets.only(left: 16),
                    leading: const Icon(Icons.person_add_outlined, size: 20),
                    title: const Text('팔로우 알림'),
                    subtitle: const Text('새로운 팔로워가 생겼을 때'),
                    trailing: Switch.adaptive(
                      value: true, // TODO: 실제 설정 값으로 연결
                      onChanged: isProcessing
                          ? null
                          : (value) {
                              // TODO: 개별 알림 설정 구현
                            },
                    ),
                  ),
                ],
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
            _SettingsSection(
              title: '저장소 관리',
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.cleaning_services_outlined),
                  title: const Text('캐시 삭제'),
                  subtitle: const Text('임시 파일과 캐시를 삭제하여 저장 공간을 확보합니다.'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showCacheClearDialog(context),
                ),
              ],
            ),
            const Gap(16),
            _SettingsSection(
              title: '고객 지원',
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.help_outline),
                  title: const Text('자주 묻는 질문'),
                  subtitle: const Text('공통적인 질문과 답변을 확인하세요.'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showFAQDialog(context),
                ),
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
                  onTap: () => _launchUrl('https://privacy.policy.url'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('서비스 이용약관'),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => _launchUrl('https://terms.of.service.url'),
                ),
              ],
            ),
            const Gap(16),
            _SettingsSection(
              title: '앱 정보',
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.info_outline),
                  title: const Text('버전 정보'),
                  subtitle: const Text('1.0.0 (빌드 1)'), // TODO: 실제 버전 정보로 대체
                  onTap: () => _showVersionInfo(context),
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

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _showCacheClearDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('캐시 삭제'),
          content: const Text('앱의 임시 파일과 캐시를 모두 삭제하시겠습니까?\n\n삭제된 데이터는 복구할 수 없습니다.'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('취소')),
            FilledButton(
              onPressed: () async {
                Navigator.of(context).pop();
                // TODO: 실제 캐시 삭제 로직 구현
                _showMessage(context, '캐시가 삭제되었습니다.');
              },
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );
  }

  void _showFAQDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('자주 묻는 질문'),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Q: 회원가입은 어떻게 하나요?', style: TextStyle(fontWeight: FontWeight.w600)),
                SizedBox(height: 4),
                Text('A: Google 또는 Kakao 계정으로 간편하게 가입할 수 있습니다.'),
                SizedBox(height: 16),
                Text('Q: 직렬 인증은 필수인가요?', style: TextStyle(fontWeight: FontWeight.w600)),
                SizedBox(height: 4),
                Text('A: 기본 기능은 인증 없이도 사용 가능하지만, 커뮤니티 등 확장 기능을 위해서는 인증이 필요합니다.'),
                SizedBox(height: 16),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('확인')),
          ],
        );
      },
    );
  }

  void _showFeedbackDialog(BuildContext context) {
    final TextEditingController feedbackController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('피드백 보내기'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('개선 사항이나 문제점을 알려주세요.'),
              const SizedBox(height: 16),
              TextField(
                controller: feedbackController,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: '의견을 자유롭게 작성해주세요...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('취소')),
            FilledButton(
              onPressed: () {
                if (feedbackController.text.trim().isNotEmpty) {
                  Navigator.of(context).pop();
                  // TODO: 실제 피드백 전송 로직 구현
                  _showMessage(context, '피드백이 전송되었습니다. 감사합니다!');
                }
              },
              child: const Text('전송'),
            ),
          ],
        );
      },
    );
  }

  void _launchUrl(String url) {
    // TODO: url_launcher 패키지 사용하여 URL 열기
    // launchUrl(Uri.parse(url));
  }

  void _showVersionInfo(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('버전 정보'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('앱 버전: 1.0.0'),
              Text('빌드 번호: 1'),
              Text('출시일: 2024.09'),
              SizedBox(height: 16),
              Text('최신 버전을 사용 중입니다.'),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('확인')),
          ],
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
    showLicensePage(
      context: context,
      applicationName: '공무톡',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2024 HANISOFT. All rights reserved.',
    );
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
    // TODO: 실제 팔로우 상태 확인 로직 구현
    // 현재는 임시로 false로 설정
    setState(() {
      _isFollowing = false;
    });
  }

  Future<void> _toggleFollow() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: 실제 팔로우/언팔로우 API 호출
      await Future.delayed(const Duration(milliseconds: 500)); // 임시 딜레이

      setState(() {
        _isFollowing = !_isFollowing;
      });

      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(_isFollowing ? '팔로우했습니다' : '팔로우를 취소했습니다'),
              duration: const Duration(seconds: 2),
            ),
          );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text('오류가 발생했습니다: $error'), duration: const Duration(seconds: 2)),
          );
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

  @override
  void initState() {
    super.initState();
    final AuthState state = context.read<AuthCubit>().state;
    _nicknameController = TextEditingController(text: state.nickname);
    _bioController = TextEditingController(text: state.bio ?? '');
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
                padding: const EdgeInsets.all(12),
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
                        onChanged: isProcessing
                            ? null
                            : (bool value) =>
                                  context.read<AuthCubit>().updateSerialVisibility(value),
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
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('닉네임을 입력해주세요.')));
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
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('프로필이 저장되었습니다.')));
        context.pop();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text('저장 중 오류가 발생했습니다: $error')));
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
        Stack(
          children: [
            _ProfileAvatar(photoUrl: photoUrl, nickname: nickname),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.colorScheme.outline, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: isProcessing ? null : () => _showImagePicker(context),
                  icon: Icon(Icons.edit, color: theme.colorScheme.onSurface, size: 16),
                  iconSize: 16,
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                ),
              ),
            ),
          ],
        ),
        const Gap(12),
        Text(
          '프로필 사진 변경',
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('이미지를 불러오지 못했습니다: ${error.message}')));
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
  bool _isUploading = false;

  PaystubVerificationRepository get _repository => getIt<PaystubVerificationRepository>();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return StreamBuilder<PaystubVerification>(
      stream: _repository.watchVerification(widget.uid),
      builder: (BuildContext context, AsyncSnapshot<PaystubVerification> snapshot) {
        final PaystubVerification verification = snapshot.data ?? PaystubVerification.none;
        final bool isProcessingTimedOut = _isProcessingTimedOut(verification);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.verified_user_outlined, color: theme.colorScheme.primary),
                    const Gap(8),
                    Text(
                      '급여 명세서로 직렬 인증',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    if (verification.status == PaystubVerificationStatus.processing &&
                        !isProcessingTimedOut)
                      const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const Gap(12),
                _buildStatusSubtitle(context, verification),
                const Gap(12),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isUploading
                          ? null
                          : () async {
                              await _handleUpload();
                            },
                      icon: _isUploading
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.upload_file),
                      label: const Text('명세서 업로드'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusSubtitle(BuildContext context, PaystubVerification verification) {
    final ThemeData theme = Theme.of(context);
    switch (verification.status) {
      case PaystubVerificationStatus.none:
        return Text(
          '국공립교원, 행정직 등 직렬이 포함된 급여 명세서(PDF/이미지)를 업로드하면 자동으로 인증됩니다.',
          style: theme.textTheme.bodyMedium,
        );
      case PaystubVerificationStatus.processing:
        final bool isTimedOut = _isProcessingTimedOut(verification);
        if (isTimedOut) {
          return Text(
            '문서 분석이 오래 걸리는 중입니다. 다시 업로드하여 인증을 재시도해주세요.',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
          );
        }
        return Text('문서를 분석하여 직렬 정보를 확인하고 있습니다.', style: theme.textTheme.bodyMedium);
      case PaystubVerificationStatus.verified:
        final CareerTrack? track = verification.detectedTrack;
        final String trackLabel = track == null
            ? '알 수 없는 직렬'
            : '${track.emoji} ${track.displayName}';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '급여 명세서를 통해 직렬 인증이 완료되었습니다.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(4),
            Text('감지된 직렬: $trackLabel', style: theme.textTheme.bodyMedium),
          ],
        );
      case PaystubVerificationStatus.failed:
        return Text(
          '문서에서 직렬 정보를 확인하지 못했습니다. 다른 파일로 다시 시도해주세요.',
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
        );
    }
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

  Future<void> _handleUpload() async {
    try {
      setState(() => _isUploading = true);
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: <String>['pdf', 'png', 'jpg', 'jpeg'],
        withData: true,
      );
      if (result == null) {
        setState(() => _isUploading = false);
        return;
      }

      final PlatformFile file = result.files.single;
      final Uint8List? bytes = file.bytes;
      if (bytes == null) {
        throw StateError('파일 데이터를 읽을 수 없습니다. 다른 파일을 선택해주세요.');
      }

      final String extension = (file.extension ?? '').toLowerCase();
      final String contentType = extension == 'pdf' ? 'application/pdf' : 'image/$extension';

      await _repository.uploadPaystub(bytes: bytes, fileName: file.name, contentType: contentType);

      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('급여 명세서를 업로드했습니다. 검증 결과를 기다려주세요.')));
    } on MissingPluginException {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('이 플랫폼에서는 파일 선택 기능이 지원되지 않습니다. 앱을 완전 종료 후 다시 실행하거나 지원되는 기기에서 시도해주세요.'),
          ),
        );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('업로드 중 문제가 발생했습니다: $error')));
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
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
              title: const Text('공직자 메일 인증 완료'),
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
            final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
            messenger
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(message)));
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
                          '공직자 메일 인증',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const Gap(12),
                    Text(
                      '공직자 계정(@korea.kr, .go.kr)으로 인증하면 커뮤니티, 매칭 등 확장 기능을 이용할 수 있습니다. 입력하신 주소로 인증 메일을 보내드려요.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const Gap(12),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: '공직자 메일 주소',
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
                      '인증 메일에 포함된 링크를 24시간 이내에 열어야 합니다. 링크를 열면 계정 이메일이 공직자 메일로 변경되지만, 기존에 사용하던 로그인 방식(이메일 또는 소셜 계정)은 계속 사용할 수 있습니다.',
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
      return '공직자 메일 주소를 입력해주세요.';
    }

    final String email = value.trim().toLowerCase();
    if (!email.endsWith('@korea.kr') && !email.endsWith('.go.kr')) {
      return '공직자 메일(@korea.kr 또는 .go.kr) 주소만 인증할 수 있습니다.';
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
