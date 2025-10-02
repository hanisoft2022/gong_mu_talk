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
/// - ProfileAvatar: Circular avatar with fallback
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
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import '../../../../../di/di.dart';
import '../../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../data/paystub_verification_repository.dart';
import '../../../domain/paystub_verification.dart';

/// Profile avatar with circular design and fallback to initial letter
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.photoUrl,
    required this.nickname,
  });

  final String? photoUrl;
  final String nickname;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return CircleAvatar(
      radius: 32,
      backgroundColor: photoUrl != null && photoUrl!.isNotEmpty
          ? Colors.transparent
          : theme.colorScheme.primaryContainer,
      backgroundImage: photoUrl != null && photoUrl!.isNotEmpty
          ? CachedNetworkImageProvider(photoUrl!)
          : null,
      child: photoUrl == null || photoUrl!.isEmpty
          ? Text(
              nickname.isEmpty ? '?' : nickname.characters.first,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            )
          : null,
    );
  }
}

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
    required this.onTap,
  });

  final String title;
  final int count;
  final VoidCallback onTap;

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

/// Follow/unfollow button for other users' profiles
class FollowButton extends StatefulWidget {
  const FollowButton({super.key, required this.targetUserId});

  final String targetUserId;

  @override
  State<FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<FollowButton> {
  bool _isFollowing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkFollowStatus();
  }

  Future<void> _checkFollowStatus() async {
    try {
      final authState = context.read<AuthCubit>().state;
      final currentUserId = authState.userId;

      if (currentUserId == null || currentUserId == widget.targetUserId) {
        setState(() {
          _isFollowing = false;
        });
        return;
      }

      // Firestore에서 팔로우 관계 확인
      final followDoc = await FirebaseFirestore.instance
          .collection('follows')
          .doc('${currentUserId}_${widget.targetUserId}')
          .get();

      if (mounted) {
        setState(() {
          _isFollowing = followDoc.exists;
        });
      }
    } catch (error) {
      // 에러 발생 시 기본값으로 설정
      if (mounted) {
        setState(() {
          _isFollowing = false;
        });
      }
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _toggleFollow() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authState = context.read<AuthCubit>().state;
      final currentUserId = authState.userId;

      if (currentUserId == null || currentUserId == widget.targetUserId) {
        throw Exception('잘못된 요청입니다.');
      }

      final db = FirebaseFirestore.instance;
      final followDocId = '${currentUserId}_${widget.targetUserId}';

      if (_isFollowing) {
        // 언팔로우: Firestore에서 팔로우 관계 삭제
        await db.runTransaction((transaction) async {
          // follows 컬렉션에서 삭제
          transaction.delete(db.collection('follows').doc(followDocId));

          // 팔로워 카운트 감소
          final targetUserRef = db.collection('users').doc(widget.targetUserId);
          transaction.update(
            targetUserRef,
            {'followerCount': FieldValue.increment(-1)},
          );

          // 팔로잉 카운트 감소
          final currentUserRef = db.collection('users').doc(currentUserId);
          transaction.update(
            currentUserRef,
            {'followingCount': FieldValue.increment(-1)},
          );
        });
      } else {
        // 팔로우: Firestore에 팔로우 관계 추가
        await db.runTransaction((transaction) async {
          // follows 컬렉션에 추가
          transaction.set(db.collection('follows').doc(followDocId), {
            'followerId': currentUserId,
            'followingId': widget.targetUserId,
            'createdAt': FieldValue.serverTimestamp(),
          });

          // 팔로워 카운트 증가
          final targetUserRef = db.collection('users').doc(widget.targetUserId);
          transaction.update(
            targetUserRef,
            {'followerCount': FieldValue.increment(1)},
          );

          // 팔로잉 카운트 증가
          final currentUserRef = db.collection('users').doc(currentUserId);
          transaction.update(
            currentUserRef,
            {'followingCount': FieldValue.increment(1)},
          );
        });
      }

      setState(() {
        _isFollowing = !_isFollowing;
      });

      if (mounted) {
        _showMessage(
          context,
          _isFollowing ? '팔로우했습니다' : '팔로우를 취소했습니다',
        );
      }
    } catch (error) {
      if (mounted) {
        _showMessage(context, '오류가 발생했습니다: $error');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return IconButton(
      onPressed: _isLoading ? null : _toggleFollow,
      icon: _isLoading
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          : Icon(
              _isFollowing
                  ? Icons.person_remove_outlined
                  : Icons.person_add_outlined,
              color: _isFollowing
                  ? theme.colorScheme.error
                  : theme.colorScheme.primary,
            ),
      tooltip: _isFollowing ? '팔로우 취소' : '팔로우',
    );
  }
}
