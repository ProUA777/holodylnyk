import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app.dart';
import '../data/catalog.dart';

/// A brick with the index of the step that adds it.
class Placed {
  final Brick b;
  final int step;
  const Placed(this.b, this.step);
}

final _placedCache = Expando<List<Placed>>('placed');

/// Flattened bricks of a catalog model, computed once and reused by every card and screen.
List<Placed> placedOf(BrickModel m) => _placedCache[m] ??= flatten(m.steps);

/// Repaints a catalog model in the colours found in the user's photo: every part takes the nearest
/// photographed colour (clear parts stay clear). Keeps the design, swaps the palette.
List<BuildStep> recolorSteps(List<BuildStep> steps, List<Color> palette) {
  if (palette.isEmpty) return steps;
  double dist(Color a, Color b) {
    final r1 = a.r * 255, g1 = a.g * 255, b1 = a.b * 255, r2 = b.r * 255, g2 = b.g * 255, b2 = b.b * 255;
    final rm = (r1 + r2) / 2, dr = r1 - r2, dg = g1 - g2, db = b1 - b2;
    return (2 + rm / 256) * dr * dr + 4 * dg * dg + (2 + (255 - rm) / 256) * db * db;
  }

  String hex(Color c) => '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
  final cache = <String, String>{};
  String map(String code) {
    if (code == 'T') return code;
    return cache[code] ??= () {
      final c = catalog.colorOf(code);
      var best = palette.first;
      for (final p in palette) {
        if (dist(c, p) < dist(c, best)) best = p;
      }
      return hex(best);
    }();
  }

  return [
    for (final s in steps)
      BuildStep(label: s.label, text: s.text, bricks: [for (final b in s.bricks) Brick(b.x, b.y, b.z, b.w, b.d, map(b.c), b.h)]),
  ];
}

/// Turns the model by [quarters] × 90° so other sides face the viewer.
List<Placed> rotatePlaced(List<Placed> all, int quarters) {
  var out = all;
  for (var q = 0; q < quarters % 4; q++) {
    final maxY = out.fold<int>(0, (m, p) => p.b.y + p.b.d > m ? p.b.y + p.b.d : m);
    out = [
      for (final p in out)
        Placed(Brick(maxY - p.b.y - p.b.d, p.b.x, p.b.z, p.b.d, p.b.w, p.b.c, p.b.h), p.step),
    ];
  }
  return out;
}

List<Placed> flatten(List<BuildStep> steps) => [
      for (var i = 0; i < steps.length; i++)
        for (final b in steps[i].bricks) Placed(b, i),
    ];

Color shade(Color c, double f) {
  int ch(double v) => (f > 0 ? v + (255 - v) * f : v * (1 + f)).round().clamp(0, 255);
  return Color.fromARGB(255, ch(c.r * 255), ch(c.g * 255), ch(c.b * 255));
}

const _hz = 1.25; // brick height relative to the half-width of a stud cell

/// Isometric renderer for brick models. Front faces point to +x (right) and +y (down-left).
class IsoPainter extends CustomPainter {
  final List<Placed> all;
  final int upto; // last visible step
  final int current; // step that is dropping in
  final double drop; // extra height for the current step, in brick units
  final double pad, maxA;
  final bool shadow;
  /// 0 → no outline, 1 → full yellow outline on the bricks of [current].
  final double glow;

