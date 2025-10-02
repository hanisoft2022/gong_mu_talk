/// Settings Section Widget
///
/// Provides a consistent container for settings groups.
///
/// **Purpose**:
/// - Create visual separation between settings groups
/// - Provide consistent styling across all settings
/// - Improve settings readability and organization
///
/// **Features**:
/// - Section title with consistent typography
/// - Card-based container with border
/// - Padding and spacing optimized for settings
/// - Accepts any list of child widgets
///
/// **Usage**:
/// Used by all settings section components to maintain
/// consistent visual appearance throughout the settings tab.

library;
import 'package:flutter/material.dart';

/// Settings section container with title and children
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}
