import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/widgets/auth_dialog.dart';
import '../../domain/career_track.dart';
import '../../domain/user_profile.dart';
import '../../../../core/constants/engagement_points.dart';
import '../../../../routing/app_router.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('공무톡', style: TextStyle(fontWeight: FontWeight.w700)),
            SizedBox(width: 8),
            Text('마이페이지'),
          ],
        ),
      ),
      body: SafeArea(
        child: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            if (!state.isLoggedIn) {
              return _ProfileLoggedOut(theme: theme);
            }

            return _ProfileLoggedIn(theme: theme, state: state);
          },
        ),
      ),
    );
  }
}

class _ProfileLoggedOut extends StatelessWidget {
  const _ProfileLoggedOut({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline,
              size: 56,
              color: theme.colorScheme.primary,
            ),
            const Gap(12),
            Text(
              '로그인이 필요합니다',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(8),
            Text(
              '연금 계산, 커뮤니티 등 개별 설정을 관리하려면 먼저 로그인해주세요.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const Gap(20),
            FilledButton(
              onPressed: () => _showAuthDialog(context),
              child: const Text('로그인 / 회원가입'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileLoggedIn extends StatelessWidget {
  const _ProfileLoggedIn({required this.theme, required this.state});

  final ThemeData theme;
  final AuthState state;

  @override
  Widget build(BuildContext context) {
    final String email = state.preferredEmail ?? state.email ?? '이메일 정보 없음';
    final bool isGovernmentEmail = state.isGovernmentEmail;
    final bool isVerified = state.isGovernmentEmailVerified;
    final bool isSupporter =
        state.supporterLevel > 0 || state.premiumTier != PremiumTier.none;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          '내 계정',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        if (isSupporter) ...[
          const Gap(12),
          Align(
            alignment: Alignment.centerLeft,
            child: Chip(
              avatar: const Icon(Icons.volunteer_activism, size: 18),
              label: Text(
                state.supporterLevel > 0
                    ? '후원자 레벨 ${state.supporterLevel}'
                    : '프리미엄 이용 중',
              ),
            ),
          ),
        ],
        const Gap(20),
        _NicknameCard(state: state),
        const Gap(24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '기본 정보',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Gap(12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.alternate_email_outlined),
                  title: Text(email, style: theme.textTheme.bodyLarge),
                  subtitle: const Text('로그인 계정 (이메일)'),
                ),
                _GovernmentEmailStatusTile(
                  isVerified: isVerified,
                  isGovernmentEmail: isGovernmentEmail,
                ),
                const Divider(height: 32),
                _ProfileGuidance(theme: theme),
              ],
            ),
          ),
        ),
        const Gap(24),
        _EngagementPointsCard(state: state, theme: theme),
        const Gap(24),
        _CareerTrackSelectorCard(state: state),
        const Gap(24),
        _ExcludedTrackCard(state: state),
        const Gap(24),
        const _GovernmentEmailVerificationCard(),
        const Gap(24),
        if (state.isGovernmentEmailVerified) const _MatchingShortcutCard(),
        if (state.isGovernmentEmailVerified) const Gap(24),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('개인 정보 관리'),
                subtitle: const Text('프로필 이미지는 추후 제공 예정입니다.'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      const SnackBar(content: Text('마이페이지 세부 기능은 준비 중입니다.')),
                    );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(
                  isSupporter
                      ? Icons.volunteer_activism
                      : Icons.volunteer_activism_outlined,
                ),
                title: Text(isSupporter ? '후원 취소하기' : '후원하기'),
                subtitle: Text(
                  isSupporter
                      ? '후원을 취소하면 광고가 다시 노출됩니다.'
                      : '후원 시 프로필에 특별 배지가 표시되고 광고가 제거됩니다.',
                ),
                onTap: () {
                  final AuthCubit cubit = context.read<AuthCubit>();
                  if (isSupporter) {
                    cubit.disableSupporterMode();
                  } else {
                    cubit.enableSupporterMode();
                  }
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('로그아웃'),
                onTap: () => context.read<AuthCubit>().logOut(),
              ),
            ],
          ),
        ),
        const Gap(24),
        Center(
          child: Column(
            children: [
              Image.asset(
                'assets/images/hanisoft_logo.png',
                height: 40,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
              const Gap(8),
              Text('HANISOFT', style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileGuidance extends StatelessWidget {
  const _ProfileGuidance({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _GuidelineRow(
              icon: Icons.verified_user_outlined,
              message: '공직자 메일로 로그인하면 추가 인증 없이 주요 기능을 이용할 수 있습니다.',
            ),
            SizedBox(height: 12),
            _GuidelineRow(
              icon: Icons.badge_outlined,
              message:
                  '다른 이메일로 가입하셨다면 마이페이지에서 공직자 메일 인증 절차를 진행할 수 있도록 준비 중입니다.',
            ),
          ],
        ),
      ),
    );
  }
}

class _EngagementPointsCard extends StatelessWidget {
  const _EngagementPointsCard({required this.state, required this.theme});

  final AuthState state;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.stars, color: theme.colorScheme.primary),
                const Gap(8),
                Text(
                  '활동 포인트',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Gap(16),
            Text(
              '${state.points} pts',
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const Gap(4),
            Text('현재 레벨 ${state.level}', style: theme.textTheme.bodyMedium),
            const Gap(16),
            const Divider(height: 24),
            Text(
              '포인트는 아래 활동으로 적립됩니다.',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(12),
            const _PointRuleRow(
              icon: Icons.edit_note_outlined,
              label: '라운지 글 작성',
              value: '+${EngagementPoints.postCreation} pts',
            ),
            const _PointRuleRow(
              icon: Icons.chat_bubble_outline,
              label: '댓글 작성',
              value: '+${EngagementPoints.commentCreation} pts',
            ),
            const _PointRuleRow(
              icon: Icons.favorite_outline,
              label: '내 글/댓글에 좋아요 수신',
              value: '+${EngagementPoints.contentReceivedLike} pts',
            ),
            const Gap(8),
            Text(
              '포인트는 실시간으로 반영되며, 누적 포인트에 따라 더 많은 혜택이 제공될 예정입니다.',
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

class _PointRuleRow extends StatelessWidget {
  const _PointRuleRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.secondary),
          const Gap(12),
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CareerTrackSelectorCard extends StatelessWidget {
  const _CareerTrackSelectorCard({required this.state});

  final AuthState state;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final CareerTrack currentTrack = state.careerTrack;
    final AuthCubit authCubit = context.read<AuthCubit>();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '내 직렬 설정',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(12),
            Text(
              '직렬을 선택하면 직렬 전용 커뮤니티와 맞춤 기능이 열립니다.',
              style: theme.textTheme.bodyMedium,
            ),
            const Gap(16),
            InputDecorator(
              decoration: const InputDecoration(
                labelText: '직렬 선택',
                border: OutlineInputBorder(),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<CareerTrack>(
                  value: currentTrack,
                  isExpanded: true,
                  items: CareerTrack.values
                      .map(
                        (track) => DropdownMenuItem<CareerTrack>(
                          value: track,
                          child: Text('${track.emoji} ${track.displayName}'),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (track) {
                    if (track == null) {
                      return;
                    }
                    authCubit.updateCareerTrack(track);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NicknameCard extends StatefulWidget {
  const _NicknameCard({required this.state});

  final AuthState state;

  @override
  State<_NicknameCard> createState() => _NicknameCardState();
}

class _NicknameCardState extends State<_NicknameCard> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.state.nickname);
  }

  @override
  void didUpdateWidget(covariant _NicknameCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.nickname != widget.state.nickname) {
      _controller.text = widget.state.nickname;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AuthState state = widget.state;
    final bool canChange = state.canChangeNickname;
    final int remaining =
        (state.nicknameResetAt != null &&
            state.nicknameResetAt!.year == DateTime.now().year &&
            state.nicknameResetAt!.month == DateTime.now().month)
        ? (2 - state.nicknameChangeCount).clamp(0, 2)
        : 2;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '닉네임',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(12),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: '닉네임',
                border: OutlineInputBorder(),
              ),
            ),
            const Gap(12),
            Text(
              '이번 달 변경 가능 횟수: ${remaining + state.extraNicknameTickets}',
              style: theme.textTheme.bodySmall,
            ),
            const Gap(12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: canChange
                        ? () => context.read<AuthCubit>().updateNickname(
                            _controller.text,
                          )
                        : null,
                    child: const Text('닉네임 변경'),
                  ),
                ),
                const Gap(12),
                OutlinedButton(
                  onPressed: () =>
                      context.read<AuthCubit>().purchaseNicknameTicket(),
                  child: const Text('변경권 990원'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ExcludedTrackCard extends StatelessWidget {
  const _ExcludedTrackCard({required this.state});

  final AuthState state;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Set<CareerTrack> excluded = state.excludedTracks;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '매칭 제외 직렬',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(12),
            Text(
              '같은 직렬과 매칭을 피하고 싶다면 아래에서 제외할 직렬을 선택하세요.',
              style: theme.textTheme.bodyMedium,
            ),
            const Gap(12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: CareerTrack.values
                  .where((track) => track != CareerTrack.none)
                  .map(
                    (track) => FilterChip(
                      label: Text('${track.emoji} ${track.displayName}'),
                      selected: excluded.contains(track),
                      onSelected: (_) =>
                          context.read<AuthCubit>().toggleExcludedTrack(track),
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

class _MatchingShortcutCard extends StatelessWidget {
  const _MatchingShortcutCard();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '매칭 서비스 이용 준비 완료!',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(8),
            Text(
              '공직자 인증이 확인되었습니다. 이제 동료 공무원과의 소개팅·커넥션을 신청해보세요.',
              style: theme.textTheme.bodyMedium,
            ),
            const Gap(16),
            FilledButton.icon(
              onPressed: () => GoRouter.of(context).go(MatchingRoute.path),
              icon: const Icon(Icons.favorite_outline),
              label: const Text('매칭 서비스 바로 가기'),
            ),
          ],
        ),
      ),
    );
  }
}

class _GovernmentEmailVerificationCard extends StatefulWidget {
  const _GovernmentEmailVerificationCard();

  @override
  State<_GovernmentEmailVerificationCard> createState() =>
      _GovernmentEmailVerificationCardState();
}

class _GovernmentEmailVerificationCardState
    extends State<_GovernmentEmailVerificationCard> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final bool isLoading = state.isGovernmentEmailVerificationInProgress;
        final bool isVerified = state.isGovernmentEmailVerified;

        if (isVerified) {
          return Card(
            color: theme.colorScheme.primaryContainer,
            child: ListTile(
              leading: Icon(
                Icons.verified_outlined,
                color: theme.colorScheme.onPrimaryContainer,
              ),
              title: const Text('공직자 메일 인증 완료'),
              subtitle: const Text('확장 기능을 모두 이용할 수 있습니다.'),
              trailing: TextButton(
                onPressed: () => context
                    .read<AuthCubit>()
                    .clearGovernmentEmailVerificationForTesting(),
                child: const Text('인증 취소(개발)'),
              ),
            ),
          );
        }

        return BlocListener<AuthCubit, AuthState>(
          listenWhen: (previous, current) =>
              previous.lastMessage != current.lastMessage &&
              current.lastMessage != null,
          listener: (context, authState) {
            final String? message = authState.lastMessage;
            if (message == null || message.isEmpty) {
              return;
            }
            final ScaffoldMessengerState messenger = ScaffoldMessenger.of(
              context,
            );
            messenger
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(message)));
            context.read<AuthCubit>().clearLastMessage();
          },
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '공직자 메일 인증',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Gap(12),
                    Text(
                      '공직자 계정(@korea.kr, .go.kr)으로 인증하면 커뮤니티, 매칭 등 확장 기능을 이용할 수 있습니다. '
                      '입력하신 주소로 인증 메일을 보내드려요.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const Gap(16),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: '공직자 메일 주소',
                        hintText: 'example@korea.kr',
                      ),
                      validator: _validateGovernmentEmail,
                    ),
                    const Gap(16),
                    FilledButton.icon(
                      onPressed: isLoading ? null : _submit,
                      icon: isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_outlined),
                      label: const Text('인증 메일 보내기'),
                    ),
                    TextButton.icon(
                      onPressed: isLoading
                          ? null
                          : () => context.read<AuthCubit>().refreshAuthStatus(),
                      icon: const Icon(Icons.refresh_outlined),
                      label: const Text('메일 확인 후 상태 새로고침'),
                    ),
                    const Gap(12),
                    Text(
                      '인증 메일에 포함된 링크를 24시간 이내에 열어야 합니다. 링크를 열면 계정 이메일이 공직자 메일로 변경되지만, 기존에 사용하던 로그인 방식(이메일 또는 소셜 계정)은 계속 사용할 수 있습니다.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _submit() {
    final FormState? form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    final String email = _emailController.text.trim();
    context.read<AuthCubit>().requestGovernmentEmailVerification(email: email);
  }

  String? _validateGovernmentEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '공직자 메일 주소를 입력해주세요.';
    }

    final String email = value.trim().toLowerCase();
    if (!email.endsWith('@korea.kr') && !email.endsWith('.go.kr')) {
      return '공직자 메일(@korea.kr 또는 .go.kr) 주소만 인증할 수 있습니다.';
    }

    return null;
  }
}

class _GuidelineRow extends StatelessWidget {
  const _GuidelineRow({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(message, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    );
  }
}

void _showAuthDialog(BuildContext context) {
  final AuthCubit authCubit = context.read<AuthCubit>();

  showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return BlocProvider<AuthCubit>.value(
        value: authCubit,
        child: const AuthDialog(),
      );
    },
  );
}
class _GovernmentEmailStatusTile extends StatelessWidget {
  const _GovernmentEmailStatusTile({
    required this.isVerified,
    required this.isGovernmentEmail,
  });

  final bool isVerified;
  final bool isGovernmentEmail;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final IconData icon = isVerified
        ? Icons.verified_outlined
        : (isGovernmentEmail ? Icons.mark_email_read_outlined : Icons.mail_outline);
    final Color color = isVerified
        ? theme.colorScheme.primary
        : theme.colorScheme.tertiary;
    final String title;
    final String subtitle;
    if (isVerified) {
      title = '공직자 메일 인증 완료';
      subtitle = '확장 기능을 모두 이용할 수 있습니다.';
    } else if (isGovernmentEmail) {
      title = '공직자 메일 인증 대기중';
      subtitle = '인증 메일을 열어 상태를 업데이트해주세요.';
    } else {
      title = '공직자 메일 인증 필요';
      subtitle = '공직자 메일(@korea.kr 또는 .go.kr) 계정을 인증하면 기능이 확장됩니다.';
    }

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(color: color),
      ),
      subtitle: Text(subtitle),
    );
  }
}