  IsoPainter({
    required this.all,
    this.upto = 1 << 30,
    this.current = -1,
    this.drop = 0,
    this.pad = 16,
    this.maxA = 40,
    this.shadow = true,
    this.glow = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (all.isEmpty) return;
    // Bounds of the whole model, so the camera stays put between steps.
    double mnx = 1e9, mxx = -1e9, mny = 1e9, mxy = -1e9;
    for (final p in all) {
      final b = p.b;
      for (final (x, y) in [(b.x, b.y), (b.x + b.w, b.y), (b.x, b.y + b.d), (b.x + b.w, b.y + b.d)]) {
        for (final z in [b.z, b.z + b.h + .35]) {
          final px = (x - y).toDouble(), py = (x + y) / 2 - z * _hz;
          mnx = math.min(mnx, px);
          mxx = math.max(mxx, px);
          mny = math.min(mny, py);
          mxy = math.max(mxy, py);
        }
      }
    }
    final a = math.min(math.min((size.width - pad * 2) / (mxx - mnx), (size.height - pad * 2) / (mxy - mny)), maxA);
    final ox = size.width / 2 - (mnx + mxx) / 2 * a, oy = size.height / 2 - (mny + mxy) / 2 * a;
    Offset pr(num x, num y, num z) => Offset(ox + (x - y) * a, oy + ((x + y) / 2 - z * _hz) * a);

    if (shadow) {
      double sx0 = 1e9, sx1 = -1e9, sy0 = 1e9, sy1 = -1e9;
      for (final p in all) {
        final b = p.b;
        for (final (x, y) in [(b.x, b.y), (b.x + b.w, b.y + b.d), (b.x + b.w, b.y), (b.x, b.y + b.d)]) {
          final o = pr(x, y, 0);
          sx0 = math.min(sx0, o.dx);
          sx1 = math.max(sx1, o.dx);
          sy0 = math.min(sy0, o.dy);
          sy1 = math.max(sy1, o.dy);
        }
      }
      canvas.drawOval(
        Rect.fromCenter(center: Offset((sx0 + sx1) / 2, (sy0 + sy1) / 2 + a * .3), width: sx1 - sx0 + a * .8, height: sy1 - sy0 + a * .6),
        Paint()..color = const Color(0x1A000000),
      );
    }

    // Split bricks into unit cells and sort back-to-front.
    final cells = <_Cell>[];
    final map = <String, _Cell>{};
    String key(int x, int y, double z) => '$x,$y,${(z * 100).round()}';
    for (final p in all) {
      if (p.step > upto) continue;
      final zz = p.b.z + (p.step == current ? drop : 0);
      for (var dx = 0; dx < p.b.w; dx++) {
        for (var dy = 0; dy < p.b.d; dy++) {
          final c = _Cell(p.b.x + dx, p.b.y + dy, zz, p);
          cells.add(c);
          map[key(c.x, c.y, p.b.z)] = c;
        }
      }
    }
    cells.sort((p, q) {
      final s = (p.x + p.y).compareTo(q.x + q.y);
      if (s != 0) return s;
      final z = p.z.compareTo(q.z);
      return z != 0 ? z : p.x.compareTo(q.x);
    });

    final fill = Paint()..style = PaintingStyle.fill;
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0x38000000)
      ..strokeWidth = math.max(1, a * .035);
    void poly(List<Offset> pts, Color c) {
      final path = Path()..addPolygon(pts, true);
      canvas.drawPath(path, fill..color = c);
    }

    for (final cell in cells) {
      final b = cell.p.b;
      final x = cell.x, y = cell.y, z = cell.z, h = b.h;
      final clear = b.c == 'T';
      final base = catalog.colorOf(b.c);
      final alpha = clear ? .78 : 1.0;
      Color al(Color c) => c.withValues(alpha: alpha);
      final top = al(shade(base, .12)), left = al(shade(base, -.12)), right = al(shade(base, -.28));
      final t0 = pr(x, y, z + h), t1 = pr(x + 1, y, z + h), t2 = pr(x + 1, y + 1, z + h), t3 = pr(x, y + 1, z + h);
      final b1 = pr(x + 1, y, z), b2 = pr(x + 1, y + 1, z), b3 = pr(x, y + 1, z);
      poly([t3, t2, b2, b3], left);
      poly([t1, t2, b2, b1], right);
      poly([t0, t1, t2, t3], top);

      bool same(int dx, int dy) => identical(map[key(x + dx, y + dy, b.z)]?.p, cell.p);
      if (!same(0, 1)) {
        canvas.drawLine(t3, t2, edge);
        canvas.drawLine(b3, b2, edge);
      }
      if (!same(1, 0)) {
        canvas.drawLine(t1, t2, edge);
        canvas.drawLine(b1, b2, edge);
      }
      if (!same(-1, 0)) {
        canvas.drawLine(t0, t3, edge);
        canvas.drawLine(t3, b3, edge);
      }
      if (!same(0, -1)) {
        canvas.drawLine(t0, t1, edge);
        canvas.drawLine(t1, b1, edge);
      }
      if (!same(1, 0) && !same(0, 1)) canvas.drawLine(t2, b2, edge);

      // Stud when nothing sits directly on top.
      final above = map[key(x, y, b.z + h)];
      if (above == null || above.p.step > upto) {
        final c = pr(x + .5, y + .5, z + h);
        final rx = a * .42, ry = a * .21, sh = a * .26;
        fill.color = left;
        canvas.drawOval(Rect.fromCenter(center: c, width: rx * 2, height: ry * 2), fill);
        canvas.drawRect(Rect.fromLTRB(c.dx - rx, c.dy - sh, c.dx + rx, c.dy), fill);
        final topOval = Rect.fromCenter(center: c.translate(0, -sh), width: rx * 2, height: ry * 2);
        canvas.drawOval(topOval, fill..color = al(shade(base, .22)));
        canvas.drawOval(topOval, Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = const Color(0x24000000));
      }

      if (glow > 0 && cell.p.step == current) {
        canvas.drawPath(
          Path()..addPolygon([t0, t1, t2, t3], true),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = const Color(0xFFF6C624).withValues(alpha: .9 * glow),
        );
      }
    }
  }

