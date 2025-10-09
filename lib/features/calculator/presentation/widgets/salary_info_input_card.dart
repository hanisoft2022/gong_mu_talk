import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
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
                Column(
                  children: [
                    Text(
                      '탭하여 정보를 입력하세요',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    ),
                    const Gap(16),
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
                    ),
                  ],
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
                                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                                  const Gap(8),
                                  Text(
                                    '입력 완료',
                                    style: TextStyle(
                                      color: Colors.green[700],
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
                        ElevatedButton.icon(
                          onPressed: () => _showInputBottomSheet(context),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('수정'),
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
}
