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
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../../di/di.dart';
import '../../../data/paystub_verification_repository.dart';
import '../../../domain/paystub_verification.dart';

class PaystubVerificationCard extends StatefulWidget {
  const PaystubVerificationCard({super.key, required this.uid});

  final String uid;

  @override
  State<PaystubVerificationCard> createState() => _PaystubVerificationCardState();
}

class _PaystubVerificationCardState extends State<PaystubVerificationCard> {
  PaystubVerificationRepository get _repository => getIt<PaystubVerificationRepository>();

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

            // 인증 완료 시 카드 숨김
            if (verification.status == PaystubVerificationStatus.verified) {
              return const SizedBox.shrink();
            }

            return Card(
              child: InkWell(
                onTap: verification.status == PaystubVerificationStatus.none ||
                        (verification.status == PaystubVerificationStatus.processing &&
                            isProcessingTimedOut)
                    ? () => context.push('/profile/verify-paystub')
                    : null,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: verification.status == PaystubVerificationStatus.processing
                              ? Colors.orange.withValues(alpha: 0.1)
                              : theme.colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          verification.status == PaystubVerificationStatus.processing
                              ? Icons.hourglass_empty
                              : Icons.verified_user,
                          color: verification.status == PaystubVerificationStatus.processing
                              ? Colors.orange.shade700
                              : theme.colorScheme.primary,
                          size: 24,
                        ),
                      ),
                      const Gap(16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '직렬 인증',
                              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const Gap(4),
                            Text(
                              verification.status == PaystubVerificationStatus.processing
                                  ? '인증 처리 중입니다 (1-2일 소요)'
                                  : '전문 라운지를 이용하려면 직렬 인증이 필요합니다',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Gap(8),
                      if (verification.status == PaystubVerificationStatus.none ||
                          (verification.status == PaystubVerificationStatus.processing &&
                              isProcessingTimedOut))
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        )
                      else if (verification.status == PaystubVerificationStatus.processing)
                        const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Checks if processing timeout has occurred (2 minutes)
  bool _isProcessingTimedOut(PaystubVerification verification) {
    if (verification.status != PaystubVerificationStatus.processing) {
      return false;
    }
    final DateTime? updatedAt = verification.updatedAt;
    if (updatedAt == null) {
      return false;
    }
    final Duration elapsed = DateTime.now().difference(updatedAt);
    return elapsed.inMinutes >= 2;
  }
}
