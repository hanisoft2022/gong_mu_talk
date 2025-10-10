import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:gong_mu_talk/core/constants/app_colors.dart';

import '../../../../di/di.dart';
import '../../data/paystub_verification_repository.dart';

class PaystubVerificationPage extends StatefulWidget {
  const PaystubVerificationPage({super.key});

  @override
  State<PaystubVerificationPage> createState() => _PaystubVerificationPageState();
}

class _PaystubVerificationPageState extends State<PaystubVerificationPage> {
  bool _agreedToTerms = false;
  File? _selectedFile;
  bool _isUploading = false;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: false);

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _submitVerification() async {
    if (!_agreedToTerms || _selectedFile == null) {
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final repository = getIt<PaystubVerificationRepository>();
      final bytes = await _selectedFile!.readAsBytes();
      final fileName = _selectedFile!.path.split('/').last;

      await repository.uploadPaystub(bytes: bytes, fileName: fileName, contentType: 'image/jpeg');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('직렬 인증이 신청되었습니다. 검토까지 1-2일 소요됩니다.'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('인증 신청 실패: ${e.toString()}'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('📃급여명세서로 직렬 인증하기'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 안내 섹션
            _buildInfoSection(theme),
            const Gap(24),

            // 왜 급여 명세서인가요?
            _buildWhyPaystubSection(theme),
            const Gap(32),

            // 개인정보 동의
            _buildConsentSection(theme),
            const Gap(32),

            // 업로드 섹션
            _buildUploadSection(theme),
            const Gap(40),

            // 제출 버튼
            _buildSubmitButton(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: theme.colorScheme.primary, size: 24),
              const Gap(8),
              Text(
                '직렬 인증이 필요한 이유',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const Gap(16),
          _buildInfoItem(theme, '🏛️', '전문 라운지 접근', '같은 직렬의 공무원들과 소통할 수 있는 전용 라운지를 이용할 수 있습니다.'),
          const Gap(12),
          _buildInfoItem(theme, '💬', '맞춤형 콘텐츠', '직렬별 맞춤 정보와 같은 고민을 하는 동료들의 이야기를 만나보세요.'),
          const Gap(12),
          _buildInfoItem(theme, '🔒', '안전한 커뮤니티', '검증된 공무원만 참여하여 더욱 신뢰할 수 있는 커뮤니티입니다.'),
        ],
      ),
    );
  }

  Widget _buildInfoItem(ThemeData theme, String emoji, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const Gap(12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              const Gap(4),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWhyPaystubSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.help_outline, color: theme.colorScheme.primary, size: 24),
              const Gap(8),
              Text(
                '왜 급여 명세서인가요?',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const Gap(16),
          _buildWhyPaystubItem(
            theme,
            '📋',
            '가장 정확한 직렬 정보',
            '급여 명세서에는 "초등교사 2급 정교사", "행정직 7급" 등 정확한 직렬과 계급이 명시되어 있습니다.',
          ),
          const Gap(12),
          _buildWhyPaystubItem(
            theme,
            '❌',
            '다른 방법은 불충분합니다',
            '재직증명서나 신분증은 직렬 정보가 불명확하거나 없는 경우가 많습니다.',
          ),
          const Gap(12),
          _buildWhyPaystubItem(
            theme,
            '🔒',
            '민감 정보는 가려도 됩니다',
            '급여액이나 계좌번호 등 민감한 정보는 가린 후 업로드하셔도 됩니다. 직렬과 계급만 확인 가능하면 됩니다.',
          ),
          const Gap(12),
          _buildWhyPaystubItem(theme, '🗑️', '인증 후 즉시 삭제', '업로드된 파일은 직렬 인증 완료 후 자동으로 삭제됩니다.'),
          const Gap(12),
          _buildWhyPaystubItem(
            theme,
            '⚡',
            '필요한 정보만 추출',
            '직렬, 계급, 소속 기관 정보만 추출하며 다른 용도로 사용하지 않습니다.',
          ),
        ],
      ),
    );
  }

  Widget _buildWhyPaystubItem(ThemeData theme, String emoji, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const Gap(12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              const Gap(4),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConsentSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.security, color: AppColors.successDark, size: 20),
              const Gap(8),
              Text(
                '개인정보 처리 안내',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.successDark,
                ),
              ),
            ],
          ),
          const Gap(12),
          Text(
            '• 수집 정보: 직렬, 계급 정보만 추출됩니다.\n'
            '• 보관 기간: 인증 완료 후 자동으로 삭제됩니다.\n'
            '• 보안: 모든 데이터는 암호화되어 전송 및 저장됩니다.\n'
            '• 목적: 직렬 확인 외 다른 용도로 사용되지 않습니다.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.6,
            ),
          ),
          const Gap(16),
          InkWell(
            onTap: () {
              setState(() {
                _agreedToTerms = !_agreedToTerms;
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Checkbox(
                    value: _agreedToTerms,
                    onChanged: (value) {
                      setState(() {
                        _agreedToTerms = value ?? false;
                      });
                    },
                  ),
                  Expanded(
                    child: Text(
                      '개인정보 수집 및 이용에 동의합니다',
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
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

  Widget _buildUploadSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '급여명세서 업로드',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const Gap(8),
        Text(
          '최근 3개월 이내의 급여명세서를 업로드해주세요.',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const Gap(16),

        if (_selectedFile == null)
          InkWell(
            onTap: _pickFile,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                children: [
                  Icon(Icons.cloud_upload_outlined, size: 48, color: theme.colorScheme.primary),
                  const Gap(12),
                  Text(
                    '파일 선택하기',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const Gap(4),
                  Text(
                    'JPG, PNG 형식 지원',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Stack(
            children: [
              Container(
                width: double.infinity,
                height: 300,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(_selectedFile!, fit: BoxFit.contain),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  onPressed: () {
                    setState(() {
                      _selectedFile = null;
                    });
                  },
                  icon: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.blackAlpha50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: AppColors.white, size: 20),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildSubmitButton(ThemeData theme) {
    final canSubmit = _agreedToTerms && _selectedFile != null && !_isUploading;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: canSubmit ? _submitVerification : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          disabledBackgroundColor: theme.colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _isUploading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
              )
            : Text(
                '인증 신청하기',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: canSubmit
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
      ),
    );
  }
}
