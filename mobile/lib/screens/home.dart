import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../app.dart';
import '../data/catalog.dart';
import '../i18n.dart';
import '../render/iso.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'detail.dart';
import 'result.dart';
import 'scan.dart';
import 'shell.dart';

/// Diorama for the hero: house, tree, car, flower and cactus on one baseplate.
List<Placed> heroScene() {
  final out = <Placed>[const Placed(Brick(0, 0, 0, 17, 12, 'G', .4), 0)];
  void place(String id, int dx, int dy, double dz, int skip) {
    final m = catalog.byId[id];
    if (m == null) return;
    for (final s in m.steps.skip(skip)) {
      for (final b in s.bricks) {
        out.add(Placed(Brick(b.x + dx, b.y + dy, b.z + dz, b.w, b.d, b.c, b.h), 0));
      }
    }
  }

  place('house', 1, 1, 0, 1);
  place('tree', 8, 1, 0, 1);
  place('car', 10, 7, .4, 0);
  place('flower', 3, 7, 0, 1);
  place('cactus', 13, 2, 0, 1);
  return out;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final List<Placed> _hero = heroScene();
  static const _popular = ['dragon', 'firetruck', 'castle', 'unicorn', 'xmastree', 'train'];

  @override
  void initState() {
    super.initState();
    _recoverLostPhoto();
  }

  /// Android may kill the app while the camera is open; pick up the photo it returns.
  Future<void> _recoverLostPhoto() async {
    try {
      final lost = await ImagePicker().retrieveLostData();
      final file = lost.file;
      if (file == null || !mounted) return;
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ScanScreen(photo: File(file.path))));
    } catch (_) {
      // Not supported on this platform — nothing to recover.
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: app, builder: (context, _) => _build(context));

  Widget _build(BuildContext context) {
    final p = Palette.of(context);
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          const TopBar(),
          const SizedBox(height: 6),
          // Hero
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color.alphaBlend(Brand.blue.withValues(alpha: .14), p.card), p.card],
              ),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .07), blurRadius: 18, offset: const Offset(0, 6))],
            ),
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(height: 200, child: ModelPicture(bricks: _hero, maxA: 26, pad: 8)),
              Text(t('appName'), style: display(36, height: 1.05)),
              const SizedBox(height: 8),
              Text(t('hint'), style: body(16, color: p.muted, height: 1.4)),
              const SizedBox(height: 24),
              BrickButton(label: t('camera'), icon: Icons.photo_camera_rounded, onTap: () => startScan(context, ImageSource.camera)),
              const SizedBox(height: 6),
              Center(
                child: TextButton.icon(
                  onPressed: () => startScan(context, ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(t('gallery'), style: body(15, weight: 800)),
                ),
              ),
              Text(t('aiNote'), style: body(12.5, color: p.muted)),
            ]),
          ),
          const SizedBox(height: 16),
          // How it works
          Row(children: [
            for (final (i, (k, c)) in [('how1', Brand.red), ('how2', Brand.blue), ('how3', Brand.green)].indexed) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: SurfaceCard(
                  padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
                  radius: 16,
                  child: Column(children: [
                    Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(9)),
                      child: Text('${i + 1}', style: display(16, color: Colors.white)),
                    ),
                    const SizedBox(height: 6),
                    Text(t(k), textAlign: TextAlign.center, style: body(13, weight: 700, color: p.muted)),
                  ]),
                ),
              ),
            ],
          ]),
          const SizedBox(height: 22),
          if (app.inProgress.any((id) => catalog.byId[id] != null && !app.isBuilt(id))) ...[
            SectionTitle(t('continue')),
            const SizedBox(height: 10),
            SizedBox(
              height: 232,
              child: ListView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                children: [
                  for (final id in app.inProgress)
                    if (catalog.byId[id] != null && !app.isBuilt(id))
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: SizedBox(
                          width: (MediaQuery.of(context).size.width - 44) / 2,
                          child: IdeaCard.model(catalog.byId[id]!, onTap: () => openModel(context, catalog.byId[id]!)),
                        ),
                      ),
                ],
              ),
            ),
            const SizedBox(height: 18),
          ],
          SectionTitle(t('piles'), subtitle: t('pilesSub')),
          const SizedBox(height: 10),
          SizedBox(
            height: 196,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: catalog.piles.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, i) => _PileCard(pile: catalog.piles[i]),
            ),
          ),
          const SizedBox(height: 18),
          SectionTitle(t('popular'), action: t('all'), onAction: () => app.tab.value = 1),
          const SizedBox(height: 10),
          CardGrid(children: [
            for (final id in _popular)
              if (catalog.byId[id] != null)
                IdeaCard.model(catalog.byId[id]!, onTap: () => openModel(context, catalog.byId[id]!)),
          ]),
          const SizedBox(height: 18),
          Center(child: Text(AppConfig.credits, style: body(11, color: p.muted))),
        ],
      ),
    );
  }
}

class _PileCard extends StatelessWidget {
  final Pile pile;
  const _PileCard({required this.pile});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final first = catalog.colorOf(pile.colors.first.$1);
    return SizedBox(
      width: MediaQuery.of(context).size.width * .68,
      child: SurfaceCard(
        padding: EdgeInsets.zero,
        radius: 20,
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ResultScreen.pile(pile))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(
            height: 118,
            color: Color.alphaBlend(first.withValues(alpha: .12), p.card2),
            child: PileArt(colors: [for (final c in pile.colors) catalog.colorOf(c.$1)]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(pick(pile.name, app.lang), style: display(17)),
              Text('${count(pile.total, 'pieces')} · ${count(pile.ideas.length, 'ideasN')}', style: body(13, weight: 700, color: p.muted)),
            ]),
          ),
        ]),
      ),
    );
  }
}
