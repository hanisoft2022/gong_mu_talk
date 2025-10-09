import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  // ════════════════════════════════════════════════════════════════
  // Brand Colors (Primary Identity)
  // ════════════════════════════════════════════════════════════════
  static const Color primary = Color(0xFF0064FF); // Toss blue
  static const Color primaryDark = Color(0xFF0B1E3E);
  static const Color secondary = Color(0xFF5E8BFF);
  static const Color accent = Color(0xFF00C4B3);

  // ════════════════════════════════════════════════════════════════
  // Surface Colors (Backgrounds & Containers)
  // ════════════════════════════════════════════════════════════════
  // Light mode
  static const Color surface = Color(0xFFF3F4F8);
  static const Color surfaceBright = Color(0xFFFFFFFF);
  static const Color surfaceSubtle = Color(0xFFE8EBF3);
  static const Color outlineLight = Color(0xFFD4D9E4);

  // Dark mode
  static const Color surfaceDark = Color(0xFF0F1726);
  static const Color surfaceDarkElevated = Color(0xFF171F2F);
  static const Color surfaceDarkCard = Color(0xFF1F293C);
  static const Color outlineDark = Color(0xFF2D3A50);

  // ════════════════════════════════════════════════════════════════
  // Text Colors
  // ════════════════════════════════════════════════════════════════
  static const Color textPrimary = Color(0xFF1C2534);
  static const Color textSecondary = Color(0xFF526078);
  static const Color textPrimaryDark = Color(0xFFF4F6FF);
  static const Color textSecondaryDark = Color(0xFFB5C2DD);

  // ════════════════════════════════════════════════════════════════
  // Semantic Colors (Status & Feedback)
  // ════════════════════════════════════════════════════════════════
  // Success (Green) - 성공, 완료, 검증됨
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFF34D399);
  static const Color successDark = Color(0xFF059669);

  // Warning (Amber) - 주의, 확인 필요
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFBBF24);
  static const Color warningDark = Color(0xFFD97706);

  // Error (Red) - 오류, 실패
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFF87171);
  static const Color errorDark = Color(0xFFDC2626);

  // Info (Blue) - 정보, 안내
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFF60A5FA);
  static const Color infoDark = Color(0xFF2563EB);

  // ════════════════════════════════════════════════════════════════
  // Emotional/Action Colors (Community Features)
  // ════════════════════════════════════════════════════════════════
  // Like (Pink) - 좋아요, 인기
  static const Color like = Color(0xFFEC4899);
  static const Color likeLight = Color(0xFFF472B6);
  static const Color likeDark = Color(0xFFDB2777);

  // Highlight (Orange) - 강조, 하이라이트, 인기글
  static const Color highlight = Color(0xFFF97316);
  static const Color highlightLight = Color(0xFFFB923C);
  static const Color highlightDark = Color(0xFFEA580C);

  // Highlight Background (Yellow/Amber) - 하이라이트 배경
  static const Color highlightBgLight = Color(0xFFFFEB3B); // Light mode: Yellow
  static const Color highlightBgDark = Color(0xFFFFC107); // Dark mode: Amber
  static const Color highlightBorderLight = Color(0xFFFBC02D);
  static const Color highlightBorderDark = Color(0xFFFFD54F);

  // ════════════════════════════════════════════════════════════════
  // Financial Colors (Calculator Features)
  // ════════════════════════════════════════════════════════════════
  // Positive (Green) - 수익, 증가, 실수령액
  static const Color positive = Color(0xFF059669);
  static const Color positiveLight = Color(0xFF10B981);
  static const Color positiveDark = Color(0xFF047857);

  // Negative (Red) - 손실, 감소, 공제액
  static const Color negative = Color(0xFFDC2626);
  static const Color negativeLight = Color(0xFFEF4444);
  static const Color negativeDark = Color(0xFFB91C1C);

  // Neutral (Gray) - 중립, 기준값, 총액
  static const Color neutral = Color(0xFF6B7280);
  static const Color neutralLight = Color(0xFF9CA3AF);
  static const Color neutralDark = Color(0xFF4B5563);

  // ════════════════════════════════════════════════════════════════
  // Monochrome (Black & White variants)
  // ════════════════════════════════════════════════════════════════
  static const Color black = Color(0xFF000000);
  static const Color blackSoft = Color(0xFF1A1A1A);
  static const Color white = Color(0xFFFFFFFF);
  static const Color whiteSoft = Color(0xFFFAFAFA);
  static const Color whiteAlpha50 = Color(0x80FFFFFF); // 50% opacity
  static const Color whiteAlpha70 = Color(0xB3FFFFFF); // 70% opacity
  static const Color blackAlpha50 = Color(0x80000000); // 50% opacity
}
