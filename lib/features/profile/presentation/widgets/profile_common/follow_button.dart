import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../auth/presentation/cubit/auth_cubit.dart';

/// A follow/unfollow button for user profiles.
///
/// Displays a person_add icon when not following, person_remove when following.
/// Handles the follow/unfollow logic with Firebase transactions.
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
          transaction.update(targetUserRef, {'followerCount': FieldValue.increment(-1)});

          // 팔로잉 카운트 감소
          final currentUserRef = db.collection('users').doc(currentUserId);
          transaction.update(currentUserRef, {'followingCount': FieldValue.increment(-1)});
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
          transaction.update(targetUserRef, {'followerCount': FieldValue.increment(1)});

          // 팔로잉 카운트 증가
          final currentUserRef = db.collection('users').doc(currentUserId);
          transaction.update(currentUserRef, {'followingCount': FieldValue.increment(1)});
        });
      }

      setState(() {
        _isFollowing = !_isFollowing;
      });

      if (mounted) {
        _showMessage(context, _isFollowing ? '팔로우했습니다' : '팔로우를 취소했습니다');
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
              _isFollowing ? Icons.person_remove_outlined : Icons.person_add_outlined,
              color: _isFollowing ? theme.colorScheme.error : theme.colorScheme.primary,
            ),
      tooltip: _isFollowing ? '팔로우 취소' : '팔로우',
    );
  }
}