  @override
  bool shouldRepaint(IsoPainter old) =>
      old.all != all || old.upto != upto || old.current != current || old.drop != drop || old.glow != glow;
}

class _Cell {
  final int x, y;
  final double z;
  final Placed p;
  _Cell(this.x, this.y, this.z, this.p);
}

/// Static model picture (thumbnails, hero).
class ModelPicture extends StatelessWidget {
  final List<Placed> bricks;
  final double maxA, pad;
  final bool shadow;
  const ModelPicture({super.key, required this.bricks, this.maxA = 22, this.pad = 12, this.shadow = true});

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: CustomPaint(painter: IsoPainter(all: bricks, maxA: maxA, pad: pad, shadow: shadow), size: Size.infinite),
      );
}

/// Model shown up to [step]; when the step changes, its bricks drop in with a bounce.
/// [quarters] turns the model, [highlight] keeps a soft outline on the newest bricks after they land.
class StepModelView extends StatefulWidget {
  final List<Placed> bricks;
  final int step, quarters;
  final bool highlight;
  final double maxA, pad;
  const StepModelView({
    super.key,
    required this.bricks,
    required this.step,
    this.quarters = 0,
    this.highlight = true,
    this.maxA = 34,
    this.pad = 22,
  });

  @override
  State<StepModelView> createState() => _StepModelViewState();
}

class _StepModelViewState extends State<StepModelView> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 560))..forward();
  late List<Placed> _shown = rotatePlaced(widget.bricks, widget.quarters);

  @override
  void didUpdateWidget(StepModelView old) {
    super.didUpdateWidget(old);
    if (old.quarters != widget.quarters || old.bricks != widget.bricks) _shown = rotatePlaced(widget.bricks, widget.quarters);
    if (old.step != widget.step) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.of(context).disableAnimations;
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final p = reduce ? 1.0 : _c.value;
          final e = Curves.easeOutCubic.transform(p);
          return CustomPaint(
            size: Size.infinite,
            painter: IsoPainter(
              all: _shown,
              upto: widget.step,
              current: widget.step,
              drop: p < 1 ? (1 - e) * 2.4 : 0,
              maxA: widget.maxA,
              pad: widget.pad,
              glow: p < 1 ? 1 : (widget.highlight ? .55 : 0),
            ),
          );
        },
      ),
    );
  }
}
