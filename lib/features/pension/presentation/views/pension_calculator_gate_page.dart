import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';

class PensionCalculatorGatePage extends StatelessWidget {
  const PensionCalculatorGatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state.hasPensionAccess) {
          return const _PensionComingSoon();
        }

        return _PensionLockedView(state: state);
      },
    );
  }
}

class _PensionLockedView extends StatelessWidget {
  const _PensionLockedView({required this.state});

  final AuthState state;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AuthCubit authCubit = context.read<AuthCubit>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('연금 계산 서비스', style: theme.textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                const Gap(12),
                Text(
                  '공무원 연금 예상액, 생애소득 시뮬레이션, 휴직·전보 시나리오 등 맞춤 리포트를 확인하려면 인증과 이용권이 필요합니다.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          const Gap(28),
          _StepTile(
            index: 1,
            title: '간편 로그인',
            description: '공직자 메일 또는 본인 인증으로 로그인합니다. 현재는 데모 계정으로 체험 가능합니다.',
            trailing: OutlinedButton(
              onPressed: state.isLoggedIn ? null : authCubit.logIn,
              child: const Text('로그인'),
            ),
          ),
          const Gap(16),
          _StepTile(
            index: 2,
            title: '연금 리포트 이용권 구매',
            description: '월 4,990원으로 연금 계산, 시뮬레이션, PDF 리포트를 제공합니다.',
            trailing: ElevatedButton.icon(
              onPressed: state.isProcessing ? null : authCubit.purchasePensionAccess,
              icon: state.isProcessing
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.lock_open_outlined),
              label: const Text('4,990원 결제'),
            ),
          ),
          const Gap(16),
          const _StepTile(
            index: 3,
            title: '공무원 인증',
            description: '@korea.kr 공직자 메일 또는 급여 명세서를 인증하면 커뮤니티/매칭 기능이 열립니다.',
            trailing: IconButton(
              tooltip: '인증 절차 준비중',
              onPressed: null,
              icon: Icon(Icons.verified_outlined),
            ),
          ),
          const Gap(32),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(Icons.notifications_active_outlined, color: theme.colorScheme.secondary),
                  const Gap(12),
                  Expanded(
                    child: Text(
                      '연금 계산 기능은 현재 프리뷰 버전입니다. 이용권을 활성화하면 데모 시뮬레이션 데이터를 먼저 제공합니다.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PensionComingSoon extends StatelessWidget {
  const _PensionComingSoon();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('연금 계산 리포트가 곧 도착합니다!', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
          const Gap(16),
          Text(
            '현재 엑셀 시뮬레이터 로직을 앱에 이식하고 있습니다. 곧 월별 납입액, 퇴직금, 연금 개시 연령별 수령액을 확인할 수 있어요.',
            style: theme.textTheme.bodyMedium,
          ),
          const Gap(24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('다음 업데이트 미리보기', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const Gap(12),
                  const _PreviewBullet(text: '엑셀 로직 기반 연금 예상액 자동 계산'),
                  const _PreviewBullet(text: '휴직·복직·전보 시나리오 비교 리포트'),
                  const _PreviewBullet(text: 'PDF 요약 리포트 및 연말정산 연계'),
                  const Gap(20),
                  OutlinedButton.icon(
                    onPressed: () => context.read<AuthCubit>().logOut(),
                    icon: const Icon(Icons.logout),
                    label: const Text('다른 계정으로 이용하기'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewBullet extends StatelessWidget {
  const _PreviewBullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, size: 18, color: theme.colorScheme.primary),
          const Gap(8),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.index,
    required this.title,
    required this.description,
    required this.trailing,
  });

  final int index;
  final String title;
  final String description;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
              foregroundColor: theme.colorScheme.primary,
              child: Text('$index'),
            ),
            const Gap(16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const Gap(8),
                  Text(description, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
            const Gap(12),
            trailing,
          ],
        ),
      ),
    );
  }
}
