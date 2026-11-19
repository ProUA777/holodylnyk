import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api.dart';
import 'favorites.dart';
import 'history.dart';
import 'l10n.dart';
import 'models.dart';
import 'screens/favorites_screen.dart';
import 'screens/home_screen.dart';
import 'screens/shopping_screen.dart';
import 'screens/splash_screen.dart';
import 'shopping.dart';
import 'tastes.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final favorites = FavoritesStore();
  final shopping = ShoppingStore();
  final tastes = TasteStore();
  final history = HistoryStore();
  await Future.wait([favorites.load(), shopping.load(), tastes.load(), history.load()]);
  final prefs = await SharedPreferences.getInstance();
  // Мова: збережена → мова телефона (польська для pl) → українська
  final device = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
  final lang = prefs.getString('lang') ?? (device == 'pl' ? 'pl' : 'uk');
  runApp(RecipesApp(
    favorites: favorites,
    shopping: shopping,
    tastes: tastes,
    history: history,
    api: EngineClient(),
    initialLang: lang,
  ));
}

/// Спільні залежності для всіх екранів: AppScope.of(context)
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.favorites,
    required this.shopping,
    required this.tastes,
    required this.history,
    required this.api,
    required this.prefs,
    required this.setLanguage,
    required super.child,
  });

  final FavoritesStore favorites;
  final ShoppingStore shopping;
  final TasteStore tastes;
  final HistoryStore history;
  final EngineClient api;
  final ValueNotifier<RecipeParams> prefs; // дієта, ціль, час, порції, мова рецептів
  final ValueChanged<String> setLanguage;

  /// Налаштування + смаки (👍/👎) — саме це йде з кожним запитом до AI
  RecipeParams get requestParams => prefs.value.copyWith(liked: tastes.liked, disliked: tastes.disliked);

  static AppScope of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppScope>()!;

  @override
  bool updateShouldNotify(AppScope oldWidget) => false;
}

class RecipesApp extends StatefulWidget {
  const RecipesApp({
    super.key,
    required this.favorites,
    required this.shopping,
    required this.tastes,
    required this.history,
    required this.api,
    required this.initialLang,
  });

  final FavoritesStore favorites;
  final ShoppingStore shopping;
  final TasteStore tastes;
  final HistoryStore history;
  final EngineClient api;
  final String initialLang;

  @override
  State<RecipesApp> createState() => _RecipesAppState();
}

class _RecipesAppState extends State<RecipesApp> {
  late String _lang = widget.initialLang;
  late final _prefs = ValueNotifier(RecipeParams(language: widget.initialLang));

  void _setLanguage(String code) {
    if (code == _lang || !supportedStrings.containsKey(code)) return;
    setState(() => _lang = code);
    _prefs.value = _prefs.value.copyWith(language: code); // рецепти теж цією мовою
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
      favorites: widget.favorites,
      shopping: widget.shopping,
      tastes: widget.tastes,
      history: widget.history,
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
          home: const AnimatedSplash(child: Shell()),
        ),
      ),
    );
  }
}

/// Нижня навігація: Головна / Збережені / Покупки
class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final t = L10n.of(context);
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: const [HomeScreen(), FavoritesScreen(), ShoppingScreen()],
      ),
      bottomNavigationBar: ListenableBuilder(
        listenable: Listenable.merge([scope.favorites, scope.shopping]),
        builder: (context, _) => NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (i) => setState(() => _tab = i),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home),
              label: t.navHome,
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: scope.favorites.items.isNotEmpty,
                label: Text('${scope.favorites.items.length}'),
                child: const Icon(Icons.favorite_outline),
              ),
              selectedIcon: const Icon(Icons.favorite),
              label: t.navSaved,
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: scope.shopping.leftCount > 0,
                label: Text('${scope.shopping.leftCount}'),
                child: const Icon(Icons.shopping_basket_outlined),
              ),
              selectedIcon: const Icon(Icons.shopping_basket),
              label: t.navShopping,
            ),
          ],
        ),
      ),
    );
  }
}
