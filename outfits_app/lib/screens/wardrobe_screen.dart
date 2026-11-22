import 'package:flutter/material.dart';

import '../l10n.dart';
import '../main.dart';
import '../models.dart';
import '../theme.dart';
import 'result_screen.dart';

/// «Мій гардероб»: речі з фото, згруповані за типом. Можна додати річ словами або прибрати.
class WardrobeScreen extends StatelessWidget {
  const WardrobeScreen({super.key});

  Future<void> _add(BuildContext context) async {
    final t = L10n.of(context);
    final wardrobe = AppScope.of(context).wardrobe;
    final ctrl = TextEditingController();
    var kind = Kind.top;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text(t.addItem),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: ctrl, autofocus: true, maxLength: 60, decoration: InputDecoration(hintText: t.itemName)),
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (final k in Kind.values)
                ChoiceChip(label: Text(t.kindLabels[k]!), selected: kind == k, onSelected: (_) => setD(() => kind = k)),
            ]),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t.cancel)),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(t.save)),
          ],
        ),
      ),
    );
    final name = ctrl.text.trim();
    ctrl.dispose();
    if (ok == true && name.isNotEmpty) await wardrobe.addAll([Item(name: name, kind: kind)]);
  }

  @override
  Widget build(BuildContext context) {
    final wardrobe = AppScope.of(context).wardrobe;
    final t = L10n.of(context);
    final extra = Extra.of(context);
    return SafeArea(
      child: ListenableBuilder(
        listenable: wardrobe,
        builder: (context, _) {
          final groups = wardrobe.byKind;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              Row(children: [
                Expanded(child: Text(t.wardrobeTitle, style: display(28))),
                IconButton.filledTonal(tooltip: t.addItem, onPressed: () => _add(context), icon: const Icon(Icons.add)),
              ]),
              if (wardrobe.items.isNotEmpty)
                Text(t.itemsN(wardrobe.items.length), style: TextStyle(color: extra.muted, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              if (wardrobe.items.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: extra.leaf, borderRadius: BorderRadius.circular(24)),
                  child: Column(children: [
                    const Text('👚', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 10),
                    Text(t.wardrobeEmpty, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600, height: 1.4)),
                  ]),
                )
              else ...[
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ResultScreen(images: []))),
                  icon: const Icon(Icons.auto_awesome),
                  label: Text(t.pickLooks),
                ),
                for (final e in groups.entries) ...[
                  const SizedBox(height: 20),
                  Text('${e.value.first.emoji} ${t.kindLabels[e.key]}', style: display(16)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 6, runSpacing: 6, children: [
                    for (final i in e.value)
                      InputChip(
                        avatar: i.swatch == null
                            ? null
                            : CircleAvatar(backgroundColor: i.swatch, radius: 8),
                        label: Text(i.name),
                        onDeleted: () => wardrobe.remove(i),
                        deleteButtonTooltipMessage: t.remove,
                      ),
                  ]),
                ],
              ],
            ],
          );
        },
      ),
    );
  }
}
