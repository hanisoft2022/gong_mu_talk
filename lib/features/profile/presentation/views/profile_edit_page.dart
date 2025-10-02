/// ProfileEditPage
///
/// 프로필 편집 페이지
///
/// Phase 2 - Extracted from profile_page.dart
///
/// Features:
/// - 프로필 이미지 변경
/// - 닉네임 수정
/// - 자기소개 수정
/// - 테마 설정 (라이트/다크/시스템)
/// - 직렬 공개 설정
///
/// File Size: ~180 lines (Green Zone ✅)
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../widgets/profile_edit/profile_edit_section.dart';
import '../widgets/profile_edit/profile_image_section.dart';
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

  @override
  void initState() {
    super.initState();
    final AuthState state = context.read<AuthCubit>().state;
    _nicknameController = TextEditingController(text: state.nickname);
    _bioController = TextEditingController(text: state.bio ?? '');
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
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                children: [
                  // 프로필 이미지 섹션
                  ProfileImageSection(
                    photoUrl: state.photoUrl,
                    nickname: state.nickname,
                    isProcessing: isProcessing,
                  ),
                  const Gap(24),

                  // 닉네임 섹션
                  ProfileEditSection(
                    title: '닉네임',
                    child: TextField(
                      controller: _nicknameController,
                      enabled: !isProcessing,
                      maxLength: 20,
                      decoration: const InputDecoration(
                        hintText: '닉네임을 입력하세요',
                        counterText: '',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const Gap(24),

                  // 자기소개 섹션
                  ProfileEditSection(
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
                  const Gap(24),

                  // 테마 설정 섹션
                  ProfileEditSection(
                    title: '화면 및 테마',
                    child: ThemeSettingsSection(isProcessing: isProcessing),
                  ),
                  const Gap(24),

                  // 공개 설정 섹션
                  ProfileEditSection(
                    title: '공개 설정',
                    child: Column(
                      children: [
                        SwitchListTile.adaptive(
                          value: state.serialVisible,
                          onChanged:
                              (isProcessing || _isUpdatingSerialVisibility)
                              ? null
                              : (bool value) async {
                                  setState(
                                    () => _isUpdatingSerialVisibility = true,
                                  );
                                  try {
                                    await context
                                        .read<AuthCubit>()
                                        .updateSerialVisibility(value);
                                  } finally {
                                    if (mounted) {
                                      setState(
                                        () =>
                                            _isUpdatingSerialVisibility = false,
                                      );
                                    }
                                  }
                                },
                          title: const Text('직렬 공개'),
                          subtitle: const Text(
                            '라운지와 댓글에 내 직렬을 표시할지 선택할 수 있습니다.',
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                ],
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

    if (nickname.isEmpty) {
      _showMessage(context, '닉네임을 입력해주세요.');
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
        _showMessage(context, '프로필이 저장되었습니다.');
        context.pop();
      }
    } catch (error) {
      if (mounted) {
        _showMessage(context, '저장 중 오류가 발생했습니다: $error');
      }
    }
  }
}
