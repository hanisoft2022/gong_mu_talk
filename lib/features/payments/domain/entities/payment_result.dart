import 'package:equatable/equatable.dart';

enum PaymentStatus {
  success,
  failure,
  cancelled,
  pending,
}

class PaymentResult extends Equatable {
  const PaymentResult({
    required this.status,
    required this.message,
    this.transactionId,
    this.orderId,
    this.amount,
    this.errorCode,
  });

  const PaymentResult.success({
    required this.message,
    this.transactionId,
    this.orderId,
    this.amount,
  }) : status = PaymentStatus.success,
       errorCode = null;

  const PaymentResult.failure({
    required this.message,
    this.errorCode,
    this.orderId,
  }) : status = PaymentStatus.failure,
       transactionId = null,
       amount = null;

  const PaymentResult.cancelled({
    required this.message,
    this.orderId,
  }) : status = PaymentStatus.cancelled,
       transactionId = null,
       amount = null,
       errorCode = null;

  final PaymentStatus status;
  final String message;
  final String? transactionId;
  final String? orderId;
  final double? amount;
  final String? errorCode;

  bool get isSuccess => status == PaymentStatus.success;
  bool get isFailure => status == PaymentStatus.failure;
  bool get isCancelled => status == PaymentStatus.cancelled;
  bool get isPending => status == PaymentStatus.pending;

  @override
  List<Object?> get props => [
        status,
        message,
        transactionId,
        orderId,
        amount,
        errorCode,
      ];
}