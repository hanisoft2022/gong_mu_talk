import 'dart:math' as math;
import 'package:flutter/material.dart';

/// WCAG 2.1 Contrast Level
enum WCAGLevel {
  /// WCAG AA - Minimum contrast (4.5:1 for normal text, 3:1 for large text)
  aa,

  /// WCAG AAA - Enhanced contrast (7:1 for normal text, 4.5:1 for large text)
  aaa;

  /// Get minimum contrast ratio for normal text
  double get normalTextRatio {
    switch (this) {
      case WCAGLevel.aa:
        return 4.5;
      case WCAGLevel.aaa:
        return 7.0;
    }
  }

  /// Get minimum contrast ratio for large text
  double get largeTextRatio {
    switch (this) {
      case WCAGLevel.aa:
        return 3.0;
      case WCAGLevel.aaa:
        return 4.5;
    }
  }
}

/// Text size category for WCAG compliance
enum TextSize {
  /// Normal text (< 18pt regular or < 14pt bold)
  normal,

  /// Large text (≥ 18pt regular or ≥ 14pt bold)
  large;

  /// Check if a Flutter text style is considered "large" by WCAG standards
  static TextSize fromTextStyle(TextStyle? style) {
    if (style == null) return TextSize.normal;

    final fontSize = style.fontSize ?? 14.0;
    final isBold = (style.fontWeight ?? FontWeight.normal).index >=
        FontWeight.bold.index;

    // WCAG large text: 18pt (24px) or 14pt (18.66px) bold
    // Flutter uses logical pixels, so we use these as approximations
    if (fontSize >= 24.0) return TextSize.large;
    if (fontSize >= 18.66 && isBold) return TextSize.large;

    return TextSize.normal;
  }
}

/// Contrast check result
class ContrastResult {
  const ContrastResult({
    required this.ratio,
    required this.passesAA,
    required this.passesAAA,
    required this.recommendation,
  });

  /// Calculated contrast ratio (e.g., 4.5)
  final double ratio;

  /// Passes WCAG AA standards
  final bool passesAA;

  /// Passes WCAG AAA standards
  final bool passesAAA;

  /// Recommendation for improving contrast
  final String recommendation;

  /// Get a formatted ratio string (e.g., "4.5:1")
  String get ratioString => '${ratio.toStringAsFixed(2)}:1';

  /// Get compliance level as string
  String get complianceLevel {
    if (passesAAA) return 'AAA';
    if (passesAA) return 'AA';
    return 'Fail';
  }

  @override
  String toString() {
    return 'ContrastResult(ratio: $ratioString, compliance: $complianceLevel)';
  }
}

/// Color contrast checker following WCAG 2.1 guidelines
class ColorContrastChecker {
  const ColorContrastChecker._();

