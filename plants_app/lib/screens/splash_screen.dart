import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../l10n.dart';
import '../theme.dart';

/// Анімована заставка у два акти (як у «Що зібрати?»):
/// 1) вузол Koreec осідає, по ньому пробігає відблиск, мерехтять зірочки, з'являється напис;
/// 2) вузол розчиняється, напис їде вниз під «ВІД», а в центрі «фокусується» значок застосунку:
///    кутики видошукача заїжджають, з'являється коло, з нього проростає паросток, розлітаються краплі води.
/// Торкання — пропустити. Показується поверх [child], потім плавно зникає.
class AnimatedSplash extends StatefulWidget {
  const AnimatedSplash({super.key, required this.child});

  final Widget child;

  @override
  State<AnimatedSplash> createState() => _AnimatedSplashState();
}

class _AnimatedSplashState extends State<AnimatedSplash> with TickerProviderStateMixin {
  static const _dur = Duration(milliseconds: 3400);
  late final AnimationController _c = AnimationController(vsync: this, duration: _dur);
  late final AnimationController _out =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
  late final Ticker _clock; // безперервний час — для колихання пари
  double _now = 0;
  bool _gone = false;
  Timer? _hold;

  @override
  void initState() {
    super.initState();
    _clock = createTicker((d) => _now = d.inMilliseconds / 1000)..start();
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed) _hold = Timer(const Duration(milliseconds: 350), _finish);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.of(context).disableAnimations) {
        _c.duration = const Duration(milliseconds: 900);
      }
      _c.forward();
    });
  }

  void _finish() {
    if (!mounted || _out.isAnimating || _gone) return;
    _c.stop();
    _out.forward().then((_) {
      _clock.stop();
      if (mounted) setState(() => _gone = true);
    });
  }

  @override
  void dispose() {
    _hold?.cancel();
    _clock.dispose();
    _c.dispose();
    _out.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_gone) return widget.child;
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        AnimatedBuilder(
          animation: Listenable.merge([_c, _out]),
          builder: (context, _) => Opacity(
            opacity: 1 - _out.value,
            child: Transform.scale(
              scale: 1 + .03 * _out.value,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _finish,
                child: _SplashFrame(v: _c.value, now: _now, reduce: MediaQuery.of(context).disableAnimations),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

double _cl(double x) => x.clamp(0.0, 1.0).toDouble();
double _lerp(double a, double b, double t) => a + (b - a) * t;
double _out3(double x) => 1 - math.pow(1 - x, 3).toDouble();
double _io3(double x) => x < .5 ? 4 * x * x * x : 1 - math.pow(-2 * x + 2, 3) / 2;
double _inQ(double x) => x * x;
double _backOut(double x) {
  const c = 1.70158;
  return 1 + (c + 1) * math.pow(x - 1, 3) + c * math.pow(x - 1, 2);
}

double _seg(double t, double a, double b, [double Function(double) f = _out3]) => f(_cl((t - a) / (b - a)));

class _SplashFrame extends StatelessWidget {
  const _SplashFrame({required this.v, required this.now, required this.reduce});

  final double v; // 0..1 — увесь ролик
  final double now; // секунди — для колихання пари
  final bool reduce;

  static const _knotAspect = 460 / 257;
  static const _wordAspect = 500 / 129;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final t = L10n.of(context);
    final bg = dark ? AppColors.bgDark : AppColors.bg;
    final muted = dark ? const Color(0xFF9DB5A6) : AppColors.muted;
    final ink = dark ? const Color(0xFFEFF8F0) : AppColors.ink;
    final suffix = dark ? '_dark' : '';

    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth, h = box.maxHeight, cy = h * .40;
      final pad = MediaQuery.paddingOf(context).bottom;

      // акт 1
      final settle = reduce ? 1.0 : _seg(v, 0, .16, _backOut);
      final knotW = _lerp(150, 230, settle), knotH = knotW / _knotAspect;
      final sweep = _seg(v, .10, .32, _io3), dissolve = _seg(v, .38, .50, _inQ);
      final twinkle = v < .44 ? _seg(v, .08, .20) * (1 - _seg(v, .34, .44)) : 0.0;
      final wordIn = _seg(v, .14, .30), move = _seg(v, .40, .56, _io3), fromIn = _seg(v, .52, .64);
      final wordW = _lerp(250, 170, move), wordH = wordW / _wordAspect;
      final wordTopB = h - 28 - pad - wordH;
      final wordTop = _lerp(cy + 230 / _knotAspect / 2 + 26, wordTopB, move) + 14 * (1 - wordIn);
      final shine = reduce ? 0.0 : .35 * math.max(0, 1 - (sweep - .5).abs() * 3);

      // акт 2
      final u = _seg(v, .44, 1, (x) => x);
      final appIn = _seg(u, 0, .14), title = _seg(u, .40, .62), tag = _seg(u, .50, .72);
      final glowA = .30 * math.max(settle * (1 - dissolve * .6), appIn);
      final glowC = move < .5 ? AppColors.forest : AppColors.sprout;

      return ColoredBox(
        color: bg,
        child: Stack(children: [
          Positioned.fill(
            child: Opacity(
              opacity: _seg(v, .40, .75),
              child: CustomPaint(painter: _DotsPainter(dark ? AppColors.forestTintDark : AppColors.forestTint)),
            ),
          ),
          Positioned(
            left: w / 2 - 180,
            top: cy - 180,
            width: 360,
            height: 360,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(colors: [glowC.withValues(alpha: glowA), glowC.withValues(alpha: 0)]),
              ),
            ),
          ),
          // вузол Koreec
          Positioned(
            left: w / 2 - knotW / 2,
            top: cy - knotH / 2,
            width: knotW,
            child: Opacity(
              opacity: _cl(1 - dissolve),
              child: Transform.scale(
                scale: 1 + .15 * dissolve,
                child: _blur(
                  8 * dissolve,
                  ColorFiltered(
                    colorFilter: ColorFilter.matrix(_brightness(1 + shine)),
                    child: Image.asset('assets/brand/koreec_knot$suffix.png', gaplessPlayback: true),
                  ),
                ),
              ),
            ),
          ),
          if (!reduce && twinkle > 0)
            Positioned(
              left: w / 2 - (knotW + 60) / 2,
              top: cy - (knotH + 60) / 2,
              width: knotW + 60,
              height: knotH + 60,
              child: CustomPaint(painter: _TwinklePainter(v, twinkle)),
            ),
          // значок застосунку, назва, підпис
          if (appIn > 0)
            Positioned(
              left: 0,
              right: 0,
              top: cy - 125,
              child: Column(children: [
                SizedBox(width: 240, height: 250, child: CustomPaint(painter: _LogoPainter(u, now, reduce))),
                Opacity(
                  opacity: title,
                  child: Transform.translate(
                    offset: Offset(0, 18 * (1 - title)),
                    child: Text(t.splashTitle,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700, color: ink, fontSize: 30, height: 1.1)),
                  ),
                ),
                const SizedBox(height: 10),
                Opacity(
                  opacity: tag,
                  child: Transform.translate(
                    offset: Offset(0, 12 * (1 - tag)),
                    child: Text(t.splashTag,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: muted, fontWeight: FontWeight.w700, fontSize: 16)),
                  ),
                ),
              ]),
            ),
          // «ВІД» + напис Koreec
          Positioned(
            left: 0,
            right: 0,
            top: wordTopB - 24,
            child: Opacity(
              opacity: fromIn,
              child: Text(t.splashFrom,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: muted, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 1.6)),
            ),
          ),
          Positioned(
            left: w / 2 - wordW / 2,
            top: wordTop,
            width: wordW,
            child: Opacity(
              opacity: wordIn,
              child: Image.asset('assets/brand/koreec_word$suffix.png', gaplessPlayback: true),
            ),
          ),
        ]),
      );
    });
  }

  static List<double> _brightness(double k) => [
        k, 0, 0, 0, 0, //
        0, k, 0, 0, 0, //
        0, 0, k, 0, 0, //
        0, 0, 0, 1, 0,
      ];
}

