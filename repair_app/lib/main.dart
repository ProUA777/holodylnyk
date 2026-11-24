import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api.dart';
import 'repairs.dart';
import 'l10n.dart';
import 'models.dart';
import 'screens/repairs_screen.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repairs = RepairsStore();
  await repairs.load();
  final prefs = await SharedPreferences.getInstance();
  final device = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
  final lang = prefs.getString('lang') ?? (device == 'pl' ? 'pl' : 'uk');
  RepairParams params = RepairParams(language: lang);
  final saved = prefs.getString('params');
  if (saved != null) {
    try {
      params = RepairParams.fromJson(jsonDecode(saved) as Map<String, dynamic>).copyWith(language: lang);
    } catch (_) {}
  }
  runApp(RepairApp(repairs: repairs, api: EngineClient(), initialParams: params));
}

/// Спільні залежності для всіх екранів: AppScope.of(context)
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.repairs,
    required this.api,
    required this.prefs,
    required this.setLanguage,
    required super.child,
  });

  final RepairsStore repairs;
  final EngineClient api;
  final ValueNotifier<RepairParams> prefs; // досвід і мова
  final ValueChanged<String> setLanguage;

  static AppScope of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppScope>()!;

  @override
  bool updateShouldNotify(AppScope oldWidget) => false;
}

class RepairApp extends StatefulWidget {
  const RepairApp({super.key, required this.repairs, required this.api, required this.initialParams});

  final RepairsStore repairs;
  final EngineClient api;
  final RepairParams initialParams;

  @override
  State<RepairApp> createState() => _RepairAppState();
}

class _RepairAppState extends State<RepairApp> {
  late final _prefs = ValueNotifier(widget.initialParams);
  late String _lang = widget.initialParams.language;

  @override
  void initState() {
    super.initState();
    // Налаштування переживають перезапуск апки
    _prefs.addListener(() {
      final p = _prefs.value;
      SharedPreferences.getInstance().then((s) => s.setString('params', jsonEncode(p.toJson())));
    });
  }

  void _setLanguage(String code) {
    if (code == _lang || !supportedStrings.containsKey(code)) return;
    setState(() => _lang = code);
    _prefs.value = _prefs.value.copyWith(language: code); // відповіді AI теж цією мовою
    SharedPreferences.getInstance().then((p) => p.setString('lang', code));
  }

  @override
  void dispose() {
    _prefs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = supportedStrings[_lang]!;
    return AppScope(
      repairs: widget.repairs,
      api: widget.api,
      prefs: _prefs,
      setLanguage: _setLanguage,
      child: L10n(
        strings: strings,
        child: MaterialApp(
          title: strings.appName,
          debugShowCheckedModeBanner: false,
          theme: buildTheme(Brightness.light),
          darkTheme: buildTheme(Brightness.dark),
          home: AnimatedSplash(child: Shell(key: Shell.globalKey)),
        ),
      ),
    );
  }
}

/// Нижня навігація: Головна / Мої ремонти
class Shell extends StatefulWidget {
  const Shell({super.key});

  static final globalKey = GlobalKey<_ShellState>();

  /// Перейти на «Мої ремонти» з будь-якого екрана (закриває відкриті поверх екрани)
  static void openRepairs(BuildContext context) {
    Navigator.of(context).popUntil((r) => r.isFirst);
    globalKey.currentState?._go(1);
  }

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _tab = 0;

  void _go(int i) => setState(() => _tab = i);

  @override
  Widget build(BuildContext context) {
    final repairs = AppScope.of(context).repairs;
    final t = L10n.of(context);
    return Scaffold(
      body: IndexedStack(index: _tab, children: const [HomeScreen(), RepairsScreen()]),
      bottomNavigationBar: ListenableBuilder(
        listenable: repairs,
        builder: (context, _) => NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: _go,
          destinations: [
            NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home), label: t.navHome),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: repairs.openCount > 0,
                backgroundColor: AppColors.orange,
                textColor: AppColors.ink,
                label: Text('${repairs.openCount}'),
                child: const Icon(Icons.build_outlined),
              ),
              selectedIcon: const Icon(Icons.build),
              label: t.navRepairs,
            ),
          ],
        ),
      ),
    );
  }
}
