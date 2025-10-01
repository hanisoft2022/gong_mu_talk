/// Refactored to meet AI token optimization guidelines
/// Main coordinator file for life home page
/// Extracted widgets moved to separate files for better organization
/// Target: ≤400 lines (UI file guideline)

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../di/di.dart';
import '../../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../community/data/mock_social_graph.dart';
import '../../matching/presentation/views/matching_page.dart';
import '../data/mock_life_repository.dart';
import '../domain/life_meeting.dart';
import '../domain/life_section.dart';
import 'cubit/life_section_cubit.dart';
import 'utils/life_scroll_coordinator.dart';
import 'widgets/meeting_creation_sheet.dart';
import 'widgets/meeting_widgets.dart';
import '../../../common/widgets/app_logo_button.dart';
import '../../../common/widgets/global_app_bar_actions.dart';
import '../../../common/widgets/auth_required_view.dart';
import '../../../routing/app_router.dart';

class LifeHomePage extends StatefulWidget {
  const LifeHomePage({super.key});

  @override
  State<LifeHomePage> createState() => _LifeHomePageState();
}

class _LifeHomePageState extends State<LifeHomePage> {
  late final MockLifeRepository _lifeRepository;
  late final MockSocialGraph _socialGraph;
  late final ScrollController _scrollController;
  int _lastScrollRequestId = 0;
  bool _isAppBarElevated = false;

  @override
  void initState() {
    super.initState();
    _lifeRepository = getIt<MockLifeRepository>();
    _socialGraph = getIt<MockSocialGraph>();
    context.read<AuthCubit>().refreshAuthStatus();
    _scrollController = ScrollController();
    _scrollController.addListener(_handleScrollOffset);
    _lastScrollRequestId = LifeScrollCoordinator.instance.lastRequestId;
    LifeScrollCoordinator.instance.addListener(_handleScrollRequest);
  }

  @override
  void dispose() {
    LifeScrollCoordinator.instance.removeListener(_handleScrollRequest);
    _scrollController
      ..removeListener(_handleScrollOffset)
      ..dispose();
    super.dispose();
  }

  void _handleScrollRequest() {
    final int requestId = LifeScrollCoordinator.instance.lastRequestId;
    if (requestId == _lastScrollRequestId) {
      return;
    }
    _lastScrollRequestId = requestId;
    if (!_scrollController.hasClients) {
      return;
    }
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }

  void _handleScrollOffset() {
    if (!_scrollController.hasClients) {
      return;
    }
    final bool shouldElevate = _scrollController.offset > 4;
    if (shouldElevate != _isAppBarElevated) {
      setState(() => _isAppBarElevated = shouldElevate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        if (!authState.hasLoungeAccess) {
          return Scaffold(
            body: NestedScrollView(
              controller: _scrollController,
              headerSliverBuilder: (context, _) => <Widget>[_buildLifeSliverAppBar(context)],
              body: const AuthRequiredView(message: '라이프 기능을 이용하려면\n공직자 메일 인증을 완료해주세요.'),
            ),
          );
        }

        final LifeSection section = context.watch<LifeSectionCubit>().state;
        final Widget content = AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: section == LifeSection.meetings
              ? _MeetingsView(repository: _lifeRepository, socialGraph: _socialGraph)
              : const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: MatchingPage()),
        );

        return Scaffold(
          body: NestedScrollView(
            controller: _scrollController,
            headerSliverBuilder: (context, _) => <Widget>[_buildLifeSliverAppBar(context)],
            body: SafeArea(
              top: false,
              child: Padding(padding: const EdgeInsets.only(top: 12), child: content),
            ),
          ),
        );
      },
    );
  }

  SliverAppBar _buildLifeSliverAppBar(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final Color background = Color.lerp(
      colorScheme.surface.withValues(alpha: 0.9),
      colorScheme.surface,
      _isAppBarElevated ? 1 : 0,
    )!;
    final double radius = _isAppBarElevated ? 12 : 18;
    const double toolbarHeight = 64;

    return SliverAppBar(
      floating: true,
      snap: true,
      stretch: true,
      forceElevated: _isAppBarElevated,
      elevation: _isAppBarElevated ? 3 : 0,
      scrolledUnderElevation: 6,
      toolbarHeight: toolbarHeight,
      titleSpacing: 12,
      leadingWidth: toolbarHeight,
      backgroundColor: background,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withValues(alpha: _isAppBarElevated ? 0.08 : 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(radius)),
      ),
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: AppLogoButton(
          compact: true,
          onTap: LifeScrollCoordinator.instance.requestScrollToTop,
        ),
      ),
      title: const _LifeSectionSelector(),
      actions: [
        GlobalAppBarActions(
          compact: true,
          opacity: _isAppBarElevated ? 1 : 0.92,
          onProfileTap: () => GoRouter.of(context).push(ProfileRoute.path),
        ),
      ],
    );
  }
}

