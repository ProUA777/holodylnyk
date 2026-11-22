import 'package:flutter/material.dart';

import '../l10n.dart';
import '../main.dart';
import '../theme.dart';
import '../widgets/outfit_card.dart';

/// Збережені образи (♥)
class LooksScreen extends StatelessWidget {
  const LooksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final t = L10n.of(context);
    final extra = Extra.of(context);
    return SafeArea(
      child: ListenableBuilder(
        listenable: Listenable.merge([scope.looks, scope.wardrobe]),
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Text(t.looksSavedTitle, style: display(28)),
            const SizedBox(height: 16),
            if (scope.looks.items.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: extra.leaf, borderRadius: BorderRadius.circular(24)),
                child: Column(children: [
                  const Text('🤍', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 10),
                  Text(t.looksEmpty, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600)),
                ]),
              )
            else
              for (final o in scope.looks.items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: OutfitCard(outfit: o, known: scope.wardrobe.items),
                ),
          ],
        ),
      ),
    );
  }
}
