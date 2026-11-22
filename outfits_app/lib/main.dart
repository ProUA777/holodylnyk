import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api.dart';
import 'closet.dart';
import 'l10n.dart';
import 'models.dart';
import 'screens/home_screen.dart';
import 'screens/looks_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/wardrobe_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final wardrobe = WardrobeStore();
  final looks = LooksStore();
  await Future.wait([wardrobe.load(), looks.load()]);
  final prefs = await SharedPreferences.getInstance();
  final device = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
  final lang = prefs.getString('lang') ?? (device == 'pl' ? 'pl' : 'uk');
  var params = OutfitParams(language: lang);
  final saved = prefs.getString('params');
  if (saved != null) {
    try {
      params = OutfitParams.fromJson(jsonDecode(saved) as Map<String, dynamic>).copyWith(language: lang);
    } catch (_) {}
  }
  runApp(OutfitsApp(wardrobe: wardrobe, looks: looks, api: EngineClient(), initialParams: params));
}

/// Спільні залежності для всіх екранів: AppScope.of(context)
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.wardrobe,
    required this.looks,
    required this.api,
    required this.prefs,
    required this.setLanguage,
    required super.child,
  });

  final WardrobeStore wardrobe;
  final LooksStore looks;
  final EngineClient api;
  final ValueNotifier<OutfitParams> prefs; // куди, погода, чиї образи, мова
  final ValueChanged<String> setLanguage;

  static AppScope of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppScope>()!;

  @override
  bool updateShouldNotify(AppScope oldWidget) => false;
}

class OutfitsApp extends StatefulWidget {
  const OutfitsApp({super.key, required this.wardrobe, required this.looks, required this.api, required this.initialParams});

  final WardrobeStore wardrobe;
  final LooksStore looks;
  final EngineClient api;
  final OutfitParams initialParams;

  @override
  State<OutfitsApp> createState() => _OutfitsAppState();
}

class _OutfitsAppState extends State<OutfitsApp> {
  late final _prefs = ValueNotifier(widget.initialParams);
  late String _lang = widget.initialParams.language;

  @override
  void initState() {
    super.initState();
    _prefs.addListener(() {
      final p = _prefs.value;
      SharedPreferences.getInstance().then((s) => s.setString('params', jsonEncode(p.toJson())));
    });
  }

  void _setLanguage(String code) {
    if (code == _lang || !supportedStrings.containsKey(code)) return;
    setState(() => _lang = code);
    _prefs.value = _prefs.value.copyWith(language: code);
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
      wardrobe: widget.wardrobe,
      looks: widget.looks,
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

/// Нижня навігація: Головна / Гардероб / Образи
class Shell extends StatefulWidget {
  const Shell({super.key});

  static final globalKey = GlobalKey<_ShellState>();

  /// Перейти на вкладку з будь-якого екрана (закриває відкриті поверх екрани)
  static void openTab(BuildContext context, int tab) {
    Navigator.of(context).popUntil((r) => r.isFirst);
    globalKey.currentState?._go(tab);
  }

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _tab = 0;

  void _go(int i) => setState(() => _tab = i);

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final t = L10n.of(context);
    return Scaffold(
      body: IndexedStack(index: _tab, children: const [HomeScreen(), WardrobeScreen(), LooksScreen()]),
      bottomNavigationBar: ListenableBuilder(
        listenable: Listenable.merge([scope.wardrobe, scope.looks]),
        builder: (context, _) => NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: _go,
          destinations: [
            NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home), label: t.navHome),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: scope.wardrobe.items.isNotEmpty,
                label: Text('${scope.wardrobe.items.length}'),
                child: const Icon(Icons.checkroom_outlined),
              ),
              selectedIcon: const Icon(Icons.checkroom),
              label: t.navWardrobe,
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: scope.looks.items.isNotEmpty,
                backgroundColor: AppColors.coral,
                label: Text('${scope.looks.items.length}'),
                child: const Icon(Icons.favorite_outline),
              ),
              selectedIcon: const Icon(Icons.favorite),
              label: t.navLooks,
            ),
          ],
        ),
      ),
    );
  }
}
