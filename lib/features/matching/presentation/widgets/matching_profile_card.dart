import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../profile/domain/career_track.dart';
import '../../domain/entities/curated_match.dart';
import '../../domain/entities/match_compatibility.dart';
import '../../domain/entities/match_flow.dart';
import '../../domain/entities/match_profile.dart';
import 'matching_first_message_sheet.dart';

class MatchingProfileCard extends StatelessWidget {
  const MatchingProfileCard({
    super.key,
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
    final String displayName = revealNickname ? profile.nickname : profile.maskedNickname;
    final String subtitle = '${profile.jobTitle} · ${profile.region}';
    final int compatScore = match.compatibility.totalScore.round();

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header Section
            _buildProfileHeader(context, theme, displayName, subtitle, compatScore),
            const Gap(16),

            // Match Flow Stage Section
            _buildStageFlow(context),
            const Gap(16),

            // Highlights Section
            Text(
              '핵심 일치 포인트',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Gap(8),
            _buildHighlights(theme),
            const Gap(16),

            // Compatibility Details Section
            Text(
              '궁합 디테일',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Gap(8),
            _buildCompatibilityChips(theme),
            const Gap(16),

            // Profile Introduction Section
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

            // Available Prompts Section
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

            // CTA Section
            _buildFirstMessageCta(context),
          ],
        ),
      ),
    );
  }

  // ==================== Profile Header Section ====================

  Widget _buildProfileHeader(
    BuildContext context,
    ThemeData theme,
    String displayName,
    String subtitle,
    int compatScore,
  ) {
    return Row(
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
                      Icons.verified_outlined,
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
    );
  }

  // ==================== Stage Flow Section ====================

  Widget _buildStageFlow(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int activeIndex = MatchFlowStage.values.indexOf(match.stage);
    final List<Widget> children = <Widget>[];

    for (final MatchFlowStage stage in MatchFlowStage.values) {
      final int stageIndex = MatchFlowStage.values.indexOf(stage);
      final bool isActive = stageIndex <= activeIndex;
      final Color color = isActive ? theme.colorScheme.primary : theme.colorScheme.outline;

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

  // ==================== Highlights Section ====================

  Widget _buildHighlights(ThemeData theme) {
    final List<String> reasons = match.compatibility.highlightReasons;

    if (reasons.isEmpty) {
      return Text('설문을 더 채우면 맞춤 일치 포인트를 보여드려요.', style: theme.textTheme.bodyMedium);
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
                  Icon(Icons.check_circle_outline, size: 18, color: theme.colorScheme.primary),
                  const Gap(8),
                  Expanded(child: Text(reason, style: theme.textTheme.bodyMedium)),
                ],
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  // ==================== Compatibility Chips Section ====================

  Widget _buildCompatibilityChips(ThemeData theme) {
    final List<Widget> chips = match.compatibility.breakdowns
        .map((CompatibilityBreakdown breakdown) {
          final String label = _dimensionLabel(breakdown.dimension);
          final int percent = (breakdown.score * 100).round();
          return Chip(
            label: Text('$label $percent%'),
            backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            side: BorderSide(color: theme.colorScheme.outlineVariant),
          );
        })
        .toList(growable: false);

    return Wrap(spacing: 8, runSpacing: 8, children: chips);
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

  // ==================== First Message CTA Section ====================

  Widget _buildFirstMessageCta(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Widget icon = isProcessing
        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
        : const Icon(Icons.favorite_border, size: 20);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: isProcessing ? null : () => _openFirstMessageSheet(context),
          icon: icon,
          label: Text(isProcessing ? '보내는 중...' : '관심 보내고 첫 질문 함께 전하기'),
        ),
        const Gap(8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.timer_outlined, size: 18, color: theme.colorScheme.primary),
            const Gap(8),
            Expanded(
              child: Text(
                '상대는 24시간 내 응답하도록 1회 리마인드를 받아요. 미응답 시 "예의 있게 종료"로 깔끔하게 정리할 수 있어요.',
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
            Icon(Icons.privacy_tip_outlined, size: 18, color: theme.colorScheme.primary),
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

    final FirstMessageSelection? selection = await showModalBottomSheet<FirstMessageSelection>(
      context: context,
      isScrollControlled: true,
      builder: (context) => MatchingFirstMessageSheet(prompts: prompts),
    );

    if (selection == null) {
      return;
    }

    await onSubmit(selection.prompt, selection.answer);
  }

  // ==================== Helper Methods ====================

  String _initial(String value) {
    if (value.isEmpty) {
      return '?';
    }
    return value.substring(0, 1);
  }
}
