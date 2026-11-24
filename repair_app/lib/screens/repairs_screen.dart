import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../api.dart';
import '../l10n.dart';
import '../main.dart';
import '../models.dart';
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
              for (final (r, m, d) in repairs.dueService())
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
                    decoration: BoxDecoration(color: extra.amberBg, borderRadius: BorderRadius.circular(18)),
                    child: Row(children: [
                      const Text('🗓', style: TextStyle(fontSize: 26)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('${t.serviceDue} · ${t.dueIn(d)}', style: TextStyle(color: extra.muted, fontSize: 12, fontWeight: FontWeight.w800)),
                          Text(m.task, style: const TextStyle(fontWeight: FontWeight.w800)),
                          Text(r.result.thing, style: TextStyle(color: extra.muted, fontSize: 13)),
                        ]),
                      ),
                      TextButton(onPressed: () => repairs.markServiced(r, m), child: Text(t.serviceDoneBtn)),
                    ]),
                  ),
                ),
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
              RepairReport(
                repair: r,
                bought: repair.bought,
                onToggleBought: (p) => store.toggleBought(repair, p),
                maintenance: r.maintenance.isEmpty ? null : _Maintenance(repair: repair),
              ),
              const SizedBox(height: 22),
              _AfterCheckCard(repair: repair),
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

/// Обслуговування збереженої речі: коли наступного разу, кнопка «Зробив».
class _Maintenance extends StatelessWidget {
  const _Maintenance({required this.repair});
  final MyRepair repair;

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final extra = Extra.of(context);
    final store = AppScope.of(context).repairs;
    final now = DateTime.now();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.only(top: 26, bottom: 10), child: Text('🗓 ${t.maintTitle}', style: display(19))),
      for (final m in repair.result.maintenance)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(m.task, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(
                  repair.done ? '${t.everyDays(m.everyDays)} · ${t.dueIn(repair.daysToService(m, now))}' : t.everyDays(m.everyDays),
                  style: TextStyle(
                    color: repair.done && repair.daysToService(m, now) <= 0 ? AppColors.amber : extra.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ]),
            ),
            if (repair.done) TextButton(onPressed: () => store.markServiced(repair, m), child: Text(t.serviceDoneBtn)),
          ]),
        ),
    ]);
  }
}

/// «Перевірити фото після»: нове фото місця ремонту → AI оцінює, чи все зроблено правильно.
class _AfterCheckCard extends StatefulWidget {
  const _AfterCheckCard({required this.repair});
  final MyRepair repair;

  @override
  State<_AfterCheckCard> createState() => _AfterCheckCardState();
}

class _AfterCheckCardState extends State<_AfterCheckCard> {
  bool _busy = false;
  AfterCheck? _result;
  String? _error;

  Future<void> _check(ImageSource source) async {
    final scope = AppScope.of(context);
    final t = L10n.of(context);
    final XFile? x;
    try {
      x = await ImagePicker().pickImage(source: source, maxWidth: 1600, maxHeight: 1600, imageQuality: 85);
    } catch (_) {
      if (mounted) setState(() => _error = t.noCamera);
      return;
    }
    if (x == null || !mounted) return;
    final r = widget.repair.result;
    setState(() {
      _busy = true;
      _error = null;
      _result = null;
    });
    try {
      final params = scope.prefs.value.verify(r.thing, r.causes.isEmpty ? null : r.causes.first.title);
      final res = await scope.api.analyze([File(x.path)], params);
      final after = res.after ?? const AfterCheck();
      await scope.repairs.setAfter(widget.repair, after.ok);
      if (mounted) setState(() => _result = after);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = t.error(e));
    } catch (_) {
      if (mounted) setState(() => _error = t.errGeneric);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final extra = Extra.of(context);
    final res = _result;
    final prior = widget.repair.afterOk;
    final ok = res?.ok ?? prior;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ok == true ? (dark ? AppColors.greenBgDark : AppColors.greenBg) : (ok == false ? extra.amberBg : extra.leaf),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('📸 ${t.afterTitle}', style: display(18)),
        const SizedBox(height: 6),
        if (_busy)
          Row(children: [
            const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5)),
            const SizedBox(width: 12),
            Text(t.afterLoading, style: const TextStyle(fontWeight: FontWeight.w700)),
          ])
        else if (res != null) ...[
          Text(res.ok ? t.afterOk : t.afterBad, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          for (final i in res.issues) Padding(padding: const EdgeInsets.only(top: 4), child: Text('⚠️ $i')),
          if (res.advice.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text(res.advice, style: const TextStyle(height: 1.35))),
        ] else if (prior != null)
          Text(prior ? t.afterOk : t.afterBad, style: const TextStyle(fontWeight: FontWeight.w800))
        else
          Text(t.afterCheckHint, style: TextStyle(color: extra.muted, height: 1.35)),
        if (_error != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(_error!, style: const TextStyle(color: AppColors.red))),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: _busy ? null : () => _check(ImageSource.camera),
              icon: const Icon(Icons.photo_camera_outlined),
              label: Text(t.afterCheck),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.outlined(
            tooltip: t.gallery,
            onPressed: _busy ? null : () => _check(ImageSource.gallery),
            icon: const Icon(Icons.photo_library_outlined),
          ),
        ]),
      ]),
    );
  }
}
