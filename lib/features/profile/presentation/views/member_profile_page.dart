import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../di/di.dart';
import '../../../../routing/app_router.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../community/domain/models/post.dart';
import '../../../community/presentation/widgets/post_card.dart';
import '../../data/follow_repository.dart';
import '../../data/user_profile_repository.dart';
import '../../domain/career_track.dart';
import '../../domain/user_profile.dart';
import '../cubit/profile_timeline_cubit.dart';

class MemberProfilePage extends StatefulWidget {
  const MemberProfilePage({super.key, required this.uid});

  final String uid;

  @override
  State<MemberProfilePage> createState() => _MemberProfilePageState();
}

class _MemberProfilePageState extends State<MemberProfilePage> {
  late final ProfileTimelineCubit _timelineCubit;
  late final UserProfileRepository _profileRepository;
  late final FollowRepository _followRepository;
  bool _isFollowActionPending = false;

  @override
  void initState() {
    super.initState();
    _profileRepository = getIt<UserProfileRepository>();
    _followRepository = getIt<FollowRepository>();
    _timelineCubit = ProfileTimelineCubit(
      repository: getIt(),
      authCubit: getIt<AuthCubit>(),
      targetUserId: widget.uid,
    )..loadInitial();
  }

  @override
  void dispose() {
    _timelineCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AuthState authState = context.watch<AuthCubit>().state;
    return BlocProvider<ProfileTimelineCubit>.value(
      value: _timelineCubit,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('사용자 프로필'),
          actions: [
            IconButton(
              tooltip: '내 프로필',
              icon: const Icon(Icons.person_outline),
              onPressed: () => context.pushNamed(ProfileRoute.name),
            ),
          ],
        ),
        body: StreamBuilder<UserProfile?>(
          stream: _profileRepository.watchProfile(widget.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final UserProfile? profile = snapshot.data;
            if (profile == null) {
              return const _ProfileNotFoundView();
            }
            final bool isSelf = authState.userId == profile.uid;
            return RefreshIndicator(
              onRefresh: () async {
                await _timelineCubit.refresh();
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                children: [
                  _MemberHeader(
                    profile: profile,
                    isSelf: isSelf,
                    isFollowPending: _isFollowActionPending,
                    followButton: isSelf
                        ? null
                        : _FollowButton(
                            targetUid: profile.uid,
                            followerUid: authState.userId,
                            followRepository: _followRepository,
                            onToggle: _handleFollowToggle,
                            isPending: _isFollowActionPending,
                          ),
                  ),
                  const Gap(16),
                  _MemberStats(profile: profile),
                  const Gap(16),
                  _MemberBioSection(profile: profile),
                  const Gap(24),
                  Text(
                    '작성한 글',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Gap(12),
                  const _MemberTimelineSection(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _handleFollowToggle({
    required String targetUid,
    required String followerUid,
    required bool isFollowing,
  }) async {
    if (_isFollowActionPending) {
      return;
    }
    setState(() => _isFollowActionPending = true);
    try {
      if (isFollowing) {
        await _followRepository.unfollow(
          followerUid: followerUid,
          targetUid: targetUid,
        );
        _showSnackBar('팔로우를 취소했어요.');
      } else {
        await _followRepository.follow(
          followerUid: followerUid,
          targetUid: targetUid,
        );
        _showSnackBar('새로운 동료를 팔로우했어요.');
      }
    } catch (_) {
      _showSnackBar('팔로우 상태를 변경하지 못했습니다. 잠시 후 다시 시도해주세요.');
    } finally {
      if (mounted) {
        setState(() => _isFollowActionPending = false);
      }
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ProfileNotFoundView extends StatelessWidget {
  const _ProfileNotFoundView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_off_outlined, size: 48),
            const Gap(12),
            Text(
              '해당 사용자를 찾을 수 없습니다.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberHeader extends StatelessWidget {
  const _MemberHeader({
    required this.profile,
    required this.isSelf,
    required this.isFollowPending,
    this.followButton,
  });

  final UserProfile profile;
  final bool isSelf;
  final bool isFollowPending;
  final Widget? followButton;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: theme.colorScheme.primaryContainer,
              foregroundColor: theme.colorScheme.onPrimaryContainer,
              backgroundImage:
                  profile.photoUrl != null && profile.photoUrl!.isNotEmpty
                  ? NetworkImage(profile.photoUrl!)
                  : null,
              child: profile.photoUrl == null || profile.photoUrl!.isEmpty
                  ? Text(
                      profile.nickname.characters.first,
                      style: theme.textTheme.headlineSmall,
                    )
                  : null,
            ),
            const Gap(16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.nickname,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Gap(4),
                            Text(
                              '@${profile.handle}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isSelf) ...[
                        const Gap(12),
                        followButton ??
                            FilledButton.tonal(
                              onPressed: isFollowPending ? null : () {},
                              child: const Text('로딩 중'),
                            ),
                      ],
                    ],
                  ),
                  const Gap(12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _HeaderChip(
                        icon: Icons.badge_outlined,
                        label: profile.careerTrack == CareerTrack.none
                            ? '직렬 미설정'
                            : profile.careerTrack.displayName,
                      ),
                      _HeaderChip(
                        icon: Icons.location_city_outlined,
                        label: profile.region,
                      ),
                      if (profile.supporterLevel > 0 &&
                          profile.supporterBadgeVisible)
                        _HeaderChip(
                          icon: Icons.workspace_premium,
                          label: '후원자 레벨 ${profile.supporterLevel}',
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

class _MemberStats extends StatelessWidget {
  const _MemberStats({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _StatTile(label: '팔로워', value: profile.followerCount),
            Container(
              width: 1,
              height: 28,
              color: theme.colorScheme.outlineVariant,
            ),
            _StatTile(label: '팔로잉', value: profile.followingCount),
            Container(
              width: 1,
              height: 28,
              color: theme.colorScheme.outlineVariant,
            ),
            _StatTile(label: '포인트', value: profile.points),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$value',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const Gap(4),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _MemberBioSection extends StatelessWidget {
  const _MemberBioSection({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String? bio = profile.bio?.trim();
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
              bio == null || bio.isEmpty ? '아직 자기소개가 작성되지 않았습니다.' : bio,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberTimelineSection extends StatelessWidget {
  const _MemberTimelineSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileTimelineCubit, ProfileTimelineState>(
      builder: (context, state) {
        if (state.isInitial || state.status == ProfileTimelineStatus.loading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (state.status == ProfileTimelineStatus.error &&
            state.posts.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                state.errorMessage ?? '작성한 글을 불러오지 못했습니다.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          );
        }

        if (state.posts.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                const Icon(Icons.forum_outlined, size: 40),
                const Gap(8),
                Text(
                  '아직 작성한 글이 없습니다.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            ...state.posts.map(
              (Post post) => PostCard(
                post: post,
                onToggleLike: () =>
                    context.read<ProfileTimelineCubit>().toggleLike(post),
                onToggleBookmark: () =>
                    context.read<ProfileTimelineCubit>().toggleBookmark(post),
              ),
            ),
            if (state.isLoadingMore)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: CircularProgressIndicator(),
              ),
            if (state.hasMore && !state.isLoadingMore)
              TextButton(
                onPressed: () =>
                    context.read<ProfileTimelineCubit>().loadMore(),
                child: const Text('더 보기'),
              ),
          ],
        );
      },
    );
  }
}

class _FollowButton extends StatelessWidget {
  const _FollowButton({
    required this.targetUid,
    required this.followerUid,
    required this.followRepository,
    required this.onToggle,
    required this.isPending,
  });

  final String targetUid;
  final String? followerUid;
  final FollowRepository followRepository;
  final void Function({
    required String targetUid,
    required String followerUid,
    required bool isFollowing,
  })
  onToggle;
  final bool isPending;

  @override
  Widget build(BuildContext context) {
    final String? currentUid = followerUid;
    if (currentUid == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<bool>(
      stream: followRepository.watchIsFollowing(
        followerUid: currentUid,
        targetUid: targetUid,
      ),
      builder: (context, snapshot) {
        final bool isFollowing = snapshot.data ?? false;
        return FilledButton.tonal(
          onPressed: isPending
              ? null
              : () => onToggle(
                  targetUid: targetUid,
                  followerUid: currentUid,
                  isFollowing: isFollowing,
                ),
          style: FilledButton.styleFrom(
            backgroundColor: isFollowing
                ? Theme.of(context).colorScheme.surfaceContainerHighest
                : null,
          ),
          child: Text(isFollowing ? '팔로잉' : '팔로우'),
        );
      },
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
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
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
