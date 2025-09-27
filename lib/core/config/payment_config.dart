class PaymentConfig {
  const PaymentConfig._();

  static const String androidApplicationId = String.fromEnvironment(
    'BOOTPAY_ANDROID_APP_ID',
  );
  static const String iosApplicationId = String.fromEnvironment(
    'BOOTPAY_IOS_APP_ID',
  );
  static const String webApplicationId = String.fromEnvironment(
    'BOOTPAY_WEB_APPLICATION_ID',
  );
  static const String restApplicationId = String.fromEnvironment(
    'BOOTPAY_REST_APPLICATION_ID',
  );
  static const String restPrivateKey = String.fromEnvironment(
    'BOOTPAY_REST_PRIVATE_KEY',
  );

  static bool get isBootpayConfigured =>
      androidApplicationId.isNotEmpty &&
      iosApplicationId.isNotEmpty &&
      restApplicationId.isNotEmpty &&
      restPrivateKey.isNotEmpty;
}
