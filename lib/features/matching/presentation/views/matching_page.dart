import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../../routing/app_router.dart';
import '../../domain/entities/curated_match.dart';
import '../../domain/entities/match_compatibility.dart';
import '../../domain/entities/match_flow.dart';
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
      listenWhen: (previous, current) =>
          previous.lastActionMessage != current.lastActionMessage,
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
            return const _MatchingLockedView(
              reason: '공직자 메일 인증이 완료된 사용자만 이용할 수 있어요.',
              showVerifyShortcut: true,
            );
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
                  body = _MatchingErrorView(
                    onRetry: () =>
                        context.read<MatchingCubit>().loadCandidates(),
                  );
                  break;
                case MatchingStatus.locked:
                  body = const _MatchingLockedView(
                    reason: '공직자 메일 인증 완료 후 이용 가능합니다.',
                    showVerifyShortcut: true,
                  );
                  break;
                case MatchingStatus.loaded:
                  body = _MatchingCandidatesView(state: state);
                  break;
              }

              if (state.status == MatchingStatus.loaded ||
                  state.status == MatchingStatus.error) {
                return RefreshIndicator(
                  onRefresh: () =>
                      context.read<MatchingCubit>().refreshCandidates(),
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
              Text(
                '매칭 후보를 불러오지 못했어요.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
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
  const _MatchingLockedView({
    required this.reason,
    this.showVerifyShortcut = false,
  });

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
            Icon(
              Icons.lock_outline,
              size: 56,
              color: theme.colorScheme.primary,
            ),
            const Gap(12),
            Text(
              '매칭 서비스 잠금',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(8),
            Text(
              reason,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
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
    final List<CuratedMatch> matches = state.candidates;

    if (matches.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const _MatchingExcludedTrackCard(),
          const Gap(24),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.hourglass_bottom_outlined, size: 56),
                const Gap(12),
                Text('오늘의 큐레이션이 소진됐어요.', style: theme.textTheme.titleMedium),
                const Gap(8),
                Text(
                  '내일 새로운 후보를 준비할게요. 취향 설문을 업데이트하면 추천 폭이 넓어져요.',
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
      itemCount: matches.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [_MatchingExcludedTrackCard(), Gap(20)],
          );
        }

        final CuratedMatch match = matches[index - 1];
        final bool isProcessing = state.actionInProgressId == match.profile.id;
        return _CuratedMatchCard(
          match: match,
          isProcessing: isProcessing,
          onSubmit: (String prompt, String answer) =>
              cubit.requestMatch(match: match, prompt: prompt, answer: answer),
        );
      },
    );
  }
}

