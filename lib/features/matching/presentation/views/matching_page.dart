import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../../routing/app_router.dart';
import '../../domain/entities/match_profile.dart';
import '../cubit/matching_cubit.dart';
import '../../../profile/domain/career_track.dart';

class MatchingPage extends StatefulWidget {
  const MatchingPage({super.key});

  @override
  State<MatchingPage> createState() => _MatchingPageState();
}

class _MatchingPageState extends State<MatchingPage> {
  @override
  void initState() {
    super.initState();
    final AuthCubit authCubit = context.read<AuthCubit>();
    authCubit.refreshAuthStatus();
    context.read<MatchingCubit>().loadCandidates();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MatchingCubit, MatchingState>(
      listenWhen: (previous, current) => previous.lastActionMessage != current.lastActionMessage,
      listener: (context, state) {
        final String? message = state.lastActionMessage;
        if (message == null) {
          return;
        }
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
        context.read<MatchingCubit>().clearMessage();
      },
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          if (!authState.isLoggedIn) {
            return const _MatchingLockedView(reason: '로그인이 필요합니다.');
          }

          if (!authState.isGovernmentEmailVerified) {
            return const _MatchingLockedView(reason: '공직자 메일 인증이 완료된 사용자만 이용할 수 있어요.', showVerifyShortcut: true);
          }

          return BlocBuilder<MatchingCubit, MatchingState>(
            builder: (context, state) {
              Widget body;
              switch (state.status) {
                case MatchingStatus.initial:
                case MatchingStatus.loading:
                  body = const _MatchingLoadingView();
                  break;
                case MatchingStatus.error:
                  body = _MatchingErrorView(onRetry: () => context.read<MatchingCubit>().loadCandidates());
                  break;
                case MatchingStatus.locked:
                  body = const _MatchingLockedView(reason: '공직자 메일 인증 완료 후 이용 가능합니다.', showVerifyShortcut: true);
                  break;
                case MatchingStatus.loaded:
                  body = _MatchingCandidatesView(state: state);
                  break;
              }

              if (state.status == MatchingStatus.loaded || state.status == MatchingStatus.error) {
                return RefreshIndicator(
                  onRefresh: () => context.read<MatchingCubit>().refreshCandidates(),
                  child: body,
                );
              }

              return body;
            },
          );
        },
      ),
    );
  }
}

class _MatchingLoadingView extends StatelessWidget {
  const _MatchingLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _MatchingErrorView extends StatelessWidget {
  const _MatchingErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 56),
              const Gap(12),
              Text('매칭 후보를 불러오지 못했어요.', style: Theme.of(context).textTheme.titleMedium),
              const Gap(12),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_outlined),
                label: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MatchingLockedView extends StatelessWidget {
  const _MatchingLockedView({required this.reason, this.showVerifyShortcut = false});

  final String reason;
  final bool showVerifyShortcut;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 56, color: theme.colorScheme.primary),
            const Gap(12),
            Text('매칭 서비스 잠금', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const Gap(8),
            Text(reason, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
            if (showVerifyShortcut) ...[
              const Gap(20),
              OutlinedButton.icon(
                onPressed: () => _goToProfile(context),
                icon: const Icon(Icons.verified_user_outlined),
                label: const Text('공직자 메일 인증하기'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _goToProfile(BuildContext context) {
    final GoRouter router = GoRouter.of(context);
    router.go(ProfileRoute.path);
  }
}

class _MatchingCandidatesView extends StatelessWidget {
  const _MatchingCandidatesView({required this.state});

  final MatchingState state;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final MatchingCubit cubit = context.read<MatchingCubit>();

    if (state.candidates.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Gap(24),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.sentiment_satisfied_alt_outlined, size: 56),
                const Gap(12),
                Text('지금은 추천할 후보가 없어요.', style: theme.textTheme.titleMedium),
                const Gap(8),
                Text(
                  '잠시 후 다시 확인하거나, 프로필 정보를 업데이트해보세요.',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: state.candidates.length,
      itemBuilder: (context, index) {
        final MatchProfile profile = state.candidates[index];
        final bool isProcessing = state.actionInProgressId == profile.id;
        final bool revealNickname =
            profile.stage == MatchProfileStage.nicknameRevealed || profile.stage == MatchProfileStage.fullProfile;
        final String displayName = revealNickname ? profile.nickname : profile.maskedNickname;
        final String subTitle = '${profile.jobTitle} · ${profile.region}';

        return Card(
          margin: const EdgeInsets.only(bottom: 20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
                      foregroundColor: theme.colorScheme.primary,
                      child: Text(_initial(displayName)),
                    ),
                    const Gap(16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(displayName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                          Text(subTitle, style: theme.textTheme.bodyMedium),
                          Text(
                            '${profile.careerTrack.emoji} ${profile.careerTrack.displayName} · 근무 ${profile.yearsOfService}년',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Gap(16),
                Text(profile.introduction, style: theme.textTheme.bodyMedium),
                const Gap(12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: profile.interests.map((interest) => Chip(label: Text(interest))).toList(growable: false),
                ),
                if (profile.badges.isNotEmpty) ...[
                  const Gap(12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: profile.badges
                        .map((badge) => Chip(avatar: const Icon(Icons.stars, size: 16), label: Text(badge)))
                        .toList(growable: false),
                  ),
                ],
                const Gap(16),
                _MatchRequestButton(isProcessing: isProcessing, onPressed: () => cubit.requestMatch(profile.id)),
              ],
            ),
          ),
        );
      },
    );
  }
}

String _initial(String value) {
  if (value.isEmpty) {
    return '?';
  }
  return value.substring(0, 1);
}

class _MatchRequestButton extends StatefulWidget {
  const _MatchRequestButton({required this.isProcessing, required this.onPressed});

  final bool isProcessing;
  final VoidCallback onPressed;

  @override
  State<_MatchRequestButton> createState() => _MatchRequestButtonState();
}

class _MatchRequestButtonState extends State<_MatchRequestButton> {
  @override
  void initState() {
    super.initState();
  }

  void _handlePressed() {
    if (widget.isProcessing) {
      return;
    }

    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final Widget icon = widget.isProcessing
        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
        : const Icon(Icons.favorite_border, size: 22);

    return FilledButton(
      onPressed: widget.isProcessing ? null : _handlePressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: 28, height: 28, child: Center(child: icon)),
          const Gap(8),
          Text(widget.isProcessing ? '요청 중...' : '매칭 신청'),
        ],
      ),
    );
  }
}
