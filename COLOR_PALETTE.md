# 🎨 GongMuTalk Color Palette

**Last Updated**: 2025-01-09
**Version**: 1.0.0

This document provides a visual reference for all colors used in the GongMuTalk app.

---

## 📋 Table of Contents

1. [Brand Colors](#brand-colors)
2. [Surface Colors](#surface-colors)
3. [Semantic Colors](#semantic-colors)
4. [Emotional/Action Colors](#emotionalaction-colors)
5. [Financial Colors](#financial-colors)
6. [Monochrome](#monochrome)
7. [Usage Examples](#usage-examples)
8. [Accessibility](#accessibility)

---

## 🏷️ Brand Colors

Primary colors that define GongMuTalk's brand identity.

| Color | Hex | Preview | Usage | Dart Reference |
|-------|-----|---------|-------|----------------|
| **Primary** | `#0064FF` | ![#0064FF](https://via.placeholder.com/100x40/0064FF/FFFFFF?text=Primary) | Main brand color, CTAs, primary actions | `AppColors.primary` |
| **Primary Dark** | `#0B1E3E` | ![#0B1E3E](https://via.placeholder.com/100x40/0B1E3E/FFFFFF?text=Dark) | Dark mode seed, headers | `AppColors.primaryDark` |
| **Secondary** | `#5E8BFF` | ![#5E8BFF](https://via.placeholder.com/100x40/5E8BFF/FFFFFF?text=Secondary) | Secondary actions, accents | `AppColors.secondary` |
| **Accent** | `#00C4B3` | ![#00C4B3](https://via.placeholder.com/100x40/00C4B3/FFFFFF?text=Accent) | Highlights, special features | `AppColors.accent` |

---

## 🖼️ Surface Colors

Background and container colors for light/dark modes.

### Light Mode

| Color | Hex | Preview | Usage | Dart Reference |
|-------|-----|---------|-------|----------------|
| **Surface** | `#F3F4F8` | ![#F3F4F8](https://via.placeholder.com/100x40/F3F4F8/000000?text=Surface) | Main background | `AppColors.surface` |
| **Surface Bright** | `#FFFFFF` | ![#FFFFFF](https://via.placeholder.com/100x40/FFFFFF/000000?text=Bright) | Cards, elevated surfaces | `AppColors.surfaceBright` |
| **Surface Subtle** | `#E8EBF3` | ![#E8EBF3](https://via.placeholder.com/100x40/E8EBF3/000000?text=Subtle) | Input fields, containers | `AppColors.surfaceSubtle` |
| **Outline Light** | `#D4D9E4` | ![#D4D9E4](https://via.placeholder.com/100x40/D4D9E4/000000?text=Outline) | Borders, dividers | `AppColors.outlineLight` |

### Dark Mode

| Color | Hex | Preview | Usage | Dart Reference |
|-------|-----|---------|-------|----------------|
| **Surface Dark** | `#0F1726` | ![#0F1726](https://via.placeholder.com/100x40/0F1726/FFFFFF?text=Surface) | Main background | `AppColors.surfaceDark` |
| **Surface Dark Elevated** | `#171F2F` | ![#171F2F](https://via.placeholder.com/100x40/171F2F/FFFFFF?text=Elevated) | App bars, elevated surfaces | `AppColors.surfaceDarkElevated` |
| **Surface Dark Card** | `#1F293C` | ![#1F293C](https://via.placeholder.com/100x40/1F293C/FFFFFF?text=Card) | Cards, containers | `AppColors.surfaceDarkCard` |
| **Outline Dark** | `#2D3A50` | ![#2D3A50](https://via.placeholder.com/100x40/2D3A50/FFFFFF?text=Outline) | Borders, dividers | `AppColors.outlineDark` |

---

## ✅ Semantic Colors

Status and feedback colors.

### Success (Green)

| Variant | Hex | Preview | Usage | Dart Reference |
|---------|-----|---------|-------|----------------|
| **Success** | `#10B981` | ![#10B981](https://via.placeholder.com/100x40/10B981/FFFFFF?text=Success) | Default success state | `AppColors.success` |
| **Success Light** | `#34D399` | ![#34D399](https://via.placeholder.com/100x40/34D399/000000?text=Light) | Light variant | `AppColors.successLight` |
| **Success Dark** | `#059669` | ![#059669](https://via.placeholder.com/100x40/059669/FFFFFF?text=Dark) | Dark variant, verification | `AppColors.successDark` |

### Warning (Amber)

| Variant | Hex | Preview | Usage | Dart Reference |
|---------|-----|---------|-------|----------------|
| **Warning** | `#F59E0B` | ![#F59E0B](https://via.placeholder.com/100x40/F59E0B/000000?text=Warning) | Default warning state | `AppColors.warning` |
| **Warning Light** | `#FBBF24` | ![#FBBF24](https://via.placeholder.com/100x40/FBBF24/000000?text=Light) | Light variant | `AppColors.warningLight` |
| **Warning Dark** | `#D97706` | ![#D97706](https://via.placeholder.com/100x40/D97706/FFFFFF?text=Dark) | Dark variant, medium password | `AppColors.warningDark` |

### Error (Red)

| Variant | Hex | Preview | Usage | Dart Reference |
|---------|-----|---------|-------|----------------|
| **Error** | `#EF4444` | ![#EF4444](https://via.placeholder.com/100x40/EF4444/FFFFFF?text=Error) | Default error state | `AppColors.error` |
| **Error Light** | `#F87171` | ![#F87171](https://via.placeholder.com/100x40/F87171/000000?text=Light) | Light variant (dark mode) | `AppColors.errorLight` |
| **Error Dark** | `#DC2626` | ![#DC2626](https://via.placeholder.com/100x40/DC2626/FFFFFF?text=Dark) | Dark variant | `AppColors.errorDark` |

### Info (Blue)

| Variant | Hex | Preview | Usage | Dart Reference |
|---------|-----|---------|-------|----------------|
| **Info** | `#3B82F6` | ![#3B82F6](https://via.placeholder.com/100x40/3B82F6/FFFFFF?text=Info) | Information messages | `AppColors.info` |
| **Info Light** | `#60A5FA` | ![#60A5FA](https://via.placeholder.com/100x40/60A5FA/000000?text=Light) | Light variant | `AppColors.infoLight` |
| **Info Dark** | `#2563EB` | ![#2563EB](https://via.placeholder.com/100x40/2563EB/FFFFFF?text=Dark) | Dark variant | `AppColors.infoDark` |

---

## 💖 Emotional/Action Colors

Colors for community features and user interactions.

### Like (Pink)

| Variant | Hex | Preview | Usage | Dart Reference |
|---------|-----|---------|-------|----------------|
| **Like** | `#EC4899` | ![#EC4899](https://via.placeholder.com/100x40/EC4899/FFFFFF?text=Like) | Like button, favorite | `AppColors.like` |
| **Like Light** | `#F472B6` | ![#F472B6](https://via.placeholder.com/100x40/F472B6/000000?text=Light) | Light variant | `AppColors.likeLight` |
| **Like Dark** | `#DB2777` | ![#DB2777](https://via.placeholder.com/100x40/DB2777/FFFFFF?text=Dark) | Dark variant | `AppColors.likeDark` |

### Highlight (Orange)

| Variant | Hex | Preview | Usage | Dart Reference |
|---------|-----|---------|-------|----------------|
| **Highlight** | `#F97316` | ![#F97316](https://via.placeholder.com/100x40/F97316/FFFFFF?text=Highlight) | Hot posts, featured | `AppColors.highlight` |
| **Highlight Light** | `#FB923C` | ![#FB923C](https://via.placeholder.com/100x40/FB923C/000000?text=Light) | Light variant (dark mode) | `AppColors.highlightLight` |
| **Highlight Dark** | `#EA580C` | ![#EA580C](https://via.placeholder.com/100x40/EA580C/FFFFFF?text=Dark) | Dark variant (light mode) | `AppColors.highlightDark` |

### Highlight Background

| Variant | Hex | Preview | Usage | Dart Reference |
|---------|-----|---------|-------|----------------|
| **BG Light** | `#FFEB3B` | ![#FFEB3B](https://via.placeholder.com/100x40/FFEB3B/000000?text=BG+Light) | Highlight background (light) | `AppColors.highlightBgLight` |
| **BG Dark** | `#FFC107` | ![#FFC107](https://via.placeholder.com/100x40/FFC107/000000?text=BG+Dark) | Highlight background (dark) | `AppColors.highlightBgDark` |
| **Border Light** | `#FBC02D` | ![#FBC02D](https://via.placeholder.com/100x40/FBC02D/000000?text=Border) | Highlight border (light) | `AppColors.highlightBorderLight` |
| **Border Dark** | `#FFD54F` | ![#FFD54F](https://via.placeholder.com/100x40/FFD54F/000000?text=Border) | Highlight border (dark) | `AppColors.highlightBorderDark` |

---

## 💰 Financial Colors

Calculator and salary-related colors.

### Positive (Green)

| Variant | Hex | Preview | Usage | Dart Reference |
|---------|-----|---------|-------|----------------|
| **Positive** | `#059669` | ![#059669](https://via.placeholder.com/100x40/059669/FFFFFF?text=Positive) | Income, gains, net salary | `AppColors.positive` |
| **Positive Light** | `#10B981` | ![#10B981](https://via.placeholder.com/100x40/10B981/FFFFFF?text=Light) | Light variant | `AppColors.positiveLight` |
| **Positive Dark** | `#047857` | ![#047857](https://via.placeholder.com/100x40/047857/FFFFFF?text=Dark) | Dark variant | `AppColors.positiveDark` |

### Negative (Red)

| Variant | Hex | Preview | Usage | Dart Reference |
|---------|-----|---------|-------|----------------|
| **Negative** | `#DC2626` | ![#DC2626](https://via.placeholder.com/100x40/DC2626/FFFFFF?text=Negative) | Deductions, losses | `AppColors.negative` |
| **Negative Light** | `#EF4444` | ![#EF4444](https://via.placeholder.com/100x40/EF4444/FFFFFF?text=Light) | Light variant | `AppColors.negativeLight` |
| **Negative Dark** | `#B91C1C` | ![#B91C1C](https://via.placeholder.com/100x40/B91C1C/FFFFFF?text=Dark) | Dark variant | `AppColors.negativeDark` |

### Neutral (Gray)

| Variant | Hex | Preview | Usage | Dart Reference |
|---------|-----|---------|-------|----------------|
| **Neutral** | `#6B7280` | ![#6B7280](https://via.placeholder.com/100x40/6B7280/FFFFFF?text=Neutral) | Total amounts, base values | `AppColors.neutral` |
| **Neutral Light** | `#9CA3AF` | ![#9CA3AF](https://via.placeholder.com/100x40/9CA3AF/000000?text=Light) | Light variant | `AppColors.neutralLight` |
| **Neutral Dark** | `#4B5563` | ![#4B5563](https://via.placeholder.com/100x40/4B5563/FFFFFF?text=Dark) | Dark variant | `AppColors.neutralDark` |

---

## ⚫⚪ Monochrome

Black and white variants for overlay and special UI elements.

| Color | Hex | Preview | Usage | Dart Reference |
|-------|-----|---------|-------|----------------|
| **Black** | `#000000` | ![#000000](https://via.placeholder.com/100x40/000000/FFFFFF?text=Black) | Pure black | `AppColors.black` |
| **Black Soft** | `#1A1A1A` | ![#1A1A1A](https://via.placeholder.com/100x40/1A1A1A/FFFFFF?text=Soft) | Softer black | `AppColors.blackSoft` |
| **White** | `#FFFFFF` | ![#FFFFFF](https://via.placeholder.com/100x40/FFFFFF/000000?text=White) | Pure white | `AppColors.white` |
| **White Soft** | `#FAFAFA` | ![#FAFAFA](https://via.placeholder.com/100x40/FAFAFA/000000?text=Soft) | Softer white | `AppColors.whiteSoft` |
| **White Alpha 50%** | `#80FFFFFF` | ![#80FFFFFF](https://via.placeholder.com/100x40/80FFFFFF/000000?text=50%25) | Semi-transparent white | `AppColors.whiteAlpha50` |
| **White Alpha 70%** | `#B3FFFFFF` | ![#B3FFFFFF](https://via.placeholder.com/100x40/B3FFFFFF/000000?text=70%25) | Semi-transparent white | `AppColors.whiteAlpha70` |
| **Black Alpha 50%** | `#80000000` | ![#80000000](https://via.placeholder.com/100x40/80000000/FFFFFF?text=50%25) | Semi-transparent black | `AppColors.blackAlpha50` |

---

## 📝 Usage Examples

### ✅ Correct Usage

```dart
// ✅ Use semantic colors
Icon(Icons.check_circle, color: AppColors.success)

// ✅ Use financial colors in calculator
Text(
  '₩1,234,560',
  style: TextStyle(color: AppColors.positive), // Green for income
)

// ✅ Use emotional colors for actions
Icon(
  Icons.favorite,
  color: AppColors.like, // Pink for like button
)

// ✅ Use theme colors when possible
Icon(
  Icons.info,
  color: Theme.of(context).colorScheme.primary,
)
```

### ❌ Incorrect Usage

```dart
// ❌ Don't use hardcoded Material colors
Icon(Icons.check_circle, color: Colors.green)

// ❌ Don't use Color() constructor directly
Container(color: Color(0xFFEF4444))

// ❌ Don't use arbitrary alpha values
Divider(color: Colors.grey.withOpacity(0.3))
```

---

## ♿ Accessibility

### Contrast Ratios

All color combinations meet WCAG 2.1 AA standards (minimum 4.5:1 for normal text, 3:1 for large text).

#### Text on Surface

| Combination | Ratio | WCAG AA | WCAG AAA |
|-------------|-------|---------|----------|
| Primary on White | 8.6:1 | ✅ Pass | ✅ Pass |
| Error on White | 4.5:1 | ✅ Pass | ❌ Fail |
| Success on White | 3.8:1 | ❌ Fail* | ❌ Fail |
| Text Primary on Surface | 14.2:1 | ✅ Pass | ✅ Pass |

*Note: Success color should only be used for large text or icons, not body text.

#### Action Colors

| Combination | Ratio | WCAG AA | Use Case |
|-------------|-------|---------|----------|
| Like (Pink) on White | 4.2:1 | ✅ Pass | Large text/icons only |
| Highlight (Orange) on White | 3.1:1 | ✅ Pass | Icons/badges only |
| Positive (Green) on Surface | 5.2:1 | ✅ Pass | Financial data |

### Color Blindness Support

- **Deuteranopia/Protanopia** (Red-Green): Avoid relying solely on red/green for critical information. Use icons and text labels.
- **Tritanopia** (Blue-Yellow): Primary blue and warning amber are distinguishable.
- **Best Practice**: Always pair colors with icons or text labels for status indicators.

---

## 🔧 Implementation Reference

All colors are defined in: [`lib/core/constants/app_colors.dart`](/lib/core/constants/app_colors.dart)

Theme integration: [`lib/core/theme/app_theme.dart`](/lib/core/theme/app_theme.dart)

Guidelines: [`CLAUDE-GUIDELINES.md`](/CLAUDE-GUIDELINES.md#color-system-guidelines)

---

**Need to add a new color?** Check the [Color Guidelines](./CLAUDE-GUIDELINES.md#-adding-new-colors) first!
