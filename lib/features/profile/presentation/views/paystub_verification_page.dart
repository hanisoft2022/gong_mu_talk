import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:gong_mu_talk/core/constants/app_colors.dart';

import '../../../../core/utils/snackbar_helpers.dart';
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
  bool _securityExpanded = false;
  bool _faqExpanded = false;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: false,
    );

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

      await repository.uploadPaystub(
        bytes: bytes,
        fileName: fileName,
        contentType: 'application/pdf',
      );

      if (mounted) {
        SnackbarHelpers.showSuccess(
          context,
          '직렬 인증이 신청되었습니다. 자동 검증 중입니다.',
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelpers.showError(context, '인증 신청 실패: ${e.toString()}');
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
      appBar: AppBar(
        title: const Text('급여명세서로 직렬 인증하기'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Trust Badge Header
            _buildTrustBadgeHeader(theme),
            const Gap(24),

            // NEIS Download Guide
            _buildNeisGuideSection(theme),
            const Gap(20),

            // Security Explanation (Expandable)
            _buildSecuritySection(theme),
            const Gap(20),

            // PDF Upload Section
            _buildUploadSection(theme),
            const Gap(20),

            // Privacy Consent
            _buildConsentSection(theme),
            const Gap(20),

            // FAQ Section
            _buildFaqSection(theme),
            const Gap(20),

            // Submit Button
            _buildSubmitButton(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildTrustBadgeHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.verified_user,
              size: 32,
              color: theme.colorScheme.primary,
            ),
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '신뢰할 수 있는 인증',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const Gap(4),
                Text(
                  '나이스(NEIS) 원본 PDF로\n위조 방지 검증을 진행합니다',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNeisGuideSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.download_outlined,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              const Gap(8),
              Text(
                '나이스(NEIS)에서 급여명세서 다운로드',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Gap(16),
          _buildGuideStep(theme, '1', '나이스(NEIS) 접속', 'https://neis.go.kr'),
          _buildGuideStep(theme, '2', '로그인 후 "급여" 메뉴 선택', null),
          _buildGuideStep(theme, '3', '"급여명세서 조회" 클릭', null),
          _buildGuideStep(theme, '4', '최근 월 선택 후 조회', null),
          _buildGuideStep(
            theme,
            '5',
            '"PDF 저장" 버튼으로 다운로드',
            '⚠️ 스크린샷이나 인쇄는 불가합니다',
          ),
        ],
      ),
    );
  }

  Widget _buildGuideStep(
    ThemeData theme,
    String step,
    String title,
    String? subtitle,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                step,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const Gap(2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontStyle: subtitle.startsWith('⚠️')
                          ? FontStyle.italic
                          : FontStyle.normal,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySection(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.tertiary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _securityExpanded = !_securityExpanded;
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(
                    Icons.security,
                    color: theme.colorScheme.tertiary,
                    size: 24,
                  ),
                  const Gap(12),
                  Expanded(
                    child: Text(
                      '어떻게 위조를 방지하나요?',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.tertiary,
                      ),
                    ),
                  ),
                  Icon(
                    _securityExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: theme.colorScheme.tertiary,
                  ),
                ],
              ),
            ),
          ),
          if (_securityExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const Gap(12),
                  _buildSecurityItem(
                    theme,
                    '✅ PDF 원본 검증',
                    '나이스에서 생성된 PDF인지 자동으로 확인합니다',
                  ),
                  const Gap(12),
                  _buildSecurityItem(
                    theme,
                    '✅ 수정 여부 검증',
                    'PDF가 편집되지 않은 원본인지 확인합니다',
                  ),
                  const Gap(12),
                  _buildSecurityItem(
                    theme,
                    '✅ 워터마크 검증',
                    '나이스 워터마크(기관명, 일시, IP, 성명)를 확인합니다',
                  ),
                  const Gap(12),
                  _buildSecurityItem(
                    theme,
                    '✅ 생성시간 교차검증',
                    'PDF 다운로드 시간과 워터마크 시간을 비교합니다',
                  ),
                  const Gap(16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const Gap(8),
                        Expanded(
                          child: Text(
                            '5회 실패 시 24시간 동안 재시도가 제한됩니다.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSecurityItem(ThemeData theme, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
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

  Widget _buildUploadSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '급여명세서 업로드',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const Gap(8),
        Text(
          '나이스에서 다운로드한 원본 PDF 파일만 업로드해주세요.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
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
                  Icon(
                    Icons.picture_as_pdf_outlined,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                  const Gap(12),
                  Text(
                    'PDF 파일 선택하기',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const Gap(4),
                  Text(
                    'PDF 형식만 지원',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.picture_as_pdf,
                  size: 40,
                  color: theme.colorScheme.primary,
                ),
                const Gap(16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedFile!.path.split('/').last,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Gap(4),
                      Text(
                        'PDF 파일 준비됨',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _selectedFile = null;
                    });
                  },
                  icon: Icon(
                    Icons.close,
                    color: theme.colorScheme.error,
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
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.security,
                color: AppColors.successDark,
                size: 20,
              ),
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
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
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

  Widget _buildFaqSection(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _faqExpanded = !_faqExpanded;
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(
                    Icons.help_outline,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                  const Gap(12),
                  Expanded(
                    child: Text(
                      '자주 묻는 질문',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    _faqExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (_faqExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const Gap(12),
                  _buildFaqItem(
                    theme,
                    'Q. 왜 PDF만 가능한가요?',
                    'A. 스크린샷이나 편집된 이미지는 위조가 가능합니다. 나이스에서 생성한 원본 PDF만 메타데이터 검증이 가능합니다.',
                  ),
                  const Gap(16),
                  _buildFaqItem(
                    theme,
                    'Q. 인증이 실패하면 어떻게 하나요?',
                    'A. 오류 메시지를 확인하고 나이스에서 다시 다운로드한 원본 PDF를 제출해주세요. 5회 실패 시 24시간 후 재시도 가능합니다.',
                  ),
                  const Gap(16),
                  _buildFaqItem(
                    theme,
                    'Q. 급여액이 표시되나요?',
                    'A. 아니요. 직렬과 계급 정보만 추출되며 급여액은 추출되지 않습니다.',
                  ),
                  const Gap(16),
                  _buildFaqItem(
                    theme,
                    'Q. 파일은 얼마나 보관되나요?',
                    'A. 인증 완료 후 자동으로 삭제됩니다.',
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFaqItem(ThemeData theme, String question, String answer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const Gap(6),
        Text(
          answer,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isUploading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.white,
                ),
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
