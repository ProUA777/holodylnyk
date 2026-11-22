import 'dart:io';

import 'package:flutter/material.dart';

import '../garden.dart';
import '../l10n.dart';
import '../main.dart';
import '../theme.dart';
import '../widgets/plant_report.dart';
import 'plant_screen.dart';

/// «Мої рослини»: спершу ті, кого пора полити; кнопка «Полити» прямо в списку.
class GardenScreen extends StatelessWidget {
  const GardenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final garden = AppScope.of(context).garden;
    final t = L10n.of(context);
    final extra = Extra.of(context);
    return SafeArea(
      child: ListenableBuilder(
        listenable: garden,
        builder: (context, _) {
          final now = DateTime.now();
          final items = garden.sorted(now);
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              Text(t.gardenTitle, style: display(30)),
              if (items.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(t.plantsN(items.length), style: TextStyle(color: extra.muted, fontWeight: FontWeight.w700)),
              ],
              const SizedBox(height: 18),
              if (items.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: extra.leaf, borderRadius: BorderRadius.circular(24)),
                  child: Column(children: [
                    const Text('🪴', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 10),
                    Text(t.gardenEmpty, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600, height: 1.4)),
                  ]),
                )
              else
                for (final p in items) Padding(padding: const EdgeInsets.only(bottom: 10), child: _PlantTile(plant: p, now: now)),
            ],
          );
        },
      ),
    );
  }
}

class _PlantTile extends StatelessWidget {
  const _PlantTile({required this.plant, required this.now});
  final MyPlant plant;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final t = L10n.of(context);
    final extra = Extra.of(context);
    final theme = Theme.of(context);
    final days = plant.daysToWater(now);
    final thirsty = days <= 0;
    final thumb = plant.thumbPath != null && File(plant.thumbPath!).existsSync() ? File(plant.thumbPath!) : null;
    return Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: thirsty ? extra.water : theme.colorScheme.outline, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PlantScreen(plantId: plant.id))),
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
                    : Container(color: extra.leaf, child: const Center(child: Text('🌿', style: TextStyle(fontSize: 32)))),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(plant.nickname, style: display(15), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(t.waterIn(days),
                    style: TextStyle(color: thirsty ? extra.water : extra.muted, fontWeight: FontWeight.w800, fontSize: 13)),
                const SizedBox(height: 6),
                HealthBadge(health: plant.result.health),
              ]),
            ),
            if (thirsty)
              IconButton.filled(
                style: IconButton.styleFrom(backgroundColor: extra.water, foregroundColor: Colors.white),
                tooltip: t.water,
                onPressed: () async {
                  await scope.garden.water(plant);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.wateredToast)));
                  }
                },
                icon: const Icon(Icons.water_drop),
              ),
          ]),
        ),
      ),
    );
  }
}
