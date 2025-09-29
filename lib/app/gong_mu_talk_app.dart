import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/theme_cubit.dart';
import '../di/di.dart';
import '../features/auth/presentation/cubit/auth_cubit.dart';
import '../features/community/data/community_repository.dart';

class GongMuTalkApp extends StatelessWidget {
  const GongMuTalkApp({super.key});

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
