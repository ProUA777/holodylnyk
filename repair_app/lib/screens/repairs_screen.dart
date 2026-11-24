import 'dart:io';

import 'package:flutter/material.dart';

import '../l10n.dart';
import '../main.dart';
import '../repairs.dart';
import '../theme.dart';
import '../widgets/repair_report.dart';

/// «Мої ремонти»: спершу ті, що в роботі; відмітки «купив», «полагоджено».
class RepairsScreen extends StatelessWidget {
  const RepairsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repairs = AppScope.of(context).repairs;
    final t = L10n.of(context);
    final extra = Extra.of(context);
    return SafeArea(
      child: ListenableBuilder(
        listenable: repairs,
        builder: (context, _) {
          final items = repairs.sorted;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              Text(t.repairsTitle, style: display(30)),
              if (repairs.openCount > 0) ...[
                const SizedBox(height: 4),
                Text(t.inWork(repairs.openCount), style: TextStyle(color: extra.muted, fontWeight: FontWeight.w700)),
              ],
              const SizedBox(height: 18),
              if (items.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: extra.leaf, borderRadius: BorderRadius.circular(24)),
                  child: Column(children: [
                    const Text('🧰', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 10),
                    Text(t.repairsEmpty, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600, height: 1.4)),
                  ]),
                )
              else
                for (final r in items) Padding(padding: const EdgeInsets.only(bottom: 10), child: _RepairTile(repair: r)),
            ],
          );
        },
      ),
    );
  }
}

class _RepairTile extends StatelessWidget {
  const _RepairTile({required this.repair});
  final MyRepair repair;

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final extra = Extra.of(context);
    final theme = Theme.of(context);
    final r = repair.result;
    final thumb = repair.thumbPath != null && File(repair.thumbPath!).existsSync() ? File(repair.thumbPath!) : null;
    final need = r.parts.where((p) => !repair.bought.contains(p.name)).length;
    return Opacity(
      opacity: repair.done ? .6 : 1,
      child: Material(
        color: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: theme.colorScheme.outline, width: 1.5)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => RepairScreen(repairId: repair.id))),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: thumb != null
                      ? Image.file(thumb, fit: BoxFit.cover, cacheWidth: 220)
                      : Container(color: extra.leaf, child: Center(child: Text(r.emoji, style: const TextStyle(fontSize: 32)))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(r.thing, style: display(15), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(
                    repair.done
                        ? '✓ ${t.fixed}'
                        : [if (r.causes.isNotEmpty) r.causes.first.title, if (need > 0) '🛒 $need'].join(' · '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: repair.done ? AppColors.green : extra.muted, fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ]),
              ),
              const Icon(Icons.chevron_right),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Збережений ремонт: звіт, відмітки «вже є», «полагоджено», видалення.
class RepairScreen extends StatelessWidget {
  const RepairScreen({super.key, required this.repairId});
  final String repairId;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context).repairs;
    final t = L10n.of(context);
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final found = store.items.where((r) => r.id == repairId);
        if (found.isEmpty) return const Scaffold(body: SizedBox.shrink());
        final repair = found.first;
        final r = repair.result;
        final thumb = repair.thumbPath != null && File(repair.thumbPath!).existsSync() ? File(repair.thumbPath!) : null;
        return Scaffold(
          appBar: AppBar(actions: [
            IconButton(tooltip: t.askTitle, onPressed: () => showAskSheet(context, r), icon: const Icon(Icons.chat_bubble_outline)),
            IconButton(
              tooltip: t.delete,
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(content: Text(t.deleteQ), actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t.cancel)),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(t.delete)),
                  ]),
                );
                if (ok == true && context.mounted) {
                  Navigator.of(context).pop();
                  await store.remove(repair);
                }
              },
            ),
          ]),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: [
              if (thumb != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: AspectRatio(aspectRatio: 4 / 3, child: Image.file(thumb, fit: BoxFit.cover, cacheWidth: 1000)),
                ),
              const SizedBox(height: 16),
              Text('${r.emoji} ${r.thing}', style: display(26)),
              RepairReport(repair: r, bought: repair.bought, onToggleBought: (p) => store.toggleBought(repair, p)),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: repair.done
                  ? OutlinedButton.icon(
                      onPressed: () => store.setDone(repair, false),
                      icon: const Icon(Icons.undo),
                      label: Text(t.markOpen),
                    )
                  : FilledButton.icon(
                      onPressed: () => store.setDone(repair, true),
                      icon: const Icon(Icons.check_circle_outline),
                      label: Text(t.markDone),
                    ),
            ),
          ),
        );
      },
    );
  }
}
