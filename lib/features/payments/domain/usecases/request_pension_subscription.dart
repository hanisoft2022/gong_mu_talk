import 'package:flutter/material.dart';
import '../../../../core/utils/result.dart';
import '../entities/payment_result.dart';
import '../repositories/i_payment_repository.dart';

class RequestPensionSubscription {
  const RequestPensionSubscription(this._repository);

  final IPaymentRepository _repository;

  Future<AppResult<PaymentResult>> call({
    required BuildContext context,
    required int price,
    required String orderId,
    String? userEmail,
    String? userName,
  }) async {
    return _repository.requestPensionSubscription(
      context: context,
      price: price,
      orderId: orderId,
      userEmail: userEmail,
      userName: userName,
    );
  }
}