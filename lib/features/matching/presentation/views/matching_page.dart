import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../domain/entities/curated_match.dart';
import '../cubit/matching_cubit.dart';
import '../widgets/matching_filter_card.dart';
import '../widgets/matching_profile_card.dart';
import '../widgets/matching_state_views.dart';

class MatchingPage extends StatefulWidget {
  const MatchingPage({super.key});

  @override
  State<MatchingPage> createState() => _MatchingPageState();
}

class _MatchingPageState extends State<MatchingPage> {
  @override
  void initState() {
    super.initState();
    final AuthCubit authCubit = context.read<AuthCubit>();
    authCubit.refreshAuthStatus();
    context.read<MatchingCubit>().loadCandidates();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MatchingCubit, MatchingState>(
      listenWhen: (previous, current) => previous.lastActionMessage != current.lastActionMessage,
      listener: (context, state) {
        final String? message = state.lastActionMessage;
        if (message == null) {
          return;
        }
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
        context.read<MatchingCubit>().clearMessage();
      },
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          // Authentication Check
          if (!authState.isLoggedIn) {
            return const MatchingLockedView(reason: '로그인이 필요합니다.');
          }

          // Email Verification Check
          if (!authState.isGovernmentEmailVerified) {
            return const MatchingLockedView(
              reason: '공직자 통합 메일 인증이 완료된 사용자만 이용할 수 있어요.',
              showVerifyShortcut: true,
            );
          }

          // Matching State Handling
          return BlocBuilder<MatchingCubit, MatchingState>(
            builder: (context, state) {
              Widget body;
              switch (state.status) {
                case MatchingStatus.initial:
                case MatchingStatus.loading:
                  body = const MatchingLoadingView();
                  break;
                case MatchingStatus.error:
                  body = MatchingErrorView(
                    onRetry: () => context.read<MatchingCubit>().loadCandidates(),
                  );
                  break;
                case MatchingStatus.locked:
                  body = const MatchingLockedView(
                    reason: '공직자 통합 메일 인증 완료 후 이용 가능합니다.',
                    showVerifyShortcut: true,
                  );
                  break;
                case MatchingStatus.loaded:
                  body = _MatchingCandidatesView(state: state);
                  break;
              }

              // Add pull-to-refresh for loaded and error states
              if (state.status == MatchingStatus.loaded || state.status == MatchingStatus.error) {
                return RefreshIndicator(
                  onRefresh: () => context.read<MatchingCubit>().refreshCandidates(),
                  child: body,
                );
              }

              return body;
            },
          );
        },
      ),
    );
  }
}

// ==================== Candidates View ====================

class _MatchingCandidatesView extends StatelessWidget {
  const _MatchingCandidatesView({required this.state});

  final MatchingState state;

  @override
  Widget build(BuildContext context) {
    final MatchingCubit cubit = context.read<MatchingCubit>();
    final List<CuratedMatch> matches = state.candidates;

    // Empty State
    if (matches.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: const [
          MatchingFilterCard(),
          Gap(24),
          MatchingEmptyView(),
        ],
      );
    }

    // Candidates List
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: matches.length + 1,
      itemBuilder: (context, index) {
        // Filter Card at Top
        if (index == 0) {
          return const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [MatchingFilterCard(), Gap(20)],
          );
        }

        // Profile Cards
        final CuratedMatch match = matches[index - 1];
        final bool isProcessing = state.actionInProgressId == match.profile.id;
        return MatchingProfileCard(
          match: match,
          isProcessing: isProcessing,
          onSubmit: (String prompt, String answer) =>
              cubit.requestMatch(match: match, prompt: prompt, answer: answer),
        );
      },
    );
  }
}
