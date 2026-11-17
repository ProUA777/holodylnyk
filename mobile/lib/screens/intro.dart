import 'dart:math' as math;
import 'dart:ui' show ImageFilter, lerpDouble;

import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../i18n.dart';
import '../render/iso.dart';
import '../theme.dart';

/// Animated launch in two acts. Picks up from the native splash (Koreec knot in the centre):
///  A. Koreec: the knot settles with a light sweep and twinkles, the wordmark rises under it.
///  B. The knot dissolves, the app's bricks drop into place, the title appears,
///     and the wordmark glides down to become the "from KOREEC" footer.
/// Tap anywhere to skip. Shown once per cold start.
class SplashGate extends StatefulWidget {
  final Widget child;
  const SplashGate({super.key, required this.child});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  bool _done = false;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 450),
        switchInCurve: Curves.easeOutCubic,
        transitionBuilder: (child, a) => FadeTransition(
          opacity: a,
          child: ScaleTransition(scale: Tween(begin: 1.03, end: 1.0).animate(a), child: child),
        ),
        child: _done ? widget.child : _Intro(key: const ValueKey('intro'), onDone: () => setState(() => _done = true)),
      );
}

class _Intro extends StatefulWidget {
  final VoidCallback onDone;
  const _Intro({super.key, required this.onDone});

  @override
  State<_Intro> createState() => _IntroState();
}

class _IntroState extends State<_Intro> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  static const _logo = [
    Placed(Brick(0, 0, 0, 4, 2, 'R', 1), 0),
    Placed(Brick(1, 0, 1, 2, 2, 'Y', 1), 1),
  ];
  static const _knotAspect = 535 / 299, _wordAspect = 593 / 153;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 3400))
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) _finish();
      });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.of(context).disableAnimations) _c.duration = const Duration(milliseconds: 900);
      _c.forward();
    });
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    widget.onDone();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// 0→1 progress of [t] inside the window [a, b].
  static double _seg(double t, double a, double b, [Curve curve = Curves.easeOutCubic]) =>
      curve.transform(((t - a) / (b - a)).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final reduce = MediaQuery.of(context).disableAnimations;
    final knotAsset = dark ? 'assets/brand/knot_dark.png' : 'assets/brand/knot.png';
    final wordAsset = dark ? 'assets/brand/koreec_light.png' : 'assets/brand/koreec_dark.png';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _finish,
      child: Scaffold(
        backgroundColor: p.plate,
        body: LayoutBuilder(builder: (context, box) {
          final pad = MediaQuery.of(context).padding;
          final w = box.maxWidth, h = box.maxHeight;
          final centerY = h * .40;
          return AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final v = _c.value;

              // ── Act A: Koreec ──
              final settle = reduce ? 1.0 : _seg(v, 0, .16, Curves.easeOutBack);
              final knotW = lerpDouble(150, 230, settle)!;
              final sweep = _seg(v, .10, .32, Curves.easeInOut);
              final dissolve = _seg(v, .38, .50, Curves.easeIn);
              final knotOpacity = 1 - dissolve;
              final knotScale = 1 + .15 * dissolve;
              final twinkle = v < .44 ? _seg(v, .08, .20) * (1 - _seg(v, .34, .44)) : 0.0;
              final wordIn = _seg(v, .14, .30);
              final move = _seg(v, .40, .56, Curves.easeInOutCubic);
              final fromIn = _seg(v, .52, .64);

              final wordW = lerpDouble(250, 170, move)!;
              final wordH = wordW / _wordAspect;
              final knotH = knotW / _knotAspect;
              final wordTopA = centerY + 230 / _knotAspect / 2 + 26;
              final wordTopB = h - pad.bottom - 28 - wordH;
              final wordTop = lerpDouble(wordTopA, wordTopB, move)! + 14 * (1 - wordIn);

              // ── Act B: the app ──
              final u = _seg(v, .44, 1.0, Curves.linear);
              final appIn = _seg(u, 0, .14);
              final up = _seg(u, .14, .28), down = _seg(u, .28, .48, Curves.bounceOut);
              final lift = reduce ? 0.0 : (u < .28 ? up * 1.6 : (1 - down) * 1.6);
              final pop = reduce ? 1.0 : .6 + .4 * _seg(u, 0, .2, Curves.easeOutBack);
              final burst = _seg(u, .46, .72);
              final title = _seg(u, .36, .58), tag = _seg(u, .46, .68);
              final studs = _seg(v, .40, .75);

              return Stack(children: [
                Positioned.fill(child: Opacity(opacity: studs, child: CustomPaint(painter: _Studs(p.stud)))),
                // glow: cool silver for Koreec, warm yellow for the bricks
                Positioned(
                  left: w / 2 - 170,
                  top: centerY - 170,
                  width: 340,
                  height: 340,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        Color.lerp(const Color(0xFF7FD3E0), Brand.yellow, move)!.withValues(alpha: .26 * math.max(settle * (1 - dissolve * .6), appIn)),
                        Colors.transparent,
                      ]),
                    ),
                  ),
                ),

                // Act A — knot
                if (knotOpacity > 0)
                  Positioned(
                    left: w / 2 - knotW / 2,
                    top: centerY - knotH / 2,
                    width: knotW,
                    height: knotH,
                    child: Opacity(
                      opacity: knotOpacity,
                      child: Transform.scale(
                        scale: knotScale,
                        child: ImageFiltered(
                          imageFilter: ImageFilter.blur(sigmaX: 8 * dissolve, sigmaY: 8 * dissolve),
                          child: ShaderMask(
                            blendMode: BlendMode.srcATop,
                            shaderCallback: (r) => LinearGradient(
                              begin: Alignment(-1 + 2.6 * sweep - 1.3, -1),
                              end: Alignment(-1 + 2.6 * sweep - .3, 1),
                              colors: [Colors.transparent, Colors.white.withValues(alpha: reduce ? 0 : .55), Colors.transparent],
                              stops: const [.35, .5, .65],
                            ).createShader(r),
                            child: Image.asset(knotAsset, fit: BoxFit.contain, filterQuality: FilterQuality.medium),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (!reduce && twinkle > 0)
                  Positioned(
                    left: w / 2 - knotW / 2 - 30,
                    top: centerY - knotH / 2 - 30,
                    width: knotW + 60,
                    height: knotH + 60,
                    child: IgnorePointer(child: CustomPaint(painter: _Twinkles(v, twinkle))),
                  ),

                // Act B — bricks and title
                if (appIn > 0)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: centerY - 130,
                    child: Column(children: [
                      SizedBox(
                        width: 240,
                        height: 220,
                        child: Opacity(
                          opacity: appIn,
                          child: Stack(clipBehavior: Clip.none, children: [
                            if (!reduce && burst > 0 && burst < 1) Positioned.fill(child: CustomPaint(painter: _Burst(burst))),
                            Positioned.fill(
                              child: Transform.scale(
                                scale: pop,
                                child: CustomPaint(painter: IsoPainter(all: _logo, current: 1, drop: lift, maxA: 44, pad: 18)),
                              ),
                            ),
                          ]),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Opacity(
                        opacity: title,
                        child: Transform.translate(
                          offset: Offset(0, 18 * (1 - title)),
                          child: Text(t('appName'), style: display(40, color: p.ink, height: 1)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Opacity(
                        opacity: tag,
                        child: Transform.translate(
                          offset: Offset(0, 12 * (1 - tag)),
                          child: Text(t('splashTag'), style: body(16, weight: 700, color: p.muted)),
                        ),
                      ),
                    ]),
                  ),

                // wordmark: under the knot in act A, footer in act B
                if (fromIn > 0)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: wordTopB - 24,
                    child: Opacity(
                      opacity: fromIn,
                      child: Text(t('from'),
                          textAlign: TextAlign.center, style: body(12, weight: 800, color: p.muted).copyWith(letterSpacing: 1.6)),
                    ),
                  ),
                Positioned(
                  left: w / 2 - wordW / 2,
                  top: wordTop,
                  width: wordW,
                  height: wordH,
                  child: Opacity(
                    opacity: wordIn,
                    child: Image.asset(wordAsset, fit: BoxFit.contain, filterQuality: FilterQuality.medium, semanticLabel: 'Koreec Project Group'),
                  ),
                ),
              ]);
            },
          );
        }),
      ),
    );
  }
}

