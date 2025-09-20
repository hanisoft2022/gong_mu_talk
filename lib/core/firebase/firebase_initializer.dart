import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'package:gong_mu_talk/firebase_options.dart';

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
    } on UnsupportedError catch (error, stackTrace) {
      debugPrint(
        '현재 실행 중인 플랫폼에 대한 Firebase 옵션이 구성되지 않았습니다. 필요한 경우 FlutterFire CLI로 다시 설정하세요.',
      );
      debugPrint('$error');
      debugPrint('$stackTrace');
      _initialized = true;
      return;
    } catch (error, stackTrace) {
      debugPrint('Firebase 초기화 중 오류 발생: $error');
      debugPrint('$stackTrace');
      rethrow;
    }
  }
}
