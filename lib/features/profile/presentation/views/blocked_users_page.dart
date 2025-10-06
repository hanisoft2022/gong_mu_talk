import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../community/data/community_repository.dart';

/// Blocked Users Page
///
/// Responsibilities:
/// - Display list of blocked users
/// - Allow unblocking users
/// - Show empty state when no blocked users
class BlockedUsersPage extends StatefulWidget {
  const BlockedUsersPage({super.key});

  @override
  State<BlockedUsersPage> createState() => _BlockedUsersPageState();
}

class _BlockedUsersPageState extends State<BlockedUsersPage> {
  bool _isLoading = true;
  Set<String> _blockedUserIds = {};
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
      final blockedIds = await _repository.getBlockedUserIds(_currentUid);
      if (mounted) {
        setState(() {
          _blockedUserIds = blockedIds;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('차단 목록을 불러오지 못했습니다'),
              duration: Duration(seconds: 2),
            ),
          );
      }
    }
  }

  Future<void> _unblockUser(String userId) async {
    try {
      await _repository.unblockUser(userId);

      if (mounted) {
        setState(() {
          _blockedUserIds.remove(userId);
        });

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('차단을 해제했습니다'),
              duration: Duration(seconds: 2),
            ),
          );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('차단 해제에 실패했습니다'),
              duration: Duration(seconds: 2),
            ),
          );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('차단한 사용자'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _blockedUserIds.isEmpty
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
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            '차단한 사용자가 없습니다',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '차단한 사용자의 게시글과 댓글이\n표시되지 않습니다',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockedUsersList(ThemeData theme) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _blockedUserIds.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final userId = _blockedUserIds.elementAt(index);
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Icon(
              Icons.person,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          title: Text(
            '사용자 (ID: ${userId.substring(0, 8)}...)',
            style: theme.textTheme.bodyLarge,
          ),
          subtitle: const Text('차단됨'),
          trailing: OutlinedButton(
            onPressed: () => _showUnblockConfirmation(userId),
            child: const Text('차단 해제'),
          ),
        );
      },
    );
  }

  Future<void> _showUnblockConfirmation(String userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('차단 해제'),
        content: const Text('이 사용자의 차단을 해제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('해제'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _unblockUser(userId);
    }
  }
}
