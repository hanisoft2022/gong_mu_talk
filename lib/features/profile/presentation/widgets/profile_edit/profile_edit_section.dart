/// ProfileEditSection
///
/// 프로필 편집 페이지의 섹션 레이아웃 위젯
///
/// Phase 2 - Extracted from profile_page.dart
///
/// Features:
/// - 섹션 타이틀과 컨텐츠를 감싸는 레이아웃
/// - 일관된 간격과 스타일
///
/// File Size: ~40 lines (Green Zone ✅)
library;

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class ProfileEditSection extends StatelessWidget {
  const ProfileEditSection({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const Gap(8),
        child,
      ],
    );
  }
}
