import 'dart:async';

import 'package:bootpay/bootpay.dart';
import 'package:bootpay/model/extra.dart';
import 'package:bootpay/model/item.dart';
import 'package:bootpay/model/payload.dart';
import 'package:bootpay/model/user.dart';
import 'package:flutter/material.dart';

import '../../../core/config/payment_config.dart';

class PaymentResult {
  const PaymentResult.success()
    : isSuccess = true,
      message = '결제가 성공적으로 완료되었습니다.';

  const PaymentResult.failure(this.message) : isSuccess = false;

  final bool isSuccess;
  final String message;
}

class BootpayPaymentService {
  Future<PaymentResult> requestPensionSubscription({
    required BuildContext context,
    required int price,
    required String orderId,
  }) async {
    if (!PaymentConfig.isBootpayConfigured) {
      return const PaymentResult.failure(
        'Bootpay 환경 변수가 설정되지 않았습니다.\n'
        '--dart-define 으로 BOOTPAY_* 값을 설정해주세요.',
      );
    }

    final Completer<PaymentResult> completer = Completer<PaymentResult>();

    final Payload payload = Payload(
      androidApplicationId: PaymentConfig.androidApplicationId,
      iosApplicationId: PaymentConfig.iosApplicationId,
      webApplicationId: PaymentConfig.webApplicationId,
      price: price.toDouble(),
      orderId: orderId,
      orderName: '공무톡 연금 계산 이용권',
      pg: '나이스페이',
      method: 'card',
      items: [
        Item(
          name: '연금 계산 이용권',
          qty: 1,
          id: 'pension-pass',
          price: price.toDouble(),
        ),
      ],
      extra: Extra(displayCashReceipt: true, cardQuota: '0,2,3,4,5,6,9,12'),
      user: User()
        ..username = '공무원'
        ..phone = '',
    );

    Bootpay().requestPayment(
      context: context,
      payload: payload,
      onError: (error) {
        if (!completer.isCompleted) {
          completer.complete(PaymentResult.failure('결제 오류: $error'));
        }
      },
      onCancel: (data) {
        if (!completer.isCompleted) {
          completer.complete(const PaymentResult.failure('사용자가 결제를 취소했습니다.'));
        }
      },
      onClose: () {
        if (!completer.isCompleted) {
          completer.complete(
            const PaymentResult.failure('결제가 완료되지 않았습니다. 창이 닫혔어요.'),
          );
        }
      },
      onIssued: (data) {},
      onConfirm: (data) {
        // 서버 검증 로직이 필요한 경우 이 지점에서 처리합니다.
        return true;
      },
      onDone: (data) {
        if (!completer.isCompleted) {
          completer.complete(const PaymentResult.success());
        }
      },
    );

    return completer.future;
  }
}
