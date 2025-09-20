import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../core/config/app_config.dart';
import '../core/firebase/firebase_initializer.dart';
import '../core/observers/app_bloc_observer.dart';
import '../di/di.dart';

typedef AppBuilder = Widget Function();

Future<void> bootstrap(AppBuilder builder) async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      AppConfig.initialize();
      Intl.defaultLocale = 'ko_KR';
      await FirebaseInitializer.ensureInitialized();

      final Future<void> localeFuture = initializeDateFormatting('ko_KR');
      final Future<void> diFuture = configureDependencies();
      unawaited(_initializeMobileAds());

      await Future.wait(<Future<void>>[localeFuture, diFuture]);
      Bloc.observer = AppBlocObserver();
      runApp(builder());
    },
    (error, stackTrace) {
      debugPrint('Uncaught exception: $error');
      debugPrint('$stackTrace');
    },
  );
}

Future<void> _initializeMobileAds() async {
  try {
    await MobileAds.instance.initialize();
  } catch (error, stackTrace) {
    debugPrint('Failed to initialize Mobile Ads: $error');
    debugPrint('$stackTrace');
  }
}
