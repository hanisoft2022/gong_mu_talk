import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

import '../../features/auth/presentation/cubit/auth_cubit.dart';

// 허용되는 공무원 메일 도메인 목록
const List<String> _allowedGovernmentDomains = [
  // 중앙정부
  'korea.kr', // 공직자통합메일
  'go.kr', // 정부기관 (*.go.kr)

  // 주요 부처
  'moe.go.kr', // 교육부
  'moj.go.kr', // 법무부
  'mofa.go.kr', // 외교부
  'unification.go.kr', // 통일부
  'mosf.go.kr', // 기획재정부
  'mois.go.kr', // 행정안전부
  'motie.go.kr', // 산업통상자원부
  'mohw.go.kr', // 보건복지부

  // 헌법기관
  'assembly.go.kr', // 국회
  'scourt.go.kr', // 대법원
  'ccourt.go.kr', // 헌법재판소
  'nec.go.kr', // 중앙선거관리위원회

  // 지방자치단체
  'seoul.kr', // 서울특별시
  'busan.kr', // 부산광역시
  'daegu.kr', // 대구광역시
  'incheon.kr', // 인천광역시
  'gwangju.kr', // 광주광역시
  'daejeon.kr', // 대전광역시
  'ulsan.kr', // 울산광역시
  'sejong.kr', // 세종특별자치시
  'gyeonggi.kr', // 경기도
  'gangwon.kr', // 강원도
  'chungbuk.kr', // 충청북도
  'chungnam.kr', // 충청남도
  'jeonbuk.kr', // 전라북도
  'jeonnam.kr', // 전라남도
  'gyeongbuk.kr', // 경상북도
  'gyeongnam.kr', // 경상남도
  'jeju.kr', // 제주특별자치도

  // 테스트용
  'naver.com', // 공무원 테스트용
];

class AuthRequiredView extends StatefulWidget {
  const AuthRequiredView({
    super.key,
    this.title = '공무원 메일 인증이 필요합니다',
    this.message = '공무원 메일 인증을 완료해주세요.',
    this.icon = Icons.verified_user_outlined,
    this.onRefresh,
  });

  final String title;
  final String message;
  final IconData icon;
  final VoidCallback? onRefresh;

  @override
  State<AuthRequiredView> createState() => _AuthRequiredViewState();
}