/// Розмиття лише коли воно є (blur(0) на деяких пристроях дає артефакти)
Widget _blur(double sigma, Widget child) =>
    sigma < .05 ? child : ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma), child: child);

class _DotsPainter extends CustomPainter {
  _DotsPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    for (double y = 12; y < size.height; y += 24) {
      for (double x = 12; x < size.width; x += 24) {
        canvas.drawCircle(Offset(x, y), 3, p);
      }
    }
  }

  @override
  bool shouldRepaint(_DotsPainter old) => old.color != color;
}

class _TwinklePainter extends CustomPainter {
  _TwinklePainter(this.v, this.twinkle);
  final double v, twinkle;

  static const _pts = [[.12, .22], [.88, .18], [.06, .70], [.94, .74], [.30, .04], [.70, .96], [.5, .5]];
  static const _tints = [Color(0xFFFFFFFF), AppColors.sprout, AppColors.sun]; // кольори застосунку

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < _pts.length; i++) {
      final ph = math.sin((v * 9 + i * 1.7) * math.pi).abs();
      final a = math.min(1.0, twinkle * (.35 + .65 * ph));
      final r = 5 + 5 * ph, cx = _pts[i][0] * size.width, cy = _pts[i][1] * size.height;
      final path = Path()
        ..moveTo(cx, cy - r)
        ..quadraticBezierTo(cx, cy, cx + r, cy)
        ..quadraticBezierTo(cx, cy, cx, cy + r)
        ..quadraticBezierTo(cx, cy, cx - r, cy)
        ..quadraticBezierTo(cx, cy, cx, cy - r);
      canvas.drawPath(path, Paint()..color = _tints[i % 3].withValues(alpha: a));
    }
  }

  @override
  bool shouldRepaint(_TwinklePainter old) => true;
}

