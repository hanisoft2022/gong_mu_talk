import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gong_mu_talk/core/constants/app_colors.dart';
import 'package:gong_mu_talk/core/utils/color_contrast_checker.dart';

void main() {
  group('ColorContrastChecker', () {
    group('calculateRatio', () {
      test('maximum contrast (black on white) should be 21:1', () {
        final ratio = ColorContrastChecker.calculateRatio(
          Colors.black,
          Colors.white,
        );
        expect(ratio, closeTo(21.0, 0.1));
      });

      test('minimum contrast (same color) should be 1:1', () {
        final ratio = ColorContrastChecker.calculateRatio(
          Colors.blue,
          Colors.blue,
        );
        expect(ratio, closeTo(1.0, 0.01));
      });

      test('primary on white should have good contrast', () {
        final ratio = ColorContrastChecker.calculateRatio(
          AppColors.primary,
          Colors.white,
        );
        expect(ratio, greaterThan(4.5)); // Should pass WCAG AA
      });
    });

    group('check', () {
      test('black on white should pass both AA and AAA', () {
        final result = ColorContrastChecker.check(
          foreground: Colors.black,
          background: Colors.white,
        );

        expect(result.ratio, greaterThan(7.0));
        expect(result.passesAA, isTrue);
        expect(result.passesAAA, isTrue);
        expect(result.complianceLevel, 'AAA');
      });

      test('AppColors.success on white should pass AA for large text', () {
        final result = ColorContrastChecker.check(
          foreground: AppColors.success,
          background: Colors.white,
          textSize: TextSize.large,
        );

        expect(result.passesAA, isTrue);
      });

      test('AppColors.error on white should pass AA', () {
        final result = ColorContrastChecker.check(
          foreground: AppColors.error,
          background: Colors.white,
        );

        expect(result.passesAA, isTrue);
        expect(result.ratio, greaterThan(4.5));
      });

      test('low contrast should fail and provide recommendation', () {
        final result = ColorContrastChecker.check(
          foreground: const Color(0xFFCCCCCC),
          background: Colors.white,
        );

        expect(result.passesAA, isFalse);
        expect(result.recommendation, contains('too low'));
        expect(result.recommendation, contains('4.5:1'));
      });
    });

    group('TextSize.fromTextStyle', () {
      test('should identify large text correctly (18pt)', () {
        final textSize = TextSize.fromTextStyle(
          const TextStyle(fontSize: 24.0),
        );
        expect(textSize, TextSize.large);
      });

      test('should identify large text correctly (14pt bold)', () {
        final textSize = TextSize.fromTextStyle(
          const TextStyle(fontSize: 18.66, fontWeight: FontWeight.bold),
        );
        expect(textSize, TextSize.large);
      });

      test('should identify normal text', () {
        final textSize = TextSize.fromTextStyle(
          const TextStyle(fontSize: 16.0),
        );
        expect(textSize, TextSize.normal);
      });
    });

    group('getSuggestedForeground', () {
      test('should suggest white for dark backgrounds', () {
        final suggested = ColorContrastChecker.getSuggestedForeground(
          Colors.black,
        );
        expect(suggested, Colors.white);
      });

      test('should suggest black for light backgrounds', () {
        final suggested = ColorContrastChecker.getSuggestedForeground(
          Colors.white,
        );
        expect(suggested, Colors.black);
      });

      test('should suggest correct color for AppColors.primary', () {
        final suggested = ColorContrastChecker.getSuggestedForeground(
          AppColors.primary,
        );
        expect(suggested, Colors.white);
      });
    });

    group('isDark', () {
      test('should identify dark colors', () {
        expect(ColorContrastChecker.isDark(Colors.black), isTrue);
        expect(ColorContrastChecker.isDark(AppColors.primary), isTrue);
        expect(ColorContrastChecker.isDark(AppColors.error), isTrue);
      });

      test('should identify light colors', () {
        expect(ColorContrastChecker.isDark(Colors.white), isFalse);
        expect(ColorContrastChecker.isDark(const Color(0xFFF0F0F0)), isFalse);
      });
    });

    group('ColorContrastExtension', () {
      test('contrastWith should calculate ratio', () {
        final ratio = Colors.black.contrastWith(Colors.white);
        expect(ratio, closeTo(21.0, 0.1));
      });

      test('hasGoodContrastWith should check AA compliance', () {
        expect(
          Colors.black.hasGoodContrastWith(Colors.white),
          isTrue,
        );
        expect(
          const Color(0xFFCCCCCC).hasGoodContrastWith(Colors.white),
          isFalse,
        );
      });

      test('suggestedTextColor should work', () {
        expect(Colors.black.suggestedTextColor, Colors.white);
        expect(Colors.white.suggestedTextColor, Colors.black);
      });

      test('isDark extension should work', () {
        expect(Colors.black.isDark, isTrue);
        expect(Colors.white.isDark, isFalse);
      });
    });

    group('App Colors Validation', () {
      test('all semantic colors should have good contrast on white', () {
        final colors = {
          'error': AppColors.error,
          'warning': AppColors.warning,
          'info': AppColors.info,
        };

        for (final entry in colors.entries) {
          final result = ColorContrastChecker.check(
            foreground: entry.value,
            background: Colors.white,
          );

          expect(
            result.passesAA,
            isTrue,
            reason: '${entry.key} should pass AA on white background',
          );
        }
      });

      test('financial colors should be distinguishable', () {
        // Positive and Negative should have different enough colors
        final positiveRatio = ColorContrastChecker.calculateRatio(
          AppColors.positive,
          Colors.white,
        );
        final negativeRatio = ColorContrastChecker.calculateRatio(
          AppColors.negative,
          Colors.white,
        );

        expect(positiveRatio, greaterThan(3.0));
        expect(negativeRatio, greaterThan(3.0));
      });
    });
  });
}
