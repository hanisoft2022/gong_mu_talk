/// Lounge App Bar - Custom SliverAppBar for community feed
///
/// Responsibilities:
/// - Dynamic app bar with elevation control
/// - Lounge title display
/// - Profile navigation
/// - Theme integration

library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../cubit/community_feed_cubit.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../common/widgets/global_app_bar_actions.dart';
import '../../../../common/widgets/app_logo_button.dart';
import '../../../../routing/app_router.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';

/// Custom SliverAppBar for lounge/community feed
class LoungeSliverAppBar extends StatelessWidget {
  const LoungeSliverAppBar({
    required this.feedState,
    required this.isElevated,
    required this.onLogoTap,
    super.key,
  });

  final CommunityFeedState feedState;
  final bool isElevated;
  final VoidCallback onLogoTap;

  String _getAppBarTitle(CommunityFeedState feedState) {
    if (feedState.selectedLoungeInfo != null) {
      final lounge = feedState.selectedLoungeInfo!;
      if (lounge.id == 'all') {
        return '전체 라운지';
      } else {
        return '${lounge.name} 라운지';
      }
    }
    return '공무톡';
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final Color background = Color.lerp(
      colorScheme.surface.withValues(alpha: 0.9),
      colorScheme.surface,
      isElevated ? 1 : 0,
    )!;
    final double radius = isElevated ? 12 : 18;
    const double toolbarHeight = 64;

    return SliverAppBar(
      floating: true,
      snap: true,
      stretch: true,
      forceElevated: isElevated,
      elevation: isElevated ? 3 : 0,
      scrolledUnderElevation: 6,
      titleSpacing: 12,
      toolbarHeight: toolbarHeight,
      leadingWidth: toolbarHeight,
      backgroundColor: background,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withValues(alpha: isElevated ? 0.08 : 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(radius)),
      ),
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: AppLogoButton(compact: true, onTap: onLogoTap),
      ),
      title: Text(
        _getAppBarTitle(feedState),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      actions: [
        BlocSelector<AuthCubit, AuthState, bool>(
          selector: (state) => state.isLoggedIn,
          builder: (context, isLoggedIn) {
            if (!isLoggedIn) return const SizedBox.shrink();

            return BlocBuilder<ThemeCubit, ThemeMode>(
              builder: (context, themeMode) {
                return GlobalAppBarActions(
                  compact: true,
                  opacity: isElevated ? 1 : 0.92,
                  onProfileTap: () => GoRouter.of(context).push(ProfileRoute.path),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
