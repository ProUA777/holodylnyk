import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app.dart';
import '../data/api.dart';
import '../data/catalog.dart';
import '../i18n.dart';
import '../render/iso.dart';
import '../theme.dart';

/// Flat side-view brick with studs on top (decor, swatches, parts).
class BrickShape extends StatelessWidget {
  final Color color;
  final int studs;
  final double unit;
  final Widget? child;
  final double? width;

  const BrickShape({super.key, required this.color, this.studs = 2, this.unit = 18, this.child, this.width});

  @override
  Widget build(BuildContext context) {
    final w = width ?? studs * unit;
    final cell = w / studs;
    final h = unit * 1.1, studH = unit * .3;
    final light = shade(color, .2);
    return SizedBox(
      width: w,
      height: h + studH,
      child: Stack(children: [
        for (var i = 0; i < studs; i++)
          Positioned(
            left: i * cell + cell * .2,
            top: 0,
            child: Container(
              width: cell * .6,
              height: studH + 3,
              decoration: BoxDecoration(color: light, borderRadius: BorderRadius.vertical(top: Radius.circular(unit * .12))),
            ),
          ),
        Positioned.fill(
          top: studH,
          child: Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(unit * .16),
              border: Border(bottom: BorderSide(color: shade(color, -.22), width: unit * .18)),
            ),
            alignment: Alignment.center,
            child: child,
          ),
        ),
      ]),
    );
  }
}

/// Big call-to-action shaped like a 2×8 brick.
class BrickButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const BrickButton({super.key, required this.label, required this.icon, this.color = Brand.red, this.onTap});

  @override
  State<BrickButton> createState() => _BrickButtonState();
}

class _BrickButtonState extends State<BrickButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.onTap,
        child: AnimatedSlide(
          offset: Offset(0, _down ? .04 : 0),
          duration: const Duration(milliseconds: 90),
          child: Opacity(
            opacity: widget.onTap == null ? .5 : 1,
            child: LayoutBuilder(
              builder: (context, c) => BrickShape(
                color: widget.color,
                studs: 8,
                unit: 52,
                width: c.maxWidth,
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(widget.icon, color: Colors.white),
                  const SizedBox(width: 10),
                  Flexible(child: Text(widget.label, overflow: TextOverflow.ellipsis, style: display(19, color: Colors.white))),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ●●○ Легко · 10 хв
class DiffMeta extends StatelessWidget {
  final String diff;
  final int? minutes;
  const DiffMeta({super.key, required this.diff, this.minutes});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final c = Brand.difficulty(diff), n = difficultyStars(diff);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      for (var i = 0; i < 4; i++)
        Container(
          width: 9,
          height: 9,
          margin: const EdgeInsets.only(right: 3),
          decoration: BoxDecoration(shape: BoxShape.circle, color: i < n ? c : c.withValues(alpha: .2)),
        ),
      const SizedBox(width: 3),
      Flexible(
        child: Text(
          minutes == null ? t(diff) : '${t(diff)} · $minutes ${t('min')}',
          overflow: TextOverflow.ellipsis,
          style: body(12.5, weight: 700, color: p.muted),
        ),
      ),
    ]);
  }
}

/// Grouped parts list: "2× 2×4 червона" with a swatch.
List<Widget> partChips(BuildContext context, List<Brick> bricks) {
  final groups = <String, (Brick, int)>{};
  for (final b in bricks) {
    final s = [b.w, b.d]..sort();
    final k = '${b.c}|${s[0]}×${s[1]}|${b.isPlate}';
    final cur = groups[k];
    groups[k] = (b, (cur?.$2 ?? 0) + 1);
  }
  final p = Palette.of(context);
  return [
    for (final e in groups.entries)
      Builder(builder: (context) {
        final b = e.value.$1, n = e.value.$2;
        final s = [b.w, b.d]..sort();
        final name = catalog.colorName(b.c, app.lang, plate: b.isPlate);
        final label = '$n× ${s[0]}×${s[1]}${b.isPlate ? ' ${t('plate')}' : ''}${name.isEmpty ? '' : ' $name'}';
        return Container(
          padding: const EdgeInsets.fromLTRB(6, 4, 10, 4),
          decoration: BoxDecoration(color: p.chip, borderRadius: BorderRadius.circular(10)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            BrickShape(color: catalog.colorOf(b.c), studs: math.min(s[1], 4), unit: 11),
            const SizedBox(width: 8),
            Flexible(child: Text(label, style: body(13, weight: 700))),
          ]),
        );
      }),
  ];
}

