/// Verification Card Base Widget
///
/// Common base widget for verification status cards.
/// Used by PaystubVerificationCard and GovernmentEmailVerificationCard
/// to maintain consistent UI/UX.
///
/// Design based on PaystubVerificationCard's style:
/// - Container with padding and borderRadius for leadingIcon
/// - Row layout: leadingIcon, Column(title, subtitle), trailing
/// - InkWell for tap interaction
library;

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class VerificationCardBase extends StatelessWidget {
  const VerificationCardBase({
    super.key,
    required this.leadingIcon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
    this.backgroundColor,
  });

  /// Leading icon widget (typically Container + Icon)
  final Widget leadingIcon;

  /// Main title text
  final String title;

  /// Subtitle/description text
  final String subtitle;

  /// Optional tap handler
  final VoidCallback? onTap;

  /// Optional trailing widget (arrow, progress indicator, etc.)
  final Widget? trailing;

  /// Optional background color for the card
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Card(
      color: backgroundColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              leadingIcon,
              const Gap(16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Gap(4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const Gap(8),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper to create standard icon container
/// (for consistency across verification cards)
Widget buildIconContainer({
  required BuildContext context,
  required IconData icon,
  required Color backgroundColor,
  required Color iconColor,
}) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Icon(
      icon,
      color: iconColor,
      size: 24,
    ),
  );
}
