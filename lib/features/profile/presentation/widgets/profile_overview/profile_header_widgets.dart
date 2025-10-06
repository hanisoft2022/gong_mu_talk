/// Profile Header Helper Widgets
///
/// Contains reusable widgets used by ProfileHeader component.
///
/// **Purpose**:
/// - Provide modular, reusable UI components for profile header
/// - Keep ProfileHeader file size manageable
/// - Separate concerns for better maintainability
///
/// **Widgets**:
/// - BioCard: Expandable bio text display
/// - StatCard: Follower/following statistics
/// - VerificationStatusRow: Simple verification status indicator
/// - PaystubStatusRow: Real-time career verification status
/// - FollowButton: Follow/unfollow functionality
///
/// **Usage**:
/// These widgets are used exclusively by ProfileHeader and should
/// remain private (prefixed with underscore) to this feature.

library;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import '../../../../../di/di.dart';
import '../../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../data/paystub_verification_repository.dart';
import '../../../domain/paystub_verification.dart';



/// Bio card with expand/collapse functionality for long text
class BioCard extends StatefulWidget {
  const BioCard({super.key, required this.bio});

  final String bio;

  @override
  State<BioCard> createState() => _BioCardState();
}

class _BioCardState extends State<BioCard> {
  bool _isExpanded = false;
  static const int _maxLines = 3;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isLongText = widget.bio.length > 100;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const Gap(8),
              Text(
                '자기소개',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const Gap(12),
          Text(
            widget.bio,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: _isExpanded ? null : _maxLines,
            overflow: _isExpanded ? null : TextOverflow.ellipsis,
          ),
          if (isLongText) ...[
            const Gap(8),
            InkWell(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isExpanded ? '접기' : '더보기',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Gap(4),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Stat card showing follower/following count with tap action
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.title,
    required this.count,
    this.onTap,
  });

  final String title;
  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final IconData icon =
        title == '팔로잉' ? Icons.people_outline : Icons.favorite_border;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            const Gap(6),
            Text(
              '$count',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const Gap(2),
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Verification status row showing icon, label, and status
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
          color: isVerified
              ? theme.colorScheme.primary
              : theme.colorScheme.error,
        ),
        const Gap(8),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurface),
          ),
        ),
        Text(
          isVerified ? '인증됨' : '미인증',
          style: theme.textTheme.bodySmall?.copyWith(
            color: isVerified
                ? theme.colorScheme.primary
                : theme.colorScheme.error,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Paystub/career verification status row with real-time Firebase updates
class PaystubStatusRow extends StatelessWidget {
  const PaystubStatusRow({super.key, required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    final PaystubVerificationRepository repository =
        getIt<PaystubVerificationRepository>();
    final ThemeData theme = Theme.of(context);

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots(),
      builder: (
        BuildContext context,
        AsyncSnapshot<DocumentSnapshot> userSnapshot,
      ) {
        // 테스트 모드 직렬이 설정되어 있으면 인증됨으로 표시
        bool isTestModeVerified = false;
        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          final data = userSnapshot.data!.data() as Map<String, dynamic>?;
          isTestModeVerified = data != null && data['testModeCareer'] != null;
        }

        if (isTestModeVerified) {
          return Row(
            children: [
              Icon(
                Icons.verified,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const Gap(8),
              Expanded(
                child: Text(
                  '직렬 인증',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurface),
                ),
              ),
              Text(
                '인증됨',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );
        }

        return StreamBuilder<PaystubVerification>(
          stream: repository.watchVerification(uid),
          builder: (
            BuildContext context,
            AsyncSnapshot<PaystubVerification> snapshot,
          ) {
            final PaystubVerification verification =
                snapshot.data ?? PaystubVerification.none;

            return Row(
              children: [
                Icon(
                  verification.status == PaystubVerificationStatus.verified
                      ? Icons.verified
                      : verification.status ==
                              PaystubVerificationStatus.processing
                          ? Icons.hourglass_empty
                          : Icons.description_outlined,
                  size: 16,
                  color: verification.status ==
                          PaystubVerificationStatus.verified
                      ? theme.colorScheme.primary
                      : verification.status ==
                              PaystubVerificationStatus.processing
                          ? theme.colorScheme.tertiary
                          : theme.colorScheme.error,
                ),
                const Gap(8),
                Expanded(
                  child: Text(
                    '직렬 인증',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSurface),
                  ),
                ),
                Text(
                  verification.status == PaystubVerificationStatus.verified
                      ? '인증됨'
                      : verification.status ==
                              PaystubVerificationStatus.processing
                          ? '검토중'
                          : '미인증',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: verification.status ==
                            PaystubVerificationStatus.verified
                        ? theme.colorScheme.primary
                        : verification.status ==
                                PaystubVerificationStatus.processing
                            ? theme.colorScheme.tertiary
                            : theme.colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}