class Tag extends StatelessWidget {
  final String text;
  final bool highlight;
  const Tag(this.text, {super.key, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: highlight ? Brand.yellow.withValues(alpha: .32) : p.chip,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: body(13, weight: 700)),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? action;
  final VoidCallback? onAction;
  const SectionTitle(this.title, {super.key, this.subtitle, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: display(21)),
          if (subtitle != null) Text(subtitle!, style: body(14, color: p.muted)),
        ]),
      ),
      if (action != null)
        TextButton(onPressed: onAction, child: Text('$action →', style: body(14, weight: 800, color: Brand.blue))),
    ]);
  }
}

/// Card for a catalog model or an AI idea.
class IdeaCard extends StatelessWidget {
  final String title, emoji, diff;
  final int? minutes, parts;
  final List<Placed> bricks;
  final bool built, favorite;
  final (int, int)? progress; // (current step 1-based, total) for models in progress
  final VoidCallback onTap;

  const IdeaCard({
    super.key,
    required this.title,
    required this.emoji,
    required this.diff,
    required this.bricks,
    required this.onTap,
    this.minutes,
    this.parts,
    this.built = false,
    this.favorite = false,
    this.progress,
  });

  factory IdeaCard.model(BrickModel m, {required VoidCallback onTap}) => IdeaCard(
        title: pick(m.title, app.lang),
        emoji: m.emoji,
        diff: m.diff,
        minutes: m.minutes,
        parts: m.parts,
        bricks: placedOf(m),
        built: app.isBuilt(m.id),
        favorite: app.isFavorite(m.id),
        progress: !app.isBuilt(m.id) && app.progressOf(m.id) > 0 ? (app.progressOf(m.id) + 1, m.steps.length) : null,
        onTap: onTap,
      );

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return SurfaceCard(
      padding: EdgeInsets.zero,
      radius: 20,
      onTap: onTap,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          height: 116,
          decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [p.card2, p.card])),
          child: Stack(children: [
            Positioned.fill(
              child: bricks.isEmpty
                  ? Center(child: Text(emoji, style: const TextStyle(fontSize: 52)))
                  : ModelPicture(bricks: bricks),
            ),
            if (progress != null)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: Brand.blue, borderRadius: BorderRadius.circular(99)),
                  child: Text('▶ ${progress!.$1}/${progress!.$2}', style: body(11, weight: 800, color: Colors.white)),
                ),
              ),
            if (favorite)
              const Positioned(bottom: 6, right: 8, child: Icon(Icons.favorite_rounded, size: 18, color: Brand.red)),
            if (built)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: Brand.green, borderRadius: BorderRadius.circular(99)),
                  child: Text('✓ ${t('builtFlag')}', style: body(11, weight: 800, color: Colors.white)),
                ),
              ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$emoji $title', maxLines: 2, overflow: TextOverflow.ellipsis, style: display(16, height: 1.2)),
            const SizedBox(height: 4),
            DiffMeta(diff: diff, minutes: minutes),
            if (parts != null) ...[
              const SizedBox(height: 2),
              Text('🧱 ${count(parts!, 'pieces')}', style: body(12.5, weight: 700, color: p.muted)),
            ],
          ]),
        ),
      ]),
    );
  }
}

/// Two-column grid that sizes rows to their content.
class CardGrid extends StatelessWidget {
  final List<Widget> children;
  const CardGrid({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += 2) {
      rows.add(IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(child: children[i]),
          const SizedBox(width: 12),
          Expanded(child: i + 1 < children.length ? children[i + 1] : const SizedBox()),
        ]),
      ));
      if (i + 2 < children.length) rows.add(const SizedBox(height: 12));
    }
    return Column(children: rows);
  }
}

/// A messy pile of flat bricks in the pile's colours.
class PileArt extends StatelessWidget {
  final List<Color> colors;
  final double unit;
  const PileArt({super.key, required this.colors, this.unit = 15});

