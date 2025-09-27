import 'package:equatable/equatable.dart';

enum PaymentMethod {
  card,
  bankTransfer,
  virtualAccount,
  kakaoPayy,
  naverpay,
}

class PaymentItem extends Equatable {
  const PaymentItem({
    required this.name,
    required this.quantity,
    required this.price,
    this.id,
  });

  final String? id;
  final String name;
  final int quantity;
  final double price;

  @override
  List<Object?> get props => [id, name, quantity, price];
}

class PaymentRequest extends Equatable {
  const PaymentRequest({
    required this.orderId,
    required this.orderName,
    required this.price,
    required this.items,
    this.method = PaymentMethod.card,
    this.pg = '나이스페이',
    this.userEmail,
    this.userName,
    this.userPhone,
  });

  final String orderId;
  final String orderName;
  final double price;
  final List<PaymentItem> items;
  final PaymentMethod method;
  final String pg;
  final String? userEmail;
  final String? userName;
  final String? userPhone;

  @override
  List<Object?> get props => [
        orderId,
        orderName,
        price,
        items,
        method,
        pg,
        userEmail,
        userName,
        userPhone,
      ];
}