class _MatchingExcludedTrackCard extends StatelessWidget {
  const _MatchingExcludedTrackCard();

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
                Expanded(
                  child: Text(
                    '매칭 제외 직렬',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const Gap(12),
            Text(
              excludedTracks.isEmpty
                  ? '관심 없는 직렬을 숨기면 더 맞춤형 추천을 받을 수 있어요.'
                  : '제외 직렬: ${excludedTracks.map((CareerTrack track) => track.displayName).join(', ')}',
              style: theme.textTheme.bodyMedium,
            ),
            const Gap(16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
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

class _CuratedMatchCard extends StatelessWidget {
  const _CuratedMatchCard({
    required this.match,
    required this.isProcessing,
    required this.onSubmit,
  });

  final CuratedMatch match;
  final bool isProcessing;
  final Future<void> Function(String prompt, String answer) onSubmit;

  MatchProfile get profile => match.profile;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool revealNickname =
        profile.stage == MatchProfileStage.nicknameRevealed ||
        profile.stage == MatchProfileStage.fullProfile;
    final String displayName = revealNickname
        ? profile.nickname
        : profile.maskedNickname;
    final String subtitle = '${profile.jobTitle} · ${profile.region}';
    final int compatScore = match.compatibility.totalScore.round();

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
                  backgroundColor: theme.colorScheme.primary.withValues(
                    alpha: 0.12,
                  ),
                  foregroundColor: theme.colorScheme.primary,
                  child: Text(_initial(displayName)),
                ),
                const Gap(16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            displayName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (profile.isPremium) ...[
                            const Gap(8),
                            Icon(
                              Icons.workspace_premium_outlined,
                              size: 18,
                              color: theme.colorScheme.primary,
                            ),
                          ],
                        ],
                      ),
                      Text(subtitle, style: theme.textTheme.bodyMedium),
                      Text(
                        '${profile.careerTrack.emoji} ${profile.careerTrack.displayName} · 근무 ${profile.yearsOfService}년',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '궁합',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      Text(
                        '$compatScore점',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Gap(16),
            _buildStageFlow(context),
            const Gap(16),
            Text(
              '핵심 일치 포인트',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(8),
            _buildHighlights(theme),
            const Gap(16),
            Text(
              '궁합 디테일',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(8),
            _buildCompatibilityChips(theme),
            const Gap(16),
            Text(profile.introduction, style: theme.textTheme.bodyMedium),
            if (profile.interests.isNotEmpty) ...[
              const Gap(12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: profile.interests
                    .map((interest) => Chip(label: Text(interest)))
                    .toList(growable: false),
              ),
            ],
            if (match.availablePrompts.isNotEmpty) ...[
              const Gap(16),
              Text('서로 묻고 싶은 질문', style: theme.textTheme.titleSmall),
              const Gap(8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: match.availablePrompts
                    .map((prompt) => Chip(label: Text(prompt)))
                    .toList(growable: false),
              ),
            ],
            const Gap(16),
            _buildFirstMessageCta(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStageFlow(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int activeIndex = MatchFlowStage.values.indexOf(match.stage);
    final List<Widget> children = <Widget>[];
    for (final MatchFlowStage stage in MatchFlowStage.values) {
      final int stageIndex = MatchFlowStage.values.indexOf(stage);
      final bool isActive = stageIndex <= activeIndex;
      final Color color = isActive
          ? theme.colorScheme.primary
          : theme.colorScheme.outline;
      children.add(
        Expanded(
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isActive ? 0.16 : 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(_iconForStage(stage), color: color, size: 22),
              ),
              const Gap(6),
              Text(
                stage.label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: isActive ? FontWeight.w600 : null,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
      if (stage != MatchFlowStage.values.last) {
        children.add(const Gap(12));
      }
    }
    return Row(children: children);
  }

  Widget _buildHighlights(ThemeData theme) {
    final List<String> reasons = match.compatibility.highlightReasons;
    if (reasons.isEmpty) {
      return Text(
        '설문을 더 채우면 맞춤 일치 포인트를 보여드려요.',
        style: theme.textTheme.bodyMedium,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: reasons
          .map(
            (reason) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const Gap(8),
                  Expanded(
                    child: Text(reason, style: theme.textTheme.bodyMedium),
                  ),
                ],
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  Widget _buildCompatibilityChips(ThemeData theme) {
    final List<Widget> chips = match.compatibility.breakdowns
        .map((CompatibilityBreakdown breakdown) {
          final String label = _dimensionLabel(breakdown.dimension);
          final int percent = (breakdown.score * 100).round();
          return Chip(
            label: Text('$label $percent%'),
            backgroundColor: theme.colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.5),
            side: BorderSide(color: theme.colorScheme.outlineVariant),
          );
        })
        .toList(growable: false);
    return Wrap(spacing: 8, runSpacing: 8, children: chips);
  }

  Widget _buildFirstMessageCta(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Widget icon = isProcessing
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : const Icon(Icons.favorite_border, size: 20);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: isProcessing
              ? null
              : () => _openFirstMessageSheet(context),
          icon: icon,
          label: Text(isProcessing ? '보내는 중...' : '관심 보내고 첫 질문 함께 전하기'),
        ),
        const Gap(8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.timer_outlined,
              size: 18,
              color: theme.colorScheme.primary,
            ),
            const Gap(8),
            Expanded(
              child: Text(
                '상대는 24시간 내 응답하도록 1회 리마인드를 받아요. 미응답 시 “예의 있게 종료”로 깔끔하게 정리할 수 있어요.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const Gap(8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.privacy_tip_outlined,
              size: 18,
              color: theme.colorScheme.primary,
            ),
            const Gap(8),
            Expanded(
              child: Text(
                '원터치 신고·차단과 쉿 모드로 안전하게 관계를 관리할 수 있어요.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _openFirstMessageSheet(BuildContext context) async {
    final List<String> prompts = match.availablePrompts.isEmpty
        ? <String>['내가 먼저 여쭤보고 싶은 이야기를 직접 남길게요']
        : match.availablePrompts;
    final _FirstMessageSelection? selection =
        await showModalBottomSheet<_FirstMessageSelection>(
          context: context,
          isScrollControlled: true,
          builder: (context) => _FirstMessagePromptSheet(prompts: prompts),
        );
    if (selection == null) {
      return;
    }
    await onSubmit(selection.prompt, selection.answer);
  }

  IconData _iconForStage(MatchFlowStage stage) {
    switch (stage) {
      case MatchFlowStage.interestExpression:
        return Icons.favorite_border;
      case MatchFlowStage.conversation:
        return Icons.forum_outlined;
      case MatchFlowStage.meetingPreparation:
        return Icons.event_available_outlined;
      case MatchFlowStage.relationshipProgress:
        return Icons.rocket_launch_outlined;
    }
  }
}

class _FirstMessagePromptSheet extends StatefulWidget {
  const _FirstMessagePromptSheet({required this.prompts});

  final List<String> prompts;

  @override
  State<_FirstMessagePromptSheet> createState() =>
      _FirstMessagePromptSheetState();
}

class _FirstMessagePromptSheetState extends State<_FirstMessagePromptSheet> {
  String? _selectedPrompt;
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    if (widget.prompts.length == 1) {
      _selectedPrompt = widget.prompts.first;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _selectedPrompt != null && _controller.text.trim().isNotEmpty;

  void _handleSubmit() {
    if (!_canSubmit) {
      return;
    }
    Navigator.of(context).pop(
      _FirstMessageSelection(
        prompt: _selectedPrompt!,
        answer: _controller.text.trim(),
      ),
    );
  }

  Widget _buildPromptOption(String prompt) {
    final ThemeData theme = Theme.of(context);
    final bool isSelected = _selectedPrompt == prompt;
    final Color borderColor = isSelected
        ? theme.colorScheme.primary
        : theme.colorScheme.outlineVariant;
    final Color iconColor = isSelected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => _selectedPrompt = prompt),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Text(prompt, style: theme.textTheme.bodyMedium),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Gap(16),
              Text(
                '관심 보내기',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Gap(8),
              Text(
                '서로 묻고 싶은 질문 중 하나를 골라 답변을 함께 보내주세요.',
                style: theme.textTheme.bodyMedium,
              ),
              const Gap(16),
              ...widget.prompts.map(_buildPromptOption),
              const Gap(12),
              TextField(
                controller: _controller,
                maxLines: 4,
                maxLength: 200,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  labelText: '내 답변',
                  hintText: '상대가 대화를 이어갈 수 있도록 진심을 담아 적어주세요.',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const Gap(12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const Gap(8),
                  Expanded(
                    child: Text(
                      '상대는 24시간 내에 응답하도록 1회 리마인드를 받아요. 응답이 없으면 “예의 있게 종료” 버튼이 활성화돼요.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const Gap(8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.report_outlined,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const Gap(8),
                  Expanded(
                    child: Text(
                      '무례함·불법 권유·외부 연락 강요는 신고/차단해주세요. 누적 신고 시 자동 제재가 적용됩니다.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const Gap(20),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: _canSubmit ? _handleSubmit : null,
                      child: const Text('첫 질문과 함께 관심 보내기'),
                    ),
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

class _FirstMessageSelection {
  const _FirstMessageSelection({required this.prompt, required this.answer});

  final String prompt;
  final String answer;
}

String _dimensionLabel(CompatibilityDimension dimension) {
  switch (dimension) {
    case CompatibilityDimension.coreValues:
      return '가치관';
    case CompatibilityDimension.lifestyle:
      return '생활 리듬';
    case CompatibilityDimension.distance:
      return '이동/거리';
    case CompatibilityDimension.familyPlan:
      return '결혼·가족';
    case CompatibilityDimension.trustSignals:
      return '신뢰 신호';
    case CompatibilityDimension.preferenceTags:
      return '취향 태그';
  }
}

String _initial(String value) {
  if (value.isEmpty) {
    return '?';
  }
  return value.substring(0, 1);
}