class _LifeSectionSelector extends StatelessWidget {
  const _LifeSectionSelector();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LifeSectionCubit, LifeSection>(
      builder: (context, section) {
        final ThemeData theme = Theme.of(context);
        final TextStyle labelStyle =
            theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600) ??
            const TextStyle(fontSize: 13, fontWeight: FontWeight.w600);

        final ButtonStyle style = ButtonStyle(
          visualDensity: VisualDensity.compact,
          padding: WidgetStateProperty.resolveWith(
            (states) => const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          textStyle: WidgetStatePropertyAll<TextStyle>(labelStyle),
          shape: WidgetStateProperty.resolveWith(
            (states) =>
                const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
          ),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return theme.colorScheme.primary.withAlpha(40);
            }
            return theme.colorScheme.surfaceContainerHighest;
          }),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
          side: WidgetStateProperty.resolveWith(
            (states) => BorderSide(
              color: states.contains(WidgetState.selected)
                  ? theme.colorScheme.primary.withAlpha(153)
                  : theme.dividerColor,
            ),
          ),
        );

        return SegmentedButton<LifeSection>(
          style: style,
          segments: const <ButtonSegment<LifeSection>>[
            ButtonSegment<LifeSection>(
              value: LifeSection.meetings,
              label: Text('모임'),
              icon: Icon(Icons.groups_outlined),
            ),
            ButtonSegment<LifeSection>(
              value: LifeSection.matching,
              label: Text('매칭'),
              icon: Icon(Icons.favorite_outline),
            ),
          ],
          selected: <LifeSection>{section},
          onSelectionChanged: (selection) {
            context.read<LifeSectionCubit>().setSection(selection.first);
          },
        );
      },
    );
  }
}

class _MeetingsView extends StatelessWidget {
  const _MeetingsView({required this.repository, required this.socialGraph});

  final MockLifeRepository repository;
  final MockSocialGraph socialGraph;

  @override
  Widget build(BuildContext context) {
    final AuthState authState = context.watch<AuthCubit>().state;

    return StreamBuilder<List<LifeMeeting>>(
      stream: repository.watchMeetings(),
      builder: (context, snapshot) {
        final List<LifeMeeting> meetings = snapshot.data ?? const <LifeMeeting>[];

        return RefreshIndicator(
          onRefresh: () async {
            await Future<void>.delayed(const Duration(milliseconds: 300));
          },
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              MeetingCreateCard(
                onCreate: () =>
                    _openCreateSheet(context, repository: repository, authState: authState),
              ),
              const Gap(20),
              if (meetings.isEmpty)
                EmptyMeetingsView(
                  onCreate: () =>
                      _openCreateSheet(context, repository: repository, authState: authState),
                )
              else
                ...meetings.map(
                  (LifeMeeting meeting) =>
                      MeetingTile(meeting: meeting, authState: authState, repository: repository),
                ),
            ],
          ),
        );
      },
    );
  }

  void _openCreateSheet(
    BuildContext context, {
    required MockLifeRepository repository,
    required AuthState authState,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => MeetingCreationSheet(repository: repository, authState: authState),
    );
  }
}
