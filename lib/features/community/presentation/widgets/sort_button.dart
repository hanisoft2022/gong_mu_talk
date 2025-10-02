import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../domain/models/feed_filters.dart';

class SortButton extends StatelessWidget {
  const SortButton({
    super.key,
    required this.sortType,
    required this.isSelected,
    required this.onPressed,
    required this.theme,
  });

  final LoungeSort sortType;
  final bool isSelected;
  final VoidCallback onPressed;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final IconData icon = sortType.icon;
    final String label = sortType.label;
    final Color iconColor = sortType.getColor(context);

    if (isSelected) {
      // Show icon + text for selected button
      return Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: iconColor),
              const Gap(5),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Show only icon for unselected button
      return SizedBox(
        height: 44,
        width: 44,
        child: Material(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onPressed,
            child: Icon(icon, size: 18, color: iconColor),
          ),
        ),
      );
    }
  }
}