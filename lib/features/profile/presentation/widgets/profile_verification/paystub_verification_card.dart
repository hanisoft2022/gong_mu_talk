/// Paystub Verification Card
///
/// Real-time paystub verification status card.
/// - Firebase stream subscription for verification status
/// - Processing timeout detection (2 minutes)
/// - Shows verification prompt when not verified
/// - Hides when verified or test mode active
///
/// Phase 4 - Extracted from profile_page.dart
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gong_mu_talk/core/constants/app_colors.dart';

import '../../../../../di/di.dart';
import '../../../data/paystub_verification_repository.dart';
import '../../../domain/paystub_verification.dart';
import 'verification_card_base.dart';

class PaystubVerificationCard extends StatefulWidget {
  const PaystubVerificationCard({super.key, required this.uid});

  final String uid;

  @override
  State<PaystubVerificationCard> createState() => _PaystubVerificationCardState();
}

class _PaystubVerificationCardState extends State<PaystubVerificationCard> {
  PaystubVerificationRepository get _repository => getIt<PaystubVerificationRepository>();

  PaystubVerificationStatus? _previousStatus;
  bool _hasNavigatedToSuccess = false;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(widget.uid).snapshots(),
      builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> userSnapshot) {
        // 테스트 모드 직렬이 설정되어 있으면 카드 숨김
        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          final data = userSnapshot.data!.data() as Map<String, dynamic>?;
          if (data != null && data['testModeCareer'] != null) {
            return const SizedBox.shrink();
          }
        }

        return StreamBuilder<PaystubVerification>(
          stream: _repository.watchVerification(widget.uid),
          builder: (BuildContext context, AsyncSnapshot<PaystubVerification> snapshot) {
            final PaystubVerification verification = snapshot.data ?? PaystubVerification.none;
            final bool isProcessingTimedOut = _isProcessingTimedOut(verification);

            // 인증 완료 시 success 페이지로 네비게이션
            if (verification.status == PaystubVerificationStatus.verified) {
              if (!_hasNavigatedToSuccess &&
                  _previousStatus == PaystubVerificationStatus.processing) {
                _hasNavigatedToSuccess = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    context.push('/profile/verify-paystub/success');
                  }
                });
              }
              return const SizedBox.shrink();
            }

            // 상태 추적
            _previousStatus = verification.status;

            final bool isProcessing = verification.status == PaystubVerificationStatus.processing;
            final bool canTap =
                verification.status == PaystubVerificationStatus.none ||
                (isProcessing && isProcessingTimedOut);

            return VerificationCardBase(
              leadingIcon: buildIconContainer(
                context: context,
                icon: isProcessing ? Icons.hourglass_empty : Icons.verified_user,
                backgroundColor: isProcessing
                    ? AppColors.warning.withValues(alpha: 0.1)
                    : theme.colorScheme.primary.withValues(alpha: 0.1),
                iconColor: isProcessing ? AppColors.warningDark : theme.colorScheme.primary,
              ),
              title: '직렬 인증',
              subtitle: isProcessing
                  ? '자동 검증 중입니다 (수초 소요)'
                  : '모든 계산기 기능과 전문 라운지를 이용하려면 직렬 인증이 필요합니다',
              onTap: canTap ? () => context.push('/profile/verify-paystub') : null,
              trailing: canTap
                  ? Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    )
                  : isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
            );
          },
        );
      },
    );
  }

  /// Checks if processing timeout has occurred (5 minutes)
  bool _isProcessingTimedOut(PaystubVerification verification) {
    if (verification.status != PaystubVerificationStatus.processing) {
      return false;
    }
    final DateTime? updatedAt = verification.updatedAt;
    if (updatedAt == null) {
      return false;
    }
    final Duration elapsed = DateTime.now().difference(updatedAt);
    return elapsed.inMinutes >= 5;
  }
}
