import 'package:flutter/material.dart';

import '../app.dart';
import '../data/catalog.dart';
import '../i18n.dart';
import '../render/iso.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'detail.dart';
import 'shell.dart';

class MineScreen extends StatelessWidget {
  const MineScreen({super.key});

  Future<void> _confirmClear(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        content: Text(t('clearQ'), style: body(16, weight: 700)),
        actions: [
          TextButton(onPressed: () => Navigator.of(d).pop(false), child: Text(t('cancel'))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Brand.red),
            onPressed: () => Navigator.of(d).pop(true),
            child: Text(t('clearYes')),
          ),
        ],
      ),
    );
    if (ok == true) app.clearBuilds();
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return SafeArea(
      bottom: false,
      child: ListenableBuilder(
        listenable: app,
        builder: (context, _) {
          final builds = app.builds;
          final badges = [
            ('🧱', 'b1', 'b1d', builds.isNotEmpty),
            ('🔥', 'b3', 'b3d', builds.any((b) => b.diff == 'hard')),
            ('🏆', 'b2', 'b2d', builds.length >= 10),
            ('🚀', 'b4', 'b4d', app.countIn('space') >= 2),
            ('🐾', 'b5', 'b5d', app.countIn('animals') >= 3),
            ('🏗️', 'b6', 'b6d', app.countIn('buildings') >= 2),
            ('🍰', 'b7', 'b7d', app.countIn('food') >= 2),
            ('🎄', 'b8', 'b8d', app.countIn('holidays') >= 2),
            ('💎', 'b9', 'b9d', builds.length >= 25),
            ('🧠', 'b10', 'b10d', builds.any((b) => b.diff == 'expert')),
            ('🏛️', 'b11', 'b11d', app.countIn('landmarks') >= 3),
            ('👑', 'b12', 'b12d', catalog.categories.keys.every((c) => app.countIn(c) > 0)),
          ];
          return ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: [
            const TopBar(),
            const SizedBox(height: 4),
            Text(t('mineH'), style: display(30)),
            const SizedBox(height: 14),
            Row(children: [
              for (final (i, (v, k, c)) in [(builds.length, 'built', Brand.red), (app.minutes, 'minutes', Brand.blue), (app.stars, 'stars', Brand.amber)].indexed) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: SurfaceCard(
                    radius: 18,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                    child: Column(children: [
                      Text('$v', style: display(30, color: c, height: 1.1)),
                      Text(t(k).toUpperCase(), style: body(11.5, weight: 800, color: p.muted)),
                    ]),
                  ),
                ),
              ],
            ]),
            const SizedBox(height: 20),
            Text(t('badges'), style: display(21)),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: .95,
              children: [
                for (final (ic, n, d, ok) in badges)
                  Opacity(
                    opacity: ok ? 1 : .42,
                    child: SurfaceCard(
                      radius: 18,
                      padding: const EdgeInsets.all(8),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        ok ? Text(ic, style: const TextStyle(fontSize: 30)) : ColorFiltered(colorFilter: const ColorFilter.matrix(_grey), child: Text(ic, style: const TextStyle(fontSize: 30))),
                        const SizedBox(height: 4),
                        Text(t(n), textAlign: TextAlign.center, maxLines: 2, style: body(12.5, weight: 800, height: 1.15)),
                        Text(t(d), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: body(11, color: p.muted)),
                      ]),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Text(t('history'), style: display(21)),
            const SizedBox(height: 10),
            if (builds.isEmpty)
              SurfaceCard(
                child: Column(children: [
                  const SizedBox(height: 8),
                  const Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                    BrickShape(color: Brand.yellow, studs: 2, unit: 18),
                    SizedBox(width: 4),
                    BrickShape(color: Brand.blue, studs: 3, unit: 18),
                  ]),
                  const SizedBox(height: 10),
                  Text(t('emptyMine'), textAlign: TextAlign.center, style: body(15, color: p.muted)),
                  const SizedBox(height: 10),
                  OutlinedButton(onPressed: () => app.tab.value = 1, child: Text(t('pickModel'))),
                ]),
              )
            else ...[
              CardGrid(children: [
                for (final b in builds)
                  Builder(builder: (context) {
                    final m = catalog.byId[b.id];
                    return IdeaCard(
                      title: m != null ? pick(m.title, app.lang) : b.title,
                      emoji: b.emoji,
                      diff: b.diff,
                      bricks: m != null ? flatten(m.steps) : const [],
                      onTap: m != null ? () => openModel(context, m) : () {},
                    );
                  }),
              ]),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => _confirmClear(context),
                  child: Text(t('clear'), style: body(14, weight: 700, color: p.muted).copyWith(decoration: TextDecoration.underline)),
                ),
              ),
            ],
          ]);
        },
      ),
    );
  }
}

const _grey = <double>[
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0, 0, 0, 1, 0,
];
