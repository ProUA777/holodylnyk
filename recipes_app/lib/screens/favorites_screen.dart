import 'package:flutter/material.dart';

import '../l10n.dart';
import '../main.dart';
import '../theme.dart';
import 'recipe_screen.dart';
import 'results_screen.dart' show EmojiTile;

/// Вкладка «Збережені»: рецепти разом з детальним текстом, працюють без інтернету.
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favorites = AppScope.of(context).favorites;
    final theme = Theme.of(context);
    final extra = Extra.of(context);
    final t = L10n.of(context);
    return SafeArea(
      child: ListenableBuilder(
        listenable: favorites,
        builder: (context, _) {
          final items = favorites.items;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              Text(t.savedTitle, style: display(30)),
              const SizedBox(height: 16),
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: Column(children: [
                    const Text('🤍', style: TextStyle(fontSize: 44)),
                    const SizedBox(height: 10),
                    Text(t.savedEmpty,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(color: extra.muted)),
                  ]),
                ),
              ...items.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Dismissible(
                      key: ValueKey(r.title),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 22),
                        decoration: BoxDecoration(color: extra.tomatoBg, borderRadius: BorderRadius.circular(18)),
                        child: Icon(Icons.delete_outline, color: extra.tomato),
                      ),
                      onDismissed: (_) => favorites.toggle(r),
                      child: Material(
                        color: theme.colorScheme.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: theme.colorScheme.outline, width: 1.5),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => Navigator.of(context)
                              .push(MaterialPageRoute(builder: (_) => RecipeScreen(recipe: r))),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(children: [
                              EmojiTile(emoji: r.emoji, color: mealColor(r.mealType), size: 48),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(r.title,
                                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                                  Text(
                                    '${t.minutes(r.timeMinutes)}${r.cuisine != null ? ', ${r.cuisine}' : ''}',
                                    style: theme.textTheme.bodySmall?.copyWith(color: extra.muted),
                                  ),
                                ]),
                              ),
                              const Icon(Icons.chevron_right),
                            ]),
                          ),
                        ),
                      ),
                    ),
                  )),
              if (items.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(t.swipeToDelete, textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(color: extra.muted)),
                ),
            ],
          );
        },
      ),
    );
  }
}
