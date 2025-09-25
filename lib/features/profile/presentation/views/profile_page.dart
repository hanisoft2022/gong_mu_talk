import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/engagement_points.dart';
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
  const ProfilePage({super.key});

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
            BlocProvider<ProfileRelationsCubit>(
              create: (_) => getIt<ProfileRelationsCubit>(),
            ),
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
            Icon(
              Icons.lock_outline,
              size: 56,
              color: theme.colorScheme.primary,
            ),
            const Gap(12),
            Text(
              '로그인이 필요합니다',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(8),
            Text(
              '프로필을 관리하려면 먼저 로그인해주세요.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const Gap(20),
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
          previous.lastMessage != current.lastMessage &&
          current.lastMessage != null,
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
                Tab(text: '설정'),
              ],
            ),
          ),
          body: const TabBarView(
            children: [_ProfileOverviewTab(), _ProfileSettingsTab()],
          ),
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            children: [
              _ProfileHeader(state: state),
              const Gap(16),
              _FollowerSummary(state: state),
              const Gap(24),
              _EngagementPointsCard(state: state, theme: Theme.of(context)),
              const Gap(24),
              if (state.userId != null) ...[
                _PaystubSummary(state: state),
                const Gap(24),
              ],
              _ProfileBioSection(state: state),
              const Gap(24),
              Text(
                '라운지 타임라인',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Gap(12),
              const _TimelineSection(),
              const Gap(24),
              Text(
                '직렬 & 매칭 설정',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Gap(12),
              const _CareerTrackSelectorCard(),
              const Gap(16),
              const _ExcludedTrackCard(),
              const Gap(16),
              const _GovernmentEmailVerificationCard(),
              const Gap(16),
              const _MatchingShortcutCard(),
              const Gap(24),
              const _ProfileGuidance(),
              const Gap(24),
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
                      'HANISOFT',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Gap(24),
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
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
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
                  onPressed: () =>
                      context.read<ProfileTimelineCubit>().loadInitial(),
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
                    Text(
                      '아직 작성한 글이 없습니다.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
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
                ...state.posts.map(
                  (Post post) => _TimelinePostTile(post: post),
                ),
                if (state.hasMore) ...[
                  const Gap(8),
                  OutlinedButton(
                    onPressed: () =>
                        context.read<ProfileTimelineCubit>().loadMore(),
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
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.pushNamed(
          CommunityPostDetailRoute.name,
          pathParameters: {'postId': post.id},
          extra: post,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Chip(
                    label: Text(
                      post.audience == PostAudience.serial
                          ? post.serial.toUpperCase()
                          : '전체 공개',
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(post.createdAt),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              const Gap(12),
              Text(
                post.text,
                style: theme.textTheme.bodyLarge,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const Gap(16),
              Row(
                children: [
                  _TimelineStat(
                    icon: Icons.favorite_border,
                    value: post.likeCount,
                  ),
                  const Gap(16),
                  _TimelineStat(
                    icon: Icons.mode_comment_outlined,
                    value: post.commentCount,
                  ),
                  const Gap(16),
                  _TimelineStat(
                    icon: Icons.visibility_outlined,
                    value: post.viewCount,
                  ),
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
        Icon(
          icon,
          size: 18,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const Gap(4),
        Text('$value', style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.state});

  final AuthState state;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool hasSupporterBadge =
        (state.supporterLevel > 0 || state.premiumTier != PremiumTier.none) &&
        state.supporterBadgeVisible;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProfileAvatar(photoUrl: state.photoUrl, nickname: state.nickname),
            const Gap(16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          state.nickname,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasSupporterBadge)
                        Tooltip(
                          message: state.supporterLevel > 0
                              ? '후원자 레벨 ${state.supporterLevel}'
                              : '프리미엄 이용 중',
                          child: Icon(
                            Icons.workspace_premium,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                    ],
                  ),
                  const Gap(6),
                  Text(
                    '@${state.handle.isEmpty ? state.userId ?? 'user' : state.handle}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Gap(12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _HeaderChip(
                        icon: Icons.badge_outlined,
                        label: state.serial == 'unknown'
                            ? '직렬 미설정'
                            : state.careerTrack.displayName,
                      ),
                      _HeaderChip(
                        icon: Icons.star_border,
                        label: '레벨 ${state.level}',
                      ),
                      _HeaderChip(
                        icon: Icons.stars_outlined,
                        label: '포인트 ${state.points}',
                      ),
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

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.photoUrl, required this.nickname});

  final String? photoUrl;
  final String nickname;

  @override
  Widget build(BuildContext context) {
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 32,
        backgroundImage: CachedNetworkImageProvider(photoUrl!),
      );
    }
    return CircleAvatar(
      radius: 32,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      child: Text(
        nickname.isEmpty ? '?' : nickname.characters.first,
        style: Theme.of(context).textTheme.headlineSmall,
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.surfaceContainerHighest,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const Gap(6),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _FollowerSummary extends StatelessWidget {
  const _FollowerSummary({required this.state});

  final AuthState state;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _FollowerCountButton(
              label: '팔로워',
              count: state.followerCount,
              onTap: () =>
                  _showRelationsSheet(context, ProfileRelationType.followers),
            ),
            Container(
              height: 32,
              width: 1,
              color: theme.colorScheme.outlineVariant,
            ),
            _FollowerCountButton(
              label: '팔로잉',
              count: state.followingCount,
              onTap: () =>
                  _showRelationsSheet(context, ProfileRelationType.following),
            ),
          ],
        ),
      ),
    );
  }
}

class _FollowerCountButton extends StatelessWidget {
  const _FollowerCountButton({
    required this.label,
    required this.count,
    required this.onTap,
  });

  final String label;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$count',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const Gap(4),
            Text(label, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _ProfileBioSection extends StatelessWidget {
  const _ProfileBioSection({required this.state});

  final AuthState state;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String bio = state.bio?.trim() ?? '';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '자기소개',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(12),
            Text(
              bio.isEmpty ? '아직 자기소개가 작성되지 않았습니다.' : bio,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _PaystubSummary extends StatelessWidget {
  const _PaystubSummary({required this.state});

  final AuthState state;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      initiallyExpanded: false,
      title: const Text('급여명세서 인증'),
      subtitle: Text(
        state.isGovernmentEmailVerified
            ? '공직자 메일 인증 완료'
            : '급여 명세서로 직렬 인증을 진행할 수 있습니다.',
      ),
      children: [_PaystubVerificationCard(uid: state.userId!)],
    );
  }
}

class _ProfileSettingsTab extends StatefulWidget {
  const _ProfileSettingsTab();

  @override
  State<_ProfileSettingsTab> createState() => _ProfileSettingsTabState();
}

class _ProfileSettingsTabState extends State<_ProfileSettingsTab> {
  late final TextEditingController _nicknameController;
  late final TextEditingController _bioController;
  late final TextEditingController _currentPasswordController;
  late final TextEditingController _newPasswordController;
  late final TextEditingController _confirmPasswordController;
  late final TextEditingController _deletePasswordController;

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final AuthState state = context.read<AuthCubit>().state;
    _nicknameController = TextEditingController(text: state.nickname);
    _bioController = TextEditingController(text: state.bio ?? '');
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _deletePasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _bioController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _deletePasswordController.dispose();
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
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            children: [
              _SettingsSection(
                title: '프로필 이미지',
                children: [
                  Row(
                    children: [
                      _ProfileAvatar(
                        photoUrl: state.photoUrl,
                        nickname: state.nickname,
                      ),
                      const Gap(16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '프로필 사진을 설정하면 다른 사용자와 더 쉽게 소통할 수 있어요.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const Gap(12),
                            OutlinedButton.icon(
                              onPressed: isProcessing
                                  ? null
                                  : _pickProfileImage,
                              icon: const Icon(Icons.photo_library_outlined),
                              label: const Text('앨범에서 선택'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Gap(24),
              _SettingsSection(
                title: '닉네임',
                helper: '닉네임은 한 달에 한 번만 변경할 수 있어요. 변경권이 있다면 추가 변경이 가능합니다.',
                children: [
                  TextField(
                    controller: _nicknameController,
                    enabled: !isProcessing,
                    maxLength: 20,
                    decoration: const InputDecoration(
                      labelText: '닉네임',
                      counterText: '',
                    ),
                  ),
                  const Gap(12),
                  FilledButton(
                    onPressed: isProcessing
                        ? null
                        : () async {
                            await context.read<AuthCubit>().updateNickname(
                              _nicknameController.text,
                            );
                          },
                    child: const Text('닉네임 변경'),
                  ),
                ],
              ),
              const Gap(24),
              _SettingsSection(
                title: '자기소개',
                children: [
                  TextField(
                    controller: _bioController,
                    enabled: !isProcessing,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText: '그동안의 경험이나 관심사를 소개해보세요.',
                    ),
                  ),
                  const Gap(12),
                  FilledButton(
                    onPressed: isProcessing
                        ? null
                        : () async {
                            await context.read<AuthCubit>().updateBio(
                              _bioController.text,
                            );
                          },
                    child: const Text('자기소개 저장'),
                  ),
                ],
              ),
              const Gap(24),
              _SettingsSection(
                title: '알림 및 배지',
                children: [
                  SwitchListTile.adaptive(
                    value: state.notificationsEnabled,
                    onChanged: isProcessing
                        ? null
                        : (bool value) => context
                              .read<AuthCubit>()
                              .updateNotificationsEnabled(value),
                    title: const Text('앱 알림 수신'),
                    subtitle: const Text('새로운 댓글, 후원 소식 등을 알림으로 받아볼 수 있습니다.'),
                  ),
                  SwitchListTile.adaptive(
                    value: state.supporterBadgeVisible,
                    onChanged: isProcessing
                        ? null
                        : (bool value) => context
                              .read<AuthCubit>()
                              .updateSupporterBadgeVisibility(value),
                    title: const Text('후원 배지 표시'),
                    subtitle: const Text('후원자 배지를 프로필에 노출할지 선택할 수 있습니다.'),
                  ),
                ],
              ),
              const Gap(24),
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
                            final String currentPassword =
                                _currentPasswordController.text.trim();
                            final String newPassword = _newPasswordController
                                .text
                                .trim();
                            final String confirmPassword =
                                _confirmPasswordController.text.trim();
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
              const Gap(24),
              _SettingsSection(
                title: '후원 설정',
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      state.supporterLevel > 0 ||
                              state.premiumTier != PremiumTier.none
                          ? Icons.volunteer_activism
                          : Icons.volunteer_activism_outlined,
                    ),
                    title: Text(
                      state.supporterLevel > 0 ||
                              state.premiumTier != PremiumTier.none
                          ? '후원 취소하기'
                          : '공무톡 후원하기',
                    ),
                    subtitle: Text(
                      state.supporterLevel > 0 ||
                              state.premiumTier != PremiumTier.none
                          ? '후원을 취소하면 광고가 다시 노출됩니다.'
                          : '후원 시 배지를 획득하고 광고가 제거됩니다.',
                    ),
                    onTap: isProcessing
                        ? null
                        : () {
                            final AuthCubit cubit = context.read<AuthCubit>();
                            if (state.supporterLevel > 0 ||
                                state.premiumTier != PremiumTier.none) {
                              cubit.disableSupporterMode();
                            } else {
                              cubit.enableSupporterMode();
                            }
                          },
                  ),
                ],
              ),
              const Gap(24),
              _SettingsSection(
                title: '급여명세서 인증',
                children: [
                  if (state.userId != null)
                    _PaystubVerificationCard(uid: state.userId!),
                ],
              ),
              const Gap(24),
              _SettingsSection(
                title: '계정 관리',
                children: [
                  FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.errorContainer,
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                    onPressed: isProcessing
                        ? null
                        : () => _confirmDeleteAccount(context),
                    child: const Text('회원 탈퇴'),
                  ),
                ],
              ),
              const Gap(24),
            ],
          );
        },
      ),
    );
  }

  Future<void> _pickProfileImage() async {
    final AuthCubit authCubit = context.read<AuthCubit>();
    try {
      final XFile? file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (file == null) {
        return;
      }
      final Uint8List bytes = await file.readAsBytes();
      await authCubit.updateProfileImage(
        bytes: bytes,
        fileName: file.name,
        contentType: file.mimeType ?? 'image/jpeg',
      );
    } on PlatformException catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(context, '이미지를 불러오지 못했습니다: ${error.message}');
    }
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
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.errorContainer,
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () async {
                final String password = _deletePasswordController.text.trim();
                final AuthCubit authCubit = context.read<AuthCubit>();
                final NavigatorState navigator = Navigator.of(context);
                await authCubit.deleteAccount(
                  currentPassword: password.isEmpty ? null : password,
                );
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
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.children,
    this.helper,
  });

  final String title;
  final List<Widget> children;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        if (helper != null) ...[
          const Gap(6),
          Text(
            helper!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const Gap(16),
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
                          state.type == ProfileRelationType.followers
                              ? '팔로워'
                              : '팔로잉',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
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
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
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
                                    notification.metrics.maxScrollExtent -
                                        120 &&
                                !state.isLoadingMore &&
                                state.hasMore) {
                              cubit.loadMore();
                            }
                            return false;
                          },
                          child: ListView.separated(
                            controller: controller,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            itemBuilder: (BuildContext context, int index) {
                              final UserProfile profile = state.users[index];
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  radius: 22,
                                  backgroundImage: profile.photoUrl == null
                                      ? null
                                      : CachedNetworkImageProvider(
                                          profile.photoUrl!,
                                        ),
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
                                trailing:
                                    state.type == ProfileRelationType.following
                                    ? TextButton(
                                        onPressed: () =>
                                            cubit.unfollow(profile.uid),
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

// --- Existing components reused below ---

class _ProfileGuidance extends StatelessWidget {
  const _ProfileGuidance();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _GuidelineRow(
              icon: Icons.verified_user_outlined,
              message: '공직자 메일로 로그인하면 추가 인증 없이 주요 기능을 이용할 수 있습니다.',
            ),
            SizedBox(height: 12),
            _GuidelineRow(
              icon: Icons.badge_outlined,
              message:
                  '다른 이메일로 가입하셨다면 마이페이지에서 공직자 메일 인증 절차를 진행할 수 있도록 준비 중입니다.',
            ),
          ],
        ),
      ),
    );
  }
}

class _GuidelineRow extends StatelessWidget {
  const _GuidelineRow({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const Gap(12),
        Expanded(child: Text(message, style: theme.textTheme.bodyMedium)),
      ],
    );
  }
}

class _EngagementPointsCard extends StatelessWidget {
  const _EngagementPointsCard({required this.state, required this.theme});

  final AuthState state;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.stars, color: theme.colorScheme.primary),
                const Gap(8),
                Text(
                  '활동 포인트',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Gap(16),
            Text(
              '${state.points} pts',
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const Gap(4),
            Text('현재 레벨 ${state.level}', style: theme.textTheme.bodyMedium),
            const Gap(16),
            const Divider(height: 24),
            Text(
              '포인트는 아래 활동으로 적립됩니다.',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(12),
            const _PointRuleRow(
              icon: Icons.edit_note_outlined,
              label: '라운지 글 작성',
              value: '+${EngagementPoints.postCreation} pts',
            ),
            const _PointRuleRow(
              icon: Icons.chat_bubble_outline,
              label: '댓글 작성',
              value: '+${EngagementPoints.commentCreation} pts',
            ),
            const _PointRuleRow(
              icon: Icons.favorite_outline,
              label: '내 글/댓글에 좋아요 수신',
              value: '+${EngagementPoints.contentReceivedLike} pts',
            ),
            const Gap(8),
            Text(
              '포인트는 실시간으로 반영되며, 누적 포인트에 따라 더 많은 혜택이 제공될 예정입니다.',
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

class _PointRuleRow extends StatelessWidget {
  const _PointRuleRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.secondary),
          const Gap(12),
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaystubVerificationCard extends StatefulWidget {
  const _PaystubVerificationCard({required this.uid});

  final String uid;

  @override
  State<_PaystubVerificationCard> createState() =>
      _PaystubVerificationCardState();
}

class _PaystubVerificationCardState extends State<_PaystubVerificationCard> {
  bool _isUploading = false;

  PaystubVerificationRepository get _repository =>
      getIt<PaystubVerificationRepository>();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return StreamBuilder<PaystubVerification>(
      stream: _repository.watchVerification(widget.uid),
      builder:
          (BuildContext context, AsyncSnapshot<PaystubVerification> snapshot) {
            final PaystubVerification verification =
                snapshot.data ?? PaystubVerification.none;
            final bool isProcessingTimedOut = _isProcessingTimedOut(
              verification,
            );

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.verified_user_outlined,
                          color: theme.colorScheme.primary,
                        ),
                        const Gap(8),
                        Text(
                          '급여 명세서로 직렬 인증',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        if (verification.status ==
                                PaystubVerificationStatus.processing &&
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
                    const Gap(16),
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
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
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

  Widget _buildStatusSubtitle(
    BuildContext context,
    PaystubVerification verification,
  ) {
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
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          );
        }
        return Text(
          '문서를 분석하여 직렬 정보를 확인하고 있습니다.',
          style: theme.textTheme.bodyMedium,
        );
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
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.error,
          ),
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
      final String contentType = extension == 'pdf'
          ? 'application/pdf'
          : 'image/$extension';

      await _repository.uploadPaystub(
        bytes: bytes,
        fileName: file.name,
        contentType: contentType,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('급여 명세서를 업로드했습니다. 검증 결과를 기다려주세요.')),
        );
    } on MissingPluginException {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              '이 플랫폼에서는 파일 선택 기능이 지원되지 않습니다. 앱을 완전 종료 후 다시 실행하거나 지원되는 기기에서 시도해주세요.',
            ),
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

class _CareerTrackSelectorCard extends StatelessWidget {
  const _CareerTrackSelectorCard();

  @override
  Widget build(BuildContext context) {
    final AuthState authState = context.watch<AuthCubit>().state;
    final ThemeData theme = Theme.of(context);
    final CareerTrack currentTrack = authState.careerTrack;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.badge_outlined, color: theme.colorScheme.primary),
                const Gap(8),
                Text(
                  '내 직렬 설정',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Gap(12),
            Text(
              currentTrack == CareerTrack.none
                  ? '직렬을 설정하면 맞춤 콘텐츠를 추천해드립니다.'
                  : '현재 직렬: ${currentTrack.displayName}',
              style: theme.textTheme.bodyMedium,
            ),
            const Gap(16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: CareerTrack.values
                  .where((CareerTrack track) => track != CareerTrack.none)
                  .map(
                    (CareerTrack track) => ChoiceChip(
                      label: Text(track.displayName),
                      selected: currentTrack == track,
                      onSelected: (bool selected) =>
                          context.read<AuthCubit>().updateCareerTrack(
                            selected ? track : CareerTrack.none,
                          ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExcludedTrackCard extends StatelessWidget {
  const _ExcludedTrackCard();

  @override
  Widget build(BuildContext context) {
    final AuthState authState = context.watch<AuthCubit>().state;
    final ThemeData theme = Theme.of(context);
    final Set<CareerTrack> excludedTracks = authState.excludedTracks;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.filter_alt_outlined,
                  color: theme.colorScheme.primary,
                ),
                const Gap(8),
                Text(
                  '매칭 제외 직렬',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Gap(12),
            Text(
              excludedTracks.isEmpty
                  ? '제외할 직렬을 선택하여 관심 없는 매칭을 숨길 수 있습니다.'
                  : '제외 직렬: ${excludedTracks.map((CareerTrack track) => track.displayName).join(', ')}',
              style: theme.textTheme.bodyMedium,
            ),
            const Gap(16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: CareerTrack.values
                  .where((CareerTrack track) => track != CareerTrack.none)
                  .map(
                    (CareerTrack track) => FilterChip(
                      label: Text(track.displayName),
                      selected: excludedTracks.contains(track),
                      onSelected: (_) =>
                          context.read<AuthCubit>().toggleExcludedTrack(track),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ),
      ),
    );
  }
}

class _GovernmentEmailVerificationCard extends StatefulWidget {
  const _GovernmentEmailVerificationCard();

  @override
  State<_GovernmentEmailVerificationCard> createState() =>
      _GovernmentEmailVerificationCardState();
}

class _GovernmentEmailVerificationCardState
    extends State<_GovernmentEmailVerificationCard> {
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
              leading: Icon(
                Icons.verified_outlined,
                color: theme.colorScheme.onPrimaryContainer,
              ),
              title: const Text('공직자 메일 인증 완료'),
              subtitle: const Text('확장 기능을 모두 이용할 수 있습니다.'),
              trailing: TextButton(
                onPressed: () => context
                    .read<AuthCubit>()
                    .clearGovernmentEmailVerificationForTesting(),
                child: const Text('인증 취소(개발)'),
              ),
            ),
          );
        }

        return BlocListener<AuthCubit, AuthState>(
          listenWhen: (previous, current) =>
              previous.lastMessage != current.lastMessage &&
              current.lastMessage != null,
          listener: (context, authState) {
            final String? message = authState.lastMessage;
            if (message == null || message.isEmpty) {
              return;
            }
            final ScaffoldMessengerState messenger = ScaffoldMessenger.of(
              context,
            );
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
                        Icon(
                          Icons.mark_email_unread_outlined,
                          color: theme.colorScheme.primary,
                        ),
                        const Gap(8),
                        Text(
                          '공직자 메일 인증',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const Gap(12),
                    Text(
                      '공직자 계정(@korea.kr, .go.kr)으로 인증하면 커뮤니티, 매칭 등 확장 기능을 이용할 수 있습니다. 입력하신 주소로 인증 메일을 보내드려요.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const Gap(16),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: '공직자 메일 주소',
                        hintText: 'example@korea.kr',
                      ),
                      validator: _validateGovernmentEmail,
                    ),
                    const Gap(16),
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

class _MatchingShortcutCard extends StatelessWidget {
  const _MatchingShortcutCard();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      child: ListTile(
        leading: Icon(Icons.people_outline, color: theme.colorScheme.primary),
        title: const Text('맞춤 매칭 둘러보기'),
        subtitle: const Text('내 직렬/관심사와 유사한 공무원과 연결됩니다.'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.pushNamed(MatchingRoute.name),
      ),
    );
  }
}