  /// Calculate contrast ratio between two colors
  ///
  /// Returns a value between 1:1 (no contrast) and 21:1 (maximum contrast)
  static double calculateRatio(Color foreground, Color background) {
    final luminance1 = _calculateRelativeLuminance(foreground);
    final luminance2 = _calculateRelativeLuminance(background);

    final lighter = math.max(luminance1, luminance2);
    final darker = math.min(luminance1, luminance2);

    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Check if color combination meets WCAG standards
  ///
  /// - [foreground]: Text or icon color
  /// - [background]: Background color
  /// - [textSize]: Normal or large text
  /// - [level]: WCAG AA or AAA
  static ContrastResult check({
    required Color foreground,
    required Color background,
    TextSize textSize = TextSize.normal,
    WCAGLevel level = WCAGLevel.aa,
  }) {
    final ratio = calculateRatio(foreground, background);

    final passesAA = ratio >= (textSize == TextSize.normal
        ? WCAGLevel.aa.normalTextRatio
        : WCAGLevel.aa.largeTextRatio);

    final passesAAA = ratio >= (textSize == TextSize.normal
        ? WCAGLevel.aaa.normalTextRatio
        : WCAGLevel.aaa.largeTextRatio);

    String recommendation = '';
    if (!passesAA) {
      recommendation =
          'Contrast too low (${ratio.toStringAsFixed(2)}:1). '
          'Need at least ${WCAGLevel.aa.normalTextRatio}:1 for AA compliance. '
          'Consider using a darker foreground or lighter background.';
    } else if (!passesAAA && level == WCAGLevel.aaa) {
      recommendation =
          'Passes AA but not AAA (${ratio.toStringAsFixed(2)}:1). '
          'Need ${WCAGLevel.aaa.normalTextRatio}:1 for AAA compliance.';
    } else {
      recommendation = 'Color combination meets WCAG $complianceLevel standards.';
    }

    return ContrastResult(
      ratio: ratio,
      passesAA: passesAA,
      passesAAA: passesAAA,
      recommendation: recommendation,
    );
  }

  /// Get compliance level string based on passes
  static String get complianceLevel {
    throw UnsupportedError('Use ContrastResult.complianceLevel instead');
  }

  /// Calculate relative luminance of a color
  ///
  /// Formula from WCAG 2.1:
  /// https://www.w3.org/TR/WCAG21/#dfn-relative-luminance
  static double _calculateRelativeLuminance(Color color) {
    // Convert to sRGB
    final r = _linearizeColorComponent((color.r * 255.0).round() / 255.0);
    final g = _linearizeColorComponent((color.g * 255.0).round() / 255.0);
    final b = _linearizeColorComponent((color.b * 255.0).round() / 255.0);

    // Calculate luminance
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  /// Linearize color component for luminance calculation
  static double _linearizeColorComponent(double component) {
    if (component <= 0.03928) {
      return component / 12.92;
    } else {
      return math.pow((component + 0.055) / 1.055, 2.4).toDouble();
    }
  }

  /// Get suggested foreground color for background
  ///
  /// Returns either white or black depending on which provides better contrast
  static Color getSuggestedForeground(Color background) {
    final whiteRatio = calculateRatio(Colors.white, background);
    final blackRatio = calculateRatio(Colors.black, background);

    return whiteRatio > blackRatio ? Colors.white : Colors.black;
  }

  /// Check if color is considered "dark"
  ///
  /// Uses luminance threshold of 0.5
  static bool isDark(Color color) {
    return _calculateRelativeLuminance(color) < 0.5;
  }

  /// Validate all app colors against common backgrounds
  ///
  /// Useful for development/debugging
  static Map<String, ContrastResult> validateAppColors({
    required Map<String, Color> colors,
    required Color lightBackground,
    required Color darkBackground,
  }) {
    final results = <String, ContrastResult>{};

    for (final entry in colors.entries) {
      final bg = isDark(entry.value) ? lightBackground : darkBackground;
      results[entry.key] = check(
        foreground: entry.value,
        background: bg,
      );
    }

    return results;
  }
}

/// Extension on Color for quick contrast checks
extension ColorContrastExtension on Color {
  /// Calculate contrast ratio with another color
  double contrastWith(Color other) {
    return ColorContrastChecker.calculateRatio(this, other);
  }

  /// Check if this color has sufficient contrast with another
  bool hasGoodContrastWith(
    Color other, {
    TextSize textSize = TextSize.normal,
    WCAGLevel level = WCAGLevel.aa,
  }) {
    final result = ColorContrastChecker.check(
      foreground: this,
      background: other,
      textSize: textSize,
      level: level,
    );
    return level == WCAGLevel.aa ? result.passesAA : result.passesAAA;
  }

  /// Get suggested text color (white or black) for this background
  Color get suggestedTextColor {
    return ColorContrastChecker.getSuggestedForeground(this);
  }

  /// Check if this color is dark
  bool get isDark {
    return ColorContrastChecker.isDark(this);
  }
}
