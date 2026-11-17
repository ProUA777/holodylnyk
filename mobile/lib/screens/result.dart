import 'dart:io';

import 'package:flutter/material.dart';

import '../app.dart';
import '../data/api.dart';
import '../data/catalog.dart';
import '../i18n.dart';
import '../render/iso.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'detail.dart';

/// Result for an example pile or for the user's own photo.
class ResultScreen extends StatelessWidget {
  final Pile? pile;
  final ScanResult? scan;
  final File? photo;

  const ResultScreen.pile(Pile this.pile, {super.key})
      : scan = null,
        photo = null;
  const ResultScreen.scan(ScanResult this.scan, File this.photo, {super.key}) : pile = null;

  /// AI-picked catalog models, repainted in the colours of the photo.
  List<(BrickModel, String, List<BuildStep>)> get _matches {
    final s = scan;
    if (s == null) return const [];
    final palette = [for (final c in s.colors) if (c.hex.length == 7) parseHex(c.hex)];
    return [
      for (final (id, why) in s.matches)
        if (catalog.byId[id] != null) (catalog.byId[id]!, why, recolorSteps(catalog.byId[id]!.steps, palette)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final lang = app.lang;
    final readable = scan?.readable ?? true;
    final total = pile?.total ?? scan?.total;
    final colors = pile != null
        ? [for (final (c, n) in pile!.colors) (catalog.colorName(c, lang), catalog.colorOf(c), n as int?)]
        : [for (final c in scan!.colors) (c.name, parseHex(c.hex), c.count)];
    final notable = pile != null ? (pile!.notable[lang] ?? pile!.notable['en'] ?? const []) : scan!.notable;
    final sum = colors.fold<int>(0, (s, c) => s + (c.$3 ?? 1));

    return Scaffold(
      appBar: AppBar(
        title: Text(pile != null ? pick(pile!.name, lang) : t('ideasFound')),
        actions: [
          if (scan != null)
            ReportButton(content: [for (final i in scan!.ideas) '${i.title}: ${i.desc}'].join('\n')),
        ],
      ),
      body: Baseplate(
        child: ListenableBuilder(
          listenable: app,
          builder: (context, _) => ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 28), children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: Stack(fit: StackFit.expand, children: [
                  if (photo != null)
                    Image.file(photo!, fit: BoxFit.cover)
                  else
                    ColoredBox(
                      color: Color.alphaBlend(colors.first.$2.withValues(alpha: .12), p.card2),
                      child: PileArt(colors: [for (final c in colors) c.$2], unit: 22),
                    ),
                  if (pile != null)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Brand.yellow, borderRadius: BorderRadius.circular(99)),
                        child: Text(t('example').toUpperCase(), style: body(12, weight: 800, color: const Color(0xFF1D2433))),
                      ),
                    ),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            if (!readable)
              SurfaceCard(
                color: Color.alphaBlend(Brand.amber.withValues(alpha: .14), p.card),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(t('unreadable'), style: display(21)),
                  const SizedBox(height: 6),
                  Text(scan?.retakeHint ?? t('tip1'), style: body(15, height: 1.4)),
                ]),
              )
            else ...[
              SurfaceCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Expanded(child: Text(t('inventory'), style: display(19))),
                    Text('${total ?? '?'}', style: display(42, weight: 700, color: Brand.red, height: 1)),
                    const SizedBox(width: 4),
                    Padding(padding: const EdgeInsets.only(bottom: 4), child: Text(total == null ? t('pieces') : noun(total, 'pieces'), style: body(13, weight: 700, color: p.muted))),
                  ]),
                  if (colors.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: SizedBox(
                        height: 12,
                        child: Row(children: [
                          for (final (i, c) in colors.indexed) ...[
                            if (i > 0) const SizedBox(width: 2),
                            Expanded(flex: ((c.$3 ?? 1) * 1000 / (sum == 0 ? 1 : sum)).round().clamp(1, 1000), child: ColoredBox(color: c.$2)),
                          ],
                        ]),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(spacing: 14, runSpacing: 12, children: [
                      for (final c in colors)
                        Column(mainAxisSize: MainAxisSize.min, children: [
                          BrickShape(color: c.$2, studs: 2, unit: 16),
                          const SizedBox(height: 3),
                          Text(c.$3 == null ? c.$1 : '${c.$1} · ${c.$3}', style: body(12, weight: 700, color: p.muted)),
                        ]),
                    ]),
                  ],
                  if (notable.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(t('special'), style: body(13, weight: 800, color: p.muted)),
                    const SizedBox(height: 6),
                    Wrap(spacing: 6, runSpacing: 6, children: [for (final n in notable) Tag(n, highlight: true)]),
                  ],
                ]),
              ),
              if (scan != null && (scan!.source == 'instructions' || scan!.source == 'built')) ...[
                const SizedBox(height: 12),
                SurfaceCard(
                  color: Color.alphaBlend(Brand.blue.withValues(alpha: .10), p.card),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('💡', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        t(scan!.source == 'instructions' ? 'fromInstr' : 'fromBuilt').replaceAll('{d}', scan!.depicted == null ? '' : ' («${scan!.depicted}»)'),
                        style: body(14.5, weight: 600, height: 1.4),
                      ),
                    ),
                  ]),
                ),
              ],
              if (scan != null && _matches.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(t('inYourColors'), style: display(22)),
                const SizedBox(height: 10),
                CardGrid(children: [
                  for (final (m, why, steps) in _matches)
                    IdeaCard(
                      title: pick(m.title, lang),
                      emoji: m.emoji,
                      diff: m.diff,
                      minutes: m.minutes,
                      parts: m.parts,
                      bricks: flatten(steps),
                      built: app.isBuilt(m.id),
                      onTap: () => openModel(context, m, steps: steps, note: why),
                    ),
                ]),
              ],
              if (pile != null || scan!.ideas.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(scan != null ? t('moreIdeas') : t('ideasFound'), style: display(22)),
              const SizedBox(height: 10),
              CardGrid(children: [
                if (pile != null)
                  for (final id in pile!.ideas)
                    if (catalog.byId[id] != null) IdeaCard.model(catalog.byId[id]!, onTap: () => openModel(context, catalog.byId[id]!))
                    else const SizedBox()
                else
                  for (final idea in scan!.ideas)
                    IdeaCard(
                      title: idea.title,
                      emoji: idea.emoji,
                      diff: idea.diff,
                      minutes: idea.minutes,
                      bricks: flatten(idea.steps),
                      built: app.isBuilt(idea.id),
                      onTap: () => openAiIdea(context, idea),
                    ),
              ]),
              ],
            ],
            const SizedBox(height: 20),
            if (scan != null)
              Center(
                child: TextButton.icon(
                  onPressed: () => reportAiAnswer(context, [for (final i in scan!.ideas) '${i.title}: ${i.desc}'].join('\n')),
                  icon: const Icon(Icons.outlined_flag_rounded, size: 18),
                  label: Text(t('report'), style: body(14, weight: 700, color: p.muted)),
                ),
              ),
            if (photo != null)
              BrickButton(label: t('again'), icon: Icons.photo_camera_rounded, color: Brand.blue, onTap: () => Navigator.of(context).pop()),
          ]),
        ),
      ),
    );
  }
}
