import 'package:flutter/material.dart';

import '../app.dart';
import '../i18n.dart';
import '../theme.dart';
import 'catalog_screen.dart';
import 'home.dart';
import 'mine.dart';
import 'settings.dart';

/// Bottom-navigation shell: Scan · Ideas · My builds.
class Shell extends StatelessWidget {
  const Shell({super.key});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([app, app.tab]),
      builder: (context, _) {
        final tab = app.tab.value;
        return PopScope(
        canPop: tab == 0,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) app.tab.value = 0;
        },
        child: Scaffold(
          body: Baseplate(
            child: IndexedStack(index: tab, children: const [HomeScreen(), CatalogScreen(), MineScreen()]),
          ),
          bottomNavigationBar: NavigationBarTheme(
            data: NavigationBarThemeData(
              backgroundColor: p.card,
              indicatorColor: Brand.red.withValues(alpha: .12),
              labelTextStyle: WidgetStateProperty.resolveWith(
                (s) => body(12, weight: 800, color: s.contains(WidgetState.selected) ? Brand.red : p.muted),
              ),
              iconTheme: WidgetStateProperty.resolveWith(
                (s) => IconThemeData(color: s.contains(WidgetState.selected) ? Brand.red : p.muted),
              ),
            ),
            child: NavigationBar(
              selectedIndex: tab,
              onDestinationSelected: (i) => app.tab.value = i,
              height: 68,
              destinations: [
                NavigationDestination(icon: const Icon(Icons.center_focus_weak_rounded), label: t('tScan')),
                NavigationDestination(icon: const Icon(Icons.view_module_rounded), label: t('tIdeas')),
                NavigationDestination(
                  icon: Badge(
                    isLabelVisible: app.builds.isNotEmpty,
                    label: Text('${app.builds.length}'),
                    backgroundColor: Brand.red,
                    child: const Icon(Icons.star_outline_rounded),
                  ),
                  selectedIcon: const Icon(Icons.star_rounded),
                  label: t('tMine'),
                ),
              ],
            ),
          ),
        ),
      );
      },
    );
  }
}

/// Top bar shared by the three tabs: logo + settings.
class TopBar extends StatelessWidget {
  const TopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      const _Logo(),
      const SizedBox(width: 8),
      Expanded(child: Text(t('appName'), style: display(17))),
      IconButton(
        tooltip: t('settings'),
        icon: const Icon(Icons.settings_rounded),
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
      ),
    ]);
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) => Container(
        width: 26,
        height: 18,
        decoration: BoxDecoration(
          color: Brand.red,
          borderRadius: BorderRadius.circular(4),
          border: const Border(bottom: BorderSide(color: Color(0xFFA51C16), width: 4)),
        ),
      );
}
