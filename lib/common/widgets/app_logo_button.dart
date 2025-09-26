import 'package:flutter/material.dart';

class AppLogoButton extends StatefulWidget {
  const AppLogoButton({
    super.key,
    required this.onTap,
    this.compact = false,
  });

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
    final double diameter = widget.compact ? 36 : 40;
    final InteractiveInkFeatureFactory splashFactory = Theme.of(context).splashFactory;

    return AnimatedScale(
      scale: _isPressed ? 0.94 : 1,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      child: Material(
        color: Colors.transparent,
        child: InkResponse(
          onTap: _handleTap,
          onTapDown: _handleTapDown,
          onTapCancel: _handleTapCancel,
          radius: diameter,
          containedInkWell: true,
          splashFactory: splashFactory,
          child: Padding(
            padding: widget.compact
                ? const EdgeInsets.symmetric(horizontal: 4)
                : const EdgeInsets.symmetric(horizontal: 6),
            child: Image.asset(
              'assets/images/app_logo.png',
              height: diameter,
              width: diameter,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
      ),
    );
  }
}
