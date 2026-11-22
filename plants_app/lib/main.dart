import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api.dart';
import 'garden.dart';
import 'l10n.dart';
import 'models.dart';
import 'screens/garden_screen.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final garden = GardenStore();
  await garden.load();
  final prefs = await SharedPreferences.getInstance();
  final device = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
  final lang = prefs.getString('lang') ?? (device == 'pl' ? 'pl' : 'uk');
  PlantParams params = PlantParams(language: lang);
  final saved = prefs.getString('params');
  if (saved != null) {
    try {
      params = PlantParams.fromJson(jsonDecode(saved) as Map<String, dynamic>).copyWith(language: lang);
    } catch (_) {}
  }
  runApp(PlantsApp(garden: garden, api: EngineClient(), initialParams: params));
}

/// Спільні залежності для всіх екранів: AppScope.of(context)
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.garden,
    required this.api,
    required this.prefs,
    required this.setLanguage,
    required super.child,
  });

  final GardenStore garden;
  final EngineClient api;
  final ValueNotifier<PlantParams> prefs; // де росте, тварини, діти, мова
  final ValueChanged<String> setLanguage;

  static AppScope of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppScope>()!;

  @override
  bool updateShouldNotify(AppScope oldWidget) => false;
}

class PlantsApp extends StatefulWidget {
  const PlantsApp({super.key, required this.garden, required this.api, required this.initialParams});

  final GardenStore garden;
  final EngineClient api;
  final PlantParams initialParams;

  @override
  State<PlantsApp> createState() => _PlantsAppState();
}

class _PlantsAppState extends State<PlantsApp> {
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
      garden: widget.garden,
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

/// Нижня навігація: Головна / Мої рослини
class Shell extends StatefulWidget {
  const Shell({super.key});

  static final globalKey = GlobalKey<_ShellState>();

  /// Перейти на «Мої рослини» з будь-якого екрана (закриває відкриті поверх екрани)
  static void openGarden(BuildContext context) {
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
    final garden = AppScope.of(context).garden;
    final t = L10n.of(context);
    return Scaffold(
      body: IndexedStack(index: _tab, children: const [HomeScreen(), GardenScreen()]),
      bottomNavigationBar: ListenableBuilder(
        listenable: garden,
        builder: (context, _) {
          final thirsty = garden.thirstyCount(DateTime.now());
          return NavigationBar(
            selectedIndex: _tab,
            onDestinationSelected: _go,
            destinations: [
              NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home), label: t.navHome),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: thirsty > 0,
                  backgroundColor: AppColors.water,
                  label: Text('$thirsty'),
                  child: const Icon(Icons.local_florist_outlined),
                ),
                selectedIcon: const Icon(Icons.local_florist),
                label: t.navGarden,
              ),
            ],
          );
        },
      ),
    );
  }
}
