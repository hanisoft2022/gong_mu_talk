# Flutter Color API Guidelines

## Deprecated APIs

### ❌ withOpacity() - DEPRECATED
```dart
// WRONG - deprecated
color.withOpacity(0.5)
```

### ✅ withValues() - USE THIS
```dart
// CORRECT
color.withValues(alpha: 0.5)
```

## Why the Change?

`withOpacity()` is deprecated to avoid precision loss. Use `withValues()` instead.

## Common Patterns

```dart
// Divider with transparency
theme.dividerColor.withValues(alpha: 0.1)

// Outline with transparency
theme.colorScheme.outline.withValues(alpha: 0.5)

// Background with transparency
theme.colorScheme.surface.withValues(alpha: 0.8)
```

## Migration

When you see deprecation warning for `withOpacity`:
1. Replace `withOpacity(value)` with `withValues(alpha: value)`
2. The alpha value range is still 0.0-1.0

## AI Agent Instruction

**ALWAYS use `withValues(alpha: value)` instead of `withOpacity(value)` when modifying color transparency in Flutter.**
