import 'package:flutter/material.dart';

import 'app_logo.dart';

class AppLogoButton extends StatefulWidget {
  const AppLogoButton({super.key, required this.onTap, this.compact = false});

  final VoidCallback onTap;
  final bool compact;

  @override
  State<AppLogoButton> createState() => _AppLogoButtonState();
}

class _AppLogoButtonState extends State<AppLogoButton> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
  }

  void _handleTapCancel() {
    if (_isPressed) {
      setState(() => _isPressed = false);
    }
  }

  Future<void> _handleTap() async {
    setState(() => _isPressed = false);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final double diameter = widget.compact ? 44 : 52;
    final BorderRadius borderRadius = BorderRadius.circular(widget.compact ? 14 : 18);
    final InteractiveInkFeatureFactory splashFactory = Theme.of(context).splashFactory;
    final EdgeInsets padding = widget.compact ? const EdgeInsets.all(4) : const EdgeInsets.all(6);
    final double paddedWidth = diameter + padding.horizontal;
    final double paddedHeight = diameter + padding.vertical;
    final double containerSize = paddedWidth > paddedHeight ? paddedWidth : paddedHeight;

    return AnimatedScale(
      scale: _isPressed ? 0.94 : 1,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      child: SizedBox.square(
        dimension: containerSize,
        child: Material(
          color: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _handleTap,
            onTapDown: _handleTapDown,
            onTapCancel: _handleTapCancel,
            splashFactory: splashFactory,
            customBorder: RoundedRectangleBorder(borderRadius: borderRadius),
            borderRadius: borderRadius,
            child: Padding(
              padding: padding,
              child: ClipRRect(
                borderRadius: borderRadius,
                child: SizedBox.square(
                  dimension: diameter,
                  child: Center(child: AppLogo(size: diameter * 0.9)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
