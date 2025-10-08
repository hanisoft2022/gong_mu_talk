import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:app_links/app_links.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/theme_cubit.dart';
import '../di/di.dart';
import '../features/auth/presentation/cubit/auth_cubit.dart';
import '../features/community/data/community_repository.dart';
import '../features/profile/presentation/cubit/notification_preferences_cubit.dart';

class GongMuTalkApp extends StatefulWidget {
  const GongMuTalkApp({super.key});

  @override
  State<GongMuTalkApp> createState() => _GongMuTalkAppState();
}

class _GongMuTalkAppState extends State<GongMuTalkApp> {
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    // Handle initial link if app was opened via deep link
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }
    } catch (e) {
      debugPrint('Failed to get initial link: $e');
    }

    // Handle links while app is running
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        _handleDeepLink(uri);
      },
      onError: (err) {
        debugPrint('Deep link error: $err');
      },
    );
  }

  void _handleDeepLink(Uri uri) {
    debugPrint('Deep link received: $uri');

    // Navigate to the path from deep link
    // gongmutalk://community/posts/abc123 -> /community/posts/abc123
    final router = getIt<GoRouter>();
    router.go(uri.path);
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final GoRouter router = getIt<GoRouter>();

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<CommunityRepository>.value(
          value: getIt<CommunityRepository>(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<ThemeCubit>.value(value: getIt<ThemeCubit>()),
          BlocProvider<AuthCubit>.value(value: getIt<AuthCubit>()),
          BlocProvider<NotificationPreferencesCubit>.value(
            value: getIt<NotificationPreferencesCubit>(),
          ),
        ],
        child: BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, themeMode) {
            return MaterialApp.router(
              debugShowCheckedModeBanner: false,
              title: '공무톡',
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: themeMode,
              routerConfig: router,
              locale: const Locale('ko'),
              supportedLocales: const [Locale('ko'), Locale('en')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
              ],
            );
          },
        ),
      ),
    );
  }
}
