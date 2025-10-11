import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../domain/entities/feature_access_level.dart';

/// 접근 레벨 기반 버튼 위젯
///
/// 사용자의 인증 레벨에 따라 자동으로 활성화/비활성화 처리
/// 비활성화 상태에서 탭하면 인증 안내 다이얼로그 표시
///
/// 사용 예시:
/// ```dart
/// FeatureButton(
///   requiredLevel: FeatureAccessLevel.careerVerified,
///   onPressed: () => Navigator.push(...),
///   child: Text('30년 시뮬레이션'),
/// )
/// ```
class FeatureButton extends StatelessWidget {
  const FeatureButton({
    super.key,
    required this.requiredLevel,
    required this.onPressed,
    required this.child,
    this.featureName,
    this.icon,
    this.style,
  });

  /// 이 버튼에 필요한 최소 접근 레벨
  final FeatureAccessLevel requiredLevel;

  /// 버튼이 활성화되었을 때 실행할 콜백
  final VoidCallback onPressed;

  /// 버튼 내용 (텍스트 또는 아이콘)
  final Widget child;

  /// 기능 이름 (다이얼로그 메시지에 사용)
  final String? featureName;

  /// 버튼 아이콘 (ElevatedButton.icon 형태로 사용)
  final Widget? icon;

  /// 버튼 스타일
  final ButtonStyle? style;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        final bool canAccess = authState.canAccess(requiredLevel);

        // 접근 가능한 경우
        if (canAccess) {
          if (icon != null) {
            return ElevatedButton.icon(
              onPressed: onPressed,
              icon: icon,
              label: child,
              style: style,
            );
          }
          return ElevatedButton(onPressed: onPressed, style: style, child: child);
        }

        // 접근 불가능한 경우 - 잠금 아이콘 표시
        final colorScheme = Theme.of(context).colorScheme;
        return ElevatedButton.icon(
          onPressed: () => _showAccessDeniedDialog(context, authState),
          icon: const Icon(Icons.lock_outline, size: 18),
          label: child,
          style:
              style ??
              ElevatedButton.styleFrom(
                backgroundColor: colorScheme.surfaceContainerHighest,
                foregroundColor: colorScheme.onSurfaceVariant,
              ),
        );
      },
    );
  }

  /// 접근 불가 다이얼로그 표시
  void _showAccessDeniedDialog(BuildContext context, AuthState authState) {
    final currentLevel = authState.currentAccessLevel;
    final dialogTitle = _getDialogTitle(currentLevel);
    final message = _generateMessage(currentLevel);
    final buttonText = _getButtonText(currentLevel);

    // 현재 레벨이 guest/member이면 로그인 페이지로, 아니면 인증 페이지로
    final route = currentLevel <= FeatureAccessLevel.member
        ? '/login'
        : requiredLevel.verificationRoute;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [const Icon(Icons.lock_outline, size: 24), const Gap(8), Text(dialogTitle)],
        ),
        content: Text(message, style: const TextStyle(height: 1.5)),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('취소')),
          if (route != null)
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.push(route);
              },
              child: Text(buttonText),
            ),
        ],
      ),
    );
  }

  /// 다이얼로그 타이틀 생성
  String _getDialogTitle(FeatureAccessLevel currentLevel) {
    // 현재 레벨이 guest/member인 경우, 무조건 로그인 유도
    if (currentLevel <= FeatureAccessLevel.member) {
      return '로그인이 필요해요';
    }

    // 이미 로그인했으면 required level에 맞는 타이틀
    return switch (requiredLevel) {
      FeatureAccessLevel.guest || FeatureAccessLevel.member => '로그인이 필요해요',
      FeatureAccessLevel.emailVerified => '인증 필요',
      FeatureAccessLevel.careerVerified => '인증 필요',
    };
  }

  /// 레벨별 메시지 자동 생성
  String _generateMessage(FeatureAccessLevel currentLevel) {
    final name = featureName ?? '이 기능';

    // 현재 레벨이 guest/member인 경우, 무조건 로그인 유도
    if (currentLevel <= FeatureAccessLevel.member) {
      return '로그인하시면 $name을 비롯한 다양한 기능을 이용하실 수 있습니다.';
    }

    // 이미 로그인했으면 required level에 맞는 메시지
    return switch (requiredLevel) {
      FeatureAccessLevel.guest ||
      FeatureAccessLevel.member => '로그인하시면 $name을 비롯한 다양한 기능을 이용하실 수 있습니다.',
      FeatureAccessLevel.emailVerified =>
        '$name 기능은 공직자 메일 인증 후 이용할 수 있습니다.\n\n💡 직렬 인증(급여명세서)을 완료하시면 메일 인증 없이도 바로 이용 가능합니다.',
      FeatureAccessLevel.careerVerified => '$name 기능은 직렬 인증(급여명세서) 후 이용할 수 있습니다.',
    };
  }

  /// 버튼 텍스트 생성
  String _getButtonText(FeatureAccessLevel currentLevel) {
    // 현재 레벨이 guest/member인 경우, 무조건 로그인 버튼
    if (currentLevel <= FeatureAccessLevel.member) {
      return '로그인하기';
    }

    // 이미 로그인했으면 required level에 맞는 버튼
    return switch (requiredLevel) {
      FeatureAccessLevel.guest || FeatureAccessLevel.member => '로그인하기',
      FeatureAccessLevel.emailVerified => '지금 인증하기',
      FeatureAccessLevel.careerVerified => '직렬 인증하기',
    };
  }
}
