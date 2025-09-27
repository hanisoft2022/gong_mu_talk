import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_logo.dart';

class AppLogoButton extends StatefulWidget {
  const AppLogoButton({super.key, required this.onTap, this.compact = false});

  final VoidCallback onTap;
  final bool compact;

  @override
  State<AppLogoButton> createState() => _AppLogoButtonState();
}

class _AppLogoButtonState extends State<AppLogoButton> with TickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.25,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.ease));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
  }

  void _handleTapCancel() {
    if (_isPressed) {
      setState(() => _isPressed = false);
    }
  }

  Future<void> _handleTap() async {
    // 매우 미묘한 햅틱 피드백
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {
      // 햅틱 피드백이 지원되지 않는 경우 무시
    }

    // 부드러운 펄스 애니메이션 실행
    _pulseController.forward().then((_) {
      _pulseController.reverse();
    });

    setState(() => _isPressed = false);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final double diameter = widget.compact ? 44 : 52;
    final double cornerRadius = widget.compact ? 14 : 18;
    final EdgeInsets padding = widget.compact ? const EdgeInsets.all(4) : const EdgeInsets.all(6);
    final double containerSize = diameter + padding.horizontal;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return AnimatedScale(
          scale: (_isPressed ? 0.94 : 1) * _pulseAnimation.value,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: SizedBox(
            width: containerSize,
            height: containerSize,
            child: GestureDetector(
              onTap: _handleTap,
              onTapDown: _handleTapDown,
              onTapCancel: _handleTapCancel,
              child: Container(
                width: containerSize,
                height: containerSize,
                child: Container(
                  padding: padding,
                  child: Center(child: AppLogo(size: diameter * 0.9)),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
