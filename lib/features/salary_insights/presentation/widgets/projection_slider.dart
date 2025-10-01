/// Extracted from teacher_salary_insight_page.dart for better file organization
/// This widget displays a slider for adjusting projection parameters

import 'package:flutter/material.dart';

class ProjectionSlider extends StatelessWidget {
  const ProjectionSlider({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label (${(value * 100).toStringAsFixed(1)}%)',
          style: theme.textTheme.bodyLarge,
        ),
        Slider(
          value: value,
          min: 0,
          max: 0.05,
          divisions: 10,
          label: '${(value * 100).toStringAsFixed(1)}%',
          onChanged: onChanged,
        ),
      ],
    );
  }
}
