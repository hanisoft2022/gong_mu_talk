import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

/// 권한이 없는 사용자에게 콘텐츠를 블러 처리하여 표시하는 위젯
///
/// 실제 콘텐츠 위에 블러 효과와 자물쇠 아이콘, 안내 메시지를 오버레이
class BlurredContent extends StatelessWidget {
  /// 블러 처리할 실제 콘텐츠
  final Widget child;

  /// 블러 처리 여부
  final bool isBlurred;

  /// 블러 강도 (기본값: 10.0)
  final double blurIntensity;

  /// 중앙에 표시할 메시지 (선택 사항)
  final String? lockMessage;

  /// 중앙에 표시할 버튼 텍스트 (선택 사항)
  final String? actionButtonText;

  /// 버튼 클릭 시 실행할 콜백 (선택 사항)
  final VoidCallback? onActionPressed;

  /// 카드 전체를 탭 가능하게 만들기 위한 콜백 (선택 사항)
  /// 제공되면 카드 전체에 InkWell 적용, 버튼과 동일한 동작 수행
  final VoidCallback? onCardTap;

  const BlurredContent({
    super.key,
    required this.child,
    required this.isBlurred,
    this.blurIntensity = 10.0,
    this.lockMessage,
    this.actionButtonText,
    this.onActionPressed,
    this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    if (!isBlurred) {
      return child;
    }

    return Stack(
      children: [
        // 블러 처리된 실제 콘텐츠
        Opacity(
          opacity: 0.3,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(
              sigmaX: blurIntensity,
              sigmaY: blurIntensity,
            ),
            child: IgnorePointer(child: child),
          ),
        ),

        // 중앙 오버레이 (자물쇠 + 메시지 + 버튼)
        Center(
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: InkWell(
              onTap: onCardTap,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    if (lockMessage != null) ...[
                      const Gap(16),
                      Text(
                        lockMessage!,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (actionButtonText != null && onActionPressed != null) ...[
                      const Gap(24),
                      ElevatedButton(
                        onPressed: onActionPressed,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                        ),
                        child: Text(actionButtonText!),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 개별 숫자나 텍스트를 블러 처리하는 인라인 위젯
class BlurredText extends StatelessWidget {
  /// 표시할 텍스트 (블러 처리됨)
  final String text;

  /// 텍스트 스타일
  final TextStyle? style;

  /// 블러 처리 여부
  final bool isBlurred;

  /// 블러 강도 (기본값: 6.0)
  final double blurIntensity;

  /// 자물쇠 아이콘 표시 여부
  final bool showLockIcon;

  const BlurredText({
    super.key,
    required this.text,
    this.style,
    required this.isBlurred,
    this.blurIntensity = 6.0,
    this.showLockIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isBlurred) {
      return Text(text, style: style);
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        ImageFiltered(
          imageFilter: ImageFilter.blur(
            sigmaX: blurIntensity,
            sigmaY: blurIntensity,
          ),
          child: Text(text, style: style),
        ),
        if (showLockIcon)
          Icon(
            Icons.lock_outline,
            size: (style?.fontSize ?? 14) * 0.8,
            color: (style?.color ?? Colors.black).withValues(alpha: 0.7),
          ),
      ],
    );
  }
}
