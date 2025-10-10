import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:gong_mu_talk/common/widgets/confirm_dialog.dart';
import 'package:gong_mu_talk/core/theme/app_color_extension.dart';
import 'package:gong_mu_talk/features/calculator/domain/entities/teacher_profile.dart';
import 'package:gong_mu_talk/features/calculator/presentation/cubit/calculator_cubit.dart';
import 'package:gong_mu_talk/features/calculator/presentation/widgets/quick_input_bottom_sheet.dart';

/// 내 정보 입력 카드
class SalaryInfoInputCard extends StatelessWidget {
  final bool isDataEntered;
  final TeacherProfile? profile;

  const SalaryInfoInputCard({super.key, required this.isDataEntered, this.profile});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => _showInputBottomSheet(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '📝  내 정보 입력',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),

              const Gap(16),

              // 입력 상태에 따른 UI 변경
              if (!isDataEntered)
                // 미입력 상태
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showInputBottomSheet(context),
                    icon: const Icon(Icons.edit),
                    label: const Text('시작하기'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                )
              else
                // 입력 완료 상태
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: context.appColors.success,
                                    size: 20,
                                  ),
                                  const Gap(8),
                                  Text(
                                    '입력 완료',
                                    style: TextStyle(
                                      color: context.appColors.success,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const Gap(8),
                              if (profile != null)
                                Text(
                                  '${profile!.currentGrade}호봉 · ${profile!.position.displayName}',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                                ),
                            ],
                          ),
                        ),
                        IconButton.filled(
                          onPressed: () => _showInputBottomSheet(context),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          tooltip: '수정',
                          style: IconButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        const Gap(3),
                        IconButton.filled(
                          onPressed: () => _showResetConfirmDialog(context),
                          icon: const Icon(Icons.delete_outline, size: 18),
                          tooltip: '초기화',
                          style: IconButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.error,
                            foregroundColor: Theme.of(context).colorScheme.onError,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInputBottomSheet(BuildContext context) {
    final cubit = context.read<CalculatorCubit>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => QuickInputBottomSheet(
        initialProfile: profile,
        onSubmit: (profile) => cubit.saveProfile(profile),
      ),
    );
  }

  Future<void> _showResetConfirmDialog(BuildContext context) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: '입력 정보 초기화',
      message: '입력한 모든 정보가 삭제됩니다.\n계속하시겠습니까?',
      type: ConfirmDialogType.warning,
      confirmText: '초기화',
    );

    if (confirmed == true && context.mounted) {
      context.read<CalculatorCubit>().clearProfile();
    }
  }
}
