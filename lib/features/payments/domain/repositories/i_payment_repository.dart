import 'package:flutter/material.dart';
import '../../../../core/utils/result.dart';
import '../entities/payment_request.dart';
import '../entities/payment_result.dart';

abstract class IPaymentRepository {
  /// Process a payment request
  Future<AppResult<PaymentResult>> processPayment({
    required BuildContext context,
    required PaymentRequest request,
  });

  /// Request pension subscription payment
  Future<AppResult<PaymentResult>> requestPensionSubscription({
    required BuildContext context,
    required int price,
    required String orderId,
    String? userEmail,
    String? userName,
  });

  /// Verify payment transaction
  Future<AppResult<bool>> verifyPayment(String transactionId);

  /// Cancel payment
  Future<AppResult<PaymentResult>> cancelPayment(String orderId);

  /// Get payment history
  Future<AppResult<List<PaymentResult>>> getPaymentHistory({
    int limit = 20,
    String? lastTransactionId,
  });
}