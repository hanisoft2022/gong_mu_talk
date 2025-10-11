import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../di/di.dart';
import '../../../../routing/app_router.dart';
import '../../../../core/utils/snackbar_helpers.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../community/presentation/cubit/user_comments_cubit.dart';
import '../../data/follow_repository.dart';
import '../../data/user_profile_repository.dart';
import '../../domain/user_profile.dart';
import '../cubit/profile_timeline_cubit.dart';
import '../cubit/profile_relations_cubit.dart';
import '../widgets/profile_overview/profile_header.dart';
import '../widgets/profile_timeline/profile_comments_tab_content.dart';
import '../widgets/profile_timeline/profile_posts_tab_content.dart';

class MemberProfilePage extends StatefulWidget {
  const MemberProfilePage({super.key, required this.uid});

  final String uid;

  @override
  State<MemberProfilePage> createState() => _MemberProfilePageState();
}

class _MemberProfilePageState extends State<MemberProfilePage> with SingleTickerProviderStateMixin {
  late final ProfileTimelineCubit _timelineCubit;
  late final UserCommentsCubit _commentsCubit;
  late final ProfileRelationsCubit _relationsCubit;
  late final UserProfileRepository _profileRepository;
  late final FollowRepository _followRepository;
  late TabController _tabController;
  bool _isFollowActionPending = false;

  // Follow Undo State
  Timer? _followUndoTimer;
  String? _followTargetUid;

  bool? _wasFollowing;

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
    _commentsCubit = UserCommentsCubit(getIt())..loadInitial(widget.uid);
    _relationsCubit = ProfileRelationsCubit(
      followRepository: getIt<FollowRepository>(),
      authCubit: getIt<AuthCubit>(),
    );
  }

  @override
  void dispose() {
    _followUndoTimer?.cancel();
    _tabController.dispose();
    _timelineCubit.close();
    _commentsCubit.close();
    _relationsCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AuthState authState = context.watch<AuthCubit>().state;
    return MultiBlocProvider(
      providers: [
        BlocProvider<ProfileTimelineCubit>.value(value: _timelineCubit),
        BlocProvider<UserCommentsCubit>.value(value: _commentsCubit),
        BlocProvider<ProfileRelationsCubit>.value(value: _relationsCubit),
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

    final AuthState authState = context.read<AuthCubit>().state;

    // Check verification status
    if (!authState.hasLoungeWriteAccess) {
      _showVerificationRequiredDialog(authState, actionType: 'follow');
      return;
    }

    setState(() => _isFollowActionPending = true);

    // Cancel any existing undo timer
    _followUndoTimer?.cancel();

    // Store for undo
    _followTargetUid = targetUid;
    _wasFollowing = isFollowing;

    try {
      if (isFollowing) {
        await _followRepository.unfollow(followerUid: followerUid, targetUid: targetUid);
      } else {
        await _followRepository.follow(followerUid: followerUid, targetUid: targetUid);
      }

      if (!mounted) return;

      // Show undo snackbar
      SnackbarHelpers.showUndo(
        context,
        message: isFollowing ? '팔로우를 취소했어요.' : '새로운 동료를 팔로우했어요.',
        onUndo: () {
          _followUndoTimer?.cancel();
          _handleUndoFollow();
        },
      );

      // Set timer to clear undo data after 5 seconds
      _followUndoTimer = Timer(const Duration(seconds: 5), () {
        if (mounted) {
          _followTargetUid = null;
          _wasFollowing = null;
        }
      });
    } catch (_) {
      if (!mounted) return;
      SnackbarHelpers.showError(context, '팔로우 상태를 변경하지 못했습니다. 잠시 후 다시 시도해주세요.');
    } finally{
      if (mounted) {
        setState(() => _isFollowActionPending = false);
      }
    }
  }

  Future<void> _handleUndoFollow() async {
    if (_followTargetUid == null || _wasFollowing == null) {
      return;
    }

    final AuthState authState = context.read<AuthCubit>().state;
    final String? currentUid = authState.userId;
    if (currentUid == null) {
      return;
    }

    final String targetUid = _followTargetUid!;
    final bool wasFollowing = _wasFollowing!;

    // Clear undo data
    _followTargetUid = null;

    _wasFollowing = null;

    setState(() => _isFollowActionPending = true);

    try {
      // Restore previous follow state
      if (wasFollowing) {
        await _followRepository.follow(followerUid: currentUid, targetUid: targetUid);
      } else {
        await _followRepository.unfollow(followerUid: currentUid, targetUid: targetUid);
      }

      if (!mounted) return;

      SnackbarHelpers.showSuccess(context, '팔로우 상태를 복구했습니다');
    } catch (_) {
      if (!mounted) return;

      SnackbarHelpers.showError(context, '팔로우 상태 복구에 실패했습니다');
    } finally {
      if (mounted) {
        setState(() => _isFollowActionPending = false);
      }
    }
  }

  /// Show verification required dialog when user tries to interact without verification
  void _showVerificationRequiredDialog(AuthState authState, {String? actionType}) {
    final String action;
    switch (actionType) {
      case 'follow':
        action = '팔로우하려면';
        break;
      default:
        action = '작업을 수행하려면';
        break;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [Icon(Icons.lock_outline, size: 24), SizedBox(width: 8), Text('인증 필요')],
        ),
        content: Text(
          '$action 공직자 메일 인증이 필요합니다.\n\n💡 직렬 인증(급여명세서)을 완료하시면 메일 인증 없이도 바로 이용 가능합니다.',
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('취소')),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.push('/profile');
            },
            child: const Text('지금 인증하기'),
          ),
        ],
      ),
    );
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
            Text('해당 사용자를 찾을 수 없습니다.', style: Theme.of(context).textTheme.titleMedium),
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
      stream: followRepository.watchIsFollowing(followerUid: currentUid, targetUid: targetUid),
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
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: Theme.of(context).scaffoldBackgroundColor, child: _tabBar);
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