class _Studs extends CustomPainter {
  final Color color;
  _Studs(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    const step = 28.0;
    final paint = Paint()..color = color;
    for (double y = step / 2; y < size.height; y += step) {
      for (double x = step / 2; x < size.width; x += step) {
        canvas.drawCircle(Offset(x, y), 7, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_Studs old) => old.color != color;
}

/// Four-point stars twinkling around the knot (echoing the sparkles in the logo).
class _Twinkles extends CustomPainter {
  final double v, strength;
  _Twinkles(this.v, this.strength);

  static const _spots = [(.12, .22), (.88, .18), (.06, .70), (.94, .74), (.30, .04), (.70, .96), (.50, .50)];
  static const _tints = [Color(0xFFFFFFFF), Color(0xFF9FE6F0), Color(0xFFE8B48A)];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < _spots.length; i++) {
      final (x, y) = _spots[i];
      final phase = math.sin((v * 9 + i * 1.7) * math.pi);
      final a = (strength * (.35 + .65 * phase.abs())).clamp(0.0, 1.0);
      final r = 5.0 + 5 * phase.abs();
      final c = Offset(x * size.width, y * size.height);
      paint.color = _tints[i % 3].withValues(alpha: a);
      final path = Path()
        ..moveTo(c.dx, c.dy - r)
        ..quadraticBezierTo(c.dx, c.dy, c.dx + r, c.dy)
        ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r)
        ..quadraticBezierTo(c.dx, c.dy, c.dx - r, c.dy)
        ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_Twinkles old) => old.v != v || old.strength != strength;
}

/// Little studs flying out when the yellow brick lands.
class _Burst extends CustomPainter {
  final double t;
  _Burst(this.t);

  static const _colors = [Brand.red, Brand.yellow, Brand.blue, Brand.green];

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height * .42);
    final paint = Paint();
    for (var i = 0; i < 10; i++) {
      final a = -math.pi / 2 + (i - 4.5) * .33;
      final r = 40 + 95 * t;
      paint.color = _colors[i % 4].withValues(alpha: (1 - t).clamp(0.0, 1.0));
      canvas.drawCircle(c + Offset(math.cos(a), math.sin(a)) * r, 6 * (1 - t * .5), paint);
    }
  }

  @override
  bool shouldRepaint(_Burst old) => old.t != t;
}
