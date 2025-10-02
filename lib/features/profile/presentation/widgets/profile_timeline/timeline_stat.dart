import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

/// A small stat widget showing an icon and count.
///
/// Used in timeline post tiles to display likes, comments, and views.
class TimelineStat extends StatelessWidget {
  const TimelineStat({super.key, required this.icon, required this.value});

  final IconData icon;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const Gap(4),
        Text('$value', style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
