import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../domain/services/career_display_helper.dart';
import '../../domain/services/lounge_access_service.dart';
import '../../../profile/domain/lounge_info.dart';

/// 라운지 상세 정보를 표시하는 BottomSheet
class LoungeDetailSheet extends StatelessWidget {
  const LoungeDetailSheet({super.key, required this.lounge});

  final LoungeInfo lounge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final requiredCareerIds = LoungeAccessService.getRequiredCareerIds(
      lounge.id,
    );
    final isUnified = requiredCareerIds.length > 1;

    if (!isUnified) {
      // 단일 직렬 라운지는 상세 정보 없음
      return Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${lounge.emoji} ${lounge.name}',
              style: theme.textTheme.titleLarge,
            ),
            const Gap(16),
            Text(
              lounge.description ?? '',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 드래그 핸들
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // 스크롤 가능한 컨텐츠
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 헤더: 라운지 정보
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            lounge.emoji,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                      const Gap(12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lounge.name,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${requiredCareerIds.length}개 직렬 통합 라운지',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const Gap(24),

                  // 접근 가능한 직렬 제목
                  Text(
                    '접근 가능한 직렬',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Gap(12),

                  // 직렬 목록 (그룹별)
                  ...CareerDisplayHelper.groupCareers(
                    requiredCareerIds,
                  ).expand((group) {
                    return [
                      // 그룹 헤더
                      if (requiredCareerIds.length > 5) ...[
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 4,
                            top: 8,
                            bottom: 6,
                          ),
                          child: Text(
                            group.name,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],

                      // 그룹 내 직렬 목록
                      ...group.careerIds.map((careerId) {
                        final careerName =
                            CareerDisplayHelper.getCareerDisplayName(careerId);
                        final careerEmoji = CareerDisplayHelper.getCareerEmoji(
                          careerId,
                        );

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Text(
                                careerEmoji,
                                style: const TextStyle(fontSize: 18),
                              ),
                              const Gap(12),
                              Text(
                                careerName,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        );
                      }),
                    ];
                  }),

                  const Gap(16),

                  // 설명 (있는 경우)
                  if (lounge.description != null &&
                      lounge.description!.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer.withValues(
                          alpha: 0.3,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                          const Gap(8),
                          Expanded(
                            child: Text(
                              lounge.description!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSecondaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Gap(16),
                  ],
                ],
              ),
            ),
          ),

          const Gap(16),

          // 닫기 버튼 (스크롤 영역 외부)
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('닫기'),
            ),
          ),
        ],
      ),
    );
  }
}