  @override
  Widget build(BuildContext context) {
    const a = [2, 4, 3, 2, 1, 4], b = [1, 2, 4, 3, 2, 2], c = [2, 1, 2, 4, 3, 1];
    return ClipRect(
      child: Center(
        child: Transform.rotate(
          angle: -.1,
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 2,
            children: [
              for (final (i, col) in colors.indexed) ...[
                BrickShape(color: col, studs: a[i % 6], unit: unit),
                BrickShape(color: col, studs: b[i % 6], unit: unit),
                if (unit > 18) BrickShape(color: col, studs: c[i % 6], unit: unit),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Falling mini-bricks, shown over the screen after a build is finished.
class ConfettiOverlay extends StatefulWidget {
  const ConfettiOverlay({super.key});

  static void show(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return;
    final overlay = Overlay.of(context);
    late final OverlayEntry entry;
    entry = OverlayEntry(builder: (_) => const IgnorePointer(child: ConfettiOverlay()));
    overlay.insert(entry);
    Future.delayed(const Duration(milliseconds: 2000), entry.remove);
  }

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1900))..forward();
  final _rnd = math.Random();
  late final List<_Bit> _bits = List.generate(
    70,
    (_) => _Bit(
      vx: (_rnd.nextDouble() - .5) * 11,
      vy: -_rnd.nextDouble() * 13 - 5,
      rot: _rnd.nextDouble() * 6,
      vr: (_rnd.nextDouble() - .5) * .3,
      w: 10 + _rnd.nextDouble() * 12,
      color: const [Brand.red, Brand.blue, Brand.yellow, Brand.green, Color(0xFFF28C28), Color(0xFFE86FA8)][_rnd.nextInt(6)],
    ),
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(size: Size.infinite, painter: _ConfettiPainter(_bits, _c.value * 110)),
      );
}

class _Bit {
  final double vx, vy, rot, vr, w;
  final Color color;
  _Bit({required this.vx, required this.vy, required this.rot, required this.vr, required this.w, required this.color});
}

class _ConfettiPainter extends CustomPainter {
  final List<_Bit> bits;
  final double t; // frames
  _ConfettiPainter(this.bits, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final b in bits) {
      final x = size.width / 2 + b.vx * t, y = size.height * .45 + b.vy * t + .225 * t * t;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(b.rot + b.vr * t);
      paint.color = b.color;
      canvas.drawRect(Rect.fromLTWH(-b.w / 2, -4, b.w, 8), paint);
      canvas.drawRect(Rect.fromLTWH(-b.w / 2 + 2, -7, 4, 3), paint);
      canvas.drawRect(Rect.fromLTWH(b.w / 2 - 6, -7, 4, 3), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}


/// Bottom sheet that sends a report about an AI answer.
Future<void> reportAiAnswer(BuildContext context, String content) async {
  final reason = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (sheet) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 8), child: Text(t('reportTitle'), style: display(20))),
        for (final (k, icon) in [('rOffensive', Icons.block_rounded), ('rWrong', Icons.help_outline_rounded), ('rOther', Icons.more_horiz_rounded)])
          ListTile(
            leading: Icon(icon),
            title: Text(t(k), style: body(16, weight: 700)),
            onTap: () => Navigator.of(sheet).pop(k),
          ),
        const SizedBox(height: 8),
      ]),
    ),
  );
  if (reason == null) return;
  final ok = await Api.report(reason: reason, content: content, lang: app.lang);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t(ok ? 'reportThanks' : 'reportFail'))));
}

/// Small flag button for AI answers.
class ReportButton extends StatelessWidget {
  final String content;
  const ReportButton({super.key, required this.content});

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: t('report'),
        icon: const Icon(Icons.outlined_flag_rounded),
        onPressed: () => reportAiAnswer(context, content),
      );
}

/// Translucent round arrow on the side of the 3D stage.
class SideArrow extends StatelessWidget {
  final IconData icon;
  final bool visible, active;
  final Color? color;
  const SideArrow({super.key, required this.icon, required this.visible, required this.active, this.color});

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: !visible ? 0 : (active ? 1 : .55),
        duration: const Duration(milliseconds: 160),
        child: AnimatedScale(
          scale: active ? 1.15 : 1,
          duration: const Duration(milliseconds: 160),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: p.card.withValues(alpha: .85), shape: BoxShape.circle, boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: .12), blurRadius: 8, offset: const Offset(0, 2)),
            ]),
            child: Icon(icon, color: color ?? p.ink, size: 24),
          ),
        ),
      ),
    );
  }
}
