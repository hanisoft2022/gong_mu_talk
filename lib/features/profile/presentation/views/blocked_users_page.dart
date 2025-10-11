import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import '../../../../core/utils/snackbar_helpers.dart';
import '../../../../di/di.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../community/data/community_repository.dart';
import '../../../community/presentation/cubit/community_feed_cubit.dart';

/// Blocked Users Page
///
/// Responsibilities:
/// - Display list of blocked users with their profile information
/// - Allow unblocking users
/// - Show empty state when no blocked users
class BlockedUsersPage extends StatefulWidget {
  const BlockedUsersPage({super.key});

  @override
  State<BlockedUsersPage> createState() => _BlockedUsersPageState();
}

class _BlockedUsersPageState extends State<BlockedUsersPage> {
  bool _isLoading = true;
  List<BlockedUserInfo> _blockedUsers = [];
  late final CommunityRepository _repository;
  late final String _currentUid;

  @override
  void initState() {
    super.initState();
    _repository = context.read<CommunityRepository>();
    _currentUid = context.read<AuthCubit>().state.userId ?? '';
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    setState(() => _isLoading = true);

    try {
      // Get blocked user IDs
      final blockedIds = await _repository.getBlockedUserIds(_currentUid);

      if (blockedIds.isEmpty) {
        if (mounted) {
          setState(() {
            _blockedUsers = [];
            _isLoading = false;
          });
        }
        return;
      }

      // Fetch user info for each blocked user (parallel)
      final userInfoFutures = blockedIds.map((uid) async {
        try {
          final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

          final blockedDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(_currentUid)
              .collection('blocked_users')
              .doc(uid)
              .get();

          if (!userDoc.exists) {
            return BlockedUserInfo(
              uid: uid,
              nickname: '알 수 없는 사용자',
              blockedAt:
                  (blockedDoc.data()?['blockedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            );
          }

          final userData = userDoc.data()!;
          return BlockedUserInfo(
            uid: uid,
            nickname: userData['nickname'] as String? ?? '익명',
            profileImageUrl: userData['profileImageUrl'] as String?,
            blockedAt: (blockedDoc.data()?['blockedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          );
        } catch (e) {
          // If fetching fails, return minimal info
          return BlockedUserInfo(uid: uid, nickname: '알 수 없는 사용자', blockedAt: DateTime.now());
        }
      }).toList();

      final userInfos = await Future.wait(userInfoFutures);

      if (mounted) {
        setState(() {
          _blockedUsers = userInfos;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        SnackbarHelpers.showError(context, '차단 목록을 불러오지 못했습니다');
      }
    }
  }

  Future<void> _unblockUser(BlockedUserInfo userInfo) async {
    try {
      await _repository.unblockUser(userInfo.uid);

      if (mounted) {
        setState(() {
          _blockedUsers.removeWhere((u) => u.uid == userInfo.uid);
        });

        // Refresh CommunityFeedCubit to update blocked user cache
        // This ensures unblocked user's posts appear when returning to feed
        // Use getIt to access global singleton (BlockedUsersPage is outside AppShell's BlocProvider)
        getIt<CommunityFeedCubit>().refresh();

        SnackbarHelpers.showSuccess(context, '${userInfo.nickname}님에 대한 차단을 해제했습니다');
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelpers.showError(context, '차단 해제에 실패했습니다');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('차단한 사용자'),
        bottom: _blockedUsers.isNotEmpty
            ? PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(color: theme.dividerColor.withValues(alpha: 0.1), height: 1),
              )
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _blockedUsers.isEmpty
          ? _buildEmptyState(theme)
          : _buildBlockedUsersList(theme),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.block_outlined,
            size: 80,
            color: theme.colorScheme.outline.withValues(alpha: 0.5),
          ),
          const Gap(24),
          Text(
            '차단한 사용자가 없습니다',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Gap(12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              '차단한 사용자의 게시글과 댓글이\n피드에 표시되지 않습니다',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockedUsersList(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _blockedUsers.length,
      itemBuilder: (context, index) {
        final userInfo = _blockedUsers[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    backgroundImage: userInfo.profileImageUrl != null
                        ? NetworkImage(userInfo.profileImageUrl!)
                        : null,
                    child: userInfo.profileImageUrl == null
                        ? Icon(Icons.person, color: theme.colorScheme.onPrimaryContainer, size: 28)
                        : null,
                  ),
                  const Gap(16),
                  // User info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userInfo.nickname,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Gap(4),
                        Row(
                          children: [
                            Icon(Icons.block, size: 14, color: theme.colorScheme.onSurfaceVariant),
                            const Gap(4),
                            Text(
                              _formatBlockedDate(userInfo.blockedAt),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Gap(12),
                  // Unblock button
                  OutlinedButton(
                    onPressed: () => _showUnblockConfirmation(userInfo),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                      side: BorderSide(color: theme.colorScheme.outline),
                    ),
                    child: const Text('차단 해제'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatBlockedDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '차단 $years년 전';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '차단 $months개월 전';
    } else if (difference.inDays > 0) {
      return '차단 ${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '차단 ${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '차단 ${difference.inMinutes}분 전';
    } else {
      return '방금 차단함';
    }
  }

  Future<void> _showUnblockConfirmation(BlockedUserInfo userInfo) async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('차단 해제'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${userInfo.nickname}님에 대한 차단을 해제하시겠습니까?'),
            const Gap(16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: theme.colorScheme.onSurfaceVariant),
                  const Gap(12),
                  Expanded(
                    child: Text(
                      '차단을 해제하면 해당 사용자의 게시글과 댓글이 다시 표시됩니다',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('해제')),
        ],
      ),
    );

    if (confirmed == true) {
      await _unblockUser(userInfo);
    }
  }
}

/// Blocked user information model
class BlockedUserInfo {
  final String uid;
  final String nickname;
  final String? profileImageUrl;
  final DateTime blockedAt;

  BlockedUserInfo({
    required this.uid,
    required this.nickname,
    this.profileImageUrl,
    required this.blockedAt,
  });
}
