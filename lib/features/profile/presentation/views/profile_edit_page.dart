/// ProfileEditPage
///
/// 프로필 편집 페이지
///
/// Phase 2 - Extracted from profile_page.dart
///
/// Features:
/// - 닉네임 수정
/// - 자기소개 수정
/// - 테마 설정 (라이트/다크/시스템)
/// - 직렬 공개 설정
///
/// File Size: ~180 lines (Green Zone ✅)
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/performance_optimizations.dart';
import '../../../../core/utils/nickname_validator.dart';
import '../../../../core/utils/snackbar_helpers.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../widgets/profile_edit/profile_edit_section.dart';
import '../widgets/profile_edit/theme_settings_section.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  late final TextEditingController _nicknameController;
  late final TextEditingController _bioController;

  // 토글 처리 중 상태
  bool _isUpdatingSerialVisibility = false;

  // 닉네임 검증 에러
  String? _nicknameError;

  @override
  void initState() {
    super.initState();
    final AuthState state = context.read<AuthCubit>().state;
    _nicknameController = TextEditingController(text: state.nickname);
    _bioController = TextEditingController(text: state.bio ?? '');
  }

  void _validateNickname(String value) {
    final result = NicknameValidator.validate(value);
    setState(() {
      _nicknameError = result.isValid ? null : result.errorMessage;
    });
  }

  String _getNicknameHelperText(AuthState state) {
    if (state.canChangeNickname) {
      return '닉네임 변경은 30일마다 가능합니다';
    }

    final DateTime? lastChanged = state.nicknameLastChangedAt;
    if (lastChanged == null) {
      return '닉네임 변경은 30일마다 가능합니다';
    }

    final DateTime nextChangeDate = lastChanged.add(const Duration(days: 30));
    final int daysRemaining = nextChangeDate.difference(DateTime.now()).inDays + 1;

    return '닉네임 변경은 30일마다 가능합니다 • $daysRemaining일 후 변경 가능';
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (AuthState previous, AuthState current) =>
          previous.nickname != current.nickname || previous.bio != current.bio,
      listener: (BuildContext context, AuthState state) {
        _nicknameController.text = state.nickname;
        _bioController.text = state.bio ?? '';
      },
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (BuildContext context, AuthState state) {
          final bool isProcessing = state.isProcessing;

          return Scaffold(
            appBar: AppBar(
              leading: BackButton(onPressed: () => context.pop()),
              title: const Text('프로필 편집'),
              actions: [
                TextButton(
                  onPressed: isProcessing ? null : _saveProfile,
                  child: Text(
                    '저장',
                    style: TextStyle(
                      color: isProcessing
                          ? Theme.of(context).colorScheme.onSurfaceVariant
                          : Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            body: SafeArea(
              child: OptimizedListView(
                itemCount: 7,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    final int maxLength = NicknameValidator.getMaxLength(_nicknameController.text);

                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: ProfileEditSection(
                        title: '닉네임',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: _nicknameController,
                              enabled: !isProcessing,
                              maxLength: maxLength,
                              onChanged: _validateNickname,
                              decoration: InputDecoration(
                                labelText: '닉네임',
                                hintText: '한글/영문/숫자 사용 가능',
                                counterText: '',
                                border: const OutlineInputBorder(),
                                helperText: _nicknameError == null
                                    ? _getNicknameHelperText(state)
                                    : null,
                                helperMaxLines: 2,
                                errorText: _nicknameError,
                                errorMaxLines: 2,
                                suffixIcon: Icon(
                                  Icons.edit_outlined,
                                  color: state.canChangeNickname && _nicknameError == null
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            // 디버그 모드에서만 표시되는 테스트 버튼
                            if (kDebugMode) ...[
                              const Gap(12),
                              OutlinedButton.icon(
                                onPressed: isProcessing
                                    ? null
                                    : () async {
                                        final cubit = context.read<AuthCubit>();
                                        final messenger = ScaffoldMessenger.of(context);
                                        final bgColor = Theme.of(context).colorScheme.primaryContainer;
                                        await cubit.resetNicknameChangeLimit();
                                        if (!mounted) return;
                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: const Text('테스트 모드: 닉네임 변경 제한이 해제되었습니다.'),
                                            behavior: SnackBarBehavior.floating,
                                            backgroundColor: bgColor,
                                          ),
                                        );
                                      },
                                icon: const Icon(Icons.bug_report),
                                label: const Text('테스트: 닉네임 제한 해제'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Theme.of(context).colorScheme.error,
                                  side: BorderSide(color: Theme.of(context).colorScheme.error),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  } else if (index == 1) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Gap(24),
                    );
                  } else if (index == 2) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ProfileEditSection(
                        title: '자기소개',
                        child: TextField(
                          controller: _bioController,
                          enabled: !isProcessing,
                          maxLines: 5,
                          maxLength: 300,
                          decoration: const InputDecoration(
                            hintText: '자신을 소개해보세요',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    );
                  } else if (index == 3) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Gap(24),
                    );
                  } else if (index == 4) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ProfileEditSection(
                        title: '화면 및 테마',
                        child: ThemeSettingsSection(isProcessing: isProcessing),
                      ),
                    );
                  } else if (index == 5) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Gap(24),
                    );
                  } else {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: ProfileEditSection(
                        title: '공개 설정',
                        child: Column(
                          children: [
                            SwitchListTile.adaptive(
                              value: state.serialVisible,
                              onChanged: (isProcessing || _isUpdatingSerialVisibility)
                                  ? null
                                  : (bool value) async {
                                      setState(() => _isUpdatingSerialVisibility = true);
                                      try {
                                        await context.read<AuthCubit>().updateSerialVisibility(
                                          value,
                                        );
                                      } finally {
                                        if (mounted) {
                                          setState(() => _isUpdatingSerialVisibility = false);
                                        }
                                      }
                                    },
                              title: const Text('직렬 공개'),
                              subtitle: const Text('라운지와 댓글에 내 직렬을 표시할지 선택할 수 있습니다.'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _saveProfile() async {
    final String nickname = _nicknameController.text.trim();
    final String bio = _bioController.text.trim();

    // 닉네임 검증
    final validationResult = NicknameValidator.validate(nickname);
    if (!validationResult.isValid) {
      SnackbarHelpers.showWarning(context, validationResult.errorMessage ?? '잘못된 닉네임입니다.');
      return;
    }

    final AuthCubit authCubit = context.read<AuthCubit>();
    final AuthState currentState = authCubit.state;

    try {
      // 닉네임이 변경된 경우
      if (nickname != currentState.nickname) {
        await authCubit.updateNickname(nickname);
      }

      // 자기소개가 변경된 경우
      if (bio != (currentState.bio ?? '')) {
        await authCubit.updateBio(bio);
      }

      if (mounted) {
        SnackbarHelpers.showSuccess(context, '프로필이 저장되었습니다.');
        context.pop();
      }
    } catch (error) {
      if (mounted) {
        SnackbarHelpers.showError(context, '저장 중 오류가 발생했습니다: $error');
      }
    }
  }
}
