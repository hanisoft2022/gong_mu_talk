import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Theme extension for easy access to custom app colors
///
/// Usage:
/// ```dart
/// // Access via theme
/// final successColor = Theme.of(context).extension<AppColorExtension>()!.success;
///
/// // Or use the helper extension
/// final successColor = context.appColors.success;
/// ```
@immutable
class AppColorExtension extends ThemeExtension<AppColorExtension> {
  const AppColorExtension({
    required this.success,
    required this.successLight,
    required this.successDark,
    required this.warning,
    required this.warningLight,
    required this.warningDark,
    required this.error,
    required this.errorLight,
    required this.errorDark,
    required this.info,
    required this.infoLight,
    required this.infoDark,
    required this.like,
    required this.likeLight,
    required this.likeDark,
    required this.highlight,
    required this.highlightLight,
    required this.highlightDark,
    required this.highlightBg,
    required this.highlightBorder,
    required this.positive,
    required this.positiveLight,
    required this.positiveDark,
    required this.negative,
    required this.negativeLight,
    required this.negativeDark,
    required this.neutral,
    required this.neutralLight,
    required this.neutralDark,
  });

  // Semantic colors
  final Color success;
  final Color successLight;
  final Color successDark;
  final Color warning;
  final Color warningLight;
  final Color warningDark;
  final Color error;
  final Color errorLight;
  final Color errorDark;
  final Color info;
  final Color infoLight;
  final Color infoDark;

  // Emotional/Action colors
  final Color like;
  final Color likeLight;
  final Color likeDark;
  final Color highlight;
  final Color highlightLight;
  final Color highlightDark;
  final Color highlightBg;
  final Color highlightBorder;

  // Financial colors
  final Color positive;
  final Color positiveLight;
  final Color positiveDark;
  final Color negative;
  final Color negativeLight;
  final Color negativeDark;
  final Color neutral;
  final Color neutralLight;
  final Color neutralDark;

  /// Light theme colors (using darker shades for better contrast)
  static const light = AppColorExtension(
    success: AppColors.successDark, // #059669 (darker green)
    successLight: AppColors.success,
    successDark: AppColors.successDark,
    warning: AppColors.warningDark, // #D97706 (darker amber)
    warningLight: AppColors.warning,
    warningDark: AppColors.warningDark,
    error: AppColors.errorDark, // #DC2626 (darker red)
    errorLight: AppColors.error,
    errorDark: AppColors.errorDark,
    info: AppColors.infoDark, // #2563EB (darker blue)
    infoLight: AppColors.info,
    infoDark: AppColors.infoDark,
    like: AppColors.likeDark, // #DB2777 (darker pink)
    likeLight: AppColors.like,
    likeDark: AppColors.likeDark,
    highlight: AppColors.highlightDark, // #EA580C (darker orange)
    highlightLight: AppColors.highlight,
    highlightDark: AppColors.highlightDark,
    highlightBg: AppColors.highlightBgLight,
    highlightBorder: AppColors.highlightBorderLight,
    positive: AppColors.positiveDark, // #047857 (darker green)
    positiveLight: AppColors.positive,
    positiveDark: AppColors.positiveDark,
    negative: AppColors.negativeDark, // #B91C1C (darker red)
    negativeLight: AppColors.negative,
    negativeDark: AppColors.negativeDark,
    neutral: AppColors.neutralDark, // #4B5563 (darker gray)
    neutralLight: AppColors.neutral,
    neutralDark: AppColors.neutralDark,
  );

  /// Dark theme colors
  static const dark = AppColorExtension(
    success: AppColors.successLight,
    successLight: AppColors.success,
    successDark: AppColors.successDark,
    warning: AppColors.warningLight,
    warningLight: AppColors.warning,
    warningDark: AppColors.warningDark,
    error: AppColors.errorLight,
    errorLight: AppColors.error,
    errorDark: AppColors.errorDark,
    info: AppColors.infoLight,
    infoLight: AppColors.info,
    infoDark: AppColors.infoDark,
    like: AppColors.like,
    likeLight: AppColors.likeLight,
    likeDark: AppColors.likeDark,
    highlight: AppColors.highlightLight,
    highlightLight: AppColors.highlight,
    highlightDark: AppColors.highlightDark,
    highlightBg: AppColors.highlightBgDark,
    highlightBorder: AppColors.highlightBorderDark,
    positive: AppColors.positiveLight,
    positiveLight: AppColors.positive,
    positiveDark: AppColors.positiveDark,
    negative: AppColors.negativeLight,
    negativeLight: AppColors.negative,
    negativeDark: AppColors.negativeDark,
    neutral: AppColors.neutralLight,
    neutralLight: AppColors.neutral,
    neutralDark: AppColors.neutralDark,
  );

