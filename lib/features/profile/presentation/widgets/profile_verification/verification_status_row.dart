import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

/// A row displaying the verification status of a specific verification method.
///
/// Shows an icon, label, and status text (인증됨/미인증).
class VerificationStatusRow extends StatelessWidget {
  const VerificationStatusRow({
    super.key,
    required this.icon,
    required this.label,
    required this.isVerified,
  });

  final IconData icon;
  final String label;
  final bool isVerified;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: isVerified ? theme.colorScheme.primary : theme.colorScheme.error,
        ),
        const Gap(8),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface),
          ),
        ),
        Text(
          isVerified ? '인증됨' : '미인증',
          style: theme.textTheme.bodySmall?.copyWith(
            color: isVerified ? theme.colorScheme.primary : theme.colorScheme.error,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
