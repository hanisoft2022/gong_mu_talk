import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'firebase_options.dart';

class FirebaseInitializer {
  const FirebaseInitializer._();

  static bool _initialized = false;

  static Future<void> ensureInitialized() async {
    if (_initialized) {
      return;
    }

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _initialized = true;
    } on UnimplementedError catch (error, stackTrace) {
      debugPrint(
        'Firebase 옵션이 아직 구성되지 않았습니다. firebase_options.dart 스텁을 교체한 후 다시 시도하세요.',
      );
      debugPrint('$error');
      debugPrint('$stackTrace');
      return;
    } catch (error, stackTrace) {
      debugPrint('Firebase 초기화 중 오류 발생: $error');
      debugPrint('$stackTrace');
      rethrow;
    }
  }
}
