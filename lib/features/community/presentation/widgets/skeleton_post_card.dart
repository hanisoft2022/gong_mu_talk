/// Skeleton Post Card - Simplified skeleton UI for loading states
///
/// Responsibilities:
/// - Display simple skeleton structure without profile/tags/images
/// - Used during sorting and lounging transitions
/// - Regular widgets wrapped by Skeletonizer for shimmer effect

library;

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class SkeletonPostCard extends StatelessWidget {
  const SkeletonPostCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Nickname and timestamp
            Row(
              children: [
                // Nickname (will be skeletonized)
                const Text(
                  '닉네임 로딩중',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                // Timestamp (will be skeletonized)
                Text(
                  '방금 전',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),

            const Gap(12),

            // Text content lines (will be skeletonized)
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '게시글 내용을 불러오는 중입니다. 잠시만 기다려주세요.',
                  style: TextStyle(fontSize: 14, height: 1.5),
                ),
                Gap(6),
                Text(
                  '조금만 기다려주시면 새로운 게시글이 표시됩니다.',
                  style: TextStyle(fontSize: 14, height: 1.5),
                ),
                Gap(6),
                Text('로딩 중입니다.', style: TextStyle(fontSize: 14, height: 1.5)),
              ],
            ),

            const Gap(16),

            // Actions bar: Like, Comment, View (will be skeletonized)
            Row(
              children: [
                // Like
                Row(
                  children: [
                    Icon(
                      Icons.favorite_outline,
                      size: 20,
                      color: Colors.grey[700],
                    ),
                    const Gap(4),
                    Text(
                      '42',
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                  ],
                ),
                const Gap(20),
                // Comment
                Row(
                  children: [
                    Icon(
                      Icons.mode_comment_outlined,
                      size: 20,
                      color: Colors.grey[700],
                    ),
                    const Gap(4),
                    Text(
                      '8',
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                  ],
                ),
                const Gap(20),
                // View
                Row(
                  children: [
                    Icon(
                      Icons.visibility_outlined,
                      size: 20,
                      color: Colors.grey[700],
                    ),
                    const Gap(4),
                    Text(
                      '120',
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