/// Значок застосунку, намальований по частинах (координати як у icon.png 1024×1024)
class _LogoPainter extends CustomPainter {
  _LogoPainter(this.u, this.now, this.reduce);
  final double u, now;
  final bool reduce;

  static const _burst = [AppColors.water, AppColors.sprout, AppColors.sun, AppColors.water, AppColors.forest];

  /// Загострений листок від (x0,y0) до (x1,y1) шириною w — як на значку
  static Path _leaf(double x0, double y0, double x1, double y1, double w) {
    final dx = x1 - x0, dy = y1 - y0, l = math.sqrt(dx * dx + dy * dy);
    final nx = -dy / l, ny = dx / l;
    final p = Path();
    const n = 24;
    for (var i = 0; i <= n; i++) {
      final t = i / n, b = math.pow(math.sin(math.pi * t), .9) * w / 2;
      final x = x0 + dx * t + nx * b, y = y0 + dy * t + ny * b;
      i == 0 ? p.moveTo(x, y) : p.lineTo(x, y);
    }
    for (var i = n; i >= 0; i--) {
      final t = i / n, b = math.pow(math.sin(math.pi * t), .9) * w / 2 * .55;
      p.lineTo(x0 + dx * t - nx * b, y0 + dy * t - ny * b);
    }
    return p..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    const s0 = 170.0;
    final cx = size.width / 2, cy = size.height / 2 + 6;
    final tileIn = reduce ? 1.0 : _backOut(_cl(u / .16));
    final sc = (.55 + .45 * tileIn) * s0 / 1024;
    final tile = RRect.fromRectAndRadius(const Rect.fromLTWH(0, 0, 1024, 1024), const Radius.circular(230));

    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(sc);
    canvas.translate(-512, -512);
    canvas.drawRRect(tile, Paint()..color = AppColors.sprout.withValues(alpha: _cl(u / .08)));

    // кутики видошукача заїжджають ззовні — «фокус»
    final f = reduce ? 1.0 : _seg(u, .10, .32, _backOut), off = (1 - f) * 150;
    final corner = Paint()
      ..color = AppColors.ink.withValues(alpha: _cl((u - .08) / .1))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 58
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final c in const [[199.0, 199.0, 1.0, 1.0], [825.0, 199.0, -1.0, 1.0], [199.0, 825.0, 1.0, -1.0], [825.0, 825.0, -1.0, -1.0]]) {
      final x = c[0] - c[2] * off, y = c[1] - c[3] * off;
      canvas.drawPath(
          Path()
            ..moveTo(x + c[2] * 92, y)
            ..lineTo(x, y)
            ..lineTo(x, y + c[3] * 92),
          corner);
    }

    // темне коло «розкривається»
    final circle = reduce ? 1.0 : _seg(u, .12, .30, _backOut);
    if (circle > 0) {
      canvas.drawCircle(const Offset(512, 512), 215 * circle, Paint()..color = AppColors.ink);
    }

    // паросток росте: горщик → стебло → два листки розкриваються
    final grow = reduce ? 1.0 : _seg(u, .26, .62);
    if (grow > 0) {
      final sprout = Paint()..color = AppColors.sprout;
      canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromCenter(center: const Offset(512, 695), width: 144 * _cl(grow * 3), height: 30),
              const Radius.circular(15)),
          sprout);
      final top = 690 - 210 * _cl(grow * 1.4);
      canvas.drawLine(
          const Offset(512, 700),
          Offset(512, top),
          Paint()
            ..color = AppColors.sprout
            ..strokeWidth = 36
            ..strokeCap = StrokeCap.round);
      final g = _cl((grow - .35) / .65);
      if (g > 0) {
        // легке погойдування після появи
        final sway = reduce ? 0.0 : math.sin(now * 2.2) * 6 * g;
        canvas.drawPath(_leaf(512, top + 40, 512 - 150 * g, top - 60 * g + sway, 100 * g), sprout);
        canvas.drawPath(_leaf(512, top + 10, 512 + 160 * g, top - 100 * g - sway, 110 * g), sprout);
      }
    }
    canvas.restore();

    // краплі води розлітаються, коли паросток розкрився
    final burst = _seg(u, .50, .78);
    if (!reduce && burst > 0 && burst < 1) {
      for (var i = 0; i < 12; i++) {
        final an = -math.pi / 2 + (i - 5.5) * .42, r = 70 + 95 * burst;
        final x = cx + math.cos(an) * r, y = cy + math.sin(an) * r * .9;
        final s = 7 * (1 - burst * .5);
        final drop = Path()
          ..moveTo(x, y - s * 1.6)
          ..quadraticBezierTo(x + s, y - s * .2, x + s, y + s * .3)
          ..arcToPoint(Offset(x - s, y + s * .3), radius: Radius.circular(s))
          ..quadraticBezierTo(x - s, y - s * .2, x, y - s * 1.6)
          ..close();
        canvas.drawPath(drop, Paint()..color = _burst[i % _burst.length].withValues(alpha: 1 - burst));
      }
    }
  }

  @override
  bool shouldRepaint(_LogoPainter old) => true;
}