class _AuthRequiredViewState extends State<AuthRequiredView> {
  final TextEditingController _emailController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isExpanded = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state.lastMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(state.lastMessage!),
                backgroundColor: state.authError != null
                    ? Theme.of(context).colorScheme.error
                    : null,
              ),
            );
        }
      },
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: 64, color: Theme.of(context).colorScheme.primary),
              const Gap(24),
              Text(
                widget.title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const Gap(12),
              Text(
                widget.message,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const Gap(32),
              if (!_isExpanded) ...[
                FilledButton.icon(
                  onPressed: () {
                    setState(() {
                      _isExpanded = true;
                    });
                  },
                  icon: const Icon(Icons.email_outlined),
                  label: const Text('공무원 메일 인증하기'),
                ),
              ] else ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '공무원 메일 인증',
                            style: Theme.of(
                              context,
                            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const Gap(12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: const InputDecoration(
                                    labelText: '공무원 이메일 주소',
                                    hintText: 'example@korea.kr',
                                    prefixIcon: Icon(Icons.email_outlined),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return '이메일 주소를 입력해주세요.';
                                    }
                                    final email = value.trim().toLowerCase();
                                    if (!_isGovernmentEmail(email)) {
                                      return '공무원 이메일(@korea.kr, .go.kr) 주소만 인증 가능합니다.';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const Gap(8),
                              IconButton(
                                onPressed: () => _showAllowedDomainsDialog(context),
                                icon: const Icon(Icons.help_outline),
                                tooltip: '허용되는 이메일 도메인 확인',
                              ),
                            ],
                          ),
                          const Gap(16),
                          BlocBuilder<AuthCubit, AuthState>(
                            builder: (context, state) {
                              final bool isLoading = state.isGovernmentEmailVerificationInProgress;

                              return Row(
                                children: [
                                  Expanded(
                                    child: FilledButton(
                                      onPressed: isLoading ? null : _requestVerification,
                                      child: isLoading
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            )
                                          : const Text('인증 메일 발송'),
                                    ),
                                  ),
                                  const Gap(12),
                                  OutlinedButton(
                                    onPressed: isLoading
                                        ? null
                                        : () {
                                            setState(() {
                                              _isExpanded = false;
                                              _emailController.clear();
                                            });
                                          },
                                    child: const Text('취소'),
                                  ),
                                ],
                              );
                            },
                          ),
                          const Gap(12),
                          Text(
                            '입력하신 이메일 주소로 인증 메일이 발송됩니다.\n메일함을 확인하여 인증을 완료해주세요.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _requestVerification() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final String email = _emailController.text.trim();
    context.read<AuthCubit>().requestGovernmentEmailVerification(email: email);

    // 인증 요청 후 폼 접기
    setState(() {
      _isExpanded = false;
      _emailController.clear();
    });
  }

  bool _isGovernmentEmail(String email) {
    final normalizedEmail = email.trim().toLowerCase();
    return _allowedGovernmentDomains.any((domain) {
      if (domain == 'go.kr') {
        // .go.kr로 끝나는 모든 도메인 허용
        return normalizedEmail.endsWith('.go.kr');
      } else {
        // 정확한 도메인 매칭
        return normalizedEmail.endsWith('@$domain');
      }
    });
  }

  void _showAllowedDomainsDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [Icon(Icons.verified_user), SizedBox(width: 8), Text('허용되는 공무원 이메일')],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('다음 도메인의 이메일 주소로 인증할 수 있습니다:', style: Theme.of(context).textTheme.bodyMedium),
                const Gap(16),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDomainCategory(context, '중앙정부', [
                          '@korea.kr (공직자통합메일)',
                          '@*.go.kr (모든 정부기관)',
                          '@naver.com (공무원 테스트용)',
                        ]),
                        const Gap(16),
                        _buildDomainCategory(context, '정부부처', [
                          '@moe.go.kr (교육부)',
                          '@moj.go.kr (법무부)',
                          '@mofa.go.kr (외교부)',
                          '@unification.go.kr (통일부)',
                          '@mosf.go.kr (기획재정부)',
                          '@mois.go.kr (행정안전부)',
                          '@motie.go.kr (산업통상자원부)',
                          '@mohw.go.kr (보건복지부)',
                        ]),
                        const Gap(16),
                        _buildDomainCategory(context, '헌법기관', [
                          '@assembly.go.kr (국회)',
                          '@scourt.go.kr (대법원)',
                          '@ccourt.go.kr (헌법재판소)',
                          '@nec.go.kr (중앙선거관리위원회)',
                        ]),
                        const Gap(16),
                        _buildDomainCategory(context, '지방자치단체', [
                          '@seoul.kr (서울특별시)',
                          '@busan.kr (부산광역시)',
                          '@daegu.kr (대구광역시)',
                          '@incheon.kr (인천광역시)',
                          '@gwangju.kr (광주광역시)',
                          '@daejeon.kr (대전광역시)',
                          '@ulsan.kr (울산광역시)',
                          '@sejong.kr (세종특별자치시)',
                        ]),
                        const Gap(16),
                        _buildDomainCategory(context, '도 단위 자치단체', [
                          '@gyeonggi.kr (경기도)',
                          '@gangwon.kr (강원도)',
                          '@chungbuk.kr (충청북도)',
                          '@chungnam.kr (충청남도)',
                          '@jeonbuk.kr (전라북도)',
                          '@jeonnam.kr (전라남도)',
                          '@gyeongbuk.kr (경상북도)',
                          '@gyeongnam.kr (경상남도)',
                          '@jeju.kr (제주특별자치도)',
                        ]),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('확인')),
          ],
        );
      },
    );
  }

  Widget _buildDomainCategory(BuildContext context, String title, List<String> domains) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const Gap(8),
        ...domains.map(
          (domain) => Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 4),
            child: Row(
              children: [
                Icon(Icons.circle, size: 6, color: Theme.of(context).colorScheme.onSurfaceVariant),
                const Gap(8),
                Expanded(child: Text(domain, style: Theme.of(context).textTheme.bodySmall)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
