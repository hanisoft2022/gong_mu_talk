/// Profile Overview Tab
///
/// Main overview tab displaying:
/// - Profile header
/// - Paystub verification card
/// - TabBar with posts, comments, and scraps tabs
/// - HANISOFT footer
///
/// Phase 4 - Extracted from profile_page.dart
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import '../../../../../di/di.dart';
import '../../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../../community/presentation/cubit/scrap_cubit.dart';
import '../../../../community/presentation/cubit/user_comments_cubit.dart';
import '../../cubit/profile_timeline_cubit.dart';
import '../profile_verification/paystub_verification_card.dart';
import '../profile_timeline/profile_comments_tab_content.dart';
import '../profile_timeline/profile_posts_tab_content.dart';
import '../profile_timeline/profile_scraps_tab_content.dart';
import 'profile_header.dart';

class ProfileOverviewTab extends StatefulWidget {
  const ProfileOverviewTab({super.key});

  @override
  State<ProfileOverviewTab> createState() => _ProfileOverviewTabState();
}

class _ProfileOverviewTabState extends State<ProfileOverviewTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late UserCommentsCubit _userCommentsCubit;
  late ScrapCubit _scrapCubit;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _userCommentsCubit = getIt<UserCommentsCubit>();
    _scrapCubit = getIt<ScrapCubit>();

    // Load initial data for each tab
    final authState = context.read<AuthCubit>().state;
    if (authState.userId != null) {
      _userCommentsCubit.loadInitial(authState.userId!);
      _scrapCubit.loadInitial();
    }

    // Listen to tab changes to load data when needed
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final authState = context.read<AuthCubit>().state;
        if (authState.userId == null) return;

        switch (_tabController.index) {
          case 0:
            context.read<ProfileTimelineCubit>().refresh();
            break;
          case 1:
            _userCommentsCubit.refresh(authState.userId!);
            break;
          case 2:
            _scrapCubit.refresh();
            break;
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _userCommentsCubit.close();
    _scrapCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<UserCommentsCubit>.value(value: _userCommentsCubit),
        BlocProvider<ScrapCubit>.value(value: _scrapCubit),
      ],
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (BuildContext context, AuthState state) {
          final bool hasUserId = state.userId != null;

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                // Profile Header and Verification Card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        if (state.userProfile != null)
                          ProfileHeader(
                            profile: state.userProfile!,
                            isOwnProfile: true,
                            currentUserId: state.userId,
                          ),
                        if (hasUserId) ...[
                          const Gap(16),
                          PaystubVerificationCard(uid: state.userId!),
                        ],
                      ],
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
                        Tab(text: '스크랩'),
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
                if (hasUserId)
                  ProfileCommentsTabContent(authorUid: state.userId!)
                else
                  const SizedBox.shrink(),
                const ProfileScrapsTabContent(),
              ],
            ),
          );
        },
      ),
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
