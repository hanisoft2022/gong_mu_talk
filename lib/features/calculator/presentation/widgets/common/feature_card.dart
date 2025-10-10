import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../domain/entities/feature_access_level.dart';
import 'locked_feature_view.dart';

/// 접근 레벨 기반 기능 카드
///
/// 사용자의 인증 레벨에 따라 자동으로 내용을 표시하거나 잠금 화면을 표시
///
/// 사용 예시:
/// ```dart
/// FeatureCard(
///   requiredLevel: FeatureAccessLevel.emailVerified,
///   featureName: '상세 분석',
///   child: DetailedAnalysisWidget(),
/// )
/// ```
class FeatureCard extends StatelessWidget {
  const FeatureCard({
    super.key,
    required this.requiredLevel,
    required this.child,
    this.featureName,
    this.lockedMessage,
    this.showButton = true,
  });

  /// 이 기능에 필요한 최소 접근 레벨
  final FeatureAccessLevel requiredLevel;

  /// 잠금 해제 시 표시할 실제 컨텐츠
  final Widget child;

  /// 기능 이름 (잠금 메시지에 사용)
  final String? featureName;

  /// 커스텀 잠금 메시지
  final String? lockedMessage;

  /// 인증 버튼 표시 여부
  final bool showButton;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        // 접근 가능한 경우 실제 컨텐츠 표시
        if (authState.canAccess(requiredLevel)) {
          return child;
        }

        // 접근 불가능한 경우 잠금 화면 표시
        return LockedFeatureView(
          requiredLevel: requiredLevel,
          currentLevel: authState.currentAccessLevel,
          featureName: featureName ?? '이 기능',
          customMessage: lockedMessage,
          showButton: showButton,
        );
      },
    );
  }
}
