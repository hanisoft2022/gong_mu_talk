import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/feature_access_level.dart';
import 'package:gong_mu_talk/core/theme/app_color_extension.dart';

/// 권한이 부족한 사용자에게 안내 메시지와 인증 버튼을 표시하는 배너
///
/// 페이지 상단에 고정되어 사용자에게 필요한 인증 레벨을 알려줌
class AccessDeniedBanner extends StatelessWidget {
  /// 현재 사용자의 접근 레벨
  final FeatureAccessLevel currentLevel;

  /// 이 기능에 필요한 최소 레벨
  final FeatureAccessLevel requiredLevel;

  /// 기능 이름 (예: "연금 실수령액 상세 분석")
  final String featureName;

  /// 배너 표시 여부 (기본값: true)
  final bool showBanner;

  const AccessDeniedBanner({
    super.key,
    required this.currentLevel,
    required this.requiredLevel,
    required this.featureName,
    this.showBanner = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!showBanner || currentLevel >= requiredLevel) {
      return const SizedBox.shrink();
    }

    final message = _generateMessage();
    final buttonText = _getButtonText();
    final route = _getRoute();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.appColors.warningLight.withValues(alpha: 0.3),
            context.appColors.warningLight.withValues(alpha: 0.1),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(
          bottom: BorderSide(
            color: context.appColors.warning.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lock_outline,
            color: context.appColors.warningDark,
            size: 28,
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🔒 권한 필요',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.appColors.warningDark,
                  ),
                ),
                const Gap(4),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.appColors.warning,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (route != null) ...[
            const Gap(12),
            ElevatedButton(
              onPressed: () => context.push(route),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.appColors.warning,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              child: Text(buttonText),
            ),
          ],
        ],
      ),
    );
  }

  /// 레벨별 안내 메시지 생성
  String _generateMessage() {
    // Guest/Member → Email+ 필요
    if (currentLevel <= FeatureAccessLevel.member &&
        requiredLevel >= FeatureAccessLevel.emailVerified) {
      if (currentLevel == FeatureAccessLevel.guest) {
        // Guest: 로그인 + 인증 필요
        if (requiredLevel == FeatureAccessLevel.emailVerified) {
          return '로그인 및 공직자 메일 인증 후 $featureName을(를) 이용하실 수 있습니다.';
        } else {
          // Career 필요
          return '로그인 및 직렬 인증 후 $featureName을(를) 이용하실 수 있습니다.';
        }
      } else {
        // Member: 인증만 필요
        return '공직자 메일 인증 또는 직렬 인증 후 $featureName을(를) 이용하실 수 있습니다.';
      }
    }

    // Email → Career 필요
    if (currentLevel == FeatureAccessLevel.emailVerified &&
        requiredLevel == FeatureAccessLevel.careerVerified) {
      return '직렬 인증 후 $featureName을(를) 이용하실 수 있습니다.';
    }

    // 기타 경우
    return '$featureName은(는) ${requiredLevel.displayName} 이상 필요합니다.';
  }

  /// 버튼 텍스트 생성
  String _getButtonText() {
    if (currentLevel == FeatureAccessLevel.guest) {
      return '로그인하기';
    }

    if (requiredLevel == FeatureAccessLevel.emailVerified) {
      return '메일 인증하기';
    }

    if (requiredLevel == FeatureAccessLevel.careerVerified) {
      return '직렬 인증하기';
    }

    return '인증하기';
  }

  /// 라우트 경로 결정
  String? _getRoute() {
    if (currentLevel == FeatureAccessLevel.guest) {
      return '/login';
    }

    // Member 이상이면 프로필 페이지로
    return '/profile';
  }
}
