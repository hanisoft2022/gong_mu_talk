import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../core/config/app_config.dart';
import '../core/firebase/firebase_initializer.dart';
import '../core/observers/app_bloc_observer.dart';
import '../di/di.dart';
import '../features/community/domain/services/lounge_loader.dart';

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
      final Future<void> loungeFuture = LoungeLoader.init();
      // Ads removed

      await Future.wait(<Future<void>>[localeFuture, diFuture, loungeFuture]);
      Bloc.observer = AppBlocObserver();
      runApp(builder());
    },
    (error, stackTrace) {
      debugPrint('Uncaught exception: $error');
      debugPrint('$stackTrace');
    },
  );
}

// Ads removed
