import 'package:flutter/material.dart';
import '../../../../core/utils/result.dart';
import '../entities/payment_request.dart';
import '../entities/payment_result.dart';
import '../repositories/i_payment_repository.dart';

class ProcessPayment {
  const ProcessPayment(this._repository);

  final IPaymentRepository _repository;

  Future<AppResult<PaymentResult>> call({
    required BuildContext context,
    required PaymentRequest request,
  }) async {
    return _repository.processPayment(
      context: context,
      request: request,
    );
  }
}