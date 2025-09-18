import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../core/config/app_config.dart';
import '../core/observers/app_bloc_observer.dart';
import '../di/di.dart';

typedef AppBuilder = Widget Function();

Future<void> bootstrap(AppBuilder builder) async {
  runZonedGuarded(() async {
    Intl.defaultLocale = 'ko_KR';
    AppConfig.initialize();
    await configureDependencies();
    Bloc.observer = AppBlocObserver();
    runApp(builder());
  }, (error, stackTrace) {
    debugPrint('Uncaught exception: $error');
    debugPrint('$stackTrace');
  });
}
