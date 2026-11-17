import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app.dart';
import 'data/catalog.dart';
import 'i18n.dart';
import 'screens/intro.dart';
import 'screens/onboarding.dart';
import 'screens/shell.dart';
import 'state/app_state.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final loaded = await Future.wait<Object>([Catalog.load(), AppState.load()]);
  catalog = loaded[0] as Catalog;
  app = loaded[1] as AppState;
  runApp(const WhatToBuildApp());
}

class WhatToBuildApp extends StatelessWidget {
  const WhatToBuildApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) => MaterialApp(
        title: t('appName'),
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        themeMode: app.theme,
        locale: Locale(app.lang),
        supportedLocales: const [Locale('uk'), Locale('pl'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: const SplashGate(child: Root()),
      ),
    );
  }
}

/// Switches between the intro and the main app whenever the onboarding flag changes.
class Root extends StatelessWidget {
  const Root({super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: app,
        builder: (context, _) => app.onboarded ? const Shell() : const OnboardingScreen(),
      );
}
