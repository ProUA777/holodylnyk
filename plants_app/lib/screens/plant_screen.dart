import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../garden.dart';
import '../l10n.dart';
import '../main.dart';
import '../theme.dart';
import '../widgets/plant_report.dart';
import 'photos_screen.dart';

/// Збережена рослина: полив (кнопка + як часто), звіт, питання, перевірка по новому фото, видалення.
class PlantScreen extends StatelessWidget {
  const PlantScreen({super.key, required this.plantId});
  final String plantId;

  @override
  Widget build(BuildContext context) {
    final garden = AppScope.of(context).garden;
    return ListenableBuilder(
      listenable: garden,
      builder: (context, _) {
        final matches = garden.items.where((p) => p.id == plantId);
        if (matches.isEmpty) return const Scaffold(body: SizedBox.shrink()); // щойно видалили
        return _PlantView(plant: matches.first);
      },
    );
  }
}

class _PlantView extends StatelessWidget {
  const _PlantView({required this.plant});
  final MyPlant plant;

  Future<void> _rename(BuildContext context) async {
    final t = L10n.of(context);
    final garden = AppScope.of(context).garden;
    final ctrl = TextEditingController(text: plant.nickname);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.rename),
        content: TextField(controller: ctrl, autofocus: true, maxLength: 40),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: Text(t.save)),
        ],
      ),
    );
    ctrl.dispose();
    if (name != null) await garden.rename(plant, name);
  }

  Future<void> _delete(BuildContext context) async {
    final t = L10n.of(context);
    final garden = AppScope.of(context).garden;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(t.deleteQ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(t.delete)),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      Navigator.of(context).pop();
      await garden.remove(plant);
    }
  }

  Future<void> _recheck(BuildContext context) async {
    try {
      final x = await ImagePicker().pickImage(source: ImageSource.camera, maxWidth: 1600, maxHeight: 1600, imageQuality: 85);
      if (x == null || !context.mounted) return;
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => PhotosScreen(initial: [File(x.path)])));
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(L10n.of(context).noCamera)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final t = L10n.of(context);
    final extra = Extra.of(context);
    final now = DateTime.now();
    final days = plant.daysToWater(now);
    final thumb = plant.thumbPath != null && File(plant.thumbPath!).existsSync() ? File(plant.thumbPath!) : null;

    return Scaffold(
      appBar: AppBar(actions: [
        IconButton(tooltip: t.rename, onPressed: () => _rename(context), icon: const Icon(Icons.edit_outlined)),
        IconButton(tooltip: t.delete, onPressed: () => _delete(context), icon: const Icon(Icons.delete_outline)),
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
          Text(plant.nickname, style: display(28)),
          if (plant.nickname != plant.result.name) ...[
            const SizedBox(height: 2),
            Text(plant.result.name, style: TextStyle(color: extra.muted, fontWeight: FontWeight.w700)),
          ],
          const SizedBox(height: 16),
          // Полив: коли наступний, кнопка, як часто
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: extra.waterBg, borderRadius: BorderRadius.circular(20)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Text('💧', style: TextStyle(fontSize: 26)),
                const SizedBox(width: 10),
                Expanded(child: Text(t.waterIn(days), style: display(16))),
              ]),
              if (plant.lastWatered != null) ...[
                const SizedBox(height: 4),
                Text('✓ ${t.dateLabel(plant.lastWatered!)}', style: TextStyle(color: extra.muted, fontWeight: FontWeight.w700)),
              ],
              const SizedBox(height: 12),
              Row(children: [
                Text(t.changeEvery, style: const TextStyle(fontWeight: FontWeight.w700)),
                const Spacer(),
                IconButton.outlined(
                  onPressed: plant.waterEveryDays > 1 ? () => scope.garden.setEvery(plant, plant.waterEveryDays - 1) : null,
                  icon: const Icon(Icons.remove),
                ),
                SizedBox(
                  width: 92,
                  child: Text(t.everyDays(plant.waterEveryDays), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
                IconButton.outlined(
                  onPressed: plant.waterEveryDays < 60 ? () => scope.garden.setEvery(plant, plant.waterEveryDays + 1) : null,
                  icon: const Icon(Icons.add),
                ),
              ]),
              const SizedBox(height: 8),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: extra.water, foregroundColor: Colors.white),
                onPressed: () async {
                  await scope.garden.water(plant);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.wateredToast)));
                  }
                },
                icon: const Icon(Icons.water_drop),
                label: Text(t.water),
              ),
            ]),
          ),
          PlantReport(plant: plant.result),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => showAskSheet(context, plant.result),
            icon: const Icon(Icons.chat_bubble_outline),
            label: Text(t.askTitle),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _recheck(context),
            icon: const Icon(Icons.photo_camera_outlined),
            label: Text(t.recheck),
          ),
        ],
      ),
    );
  }
}
