import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/entities/feature_access_level.dart';

/// 잠긴 기능 표시 위젯
///
/// 사용자가 접근 권한이 없는 기능을 시각적으로 표시
/// - 자물쇠 아이콘
/// - 설명 메시지
/// - 인증하기 버튼
class LockedFeatureView extends StatelessWidget {
  const LockedFeatureView({
    super.key,
    required this.requiredLevel,
    required this.currentLevel,
    required this.featureName,
    this.customMessage,
    this.showButton = true,
  });

  /// 이 기능에 필요한 최소 레벨
  final FeatureAccessLevel requiredLevel;

  /// 현재 사용자의 레벨
  final FeatureAccessLevel currentLevel;

  /// 기능 이름 (예: "상세 분석", "30년 시뮬레이션")
  final String featureName;

  /// 커스텀 메시지 (없으면 자동 생성)
  final String? customMessage;

  /// 인증하기 버튼 표시 여부
  final bool showButton;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final message = customMessage ?? _generateMessage();
    final buttonText = _getButtonText();
    final route = requiredLevel.verificationRoute;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 64,
              color: colorScheme.outline,
            ),
            const Gap(16),
            Text(
              message,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 15,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (showButton && route != null) ...[
              const Gap(24),
              ElevatedButton(
                onPressed: () => context.push(route),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                child: Text(buttonText),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 레벨별 메시지 자동 생성
  String _generateMessage() {
    return switch (requiredLevel) {
      FeatureAccessLevel.guest || FeatureAccessLevel.member =>
        '$featureName 기능은\n회원만 이용할 수 있습니다',
      FeatureAccessLevel.emailVerified =>
        '$featureName 기능은\n공직자 메일 인증 후 이용할 수 있습니다\n\n💡 직렬 인증(급여명세서)을 완료하시면\n메일 인증 없이도 바로 이용 가능합니다',
      FeatureAccessLevel.careerVerified =>
        '$featureName 기능은\n직렬 인증(급여명세서) 후 이용할 수 있습니다',
    };
  }

  /// 버튼 텍스트 생성
  String _getButtonText() {
    return switch (requiredLevel) {
      FeatureAccessLevel.guest || FeatureAccessLevel.member => '로그인하기',
      FeatureAccessLevel.emailVerified => '지금 인증하기',
      FeatureAccessLevel.careerVerified => '직렬 인증하기',
    };
  }
}
