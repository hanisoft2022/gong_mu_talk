import 'package:flutter/material.dart';

/// Reusable base widget for calculator cards with lock/unlock states
///
/// This widget provides a consistent UI pattern for calculator feature cards:
/// - Lock state: Shows lock icon and message
/// - Unlocked state: Shows custom content
/// - Optional header icon with color
/// - Optional CTA button
/// - Optional tap handler
///
/// Used by: PensionCard, AnnualSalaryCard, RetirementBenefitCard, EarlyRetirementCard
class LockableInfoCard extends StatelessWidget {
  const LockableInfoCard({
    super.key,
    required this.isLocked,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.content,
    this.ctaButton,
    this.lockedMessage = '정보 입력 후 이용 가능',
    this.onTap,
    this.showArrowWhenUnlocked = false,
  });

  /// Whether the card is in locked state
  final bool isLocked;

  /// Card title displayed in header
  final String title;

  /// Icon displayed in header
  final IconData icon;

  /// Color for both icon background and icon itself
  final Color iconColor;

  /// Content to display when card is unlocked
  /// Typically contains summary rows, charts, or other information
  final Widget content;

  /// Optional CTA button shown at the bottom of unlocked content
  final Widget? ctaButton;

  /// Message to display when card is locked
  final String lockedMessage;

  /// Optional tap handler for the entire card
  final VoidCallback? onTap;

  /// Whether to show arrow icon when unlocked (like pension_card)
  final bool showArrowWhenUnlocked;

  @override
  Widget build(BuildContext context) {
    final card = Card(
      elevation: 2,
      child: Opacity(
        opacity: isLocked ? 0.5 : 1.0,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(context),
              const SizedBox(height: 20),

              // Content (locked or unlocked)
              if (isLocked) _buildLockedContent(context) else _buildUnlockedContent(),
            ],
          ),
        ),
      ),
    );

    // Wrap with InkWell if onTap is provided
    if (onTap != null && !isLocked) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: card,
      );
    }

    return card;
  }

  Widget _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isLocked
                ? colorScheme.outline.withValues(alpha: 0.1)
                : iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 28,
            color: isLocked ? colorScheme.outline : iconColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (isLocked)
          Icon(Icons.lock, color: colorScheme.outline)
        else if (showArrowWhenUnlocked)
          const Icon(Icons.arrow_forward_ios, size: 16),
      ],
    );
  }

  Widget _buildLockedContent(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        children: [
          Icon(
            Icons.lock_outline,
            size: 48,
            color: colorScheme.outline,
          ),
          const SizedBox(height: 8),
          Text(
            lockedMessage,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnlockedContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        content,
        if (ctaButton != null) ...[
          const SizedBox(height: 20),
          ctaButton!,
        ],
      ],
    );
  }
}
