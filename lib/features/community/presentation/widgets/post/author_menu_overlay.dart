/// Author menu overlay for profile and follow actions
///
/// Responsibilities:
/// - Display floating menu overlay with profile and follow options
/// - Position menu below author button
/// - Handle outside tap to close
/// - Dynamic follow/unfollow state
///
/// Used by: PostCard

library;
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

enum AuthorMenuAction { viewProfile, toggleFollow }

class AuthorMenuOverlay {
  /// Show author menu overlay at position
  static OverlayEntry? show({
    required BuildContext context,
    required GlobalKey authorButtonKey,
    required bool canFollow,
    required bool isFollowing,
    required VoidCallback onViewProfile,
    required VoidCallback onToggleFollow,
    required VoidCallback onClose,
  }) {
    final RenderBox? renderBox = authorButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return null;

    final Offset buttonPosition = renderBox.localToGlobal(Offset.zero);
    final Size buttonSize = renderBox.size;

    final double menuLeft = buttonPosition.dx;
    final double menuTop = buttonPosition.dy + buttonSize.height + 4;

    final overlayEntry = OverlayEntry(
      builder: (context) => StatefulBuilder(
        builder: (context, setMenuState) {
          return Stack(
            children: [
              // Transparent full-screen cover for outside tap detection
              Positioned.fill(
                child: GestureDetector(
                  onTap: onClose,
                  child: Container(color: Colors.transparent),
                ),
              ),

              // Menu
              Positioned(
                left: menuLeft,
                top: menuTop,
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(12),
                  shadowColor: Colors.black26,
                  child: Container(
                    width: 140,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildMenuOption(
                          context: context,
                          icon: Icons.person_outline,
                          text: '프로필 보기',
                          onTap: onViewProfile,
                        ),
                        if (canFollow)
                          _buildMenuOption(
                            context: context,
                            icon: isFollowing
                                ? Icons.person_remove_alt_1_outlined
                                : Icons.person_add_alt_1_outlined,
                            text: isFollowing ? '팔로우 취소하기' : '팔로우하기',
                            onTap: onToggleFollow,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return overlayEntry;
  }

  static Widget _buildMenuOption({
    required BuildContext context,
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 18),
            const Gap(8),
            Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
          ],
        ),
      ),
    );
  }
}
