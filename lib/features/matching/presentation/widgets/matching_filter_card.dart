import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../profile/domain/career_track.dart';

class MatchingFilterCard extends StatelessWidget {
  const MatchingFilterCard({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthState authState = context.watch<AuthCubit>().state;
    final ThemeData theme = Theme.of(context);
    final Set<CareerTrack> excludedTracks = authState.excludedTracks;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Row(
              children: [
                Icon(Icons.filter_alt_outlined, color: theme.colorScheme.primary),
                const Gap(8),
                Expanded(
                  child: Text(
                    '매칭 제외 직렬',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const Gap(12),

            // Description Section
            Text(
              excludedTracks.isEmpty
                  ? '관심 없는 직렬을 숨기면 더 맞춤형 추천을 받을 수 있어요.'
                  : '제외 직렬: ${excludedTracks.map((CareerTrack track) => track.displayName).join(', ')}',
              style: theme.textTheme.bodyMedium,
            ),
            const Gap(16),

            // Filter Chips Section
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: CareerTrack.values
                  .where((CareerTrack track) => track != CareerTrack.none)
                  .map(
                    (CareerTrack track) => FilterChip(
                      label: Text(track.displayName),
                      selected: excludedTracks.contains(track),
                      onSelected: (_) => context.read<AuthCubit>().toggleExcludedTrack(track),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ),
      ),
    );
  }
}