  @override
  ThemeExtension<AppColorExtension> copyWith({
    Color? success,
    Color? successLight,
    Color? successDark,
    Color? warning,
    Color? warningLight,
    Color? warningDark,
    Color? error,
    Color? errorLight,
    Color? errorDark,
    Color? info,
    Color? infoLight,
    Color? infoDark,
    Color? like,
    Color? likeLight,
    Color? likeDark,
    Color? highlight,
    Color? highlightLight,
    Color? highlightDark,
    Color? highlightBg,
    Color? highlightBorder,
    Color? positive,
    Color? positiveLight,
    Color? positiveDark,
    Color? negative,
    Color? negativeLight,
    Color? negativeDark,
    Color? neutral,
    Color? neutralLight,
    Color? neutralDark,
  }) {
    return AppColorExtension(
      success: success ?? this.success,
      successLight: successLight ?? this.successLight,
      successDark: successDark ?? this.successDark,
      warning: warning ?? this.warning,
      warningLight: warningLight ?? this.warningLight,
      warningDark: warningDark ?? this.warningDark,
      error: error ?? this.error,
      errorLight: errorLight ?? this.errorLight,
      errorDark: errorDark ?? this.errorDark,
      info: info ?? this.info,
      infoLight: infoLight ?? this.infoLight,
      infoDark: infoDark ?? this.infoDark,
      like: like ?? this.like,
      likeLight: likeLight ?? this.likeLight,
      likeDark: likeDark ?? this.likeDark,
      highlight: highlight ?? this.highlight,
      highlightLight: highlightLight ?? this.highlightLight,
      highlightDark: highlightDark ?? this.highlightDark,
      highlightBg: highlightBg ?? this.highlightBg,
      highlightBorder: highlightBorder ?? this.highlightBorder,
      positive: positive ?? this.positive,
      positiveLight: positiveLight ?? this.positiveLight,
      positiveDark: positiveDark ?? this.positiveDark,
      negative: negative ?? this.negative,
      negativeLight: negativeLight ?? this.negativeLight,
      negativeDark: negativeDark ?? this.negativeDark,
      neutral: neutral ?? this.neutral,
      neutralLight: neutralLight ?? this.neutralLight,
      neutralDark: neutralDark ?? this.neutralDark,
    );
  }

  @override
  ThemeExtension<AppColorExtension> lerp(
    covariant ThemeExtension<AppColorExtension>? other,
    double t,
  ) {
    if (other is! AppColorExtension) {
      return this;
    }

    return AppColorExtension(
      success: Color.lerp(success, other.success, t)!,
      successLight: Color.lerp(successLight, other.successLight, t)!,
      successDark: Color.lerp(successDark, other.successDark, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningLight: Color.lerp(warningLight, other.warningLight, t)!,
      warningDark: Color.lerp(warningDark, other.warningDark, t)!,
      error: Color.lerp(error, other.error, t)!,
      errorLight: Color.lerp(errorLight, other.errorLight, t)!,
      errorDark: Color.lerp(errorDark, other.errorDark, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoLight: Color.lerp(infoLight, other.infoLight, t)!,
      infoDark: Color.lerp(infoDark, other.infoDark, t)!,
      like: Color.lerp(like, other.like, t)!,
      likeLight: Color.lerp(likeLight, other.likeLight, t)!,
      likeDark: Color.lerp(likeDark, other.likeDark, t)!,
      highlight: Color.lerp(highlight, other.highlight, t)!,
      highlightLight: Color.lerp(highlightLight, other.highlightLight, t)!,
      highlightDark: Color.lerp(highlightDark, other.highlightDark, t)!,
      highlightBg: Color.lerp(highlightBg, other.highlightBg, t)!,
      highlightBorder: Color.lerp(highlightBorder, other.highlightBorder, t)!,
      positive: Color.lerp(positive, other.positive, t)!,
      positiveLight: Color.lerp(positiveLight, other.positiveLight, t)!,
      positiveDark: Color.lerp(positiveDark, other.positiveDark, t)!,
      negative: Color.lerp(negative, other.negative, t)!,
      negativeLight: Color.lerp(negativeLight, other.negativeLight, t)!,
      negativeDark: Color.lerp(negativeDark, other.negativeDark, t)!,
      neutral: Color.lerp(neutral, other.neutral, t)!,
      neutralLight: Color.lerp(neutralLight, other.neutralLight, t)!,
      neutralDark: Color.lerp(neutralDark, other.neutralDark, t)!,
    );
  }
}

/// Extension on BuildContext for easy access to app colors
extension AppColorExtensionGetter on BuildContext {
  /// Get app colors from theme
  ///
  /// Usage:
  /// ```dart
  /// Icon(Icons.check_circle, color: context.appColors.success)
  /// ```
  AppColorExtension get appColors {
    return Theme.of(this).extension<AppColorExtension>() ??
        AppColorExtension.light;
  }
}
