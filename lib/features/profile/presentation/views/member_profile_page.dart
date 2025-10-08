import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../di/di.dart';
import '../../../../routing/app_router.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../community/presentation/cubit/user_comments_cubit.dart';
import '../../data/follow_repository.dart';
import '../../data/user_profile_repository.dart';
import '../../domain/user_profile.dart';
import '../cubit/profile_timeline_cubit.dart';
import '../widgets/profile_overview/profile_header.dart';
import '../widgets/profile_timeline/profile_comments_tab_content.dart';
import '../widgets/profile_timeline/profile_posts_tab_content.dart';

class MemberProfilePage extends StatefulWidget {
  const MemberProfilePage({super.key, required this.uid});

  final String uid;

  @override
  State<MemberProfilePage> createState() => _MemberProfilePageState();
}

class _MemberProfilePageState extends State<MemberProfilePage>
    with SingleTickerProviderStateMixin {
  late final ProfileTimelineCubit _timelineCubit;
  late final UserCommentsCubit _commentsCubit;
  late final UserProfileRepository _profileRepository;
  late final FollowRepository _followRepository;
  late TabController _tabController;
  bool _isFollowActionPending = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _profileRepository = getIt<UserProfileRepository>();
    _followRepository = getIt<FollowRepository>();
    _timelineCubit = ProfileTimelineCubit(
      repository: getIt(),
      authCubit: getIt<AuthCubit>(),
      targetUserId: widget.uid,
    )..loadInitial();
    _commentsCubit = UserCommentsCubit(
      getIt(),
    )..loadInitial(widget.uid);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _timelineCubit.close();
    _commentsCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AuthState authState = context.watch<AuthCubit>().state;
    return MultiBlocProvider(
      providers: [
        BlocProvider<ProfileTimelineCubit>.value(value: _timelineCubit),
        BlocProvider<UserCommentsCubit>.value(value: _commentsCubit),
      ],
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
            return NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  // Profile Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: ProfileHeader(
                        profile: profile,
                        isOwnProfile: isSelf,
                        currentUserId: authState.userId,
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
                    ),
                  ),
                  // TabBar as pinned header
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SliverTabBarDelegate(
                      TabBar(
                        controller: _tabController,
                        tabs: const [
                          Tab(text: '작성한 글'),
                          Tab(text: '작성한 댓글'),
                        ],
                      ),
                    ),
                  ),
                ];
              },
              body: TabBarView(
                controller: _tabController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  const ProfilePostsTabContent(),
                  ProfileCommentsTabContent(authorUid: widget.uid),
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

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverTabBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
