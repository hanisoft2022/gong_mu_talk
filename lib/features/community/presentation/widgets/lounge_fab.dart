import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../profile/domain/lounge_info.dart';

class LoungeFAB extends StatefulWidget {
  const LoungeFAB({
    super.key,
    required this.selectedLounge,
    required this.onTap,
    required this.isMenuOpen,
  });

  final LoungeInfo? selectedLounge;
  final VoidCallback onTap;
  final bool isMenuOpen;

  @override
  State<LoungeFAB> createState() => _LoungeFABState();
}

class _LoungeFABState extends State<LoungeFAB> with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _rotationAnimation =
        Tween<double>(
          begin: 0.0,
          end: 0.125, // 45도 회전 (0.125 = 45/360)
        ).animate(
          CurvedAnimation(parent: _rotationController, curve: Curves.easeInOut),
        );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // 미묘한 펄스 애니메이션 시작 (3초마다 반복)
    _startPulseAnimation();
  }

  void _startPulseAnimation() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && !widget.isMenuOpen) {
        _pulseController.forward().then((_) {
          if (mounted) {
            _pulseController.reverse().then((_) {
              if (mounted) {
                _startPulseAnimation();
              }
            });
          }
        });
      } else if (mounted) {
        _startPulseAnimation();
      }
    });
  }

  @override
  void didUpdateWidget(LoungeFAB oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isMenuOpen != oldWidget.isMenuOpen) {
      if (widget.isMenuOpen) {
        _rotationController.forward();
      } else {
        _rotationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _handleTap() {
    // 햅틱 피드백
    HapticFeedback.lightImpact();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedLounge = widget.selectedLounge;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([_rotationController, _pulseController]),
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value * _pulseAnimation.value,
            child: Transform.rotate(
              angle: _rotationAnimation.value * 2 * 3.141592653589793, // 라디안 변환
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.surfaceContainerHighest,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _handleTap,
                    borderRadius: BorderRadius.circular(28),
                    child: Container(
                      decoration: const BoxDecoration(shape: BoxShape.circle),
                      child: Stack(
                        children: [
                          // 메인 아이콘 (라운지 이모지 또는 기본 아이콘)
                          Center(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              transitionBuilder: (child, animation) {
                                return ScaleTransition(
                                  scale: animation,
                                  child: FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  ),
                                );
                              },
                              child: selectedLounge != null
                                  ? Text(
                                      selectedLounge.emoji,
                                      key: ValueKey(selectedLounge.emoji),
                                      style: const TextStyle(fontSize: 24),
                                    )
                                  : Icon(
                                      Icons.forum,
                                      key: const ValueKey('default'),
                                      color: theme.colorScheme.onSurface,
                                      size: 24,
                                    ),
                            ),
                          ),

                          // 접근성을 위한 텍스트 (화면에는 보이지 않음)
                          Semantics(
                            label: widget.isMenuOpen
                                ? '라운지 메뉴 닫기'
                                : '라운지 메뉴 열기',
                            button: true,
                            child: const SizedBox.expand(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// FAB 주변에 표시되는 작은 인디케이터
class LoungeIndicator extends StatelessWidget {
  const LoungeIndicator({
    super.key,
    required this.lounge,
    required this.isVisible,
  });

  final LoungeInfo lounge;
  final bool isVisible;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedOpacity(
      opacity: isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(lounge.emoji, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            Text(
              lounge.shortName,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
