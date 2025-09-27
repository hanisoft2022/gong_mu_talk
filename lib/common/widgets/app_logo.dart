import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final bool isLightMode = Theme.of(context).brightness == Brightness.light;
    final String assetPath = isLightMode
        ? 'assets/images/app_logo_light.png'
        : 'assets/images/app_logo_dark.png';

    return Image.asset(
      assetPath,
      height: size,
      width: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    );
  }
}
